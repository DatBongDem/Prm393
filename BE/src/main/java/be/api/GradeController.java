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

    @Autowired
    private GradeService gradeService;

    // cache FG
    private String latestFGContent;

    // ================= UPLOAD EXCEL =================
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

            // đọc excel
            Map<String, List<StudentGrade>> classes =
                    gradeService.processExcel(
                            file.getInputStream()
                    );

            // cache
            gradeService.setLatestClasses(classes);

            // generate FG
            latestFGContent =
                    gradeService.generateFGContent(classes);

            Map<String, Object> response =
                    new HashMap<>();

            response.put("message", "Upload success");
            response.put("classes", classes);

            return ResponseEntity.ok(response);

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }
    
    // ================= EXPORT FG =================
    @GetMapping("/export-fg")
    public ResponseEntity<?> exportFG() {

        try {

            if (latestFGContent == null
                    || latestFGContent.isBlank()) {

                return ResponseEntity.badRequest()
                        .body("No FG file available");
            }

            byte[] fgBytes =
                    latestFGContent.getBytes(
                            StandardCharsets.UTF_8
                    );

            return ResponseEntity.ok()
                    .header(
                            HttpHeaders.CONTENT_DISPOSITION,
                            "attachment; filename=grade.fg"
                    )
                    .contentType(
                            MediaType.APPLICATION_OCTET_STREAM
                    )
                    .body(fgBytes);

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(
                            ("ERROR: " + e.getMessage())
                                    .getBytes()
                    );
        }
    }

    // ================= EXPORT EXCEL =================
    @GetMapping("/export-excel")
    public ResponseEntity<?> exportExcel() {

        try {

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null
                    || classes.isEmpty()) {

                return ResponseEntity.badRequest()
                        .body("No data available");
            }

            Workbook workbook =
                    new XSSFWorkbook();

            for (String className
                    : classes.keySet()) {

                Sheet sheet =
                        workbook.createSheet(
                                className
                        );

                // ===== HEADER =====

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

                for (int i = 0;
                     i < columns.length;
                     i++) {

                    header.createCell(i)
                            .setCellValue(
                                    columns[i]
                            );
                }

                // ===== DATA =====

                List<StudentGrade> students =
                        classes.get(className);

                int rowIndex = 1;

                for (StudentGrade s
                        : students) {

                    Row row =
                            sheet.createRow(
                                    rowIndex++
                            );

                    row.createCell(0)
                            .setCellValue(
                                    s.getClassName()
                            );

                    row.createCell(1)
                            .setCellValue(
                                    s.getRollNumber()
                            );

                    row.createCell(2)
                            .setCellValue(
                                    s.getEmail()
                            );

                    row.createCell(3)
                            .setCellValue(
                                    s.getMemberCode()
                            );

                    row.createCell(4)
                            .setCellValue(
                                    s.getFullName()
                            );

                    row.createCell(5)
                            .setCellValue(
                                    s.getExamDate()
                            );

                    row.createCell(6)
                            .setCellValue(
                                    s.getExamNote()
                            );

                    row.createCell(7)
                            .setCellValue(
                                    s.getFinalExam()
                            );

                    row.createCell(8)
                            .setCellValue(
                                    s.getFinalComment()
                            );

                    row.createCell(9)
                            .setCellValue(
                                    s.getFinalResit()
                            );

                    row.createCell(10)
                            .setCellValue(
                                    s.getFinalResitComment()
                            );

                    row.createCell(11)
                            .setCellValue(
                                    s.getPractical()
                            );

                    row.createCell(12)
                            .setCellValue(
                                    s.getPracticalComment()
                            );

                    row.createCell(13)
                            .setCellValue(
                                    s.getPt1()
                            );

                    row.createCell(14)
                            .setCellValue(
                                    s.getPt1Comment()
                            );

                    row.createCell(15)
                            .setCellValue(
                                    s.getPt2()
                            );

                    row.createCell(16)
                            .setCellValue(
                                    s.getPt2Comment()
                            );

                    row.createCell(17)
                            .setCellValue(
                                    s.getPt3()
                            );

                    row.createCell(18)
                            .setCellValue(
                                    s.getPt3Comment()
                            );

                    row.createCell(19)
                            .setCellValue(
                                    s.getProject()
                            );

                    row.createCell(20)
                            .setCellValue(
                                    s.getProjectComment()
                            );
                }

                // auto size
                for (int i = 0;
                     i < columns.length;
                     i++) {

                    sheet.autoSizeColumn(i);
                }
            }

            ByteArrayOutputStream out =
                    new ByteArrayOutputStream();

            workbook.write(out);

            workbook.close();

            return ResponseEntity.ok()
                    .header(
                            HttpHeaders.CONTENT_DISPOSITION,
                            "attachment; filename=grades.xlsx"
                    )
                    .contentType(
                            MediaType.APPLICATION_OCTET_STREAM
                    )
                    .body(out.toByteArray());

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }

    // ================= GET JSON =================
    @GetMapping("/latest")
    public ResponseEntity<?> getLatestData() {

        try {

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null
                    || classes.isEmpty()) {

                return ResponseEntity.badRequest()
                        .body("Chưa có dữ liệu Excel");
            }

            return ResponseEntity.ok(classes);

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body("ERROR: " + e.getMessage());
        }
    }
}