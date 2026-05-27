package be.business;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.security.GeneralSecurityException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.fasterxml.jackson.databind.ObjectMapper;

import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.StudentGrade;
import be.business.dtos.StudentGradeRequest;
import be.business.dtos.TeacherGradeFile;

@Service
public class GradeService {

    private static final String SPREADSHEET_NS =
            "urn:schemas-microsoft-com:office:spreadsheet";

    private static final String FU_GRADE_KEY =
            "l10ca968o8e4133tyne2ea2315g19377";

    private static final List<String> DEFAULT_COMPONENTS = List.of(
            "Final Exam",
            "Final Exam Resit",
            "Practical Exam",
            "Progress Test 1",
            "Progress Test 2",
            "Progress Test 3",
            "Project"
    );

    private final ObjectMapper objectMapper = new ObjectMapper();

    private Map<String, List<StudentGrade>> latestClasses;
    private TeacherGradeFile latestTeacherGrade;
    private String latestFgFileName = "grade.fg";
    private String latestExcelFileName = "grades.xlsx";

    public Map<String, List<StudentGrade>> processExcel(
            InputStream inputStream
    ) throws Exception {
        return processExcel(inputStream, null);
    }

    public Map<String, List<StudentGrade>> processExcel(
            InputStream inputStream,
            String originalFilename
    ) throws Exception {

        byte[] bytes = inputStream.readAllBytes();
        FileInfo fileInfo = parseFileName(originalFilename);
        TeacherGradeFile teacherGrade = isXmlSpreadsheet(bytes)
                ? readXmlSpreadsheet(bytes, fileInfo)
                : readPoiWorkbook(bytes, fileInfo);

        normalizeTeacherGrade(teacherGrade);

        Map<String, List<StudentGrade>> classes =
                toStudentClasses(teacherGrade, false);

        latestTeacherGrade = teacherGrade;
        latestClasses = classes;
        latestFgFileName = outputName(originalFilename, "grade", ".fg");
        latestExcelFileName = outputName(originalFilename, "grades", ".xlsx");

        return classes;
    }

    public Map<String, List<StudentGrade>> processFg(
            InputStream inputStream,
            String originalFilename
    ) throws Exception {

        byte[] bytes =
                inputStream.readAllBytes();

        TeacherGradeFile teacherGrade =
                BinaryTeacherGradeReader.canRead(bytes)
                        ? BinaryTeacherGradeReader.read(bytes)
                        : objectMapper.readValue(
                        decryptString(
                                new String(bytes, StandardCharsets.UTF_8)
                                        .trim()
                        ),
                        TeacherGradeFile.class
                );

        normalizeTeacherGrade(teacherGrade);

        Map<String, List<StudentGrade>> classes =
                toStudentClasses(teacherGrade, true);

        latestTeacherGrade = teacherGrade;
        latestClasses = classes;
        latestFgFileName = outputName(originalFilename, "grade", ".fg");
        latestExcelFileName = outputName(originalFilename, "grades", ".xlsx");

        return classes;
    }

    public byte[] generateFGContent(
            Map<String, List<StudentGrade>> data
    ) throws Exception {

        if (data == null || data.isEmpty()) {
            throw new IllegalArgumentException("No grade data available");
        }

        latestClasses = data;
        refreshTeacherGradeFromClasses();

        TeacherGradeFile teacherGrade = latestTeacherGrade != null
                ? latestTeacherGrade
                : buildTeacherGradeFromClasses(data);

        normalizeTeacherGrade(teacherGrade);

        return BinaryTeacherGradeWriter.write(teacherGrade);
    }

    public void refreshTeacherGradeFromClasses() {
        if (latestClasses == null || latestClasses.isEmpty()) {
            latestTeacherGrade = null;
            return;
        }

        if (latestTeacherGrade != null
                && latestTeacherGrade.getSubjectClassGrades() != null
                && !latestTeacherGrade.getSubjectClassGrades().isEmpty()) {

            syncTeacherGradeFromClasses(
                    latestTeacherGrade,
                    latestClasses
            );
            return;
        }

        latestTeacherGrade = buildTeacherGradeFromClasses(latestClasses);
    }

    public StudentGrade buildStudent(
            StudentGradeRequest request
    ) {

        Double finalExam =
                roundScore(request.getFinalExam());
        Double finalResit =
                roundScore(request.getFinalExamResit());
        Double practical =
                roundScore(request.getPracticalExam());
        Double pt1 =
                roundScore(request.getPt1());
        Double pt2 =
                roundScore(request.getPt2());
        Double pt3 =
                roundScore(request.getPt3());
        Double project =
                roundScore(request.getProject());

        Double finalUsed =
                finalResit != null
                        ? finalResit
                        : finalExam;

        Double total =
                null;
        String resultStatus =
                null;

        if (finalUsed != null
                && practical != null
                && pt1 != null
                && pt2 != null
                && pt3 != null
                && project != null) {

            double progressAvg =
                    (pt1 + pt2 + pt3) / 3.0;

            total =
                    round(
                            finalUsed * 0.30
                                    + practical * 0.25
                                    + progressAvg * 0.15
                                    + project * 0.30
                    );

            resultStatus =
                    total >= 5
                            && finalUsed >= 4
                            && practical >= 4
                            ? "PASS"
                            : "FAIL";
        }

        StudentGrade student =
                new StudentGrade();

        SubjectClassParts subjectClassParts =
                subjectClassParts(
                        request.getSubject(),
                        request.getClassName()
                );

        student.setSubject(subjectClassParts.subject());
        student.setClassName(subjectClassParts.className());

        student.setRollNumber(request.getRollNumber());
        student.setEmail(request.getEmail());
        student.setMemberCode(request.getMemberCode());
        student.setFullName(request.getFullName());

        student.setExamDate(request.getExamDate());
        student.setExamNote(request.getExamNote());

        student.setFinalExam(finalExam);
        student.setFinalComment(request.getFinalExamComment());

        student.setFinalResit(finalResit);
        student.setFinalResitComment(request.getFinalExamResitComment());

        student.setPractical(practical);
        student.setPracticalComment(request.getPracticalExamComment());

        student.setPt1(pt1);
        student.setPt1Comment(request.getPt1Comment());

        student.setPt2(pt2);
        student.setPt2Comment(request.getPt2Comment());

        student.setPt3(pt3);
        student.setPt3Comment(request.getPt3Comment());

        student.setProject(project);
        student.setProjectComment(request.getProjectComment());

        student.setTotal(total);
        student.setResult(resultStatus);
        student.setComment(null);

        return student;
    }

