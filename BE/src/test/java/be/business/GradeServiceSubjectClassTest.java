package be.business;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.StudentGrade;
import be.business.dtos.TeacherGradeFile;

class GradeServiceSubjectClassTest {

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
}
