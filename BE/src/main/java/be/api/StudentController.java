package be.api;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import be.business.GradeService;
import be.business.dtos.StudentGrade;
import be.business.dtos.StudentGradeRequest;

@RestController
@RequestMapping("/student")
public class StudentController {

    @Autowired
    private GradeService gradeService;

    // ================= CREATE =================
    @PostMapping
    public ResponseEntity<?> createStudent(
            @RequestBody StudentGradeRequest request
    ) {

        try {

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null) {

                return ResponseEntity.badRequest()
                        .body("No Excel uploaded");
            }

            StudentGrade student =
                    gradeService.buildStudent(request);

            String className =
                    student.getClassName();

            classes.putIfAbsent(
                    className,
                    new java.util.ArrayList<>()
            );

            classes.get(className)
                    .add(student);

            return ResponseEntity.ok(student);

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(e.getMessage());
        }
    }

    // ================= UPDATE =================
    @PutMapping("/{rollNumber}")
    public ResponseEntity<?> updateStudent(
            @PathVariable String rollNumber,
            @RequestBody StudentGradeRequest request
    ) {

        try {

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null) {

                return ResponseEntity.badRequest()
                        .body("No Excel uploaded");
            }

            for (List<StudentGrade> students
                    : classes.values()) {

                for (int i = 0;
                     i < students.size();
                     i++) {

                    StudentGrade old =
                            students.get(i);

                    if (old.getRollNumber()
                            .equalsIgnoreCase(
                                    rollNumber
                            )) {

                        StudentGrade updated =
                                gradeService.buildStudent(
                                        request
                                );

                        students.set(i, updated);

                        return ResponseEntity.ok(
                                updated
                        );
                    }
                }
            }

            return ResponseEntity.badRequest()
                    .body("Student not found");

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(e.getMessage());
        }
    }

    // ================= DELETE =================
    @DeleteMapping("/{rollNumber}")
    public ResponseEntity<?> deleteStudent(
            @PathVariable String rollNumber
    ) {

        try {

            Map<String, List<StudentGrade>> classes =
                    gradeService.getLatestClasses();

            if (classes == null) {

                return ResponseEntity.badRequest()
                        .body("No Excel uploaded");
            }

            for (List<StudentGrade> students
                    : classes.values()) {

                boolean removed =
                        students.removeIf(
                                s ->
                                        s.getRollNumber()
                                                .equalsIgnoreCase(
                                                        rollNumber
                                                )
                        );

                if (removed) {

                    return ResponseEntity.ok(
                            "Deleted successfully"
                    );
                }
            }

            return ResponseEntity.badRequest()
                    .body("Student not found");

        } catch (Exception e) {

            e.printStackTrace();

            return ResponseEntity.badRequest()
                    .body(e.getMessage());
        }
    }
}