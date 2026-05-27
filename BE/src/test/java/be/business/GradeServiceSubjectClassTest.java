package be.business;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.StudentGrade;
import be.business.dtos.StudentGradeRequest;
import be.business.dtos.TeacherGradeFile;

class GradeServiceSubjectClassTest {

    @Test
    void processFgInfersStudentEmailAndMemberCode() throws Exception {
        GradeService service =
                new GradeService();
        TeacherGradeFile teacherGrade =
                new TeacherGradeFile();
        FgSubjectClassGrade subjectClass =
                new FgSubjectClassGrade();
        FgStudent student =
                new FgStudent();

        subjectClass.setSubject("PRM393");
        subjectClass.setClassName("SE1813");
        subjectClass.setComponents(List.of("Final Exam"));

        student.setRoll("se181827");
        student.setName("Nguyễn Hữu Mỹ");
        student.setGrades(List.of(grade("Final Exam", 8.0f)));
        subjectClass.setStudents(List.of(student));
        teacherGrade.setSubjectClassGrades(List.of(subjectClass));

        Map<String, List<StudentGrade>> classes =
                service.processFg(
                        new ByteArrayInputStream(
                                BinaryTeacherGradeWriter.write(teacherGrade)
                        ),
                        "sample.fg"
                );
        StudentGrade parsed =
                classes.get("PRM393_SE1813")
                        .getFirst();

        assertEquals("mynhse181827", parsed.getMemberCode());
        assertEquals(
                "mynhse181827@fpt.edu.vn",
                parsed.getEmail()
        );
    }

    @Test
    void processExcelKeepsStudentInfoColumns() throws Exception {
        GradeService service =
                new GradeService();
        String xml =
                """
                <?xml version="1.0"?>
                <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
                          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
                  <Worksheet ss:Name="SE1813">
                    <Table>
                      <Row>
                        <Cell><Data ss:Type="String">Class</Data></Cell>
                        <Cell><Data ss:Type="String">RollNumber</Data></Cell>
                        <Cell><Data ss:Type="String">Email</Data></Cell>
                        <Cell><Data ss:Type="String">MemberCode</Data></Cell>
                        <Cell><Data ss:Type="String">FullName</Data></Cell>
                        <Cell><Data ss:Type="String">ExamDate</Data></Cell>
                        <Cell><Data ss:Type="String">ExamNote</Data></Cell>
                        <Cell><Data ss:Type="String">Final Exam</Data></Cell>
                        <Cell><Data ss:Type="String">Final Exam_Comment</Data></Cell>
                        <Cell><Data ss:Type="String">Final Exam Resit</Data></Cell>
                      </Row>
                      <Row>
                        <Cell><Data ss:Type="String">SE1813</Data></Cell>
                        <Cell><Data ss:Type="String">SE170562</Data></Cell>
                        <Cell><Data ss:Type="String">TuanMQSE170562@fpt.edu.vn</Data></Cell>
                        <Cell><Data ss:Type="String">TuanMQSE170562</Data></Cell>
                        <Cell><Data ss:Type="String">Mau Quoc Tuan</Data></Cell>
                        <Cell><Data ss:Type="String">16/05/2026</Data></Cell>
                        <Cell><Data ss:Type="String">FE</Data></Cell>
                        <Cell><Data ss:Type="Number">6</Data></Cell>
                        <Cell><Data ss:Type="String">good</Data></Cell>
                        <Cell><Data ss:Type="String"></Data></Cell>
                      </Row>
                    </Table>
                  </Worksheet>
                </Workbook>
                """;

        Map<String, List<StudentGrade>> classes =
                service.processExcel(
                        new ByteArrayInputStream(
                                xml.getBytes(StandardCharsets.UTF_8)
                        ),
                        "SE1813_PRM393_PHUONGLHK_SUMMER2026.xls"
                );
        StudentGrade student =
                classes.get("PRM393_SE1813")
                        .getFirst();

        assertEquals(
                "TuanMQSE170562@fpt.edu.vn",
                student.getEmail()
        );
        assertEquals("TuanMQSE170562", student.getMemberCode());
        assertEquals("16/05/2026", student.getExamDate());
        assertEquals("FE", student.getExamNote());
        assertEquals("good", student.getFinalComment());
        assertNull(student.getFinalResit());
        assertNull(student.getComment());

        TeacherGradeFile exported =
                BinaryTeacherGradeReader.read(
                        service.generateFGContent(classes)
                );

        assertEquals(
                "",
                exported.getSubjectClassGrades()
                        .getFirst()
                        .getStudents()
                        .getFirst()
                        .getComment()
        );
    }

