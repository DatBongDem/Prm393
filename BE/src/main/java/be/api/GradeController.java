package be.api;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import be.business.GradeService;
import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.StudentGrade;
import be.business.dtos.StudentGradeRequest;
import be.business.dtos.TeacherGradeFile;

@RestController
@RequestMapping("/grade")
public class GradeController {

    private static final MediaType XLSX_MEDIA_TYPE =
            MediaType.parseMediaType(
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            );

    @Autowired
    private GradeService gradeService;

    @PostMapping(
            value = "/upload-excel",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> uploadExcel(
            @RequestPart("file") MultipartFile file
    ) {

        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body("File is empty");
            }

            Map<String, List<StudentGrade>> classes =
                    gradeService.processExcel(
                            file.getInputStream(),
                            file.getOriginalFilename()
                    );

            Map<String, Object> response =
                    new HashMap<>();

            response.put("message", "Upload Excel success");
            response.put("fileInfo", gradeService.getLatestFileInfo());
            response.put("classes", classes);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    @PostMapping(
            value = "/upload-fg",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> uploadFg(
            @RequestPart("file") MultipartFile file
    ) {

        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body("File is empty");
            }

            Map<String, List<StudentGrade>> classes =
                    gradeService.processFg(
                            file.getInputStream(),
                            file.getOriginalFilename()
                    );

            Map<String, Object> response =
                    new HashMap<>();

            response.put("message", "Upload FG success");
            response.put("fileInfo", gradeService.getLatestFileInfo());
            response.put("classes", classes);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    @GetMapping("/export-fg")
    public ResponseEntity<?> exportFG() {

        try {
            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null || classes.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body("No FG file available");
            }

            byte[] fgBytes =
                    gradeService.generateFGContent(classes);

            return ResponseEntity.ok()
                    .header(
                            HttpHeaders.CONTENT_DISPOSITION,
                            attachment(gradeService.getLatestFgFileName())
                    )
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(fgBytes);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(
                            ("ERROR: " + e.getMessage())
                                    .getBytes(StandardCharsets.UTF_8)
                    );
        }
    }

    @GetMapping("/export-excel")
    public ResponseEntity<?> exportExcel() {

        try {
            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null || classes.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body("No data available");
            }

            return ResponseEntity.ok()
                    .header(
                            HttpHeaders.CONTENT_DISPOSITION,
                            attachment(gradeService.getLatestExcelFileName())
                    )
                    .contentType(XLSX_MEDIA_TYPE)
                    .body(
                            buildExcelBytes(
                                    gradeService.getLatestTeacherGrade(),
                                    classes
                            )
                    );

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    private byte[] buildExcelBytes(
            TeacherGradeFile teacherGrade,
            Map<String, List<StudentGrade>> classes
    ) throws Exception {

        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            CellStyle scoreStyle =
                    scoreCellStyle(workbook);

            if (teacherGrade != null
                    && teacherGrade.getSubjectClassGrades() != null
                    && !teacherGrade.getSubjectClassGrades().isEmpty()) {

                buildTeacherGradeSheets(workbook, teacherGrade, scoreStyle);
                workbook.write(out);

                return out.toByteArray();
            }

            for (String className : classes.keySet()) {
                Sheet sheet =
                        workbook.createSheet(safeSheetName(className));

                Row header =
                        sheet.createRow(0);

                String[] columns = {
                        "Class",
                        "RollNumber",
                        "Email",
                        "MemberCode",
                        "FullName",
                        "ExamDate",
                        "ExamNote",
                        "Final Exam",
                        "Final Exam_Comment",
                        "Final Exam Resit",
                        "Final Exam Resit_Comment",
                        "Practical Exam",
                        "Practical Exam_Comment",
                        "Progress Test 1",
                        "Progress Test 1_Comment",
                        "Progress Test 2",
                        "Progress Test 2_Comment",
                        "Progress Test 3",
                        "Progress Test 3_Comment",
                        "Project",
                        "Project_Comment"
                };

                for (int i = 0; i < columns.length; i++) {
                    header.createCell(i)
                            .setCellValue(columns[i]);
                }

                List<StudentGrade> students =
                        classes.get(className);

                int rowIndex = 1;

                for (StudentGrade student : students) {
                    StudentGradeRequest fileRow =
                            gradeService.toStudentGradeRequest(student);

                    Row row =
                            sheet.createRow(rowIndex++);

                    row.createCell(0)
                            .setCellValue(nullToEmpty(fileRow.getClassName()));
                    row.createCell(1)
                            .setCellValue(nullToEmpty(fileRow.getRollNumber()));
                    row.createCell(2)
                            .setCellValue(nullToEmpty(fileRow.getEmail()));
                    row.createCell(3)
                            .setCellValue(nullToEmpty(fileRow.getMemberCode()));
                    row.createCell(4)
                            .setCellValue(nullToEmpty(fileRow.getFullName()));
                    row.createCell(5)
                            .setCellValue(nullToEmpty(fileRow.getExamDate()));
                    row.createCell(6)
                            .setCellValue(nullToEmpty(fileRow.getExamNote()));
                    setNumericCell(row, 7, fileRow.getFinalExam(), scoreStyle);
                    row.createCell(8)
                            .setCellValue(nullToEmpty(fileRow.getFinalExamComment()));
                    setNumericCell(row, 9, fileRow.getFinalExamResit(), scoreStyle);
                    row.createCell(10)
                            .setCellValue(nullToEmpty(fileRow.getFinalExamResitComment()));
                    setNumericCell(row, 11, fileRow.getPracticalExam(), scoreStyle);
                    row.createCell(12)
                            .setCellValue(nullToEmpty(fileRow.getPracticalExamComment()));
                    setNumericCell(row, 13, fileRow.getPt1(), scoreStyle);
                    row.createCell(14)
                            .setCellValue(nullToEmpty(fileRow.getPt1Comment()));
                    setNumericCell(row, 15, fileRow.getPt2(), scoreStyle);
                    row.createCell(16)
                            .setCellValue(nullToEmpty(fileRow.getPt2Comment()));
                    setNumericCell(row, 17, fileRow.getPt3(), scoreStyle);
                    row.createCell(18)
                            .setCellValue(nullToEmpty(fileRow.getPt3Comment()));
                    setNumericCell(row, 19, fileRow.getProject(), scoreStyle);
                    row.createCell(20)
                            .setCellValue(nullToEmpty(fileRow.getProjectComment()));
                }

                for (int i = 0; i < columns.length; i++) {
                    sheet.autoSizeColumn(i);
                }
            }

            workbook.write(out);

            return out.toByteArray();
        }
    }

    private void buildTeacherGradeSheets(
            Workbook workbook,
            TeacherGradeFile teacherGrade,
            CellStyle scoreStyle
    ) {

        for (FgSubjectClassGrade subjectClass
                : teacherGrade.getSubjectClassGrades()) {

            Sheet sheet =
                    workbook.createSheet(
                            uniqueSheetName(
                                    workbook,
                                    safeSheetName(
                                            nullToEmpty(subjectClass.getSubject())
                                                    + "_"
                                                    + nullToEmpty(
                                                            subjectClass.getClassName()
                                                    )
                                    )
                            )
                    );

            List<String> components =
                    subjectClass.getComponents() == null
                            ? List.of()
                            : subjectClass.getComponents();

            Row header =
                    sheet.createRow(0);

            header.createCell(0).setCellValue("Class");
            header.createCell(1).setCellValue("RollNumber");
            header.createCell(2).setCellValue("FullName");
            header.createCell(3).setCellValue("Comment");

            for (int i = 0; i < components.size(); i++) {
                header.createCell(i + 4)
                        .setCellValue(components.get(i));
            }

            List<FgStudent> students =
                    subjectClass.getStudents() == null
                            ? List.of()
                            : subjectClass.getStudents();

            int rowIndex = 1;

            for (FgStudent student : students) {
                Row row =
                        sheet.createRow(rowIndex++);

                row.createCell(0)
                        .setCellValue(
                                nullToEmpty(subjectClass.getClassName())
                        );
                row.createCell(1)
                        .setCellValue(nullToEmpty(student.getRoll()));
                row.createCell(2)
                        .setCellValue(nullToEmpty(student.getName()));
                row.createCell(3)
                        .setCellValue(nullToEmpty(student.getComment()));

                Map<String, Float> grades =
                        gradeMap(student);

                for (int i = 0; i < components.size(); i++) {
                    Float grade =
                            grades.get(normalize(components.get(i)));

                    if (grade != null) {
                        setNumericCell(row, i + 4, grade, scoreStyle);
                    }
                }
            }

            for (int i = 0; i < components.size() + 4; i++) {
                sheet.autoSizeColumn(i);
            }
        }
    }

    private Map<String, Float> gradeMap(FgStudent student) {
        Map<String, Float> grades =
                new HashMap<>();

        if (student.getGrades() == null) {
            return grades;
        }

        for (FgGradeComponent grade : student.getGrades()) {
            grades.put(
                    normalize(grade.getComponent()),
                    grade.getGrade()
            );
        }

        return grades;
    }

    private void setNumericCell(
            Row row,
            int index,
            Number value,
            CellStyle scoreStyle
    ) {

        if (value != null) {
            Cell cell =
                    row.createCell(index);

            cell.setCellValue(roundScore(value.doubleValue()));
            cell.setCellStyle(scoreStyle);
        }
    }

    private CellStyle scoreCellStyle(Workbook workbook) {
        CellStyle style =
                workbook.createCellStyle();

        style.setDataFormat(
                workbook.createDataFormat()
                        .getFormat("0.0")
        );

        return style;
    }

    private double roundScore(double value) {
        return Math.round(value * 10.0) / 10.0;
    }

    private String safeSheetName(String value) {
        String name =
                nullToEmpty(value)
                        .replaceAll("[\\\\/?*\\[\\]:]", "_")
                        .trim();

        if (name.isBlank()) {
            return "Sheet1";
        }

        return name.length() > 31
                ? name.substring(0, 31)
                : name;
    }

    private String uniqueSheetName(
            Workbook workbook,
            String baseName
    ) {

        String base =
                nullToEmpty(baseName).isBlank()
                        ? "Sheet1"
                        : baseName;

        if (workbook.getSheet(base) == null) {
            return base;
        }

        int index = 2;

        while (true) {
            String suffix =
                    " (" + index + ")";
            int maxLength =
                    31 - suffix.length();
            String candidate =
                    base.substring(0, Math.min(base.length(), maxLength))
                            + suffix;

            if (workbook.getSheet(candidate) == null) {
                return candidate;
            }

            index++;
        }
    }

    private String attachment(String fileName) {
        return "attachment; filename=\"" + sanitizeFileName(fileName) + "\"";
    }

    private String sanitizeFileName(String fileName) {
        String safe =
                nullToEmpty(fileName)
                        .replace("\\", "_")
                        .replace("/", "_")
                        .replace("\"", "");

        return safe.isBlank() ? "download" : safe;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private String normalize(String value) {
        return nullToEmpty(value)
                .replace(" ", "")
                .replace("_", "")
                .trim()
                .toLowerCase(java.util.Locale.ROOT);
    }
}