    public String resolveClassKey(StudentGrade student) {
        String subject =
                nullToEmpty(student.getSubject()).trim();
        String className =
                nullToEmpty(student.getClassName()).trim();
        String subjectClassKey =
                subjectClassKey(subject, className);

        if (latestClasses == null || latestClasses.isEmpty()) {
            return !subjectClassKey.isBlank()
                    ? subjectClassKey
                    : className;
        }

        if (!subjectClassKey.isBlank()
                && latestClasses.containsKey(subjectClassKey)) {
            return subjectClassKey;
        }

        if (!className.isBlank()
                && latestClasses.containsKey(className)) {
            return className;
        }

        for (Map.Entry<String, List<StudentGrade>> entry
                : latestClasses.entrySet()) {

            if (matchesClassKey(
                    entry.getKey(),
                    subject,
                    className
            )) {
                return entry.getKey();
            }

            if (matchesStudentClass(
                    entry.getValue(),
                    subject,
                    className
            )) {
                return entry.getKey();
            }
        }

        return !subjectClassKey.isBlank()
                ? subjectClassKey
                : className;
    }

    public StudentGradeRequest toStudentGradeRequest(
            StudentGrade student
    ) {

        StudentGradeRequest request =
                new StudentGradeRequest();

        request.setSubject(student.getSubject());
        request.setClassName(student.getClassName());
        request.setRollNumber(student.getRollNumber());
        request.setEmail(student.getEmail());
        request.setMemberCode(student.getMemberCode());
        request.setFullName(student.getFullName());

        request.setExamDate(student.getExamDate());
        request.setExamNote(student.getExamNote());

        request.setFinalExam(student.getFinalExam());
        request.setFinalExamComment(student.getFinalComment());

        request.setFinalExamResit(student.getFinalResit());
        request.setFinalExamResitComment(
                student.getFinalResitComment()
        );

        request.setPracticalExam(student.getPractical());
        request.setPracticalExamComment(
                student.getPracticalComment()
        );

        request.setPt1(student.getPt1());
        request.setPt1Comment(student.getPt1Comment());

        request.setPt2(student.getPt2());
        request.setPt2Comment(student.getPt2Comment());

        request.setPt3(student.getPt3());
        request.setPt3Comment(student.getPt3Comment());

        request.setProject(student.getProject());
        request.setProjectComment(student.getProjectComment());

        return request;
    }

    private TeacherGradeFile readXmlSpreadsheet(
            byte[] bytes,
            FileInfo fileInfo
    ) throws Exception {

        DocumentBuilderFactory factory =
                DocumentBuilderFactory.newInstance();

        factory.setNamespaceAware(true);
        factory.setFeature(
                "http://apache.org/xml/features/disallow-doctype-decl",
                true
        );
        factory.setFeature(
                "http://xml.org/sax/features/external-general-entities",
                false
        );
        factory.setFeature(
                "http://xml.org/sax/features/external-parameter-entities",
                false
        );
        factory.setAttribute(
                XMLConstants.ACCESS_EXTERNAL_DTD,
                ""
        );
        factory.setAttribute(
                XMLConstants.ACCESS_EXTERNAL_SCHEMA,
                ""
        );

        DocumentBuilder builder =
                factory.newDocumentBuilder();

        Document document =
                builder.parse(new ByteArrayInputStream(bytes));

        NodeList worksheets =
                document.getElementsByTagNameNS(
                        SPREADSHEET_NS,
                        "Worksheet"
                );

        if (worksheets.getLength() == 0) {
            worksheets =
                    document.getElementsByTagName("Worksheet");
        }

        TeacherGradeFile teacherGrade =
                createTeacherGrade(fileInfo);

        Map<String, FgSubjectClassGrade> subjectClasses =
                new LinkedHashMap<>();
        boolean useSheetNameAsClass =
                worksheets.getLength() > 1;

        for (int i = 0; i < worksheets.getLength(); i++) {
            Element worksheet =
                    (Element) worksheets.item(i);

            String sheetName =
                    getSpreadsheetAttribute(worksheet, "Name");

            NodeList rowNodes =
                    worksheet.getElementsByTagNameNS(
                            SPREADSHEET_NS,
                            "Row"
                    );

            if (rowNodes.getLength() == 0) {
                rowNodes = worksheet.getElementsByTagName("Row");
            }

            List<List<String>> rows =
                    new ArrayList<>();

            for (int r = 0; r < rowNodes.getLength(); r++) {
                rows.add(readXmlRow((Element) rowNodes.item(r)));
            }

            appendWorksheetRows(
                    teacherGrade,
                    subjectClasses,
                    fileInfo,
                    sheetName,
                    rows,
                    useSheetNameAsClass
            );
        }

        sortStudents(teacherGrade);

        return teacherGrade;
    }

    private TeacherGradeFile readPoiWorkbook(
            byte[] bytes,
            FileInfo fileInfo
    ) throws Exception {

        TeacherGradeFile teacherGrade =
                createTeacherGrade(fileInfo);

        Map<String, FgSubjectClassGrade> subjectClasses =
                new LinkedHashMap<>();

        try (Workbook workbook = WorkbookFactory.create(
                new ByteArrayInputStream(bytes)
        )) {
            DataFormatter formatter =
                    new DataFormatter(Locale.US);
            boolean useSheetNameAsClass =
                    workbook.getNumberOfSheets() > 1;

            for (int s = 0; s < workbook.getNumberOfSheets(); s++) {
                org.apache.poi.ss.usermodel.Sheet sheet =
                        workbook.getSheetAt(s);

                List<List<String>> rows =
                        new ArrayList<>();

                for (Row row : sheet) {
                    int lastCell = Math.max(row.getLastCellNum(), 0);
                    List<String> values =
                            new ArrayList<>();

                    for (int c = 0; c < lastCell; c++) {
                        values.add(
                                formatter.formatCellValue(row.getCell(c))
                                        .trim()
                        );
                    }

                    rows.add(values);
                }

                appendWorksheetRows(
                        teacherGrade,
                        subjectClasses,
                        fileInfo,
                        sheet.getSheetName(),
                        rows,
                        useSheetNameAsClass
                );
            }
        }

        sortStudents(teacherGrade);

        return teacherGrade;
    }

