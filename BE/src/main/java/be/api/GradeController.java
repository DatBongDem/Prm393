package be.api;


import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

    private String latestFGContent;

    // ===== UPLOAD EXCEL =====
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadExcel(@RequestPart("file") MultipartFile file) {

        try {

            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("File is empty");
            }

            // đọc excel
            Map<String, List<StudentGrade>> classes =
                    gradeService.processExcel(file.getInputStream());

            // 🔥 LƯU CACHE cho AI
            gradeService.setLatestClasses(classes);

            // generate FG
            latestFGContent = gradeService.generateFGContent(classes);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Upload success");
            response.put("classes", classes);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("ERROR: " + e.getMessage());
        }
    }

    // ===== DOWNLOAD FG =====
    @GetMapping("/export-fg")
    public ResponseEntity<?> exportFG() {

        try {

            if (latestFGContent == null || latestFGContent.isBlank()) {
                return ResponseEntity.badRequest().body("No FG file available");
            }

            byte[] fgBytes = latestFGContent.getBytes(StandardCharsets.UTF_8);

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=grade.fg")
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(fgBytes);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(("ERROR: " + e.getMessage()).getBytes());
        }
    }
}