    @Test
    void exportFgSplitsSubjectAndClassFromSheetName() throws Exception {
        GradeService service =
                new GradeService();
        String xml =
                """
                <?xml version="1.0"?>
                <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
                          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
                  <Worksheet ss:Name="PRN221_NET1710">
                    <Table>
                      <Row>
                        <Cell><Data ss:Type="String">RollNumber</Data></Cell>
                        <Cell><Data ss:Type="String">FullName</Data></Cell>
                        <Cell><Data ss:Type="String">Final Exam</Data></Cell>
                      </Row>
                      <Row>
                        <Cell><Data ss:Type="String">SE123456</Data></Cell>
                        <Cell><Data ss:Type="String">Nguyen Van A</Data></Cell>
                        <Cell><Data ss:Type="Number">8.26</Data></Cell>
                      </Row>
                    </Table>
                  </Worksheet>
                </Workbook>
                """;

        Map<String, List<StudentGrade>> classes =
                service.processExcel(
                        new ByteArrayInputStream(
                                xml.getBytes(StandardCharsets.UTF_8)
                        ),
                        "phuonglhkSpring2024_1.xls"
                );

        TeacherGradeFile exported =
                BinaryTeacherGradeReader.read(
                        service.generateFGContent(classes)
                );
        FgSubjectClassGrade subjectClass =
                exported.getSubjectClassGrades()
                        .getFirst();

        assertEquals("PRN221", subjectClass.getSubject());
        assertEquals("NET1710", subjectClass.getClassName());
        assertEquals(
                8.3f,
                subjectClass.getStudents()
                        .getFirst()
                        .getGrades()
                        .getFirst()
                        .getGrade(),
                0.001f
        );
    }

    @Test
    void exportFgUsesFinalClassesAfterCrudChanges() throws Exception {
        GradeService service =
                new GradeService();
        String xml =
                """
                <?xml version="1.0"?>
                <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
                          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
                  <Worksheet ss:Name="PRN221_NET1710">
                    <Table>
                      <Row>
                        <Cell><Data ss:Type="String">RollNumber</Data></Cell>
                        <Cell><Data ss:Type="String">FullName</Data></Cell>
                        <Cell><Data ss:Type="String">Final Exam</Data></Cell>
                      </Row>
                      <Row>
                        <Cell><Data ss:Type="String">SE123456</Data></Cell>
                        <Cell><Data ss:Type="String">Nguyen Van A</Data></Cell>
                        <Cell><Data ss:Type="Number">8.26</Data></Cell>
                      </Row>
                    </Table>
                  </Worksheet>
                </Workbook>
                """;

        Map<String, List<StudentGrade>> classes =
                service.processExcel(
                        new ByteArrayInputStream(
                                xml.getBytes(StandardCharsets.UTF_8)
                        ),
                        "phuonglhkSpring2024_1.xls"
                );

        classes.get("PRN221_NET1710")
                .getFirst()
                .setFinalExam(9.44);

        StudentGradeRequest sameClassRequest =
                new StudentGradeRequest();
        sameClassRequest.setSubject("PRN221");
        sameClassRequest.setClassName("NET1710");
        sameClassRequest.setRollNumber("SE999999");
        sameClassRequest.setFullName("Resolved Class Student");

        assertEquals(
                "PRN221_NET1710",
                service.resolveClassKey(
                        service.buildStudent(sameClassRequest)
                )
        );

        StudentGradeRequest newClassRequest =
                new StudentGradeRequest();
        newClassRequest.setSubject("PRN221");
        newClassRequest.setClassName("NET1711");
        newClassRequest.setRollNumber("SE654321");
        newClassRequest.setFullName("Tran Thi B");
        newClassRequest.setFinalExam(7.04);

        classes.put(
                "PRN221_NET1711",
                List.of(service.buildStudent(newClassRequest))
        );

        TeacherGradeFile exported =
                BinaryTeacherGradeReader.read(
                        service.generateFGContent(classes)
                );

        assertEquals(
                2,
                exported.getSubjectClassGrades().size()
        );
        assertTrue(
                exported.getSubjectClassGrades().stream()
                        .anyMatch(subjectClass ->
                                "NET1711".equals(
                                        subjectClass.getClassName()
                                ))
        );

        FgSubjectClassGrade originalClass =
                exported.getSubjectClassGrades().stream()
                        .filter(subjectClass ->
                                "NET1710".equals(
                                        subjectClass.getClassName()
                                ))
                        .findFirst()
                        .orElseThrow();

        assertEquals(
                9.4f,
                originalClass.getStudents()
                        .getFirst()
                        .getGrades()
                        .getFirst()
                        .getGrade(),
                0.001f
        );
    }

    private FgGradeComponent grade(String component, Float value) {
        FgGradeComponent grade =
                new FgGradeComponent();

        grade.setComponent(component);
        grade.setGrade(value);

        return grade;
    }
}