    private void appendWorksheetRows(
            TeacherGradeFile teacherGrade,
            Map<String, FgSubjectClassGrade> subjectClasses,
            FileInfo fileInfo,
            String sheetName,
            List<List<String>> rows,
            boolean useSheetNameAsClass
    ) {

        List<List<String>> nonBlankRows =
                rows.stream()
                        .filter(row -> row.stream()
                                .anyMatch(value ->
                                        value != null && !value.isBlank()))
                        .collect(Collectors.toList());

        if (nonBlankRows.size() < 2) {
            return;
        }

        List<String> headers =
                nonBlankRows.get(0);

        Map<String, Integer> headerMap =
                buildHeaderMap(headers);

        List<String> components =
                getGradingComponents(headers);

        for (int r = 1; r < nonBlankRows.size(); r++) {
            List<String> row =
                    nonBlankRows.get(r);

            String roll =
                    getCell(row, headerMap, "RollNumber", "Roll");

            if (roll.isBlank()) {
                continue;
            }

            String className =
                    useSheetNameAsClass && !blank(sheetName)
                            ? sheetName
                            : getCell(row, headerMap, "Class");

            if (className.isBlank()) {
                className = !blank(sheetName)
                        ? sheetName
                        : fileInfo.className();
            }

            String subject =
                    !blank(fileInfo.subjectCode())
                            ? fileInfo.subjectCode()
                            : firstSubjectOrDefault(teacherGrade);

            SubjectClassParts subjectClassParts =
                    subjectClassParts(subject, className);

            subject =
                    subjectClassParts.subject();
            className =
                    subjectClassParts.className();

            String key =
                    normalize(subject) + "/" + normalize(className);

            final String subjectForClass = subject;
            final String classNameForClass = className;
            final List<String> componentsForClass = components;

            FgSubjectClassGrade subjectClass =
                    subjectClasses.computeIfAbsent(key, ignored -> {
                        FgSubjectClassGrade created =
                                new FgSubjectClassGrade();

                        created.setSubject(subjectForClass);
                        created.setClassName(classNameForClass);
                        created.setComponents(
                                new ArrayList<>(componentsForClass)
                        );
                        teacherGrade.getSubjectClassGrades()
                                .add(created);

                        return created;
                    });

            subjectClass.getStudents()
                    .add(mapFgStudent(row, headerMap, components));
        }
    }

    private FgStudent mapFgStudent(
            List<String> row,
            Map<String, Integer> headerMap,
            List<String> components
    ) {

        FgStudent student =
                new FgStudent();

        student.setRoll(
                emptyToNull(getCell(row, headerMap, "RollNumber", "Roll"))
        );
        student.setName(
                emptyToNull(getCell(row, headerMap, "FullName", "Name"))
        );
        student.setEmail(
                emptyToNull(getCell(row, headerMap, "Email"))
        );
        student.setMemberCode(
                emptyToNull(getCell(row, headerMap, "MemberCode"))
        );
        student.setExamDate(
                emptyToNull(getCell(row, headerMap, "ExamDate"))
        );
        student.setExamNote(
                emptyToNull(getCell(row, headerMap, "ExamNote"))
        );
        student.setFinalExamComment(
                excelComment(row, headerMap, "Final Exam")
        );
        student.setFinalExamResitComment(
                excelComment(row, headerMap, "Final Exam Resit")
        );
        student.setPracticalExamComment(
                excelComment(row, headerMap, "Practical Exam")
        );
        student.setProgressTest1Comment(
                excelComment(row, headerMap, "Progress Test 1")
        );
        student.setProgressTest2Comment(
                excelComment(row, headerMap, "Progress Test 2")
        );
        student.setProgressTest3Comment(
                excelComment(row, headerMap, "Progress Test 3")
        );
        student.setProjectComment(
                excelComment(row, headerMap, "Project")
        );
        student.setComment(
                buildStudentComment(row, headerMap)
        );

        List<FgGradeComponent> grades =
                new ArrayList<>();

        for (String component : components) {
            FgGradeComponent grade =
                    new FgGradeComponent();

            grade.setComponent(component);
            grade.setGrade(
                    parseNullableFloat(
                            getCell(row, headerMap, component)
                    )
            );

            grades.add(grade);
        }

        student.setGrades(grades);

        return student;
    }

    private List<String> readXmlRow(Element row) {
        List<String> values =
                new ArrayList<>();

        int nextIndex = 1;
        NodeList nodes =
                row.getChildNodes();

        for (int i = 0; i < nodes.getLength(); i++) {
            Node node =
                    nodes.item(i);

            if (!(node instanceof Element cell)
                    || !"Cell".equals(cell.getLocalName())) {
                continue;
            }

            String indexAttr =
                    getSpreadsheetAttribute(cell, "Index");

            if (!indexAttr.isBlank()) {
                int cellIndex =
                        Integer.parseInt(indexAttr);

                while (nextIndex < cellIndex) {
                    values.add("");
                    nextIndex++;
                }
            }

            values.add(readCellData(cell));
            nextIndex++;
        }

        return values;
    }

    private String readCellData(Element cell) {
        NodeList dataNodes =
                cell.getElementsByTagNameNS(
                        SPREADSHEET_NS,
                        "Data"
                );

        if (dataNodes.getLength() == 0) {
            dataNodes = cell.getElementsByTagName("Data");
        }

        if (dataNodes.getLength() == 0) {
            return "";
        }

        return dataNodes.item(0)
                .getTextContent()
                .trim();
    }

