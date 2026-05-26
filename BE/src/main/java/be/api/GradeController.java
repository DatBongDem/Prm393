package be.api;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
import be.business.dtos.StudentGrade;

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
            value = "/upload",
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
            response.put("classes", classes);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    @PostMapping(
            value = "/excel-to-fg",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> convertExcelToFg(
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

            byte[] fgBytes =
                    gradeService.generateFGContent(classes)
                            .getBytes(StandardCharsets.UTF_8);

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
                    .body("ERROR: " + e.getMessage());
        }
    }

    @PostMapping(
            value = "/fg-to-excel",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<?> convertFgToExcel(
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

            return ResponseEntity.ok()
                    .header(
                            HttpHeaders.CONTENT_DISPOSITION,
                            attachment(gradeService.getLatestExcelFileName())
                    )
                    .contentType(XLSX_MEDIA_TYPE)
                    .body(buildExcelBytes(classes));

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
                    gradeService.generateFGContent(classes)
                            .getBytes(StandardCharsets.UTF_8);

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
                    .body(buildExcelBytes(classes));

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    @GetMapping("/latest")
    public ResponseEntity<?> getLatestData() {

        try {
            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null || classes.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body("Chua co du lieu Excel");
            }

            return ResponseEntity.ok(classes);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    private byte[] buildExcelBytes(
            Map<String, List<StudentGrade>> classes
    ) throws Exception {

        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

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
                    Row row =
                            sheet.createRow(rowIndex++);

                    row.createCell(0)
                            .setCellValue(nullToEmpty(student.getClassName()));
                    row.createCell(1)
                            .setCellValue(nullToEmpty(student.getRollNumber()));
                    row.createCell(2)
                            .setCellValue(nullToEmpty(student.getEmail()));
                    row.createCell(3)
                            .setCellValue(nullToEmpty(student.getMemberCode()));
                    row.createCell(4)
                            .setCellValue(nullToEmpty(student.getFullName()));
                    row.createCell(5)
                            .setCellValue(nullToEmpty(student.getExamDate()));
                    row.createCell(6)
                            .setCellValue(nullToEmpty(student.getExamNote()));
                    row.createCell(7)
                            .setCellValue(student.getFinalExam());
                    row.createCell(8)
                            .setCellValue(nullToEmpty(student.getFinalComment()));
                    row.createCell(9)
                            .setCellValue(student.getFinalResit());
                    row.createCell(10)
                            .setCellValue(nullToEmpty(student.getFinalResitComment()));
                    row.createCell(11)
                            .setCellValue(student.getPractical());
                    row.createCell(12)
                            .setCellValue(nullToEmpty(student.getPracticalComment()));
                    row.createCell(13)
                            .setCellValue(student.getPt1());
                    row.createCell(14)
                            .setCellValue(nullToEmpty(student.getPt1Comment()));
                    row.createCell(15)
                            .setCellValue(student.getPt2());
                    row.createCell(16)
                            .setCellValue(nullToEmpty(student.getPt2Comment()));
                    row.createCell(17)
                            .setCellValue(student.getPt3());
                    row.createCell(18)
                            .setCellValue(nullToEmpty(student.getPt3Comment()));
                    row.createCell(19)
                            .setCellValue(student.getProject());
                    row.createCell(20)
                            .setCellValue(nullToEmpty(student.getProjectComment()));
                }

                for (int i = 0; i < columns.length; i++) {
                    sheet.autoSizeColumn(i);
                }
            }

            workbook.write(out);

            return out.toByteArray();
        }
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
}
