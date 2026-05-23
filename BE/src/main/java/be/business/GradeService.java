package be.business;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
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

        Map<String, List<StudentGrade>> classes =
                toStudentClasses(teacherGrade);

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

        String encrypted =
                new String(inputStream.readAllBytes(), StandardCharsets.UTF_8)
                        .trim();

        TeacherGradeFile teacherGrade =
                objectMapper.readValue(
                        decryptString(encrypted),
                        TeacherGradeFile.class
                );

        normalizeTeacherGrade(teacherGrade);

        Map<String, List<StudentGrade>> classes =
                toStudentClasses(teacherGrade);

        latestTeacherGrade = teacherGrade;
        latestClasses = classes;
        latestFgFileName = outputName(originalFilename, "grade", ".fg");
        latestExcelFileName = outputName(originalFilename, "grades", ".xlsx");

        return classes;
    }

    public String generateFGContent(
            Map<String, List<StudentGrade>> data
    ) throws Exception {

        if (data == null || data.isEmpty()) {
            throw new IllegalArgumentException("No grade data available");
        }

        TeacherGradeFile teacherGrade = latestTeacherGrade != null
                ? latestTeacherGrade
                : buildTeacherGradeFromClasses(data);

        return encryptString(objectMapper.writeValueAsString(teacherGrade));
    }

    public void refreshTeacherGradeFromClasses() {
        if (latestClasses == null || latestClasses.isEmpty()) {
            latestTeacherGrade = null;
            return;
        }

        latestTeacherGrade = buildTeacherGradeFromClasses(latestClasses);
    }

    public StudentGrade buildStudent(
            StudentGradeRequest request
    ) {

        double finalUsed =
                request.getFinalExamResit() > 0
                        ? request.getFinalExamResit()
                        : request.getFinalExam();

        double practicalUsed =
                request.getPracticalExam();

        double progressAvg =
                (
                        request.getPt1()
                                + request.getPt2()
                                + request.getPt3()
                ) / 3.0;

        double total =
                finalUsed * 0.30
                        + practicalUsed * 0.25
                        + progressAvg * 0.15
                        + request.getProject() * 0.30;

        total = round(total);

        String resultStatus;
        String comment;

        if (total >= 5
                && finalUsed >= 4
                && practicalUsed >= 4) {

            resultStatus = "PASS";

            comment =
                    "Congratulations, you passed the course.";

        } else {

            resultStatus = "FAIL";

            List<String> reasons =
                    new ArrayList<>();

            if (total < 5) {

                reasons.add(
                        "Your total score is below 5."
                );
            }

            if (finalUsed < 4) {

                reasons.add(
                        "Your Final Exam score is below 4."
                );
            }

            if (practicalUsed < 4) {

                reasons.add(
                        "Your Practical Exam score is below 4."
                );
            }

            comment =
                    String.join(" ", reasons);
        }

        StudentGrade student =
                new StudentGrade();

        student.setClassName(request.getClassName());

        student.setRollNumber(request.getRollNumber());
        student.setEmail(request.getEmail());
        student.setMemberCode(request.getMemberCode());
        student.setFullName(request.getFullName());

        student.setExamDate(request.getExamDate());
        student.setExamNote(request.getExamNote());

        student.setFinalExam(request.getFinalExam());
        student.setFinalComment(request.getFinalExamComment());

        student.setFinalResit(request.getFinalExamResit());
        student.setFinalResitComment(
                request.getFinalExamResitComment()
        );

        student.setPractical(request.getPracticalExam());
        student.setPracticalComment(
                request.getPracticalExamComment()
        );

        student.setPt1(request.getPt1());
        student.setPt1Comment(request.getPt1Comment());

        student.setPt2(request.getPt2());
        student.setPt2Comment(request.getPt2Comment());

        student.setPt3(request.getPt3());
        student.setPt3Comment(request.getPt3Comment());

        student.setProject(request.getProject());
        student.setProjectComment(
                request.getProjectComment()
        );

        student.setTotal(total);
        student.setResult(resultStatus);
        student.setComment(comment);

        return student;
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
                    rows
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
                        rows
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
            List<List<String>> rows
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
                    getCell(row, headerMap, "Class");

            if (className.isBlank()) {
                className = !blank(sheetName)
                        ? sheetName
                        : fileInfo.className();
            }

            String subject =
                    !blank(fileInfo.subjectCode())
                            ? fileInfo.subjectCode()
                            : firstSubjectOrDefault(teacherGrade);

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
                getCell(row, headerMap, "RollNumber", "Roll")
        );
        student.setName(
                getCell(row, headerMap, "FullName", "Name")
        );
        student.setComment(
                buildStudentComment(row, headerMap, components)
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
            TeacherGradeFile teacherGrade
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
                    nullToEmpty(subjectClass.getClassName());

            List<StudentGrade> students =
                    classes.computeIfAbsent(
                            className,
                            ignored -> new ArrayList<>()
                    );

            if (subjectClass.getStudents() == null) {
                continue;
            }

            for (FgStudent fgStudent : subjectClass.getStudents()) {
                StudentGradeRequest request =
                        new StudentGradeRequest();

                request.setClassName(className);
                request.setRollNumber(nullToEmpty(fgStudent.getRoll()));
                request.setFullName(nullToEmpty(fgStudent.getName()));

                Map<String, Float> gradeMap =
                        toGradeMap(fgStudent);

                request.setFinalExam(
                        gradeOrZero(gradeMap, "Final Exam")
                );
                request.setFinalExamResit(
                        gradeOrZero(gradeMap, "Final Exam Resit")
                );
                request.setPracticalExam(
                        gradeOrZero(gradeMap, "Practical Exam")
                );
                request.setPt1(
                        gradeOrZero(gradeMap, "Progress Test 1")
                );
                request.setPt2(
                        gradeOrZero(gradeMap, "Progress Test 2")
                );
                request.setPt3(
                        gradeOrZero(gradeMap, "Progress Test 3")
                );
                request.setProject(
                        gradeOrZero(gradeMap, "Project")
                );

                applyFgCommentToRequest(
                        fgStudent.getComment(),
                        request
                );

                StudentGrade student =
                        buildStudent(request);

                if (!blank(fgStudent.getComment())) {
                    student.setComment(fgStudent.getComment());
                }

                students.add(student);
            }
        }

        return classes;
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

            subjectClass.setSubject(
                    latestSubjectForClass(entry.getKey())
            );
            subjectClass.setClassName(entry.getKey());
            subjectClass.setComponents(new ArrayList<>(DEFAULT_COMPONENTS));

            List<StudentGrade> sortedStudents =
                    new ArrayList<>(entry.getValue());

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

    private FgStudent toFgStudent(StudentGrade student) {
        FgStudent fgStudent =
                new FgStudent();

        fgStudent.setRoll(nullToEmpty(student.getRollNumber()));
        fgStudent.setName(nullToEmpty(student.getFullName()));
        fgStudent.setComment(buildCombinedComment(student));

        List<FgGradeComponent> grades =
                new ArrayList<>();

        for (String component : DEFAULT_COMPONENTS) {
            FgGradeComponent grade =
                    new FgGradeComponent();

            grade.setComponent(component);
            grade.setGrade(componentGrade(student, component));
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
            case "project" -> toFloat(student.getProject());
            default -> null;
        };
    }

    private String buildCombinedComment(StudentGrade student) {
        List<String> comments =
                new ArrayList<>();

        addComment(
                comments,
                "Final Exam",
                student.getFinalComment()
        );
        addComment(
                comments,
                "Final Exam Resit",
                student.getFinalResitComment()
        );
        addComment(
                comments,
                "Practical Exam",
                student.getPracticalComment()
        );
        addComment(
                comments,
                "Progress Test 1",
                student.getPt1Comment()
        );
        addComment(
                comments,
                "Progress Test 2",
                student.getPt2Comment()
        );
        addComment(
                comments,
                "Progress Test 3",
                student.getPt3Comment()
        );
        addComment(
                comments,
                "Project",
                student.getProjectComment()
        );

        if (!comments.isEmpty()) {
            return String.join("; ", comments);
        }

        return blank(student.getComment())
                ? null
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

    private String buildStudentComment(
            List<String> row,
            Map<String, Integer> headerMap,
            List<String> components
    ) {

        String directComment =
                getCell(row, headerMap, "Comment", "Comments");

        if (!directComment.isBlank()) {
            return directComment;
        }

        List<String> comments =
                new ArrayList<>();

        for (String component : components) {
            String comment =
                    getCell(
                            row,
                            headerMap,
                            component + "_Comment",
                            component + " Comment",
                            component + "Comment"
                    );

            if (!comment.isBlank()) {
                comments.add(component + ": " + comment);
            }
        }

        return comments.isEmpty()
                ? null
                : String.join("; ", comments);
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
        teacherGrade.setSemester(nullToEmpty(fileInfo.semester()));
        teacherGrade.setLogin(
                nullToEmpty(fileInfo.teacherLogin())
                        .toLowerCase(Locale.ROOT)
        );
        teacherGrade.setPassword("");

        return teacherGrade;
    }

    private void normalizeTeacherGrade(
            TeacherGradeFile teacherGrade
    ) {

        if (teacherGrade.getVersion() == null) {
            teacherGrade.setVersion("1.1");
        }

        if (teacherGrade.getSemester() == null) {
            teacherGrade.setSemester("");
        }

        if (teacherGrade.getLogin() == null) {
            teacherGrade.setLogin("");
        }

        if (teacherGrade.getPassword() == null) {
            teacherGrade.setPassword("");
        }

        if (teacherGrade.getSubjectClassGrades() == null) {
            teacherGrade.setSubjectClassGrades(new ArrayList<>());
        }

        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

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

    private double gradeOrZero(
            Map<String, Float> gradeMap,
            String component
    ) {

        Float value =
                gradeMap.get(normalize(component));

        return value == null ? 0 : value;
    }

    private Float parseNullableFloat(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized =
                value.trim().replace(",", ".");

        try {
            return Float.parseFloat(normalized);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private double parseDouble(String value) {
        Float parsed =
                parseNullableFloat(value);

        return parsed == null ? 0 : parsed;
    }

    private Float toFloat(double value) {
        return (float) value;
    }

    private Float optionalResit(double value) {
        return value <= 0 ? null : (float) value;
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
            return "";
        }

        return nullToEmpty(
                teacherGrade.getSubjectClassGrades()
                        .get(0)
                        .getSubject()
        );
    }

    private String latestSemester() {
        return latestTeacherGrade == null
                ? ""
                : nullToEmpty(latestTeacherGrade.getSemester());
    }

    private String latestLogin() {
        return latestTeacherGrade == null
                ? ""
                : nullToEmpty(latestTeacherGrade.getLogin());
    }

    private String latestPassword() {
        return latestTeacherGrade == null
                ? ""
                : nullToEmpty(latestTeacherGrade.getPassword());
    }

    private String latestSubjectForClass(String className) {
        if (latestTeacherGrade == null
                || latestTeacherGrade.getSubjectClassGrades() == null) {
            return "";
        }

        for (FgSubjectClassGrade subjectClass
                : latestTeacherGrade.getSubjectClassGrades()) {

            if (Objects.equals(
                    normalize(subjectClass.getClassName()),
                    normalize(className)
            )) {
                return nullToEmpty(subjectClass.getSubject());
            }
        }

        return firstSubjectOrDefault(latestTeacherGrade);
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
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

    public String getLatestFgFileName() {
        return latestFgFileName;
    }

    public String getLatestExcelFileName() {
        return latestExcelFileName;
    }

    private record FileInfo(
            String className,
            String subjectCode,
            String teacherLogin,
            String semester
    ) {
    }
}