    private Map<String, List<StudentGrade>> toStudentClasses(
            TeacherGradeFile teacherGrade,
            boolean inferStudentAccount
    ) {

        Map<String, List<StudentGrade>> classes =
                new LinkedHashMap<>();

        if (teacherGrade == null
                || teacherGrade.getSubjectClassGrades() == null) {
            return classes;
        }

        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

            String className =
                    subjectClass.getClassName();
            String subject =
                    subjectClass.getSubject();
            String classKey =
                    subjectClassKey(subjectClass);

            List<StudentGrade> students =
                    classes.computeIfAbsent(
                            classKey,
                            ignored -> new ArrayList<>()
                    );

            if (subjectClass.getStudents() == null) {
                continue;
            }

            for (FgStudent fgStudent : subjectClass.getStudents()) {
                StudentGradeRequest request =
                        new StudentGradeRequest();

                request.setSubject(subject);
                request.setClassName(className);
                request.setRollNumber(fgStudent.getRoll());
                request.setEmail(fgStudent.getEmail());
                request.setMemberCode(fgStudent.getMemberCode());
                request.setFullName(fgStudent.getName());
                request.setExamDate(fgStudent.getExamDate());
                request.setExamNote(fgStudent.getExamNote());
                request.setFinalExamComment(
                        fgStudent.getFinalExamComment()
                );
                request.setFinalExamResitComment(
                        fgStudent.getFinalExamResitComment()
                );
                request.setPracticalExamComment(
                        fgStudent.getPracticalExamComment()
                );
                request.setPt1Comment(
                        fgStudent.getProgressTest1Comment()
                );
                request.setPt2Comment(
                        fgStudent.getProgressTest2Comment()
                );
                request.setPt3Comment(
                        fgStudent.getProgressTest3Comment()
                );
                request.setProjectComment(fgStudent.getProjectComment());

                if (inferStudentAccount) {
                    inferStudentAccount(request);
                }

                Map<String, Float> gradeMap =
                        toGradeMap(fgStudent);

                request.setFinalExam(
                        gradeOrNull(gradeMap, "Final Exam")
                );
                request.setFinalExamResit(
                        gradeOrNull(gradeMap, "Final Exam Resit")
                );
                request.setPracticalExam(
                        gradeOrNull(gradeMap, "Practical Exam")
                );
                request.setPt1(
                        gradeOrNull(gradeMap, "Progress Test 1")
                );
                request.setPt2(
                        gradeOrNull(gradeMap, "Progress Test 2")
                );
                request.setPt3(
                        gradeOrNull(gradeMap, "Progress Test 3")
                );
                request.setProject(
                        firstGradeOrNull(
                                gradeMap,
                                "Project",
                                "Group Project",
                                "Course Project",
                                "Final Project",
                                "Final Project Presentation"
                        )
                );

                applyFgCommentToRequest(
                        fgStudent.getComment(),
                        request
                );

                StudentGrade student =
                        buildStudent(request);

                student.setGradeComponents(
                        copyGradeComponents(fgStudent.getGrades())
                );

                if (!blank(fgStudent.getComment())) {
                    student.setComment(fgStudent.getComment());
                }

                students.add(student);
            }
        }

