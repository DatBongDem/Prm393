package be.business;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.Test;

import be.business.dtos.FgGradeComponent;
import be.business.dtos.FgStudent;
import be.business.dtos.FgSubjectClassGrade;
import be.business.dtos.TeacherGradeFile;

class BinaryTeacherGradeWriterTest {

    @Test
    void writesFuGradeBinaryFileWithoutDefaultingMissingGradeValues() {
        TeacherGradeFile teacherGrade =
                new TeacherGradeFile();
        teacherGrade.setVersion("1.1");
        teacherGrade.setSemester("SUMMER2026");
        teacherGrade.setLogin("phuonglhk");

        FgSubjectClassGrade subjectClass =
                new FgSubjectClassGrade();
        subjectClass.setSubject("PRM393");
        subjectClass.setClassName("SE1813");
        subjectClass.setComponents(
                List.of("Final Exam", "Progress Test 1")
        );

        FgStudent student =
                new FgStudent();
        student.setRoll("SE123456");
        student.setName("Nguyen Van A");
        student.setGrades(
                List.of(
                        grade("Final Exam", 7.56f),
                        grade("Progress Test 1", null)
                )
        );

        subjectClass.setStudents(List.of(student));
        teacherGrade.setSubjectClassGrades(List.of(subjectClass));

        byte[] bytes =
                BinaryTeacherGradeWriter.write(teacherGrade);

        assertTrue(BinaryTeacherGradeReader.canRead(bytes));

        TeacherGradeFile parsed =
                BinaryTeacherGradeReader.read(bytes);
        FgSubjectClassGrade parsedClass =
                parsed.getSubjectClassGrades()
                        .getFirst();
        FgStudent parsedStudent =
                parsedClass.getStudents()
                        .getFirst();

        assertEquals("SUMMER2026", parsed.getSemester());
        assertEquals("", parsed.getPassword());
        assertEquals("PRM393", parsedClass.getSubject());
        assertEquals("SE1813", parsedClass.getClassName());
        assertEquals("SE123456", parsedStudent.getRoll());
        assertNull(parsedStudent.getComment());
        assertEquals(
                7.6f,
                parsedStudent.getGrades()
                        .get(0)
                        .getGrade(),
                0.001f
        );
        assertNull(
                parsedStudent.getGrades()
                        .get(1)
                        .getGrade()
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