        return classes;
    }

    private String subjectClassKey(FgSubjectClassGrade subjectClass) {
        String subject =
                subjectClass.getSubject();
        String className =
                subjectClass.getClassName();

        return subjectClassKey(subject, className);
    }

    private String subjectClassKey(
            String subject,
            String className
    ) {
        String cleanSubject =
                nullToEmpty(subject).trim();
        String cleanClassName =
                nullToEmpty(className).trim();

        if (cleanSubject.isBlank()) {
            return cleanClassName;
        }

        if (cleanClassName.isBlank()) {
            return cleanSubject;
        }

        return cleanSubject + "_" + cleanClassName;
    }

    private boolean matchesClassKey(
            String key,
            String subject,
            String className
    ) {

        SubjectClassParts parts =
                splitCombinedSubjectClass(key);

        if (parts == null) {
            return false;
        }

        boolean sameClass =
                Objects.equals(
                        normalize(parts.className()),
                        normalize(className)
                );
        boolean sameSubject =
                blank(subject)
                        || Objects.equals(
                                normalize(parts.subject()),
                                normalize(subject)
                        );

        return sameClass && sameSubject;
    }

    private boolean matchesStudentClass(
            List<StudentGrade> students,
            String subject,
            String className
    ) {

        if (students == null) {
            return false;
        }

        for (StudentGrade student : students) {
            boolean sameClass =
                    Objects.equals(
                            normalize(student.getClassName()),
                            normalize(className)
                    );
            boolean sameSubject =
                    blank(subject)
                            || blank(student.getSubject())
                            || Objects.equals(
                                    normalize(student.getSubject()),
                                    normalize(subject)
                            );

            if (sameClass && sameSubject) {
                return true;
            }
        }

        return false;
    }

    private void normalizeSubjectClass(
            FgSubjectClassGrade subjectClass
    ) {

        SubjectClassParts parts =
                subjectClassParts(
                        subjectClass.getSubject(),
                        subjectClass.getClassName()
                );

        subjectClass.setSubject(parts.subject());
        subjectClass.setClassName(parts.className());
    }

    private SubjectClassParts subjectClassParts(
            String subject,
            String className
    ) {

        String cleanedSubject =
                emptyToNull(nullToEmpty(subject).trim());
        String cleanedClassName =
                emptyToNull(nullToEmpty(className).trim());

        SubjectClassParts fromClassName =
                splitCombinedSubjectClass(cleanedClassName);

        if (fromClassName != null) {
            return fromClassName;
        }

        return new SubjectClassParts(cleanedSubject, cleanedClassName);
    }

    private SubjectClassParts splitCombinedSubjectClass(String value) {
        if (blank(value)) {
            return null;
        }

        int separator =
                value.indexOf('_');

        if (separator <= 0 || separator == value.length() - 1) {
            return null;
        }

        String subject =
                value.substring(0, separator).trim();
        String className =
                value.substring(separator + 1).trim();

        if (!looksLikeSubjectCode(subject) || className.isBlank()) {
            return null;
        }

        return new SubjectClassParts(subject, className);
    }

    private boolean looksLikeSubjectCode(String value) {
        return !blank(value)
                && value.trim()
                .matches("[A-Za-z]{2,5}\\d{3}[A-Za-z]?");
    }

    private List<FgGradeComponent> copyGradeComponents(
            List<FgGradeComponent> source
    ) {

        if (source == null) {
            return null;
        }

        List<FgGradeComponent> copy =
                new ArrayList<>();

        for (FgGradeComponent grade : source) {
            FgGradeComponent item =
                    new FgGradeComponent();

            item.setComponent(grade.getComponent());
            item.setGrade(grade.getGrade());
            copy.add(item);
        }

        return copy;
    }

    private void syncTeacherGradeFromClasses(
            TeacherGradeFile teacherGrade,
            Map<String, List<StudentGrade>> data
    ) {

        Map<String, FgSubjectClassGrade> existingSubjectClasses =
                existingSubjectClassLookup(teacherGrade);
        List<FgSubjectClassGrade> syncedSubjectClasses =
                new ArrayList<>();

        for (Map.Entry<String, List<StudentGrade>> entry
                : data.entrySet()) {

            List<StudentGrade> classStudents =
                    entry.getValue() == null
                            ? List.of()
                            : entry.getValue();
            String className =
                    firstStudentClassName(classStudents, entry.getKey());
            String subject =
                    firstStudentSubject(
                            classStudents,
                            latestSubjectForClass(className)
                    );
            SubjectClassParts parts =
                    subjectClassParts(subject, className);
            FgSubjectClassGrade subjectClass =
                    existingSubjectClass(
                            existingSubjectClasses,
                            entry.getKey(),
                            parts
                    );

            if (subjectClass == null) {
                subjectClass = new FgSubjectClassGrade();
            }

            subjectClass.setSubject(parts.subject());
            subjectClass.setClassName(parts.className());

            Map<String, FgStudent> previousStudents =
                    previousStudentsByRoll(subjectClass);
            List<String> components =
                    subjectClass.getComponents() == null
                            || subjectClass.getComponents().isEmpty()
                            ? DEFAULT_COMPONENTS
                            : subjectClass.getComponents();
            List<FgStudent> students =
                    new ArrayList<>();

            for (StudentGrade student : classStudents) {
                FgStudent previous =
                        previousStudents.get(
                                normalize(student.getRollNumber())
                        );

                students.add(
                        toFgStudent(
                                student,
                                components,
                                previous
                        )
                );
            }

            subjectClass.setComponents(new ArrayList<>(components));
            subjectClass.setStudents(students);
            syncedSubjectClasses.add(subjectClass);
        }

        teacherGrade.setSubjectClassGrades(syncedSubjectClasses);
        normalizeTeacherGrade(teacherGrade);
        sortStudents(teacherGrade);
    }

    private Map<String, FgSubjectClassGrade> existingSubjectClassLookup(
            TeacherGradeFile teacherGrade
    ) {

        Map<String, FgSubjectClassGrade> existing =
                new HashMap<>();

        if (teacherGrade.getSubjectClassGrades() == null) {
            return existing;
        }

        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

            putSubjectClassLookup(
                    existing,
                    subjectClassKey(subjectClass),
                    subjectClass
            );
            putSubjectClassLookup(
                    existing,
                    subjectClass.getClassName(),
                    subjectClass
            );
        }

        return existing;
    }

    private void putSubjectClassLookup(
            Map<String, FgSubjectClassGrade> existing,
            String key,
            FgSubjectClassGrade subjectClass
    ) {

        String normalized =
                normalize(key);

        if (!normalized.isBlank()) {
            existing.putIfAbsent(normalized, subjectClass);
        }
    }

    private FgSubjectClassGrade existingSubjectClass(
            Map<String, FgSubjectClassGrade> existing,
            String classKey,
            SubjectClassParts parts
    ) {

        FgSubjectClassGrade subjectClass =
                existing.get(normalize(classKey));

        if (subjectClass != null) {
            return subjectClass;
        }

        FgSubjectClassGrade probe =
                new FgSubjectClassGrade();
        probe.setSubject(parts.subject());
        probe.setClassName(parts.className());

        subjectClass =
                existing.get(normalize(subjectClassKey(probe)));

        if (subjectClass != null) {
            return subjectClass;
        }

        return existing.get(normalize(parts.className()));
    }

    private Map<String, FgStudent> previousStudentsByRoll(
            FgSubjectClassGrade subjectClass
    ) {

        if (subjectClass.getStudents() == null) {
            return Map.of();
        }

        return subjectClass.getStudents().stream()
                .filter(student -> !blank(student.getRoll()))
                .collect(
                        Collectors.toMap(
                                student -> normalize(student.getRoll()),
                                student -> student,
                                (left, right) -> left
                        )
                );
    }

    private TeacherGradeFile buildTeacherGradeFromClasses(
            Map<String, List<StudentGrade>> data
    ) {

        TeacherGradeFile teacherGrade =
                new TeacherGradeFile();

        teacherGrade.setVersion("1.1");
        teacherGrade.setSemester(latestSemester());
        teacherGrade.setLogin(latestLogin());
        teacherGrade.setPassword(latestPassword());

        for (Map.Entry<String, List<StudentGrade>> entry
                : data.entrySet()) {

            FgSubjectClassGrade subjectClass =
                    new FgSubjectClassGrade();
            List<StudentGrade> sourceStudents =
                    entry.getValue() == null
                            ? List.of()
                            : entry.getValue();
            String className =
                    firstStudentClassName(sourceStudents, entry.getKey());
            String subject =
                    firstStudentSubject(
                            sourceStudents,
                            latestSubjectForClass(className)
                    );
            SubjectClassParts subjectClassParts =
                    subjectClassParts(subject, className);

            subjectClass.setSubject(subjectClassParts.subject());
            subjectClass.setClassName(subjectClassParts.className());
            subjectClass.setComponents(new ArrayList<>(DEFAULT_COMPONENTS));

            List<StudentGrade> sortedStudents =
                    new ArrayList<>(sourceStudents);

            sortedStudents.sort((left, right) ->
                    nullToEmpty(left.getRollNumber())
                            .compareTo(
                                    nullToEmpty(right.getRollNumber())
                            ));

            for (StudentGrade student : sortedStudents) {
                subjectClass.getStudents()
                        .add(toFgStudent(student));
            }

            teacherGrade.getSubjectClassGrades()
                    .add(subjectClass);
        }

        return teacherGrade;
    }

    private String firstStudentClassName(
            List<StudentGrade> students,
            String fallback
    ) {

        for (StudentGrade student : students) {
            if (!blank(student.getClassName())) {
                return student.getClassName();
            }
        }

        return fallback;
    }

    private String firstStudentSubject(
            List<StudentGrade> students,
            String fallback
    ) {

        for (StudentGrade student : students) {
            if (!blank(student.getSubject())) {
                return student.getSubject();
            }
        }

        return fallback;
    }

    private FgStudent toFgStudent(StudentGrade student) {
        return toFgStudent(
                student,
                DEFAULT_COMPONENTS,
                null
        );
    }

    private FgStudent toFgStudent(
            StudentGrade student,
            List<String> components,
            FgStudent previous
    ) {
        FgStudent fgStudent =
                new FgStudent();

        fgStudent.setRoll(student.getRollNumber());
        fgStudent.setName(student.getFullName());
        fgStudent.setEmail(student.getEmail());
        fgStudent.setMemberCode(student.getMemberCode());
        fgStudent.setExamDate(student.getExamDate());
        fgStudent.setExamNote(student.getExamNote());
        fgStudent.setFinalExamComment(student.getFinalComment());
        fgStudent.setFinalExamResitComment(
                student.getFinalResitComment()
        );
        fgStudent.setPracticalExamComment(student.getPracticalComment());
        fgStudent.setProgressTest1Comment(student.getPt1Comment());
        fgStudent.setProgressTest2Comment(student.getPt2Comment());
        fgStudent.setProgressTest3Comment(student.getPt3Comment());
        fgStudent.setProjectComment(student.getProjectComment());
        fgStudent.setComment(buildCombinedComment(student));

        Map<String, Float> previousGrades =
                previous == null
                        ? Map.of()
                        : toGradeMap(previous);

        List<FgGradeComponent> grades =
                new ArrayList<>();

        for (String component : components) {
            FgGradeComponent grade =
                    new FgGradeComponent();

            grade.setComponent(component);

            Float value =
                    componentGrade(student, component);

            if (value == null) {
                value = previousGrades.get(normalize(component));
            }

            grade.setGrade(value);
            grades.add(grade);
        }

        fgStudent.setGrades(grades);

        return fgStudent;
    }

    private Float componentGrade(
            StudentGrade student,
            String component
    ) {

        return switch (normalize(component)) {
            case "finalexam" -> toFloat(student.getFinalExam());
            case "finalexamresit" -> optionalResit(student.getFinalResit());
            case "practicalexam" -> toFloat(student.getPractical());
            case "progresstest1" -> toFloat(student.getPt1());
            case "progresstest2" -> toFloat(student.getPt2());
            case "progresstest3" -> toFloat(student.getPt3());
            case "project",
                    "groupproject",
                    "courseproject",
                    "finalproject",
                    "finalprojectpresentation" ->
                    toFloat(student.getProject());
            default -> null;
        };
    }

    private String buildCombinedComment(StudentGrade student) {
        return blank(student.getComment())
                ? ""
                : student.getComment();
    }

    private void applyFgCommentToRequest(
            String comment,
            StudentGradeRequest request
    ) {

        if (blank(comment)) {
            return;
        }

        for (String part : comment.split(";")) {
            String[] pieces =
                    part.split(":", 2);

            if (pieces.length != 2) {
                continue;
            }

            String component =
                    normalize(pieces[0]);
            String value =
                    pieces[1].trim();

            switch (component) {
                case "finalexam" ->
                        request.setFinalExamComment(value);
                case "finalexamresit" ->
                        request.setFinalExamResitComment(value);
                case "practicalexam" ->
                        request.setPracticalExamComment(value);
                case "progresstest1" ->
                        request.setPt1Comment(value);
                case "progresstest2" ->
                        request.setPt2Comment(value);
                case "progresstest3" ->
                        request.setPt3Comment(value);
                case "project" ->
                        request.setProjectComment(value);
                default -> {
                }
            }
        }
    }

    private void inferStudentAccount(StudentGradeRequest request) {
        String accountCode =
                studentAccountCode(
                        request.getFullName(),
                        request.getRollNumber()
                );

        if (blank(accountCode)) {
            return;
        }

        if (blank(request.getMemberCode())) {
            request.setMemberCode(accountCode);
        }

        if (blank(request.getEmail())) {
            request.setEmail(accountCode + "@fpt.edu.vn");
        }
    }

    private String studentAccountCode(
            String fullName,
            String rollNumber
    ) {

        String normalizedName =
                asciiLower(fullName)
                        .replaceAll("[^a-z\\s]", " ")
                        .trim();
        String normalizedRoll =
                asciiLower(rollNumber)
                        .replaceAll("[^a-z0-9]", "");

        if (normalizedName.isBlank() || normalizedRoll.isBlank()) {
            return null;
        }

        String[] parts =
                normalizedName.split("\\s+");

        if (parts.length == 0) {
            return null;
        }

        StringBuilder account =
                new StringBuilder(parts[parts.length - 1]);

        for (int i = 0; i < parts.length - 1; i++) {
            if (!parts[i].isBlank()) {
                account.append(parts[i].charAt(0));
            }
        }

        account.append(normalizedRoll);

        return account.toString();
    }

    private String asciiLower(String value) {
        if (value == null) {
            return "";
        }

        String normalized =
                Normalizer.normalize(
                                value.trim(),
                                Normalizer.Form.NFD
                        )
                        .replace("đ", "d")
                        .replace("Đ", "D")
                        .replaceAll("\\p{M}", "");

        return normalized.toLowerCase(Locale.ROOT);
    }

    private String buildStudentComment(
            List<String> row,
            Map<String, Integer> headerMap
    ) {

        String directComment =
                getCell(row, headerMap, "Comment", "Comments");

        if (!directComment.isBlank()) {
            return directComment;
        }

        return "";
    }

    private String excelComment(
            List<String> row,
            Map<String, Integer> headerMap,
            String component
    ) {

        return emptyToNull(
                getCell(
                        row,
                        headerMap,
                        component + "_Comment",
                        component + " Comment",
                        component + "Comment"
                )
        );
    }

    private List<String> getGradingComponents(
            List<String> headers
    ) {

        return headers.stream()
                .filter(header -> header != null && !header.isBlank())
                .filter(header -> !isStudentInfoColumn(header))
                .filter(header -> !isCommentColumn(header))
                .collect(Collectors.toList());
    }

    private Map<String, Integer> buildHeaderMap(
            List<String> headers
    ) {

        Map<String, Integer> headerMap =
                new HashMap<>();

        for (int i = 0; i < headers.size(); i++) {
            String normalized =
                    normalize(headers.get(i));

            if (!normalized.isBlank()) {
                headerMap.put(normalized, i);
            }
        }

        return headerMap;
    }

    private String getCell(
            List<String> row,
            Map<String, Integer> headerMap,
            String... headers
    ) {

        for (String header : headers) {
            Integer index =
                    headerMap.get(normalize(header));

            if (index != null && index < row.size()) {
                return nullToEmpty(row.get(index)).trim();
            }
        }

        return "";
    }

    private boolean isStudentInfoColumn(String header) {
        String normalized =
                normalize(header);

        return switch (normalized) {
            case "class",
                    "roll",
                    "rollnumber",
                    "email",
                    "membercode",
                    "fullname",
                    "name",
                    "examdate",
                    "examnote",
                    "total",
                    "result" -> true;
            default -> false;
        };
    }

    private boolean isCommentColumn(String header) {
        String normalized =
                normalize(header);

        return "comment".equals(normalized)
                || "comments".equals(normalized)
                || normalized.endsWith("comment");
    }

    private String encryptString(
            String plainText
    ) throws GeneralSecurityException {

        Cipher cipher =
                Cipher.getInstance("AES/CBC/PKCS5Padding");

        cipher.init(
                Cipher.ENCRYPT_MODE,
                new SecretKeySpec(
                        FU_GRADE_KEY.getBytes(StandardCharsets.UTF_8),
                        "AES"
                ),
                new IvParameterSpec(new byte[16])
        );

        return Base64.getEncoder()
                .encodeToString(
                        cipher.doFinal(
                                plainText.getBytes(StandardCharsets.UTF_8)
                        )
                );
    }

    private String decryptString(
            String encrypted
    ) throws GeneralSecurityException {

        Cipher cipher =
                Cipher.getInstance("AES/CBC/PKCS5Padding");

        cipher.init(
                Cipher.DECRYPT_MODE,
                new SecretKeySpec(
                        FU_GRADE_KEY.getBytes(StandardCharsets.UTF_8),
                        "AES"
                ),
                new IvParameterSpec(new byte[16])
        );

        return new String(
                cipher.doFinal(Base64.getDecoder().decode(encrypted)),
                StandardCharsets.UTF_8
        );
    }

    private boolean isXmlSpreadsheet(byte[] bytes) {
        String head =
                new String(
                        bytes,
                        0,
                        Math.min(bytes.length, 256),
                        StandardCharsets.UTF_8
                ).trim();

        return head.startsWith("<?xml")
                || head.contains("<Workbook");
    }

    private TeacherGradeFile createTeacherGrade(FileInfo fileInfo) {
        TeacherGradeFile teacherGrade =
                new TeacherGradeFile();

        teacherGrade.setVersion("1.1");

        if (!blank(fileInfo.semester())) {
            teacherGrade.setSemester(fileInfo.semester());
        }

        if (!blank(fileInfo.teacherLogin())) {
            teacherGrade.setLogin(
                    fileInfo.teacherLogin().toLowerCase(Locale.ROOT)
            );
        }

        return teacherGrade;
    }

    private void normalizeTeacherGrade(
            TeacherGradeFile teacherGrade
    ) {

        if (teacherGrade.getSubjectClassGrades() == null) {
            teacherGrade.setSubjectClassGrades(new ArrayList<>());
        }

        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

            normalizeSubjectClass(subjectClass);

            if (subjectClass.getStudents() == null) {
                subjectClass.setStudents(new ArrayList<>());
            }

            if (subjectClass.getComponents() == null) {
                subjectClass.setComponents(new ArrayList<>());
            }

            for (FgStudent student : subjectClass.getStudents()) {
                if (student.getGrades() == null) {
                    student.setGrades(new ArrayList<>());
                }

                for (FgGradeComponent grade : student.getGrades()) {
                    if (grade.getGrade() != null) {
                        grade.setGrade(
                                (float) round(grade.getGrade())
                        );
                    }
                }
            }
        }
    }

    private FileInfo parseFileName(String originalFilename) {
        String fileName =
                nullToEmpty(originalFilename);

        if (fileName.contains("/") || fileName.contains("\\")) {
            fileName = fileName.replace("\\", "/");
            fileName = fileName.substring(fileName.lastIndexOf("/") + 1);
        }

        int dot =
                fileName.lastIndexOf('.');

        if (dot > 0) {
            fileName = fileName.substring(0, dot);
        }

        String[] parts =
                fileName.split("_");

        if (parts.length >= 4) {
            String semester =
                    String.join(
                            "_",
                            java.util.Arrays.copyOfRange(
                                    parts,
                                    3,
                                    parts.length
                            )
                    );

            return new FileInfo(
                    parts[0].trim(),
                    parts[1].trim(),
                    parts[2].trim().toLowerCase(Locale.ROOT),
                    semester.trim()
            );
        }

        return new FileInfo("", fileName, "", "");
    }

    private String outputName(
            String originalFilename,
            String fallback,
            String extension
    ) {

        String fileName =
                nullToEmpty(originalFilename);

        if (fileName.contains("/") || fileName.contains("\\")) {
            fileName = fileName.replace("\\", "/");
            fileName = fileName.substring(fileName.lastIndexOf("/") + 1);
        }

        int dot =
                fileName.lastIndexOf('.');

        if (dot > 0) {
            fileName = fileName.substring(0, dot);
        }

        if (fileName.isBlank()) {
            fileName = fallback;
        }

        return fileName + extension;
    }

    private String getSpreadsheetAttribute(
            Element element,
            String localName
    ) {

        String value =
                element.getAttributeNS(SPREADSHEET_NS, localName);

        if (value == null || value.isBlank()) {
            value = element.getAttribute("ss:" + localName);
        }

        if (value == null || value.isBlank()) {
            value = element.getAttribute(localName);
        }

        return nullToEmpty(value).trim();
    }

    private Map<String, Float> toGradeMap(FgStudent student) {
        Map<String, Float> result =
                new HashMap<>();

        if (student.getGrades() == null) {
            return result;
        }

        for (FgGradeComponent grade : student.getGrades()) {
            result.put(
                    normalize(grade.getComponent()),
                    grade.getGrade()
            );
        }

        return result;
    }

    private Double gradeOrNull(
            Map<String, Float> gradeMap,
            String component
    ) {

        Float value =
                gradeMap.get(normalize(component));

        return value == null ? null : round(value);
    }

    private Double firstGradeOrNull(
            Map<String, Float> gradeMap,
            String... components
    ) {

        for (String component : components) {
            Double value =
                    gradeOrNull(gradeMap, component);

            if (value != null) {
                return value;
            }
        }

        return null;
    }

    private Float parseNullableFloat(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized =
                value.trim().replace(",", ".");

        try {
            return (float) round(Float.parseFloat(normalized));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Double parseDouble(String value) {
        Float parsed =
                parseNullableFloat(value);

        return parsed == null ? null : parsed.doubleValue();
    }

    private Float toFloat(Double value) {
        return value == null ? null : (float) round(value);
    }

    private Float optionalResit(Double value) {
        return value == null ? null : (float) round(value);
    }

    private void addComment(
            List<String> comments,
            String component,
            String comment
    ) {

        if (!blank(comment)) {
            comments.add(component + ": " + comment.trim());
        }
    }

    private void sortStudents(TeacherGradeFile teacherGrade) {
        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

            Collections.sort(subjectClass.getStudents());
        }
    }

    private String firstSubjectOrDefault(
            TeacherGradeFile teacherGrade
    ) {

        if (teacherGrade.getSubjectClassGrades().isEmpty()) {
            return null;
        }

        return teacherGrade.getSubjectClassGrades()
                .get(0)
                .getSubject();
    }

    private String latestSemester() {
        return latestTeacherGrade == null
                ? null
                : latestTeacherGrade.getSemester();
    }

    private String latestLogin() {
        return latestTeacherGrade == null
                ? null
                : latestTeacherGrade.getLogin();
    }

    private String latestPassword() {
        return latestTeacherGrade == null
                ? null
                : latestTeacherGrade.getPassword();
    }

    private String latestSubjectForClass(String className) {
        if (latestTeacherGrade == null
                || latestTeacherGrade.getSubjectClassGrades() == null) {
            return null;
        }

        for (FgSubjectClassGrade subjectClass
                : latestTeacherGrade.getSubjectClassGrades()) {

            if (Objects.equals(
                    normalize(subjectClass.getClassName()),
                    normalize(className)
            )) {
                return subjectClass.getSubject();
            }
        }

        return firstSubjectOrDefault(latestTeacherGrade);
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String emptyToNull(String value) {
        return blank(value) ? null : value;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private Double roundScore(Double value) {
        return value == null ? null : round(value);
    }

    private String normalize(String value) {
        return nullToEmpty(value)
                .replace(" ", "")
                .replace("_", "")
                .trim()
                .toLowerCase(Locale.ROOT);
    }

    public void setLatestClasses(
            Map<String, List<StudentGrade>> classes
    ) {
        this.latestClasses = classes;
    }

    public Map<String, List<StudentGrade>> getLatestClasses() {
        return latestClasses;
    }

    public TeacherGradeFile getLatestTeacherGrade() {
        return latestTeacherGrade;
    }

    public String getLatestFgFileName() {
        return latestFgFileName;
    }

    public String getLatestExcelFileName() {
        return latestExcelFileName;
    }

    public Map<String, Object> getLatestFileInfo() {
        Map<String, Object> fileInfo =
                new LinkedHashMap<>();

        if (latestTeacherGrade == null) {
            return fileInfo;
        }

        fileInfo.put("version", latestTeacherGrade.getVersion());
        fileInfo.put("semester", latestTeacherGrade.getSemester());
        fileInfo.put("login", latestTeacherGrade.getLogin());
        fileInfo.put("passwordHash", latestTeacherGrade.getPassword());

        List<Map<String, Object>> subjectClasses =
                new ArrayList<>();

        if (latestTeacherGrade.getSubjectClassGrades() != null) {
            for (FgSubjectClassGrade subjectClass
                    : latestTeacherGrade.getSubjectClassGrades()) {

                Map<String, Object> item =
                        new LinkedHashMap<>();

                item.put("subject", subjectClass.getSubject());
                item.put("className", subjectClass.getClassName());
                item.put("components", subjectClass.getComponents());
                item.put(
                        "studentCount",
                        subjectClass.getStudents() == null
                                ? 0
                                : subjectClass.getStudents().size()
                );

                subjectClasses.add(item);
            }
        }

        fileInfo.put("subjectClasses", subjectClasses);

        return fileInfo;
    }

    private record FileInfo(
            String className,
            String subjectCode,
            String teacherLogin,
            String semester
    ) {
    }

    private record SubjectClassParts(
            String subject,
            String className
    ) {
    }
}
