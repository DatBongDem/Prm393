package be.business;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import be.business.dtos.AIQuery;
import be.business.dtos.StudentGrade;

@Service
public class StudentQueryService {

    // ================= FILTER =================
    public List<StudentGrade> filter(List<StudentGrade> students, AIQuery q) {

        if (students == null || students.isEmpty())
            return List.of();

        if (q == null ||
            q.getField() == null ||
            q.getValue() == null)
            return List.of();

        List<StudentGrade> result = new ArrayList<>();

        for (StudentGrade s : students) {
            if (match(s, q)) {
                result.add(s);
            }
        }

        return result;
    }

    // ================= MATCH =================
    private boolean match(StudentGrade s, AIQuery q) {

        String field = normalize(q.getField());

        switch (field) {

            case "total":
                return compareNumber(s.getTotal(), q);

            case "project":
                return compareNumber(s.getProject(), q);

            case "finalexam":
                return compareNumber(s.getFinalExam(), q);

            case "practical":
                return compareNumber(s.getPractical(), q);

            case "pt1":
                return compareNumber(s.getPt1(), q);

            case "pt2":
                return compareNumber(s.getPt2(), q);

            case "pt3":
                return compareNumber(s.getPt3(), q);

            case "result":
                return compareString(s.getResult(), q.getValue());

            case "classname":
            case "class":
                return compareString(
                        s.getClassName(),
                        q.getValue()
                );

            case "fullname":
                return compareContains(
                        s.getFullName(),
                        q.getValue()
                );

            case "rollnumber":
                return compareContains(
                        s.getRollNumber(),
                        q.getValue()
                );

            default:
                return false;
        }
    }

    // ================= NUMBER COMPARE =================
    private boolean compareNumber(double actual, AIQuery q) {

        try {

            double value =
                    Double.parseDouble(
                            q.getValue().trim()
                    );

            String op = q.getOperator();

            if (op == null) return false;

            return switch (op) {

                case ">" -> actual > value;

                case "<" -> actual < value;

                case "=" -> actual == value;

                case ">=" -> actual >= value;

                case "<=" -> actual <= value;

                default -> false;
            };

        } catch (Exception e) {

            return false;
        }
    }

    // ================= STRING EQUAL =================
    private boolean compareString(String actual, String value) {

        if (actual == null || value == null)
            return false;

        return actual.trim()
                .equalsIgnoreCase(value.trim());
    }

    // ================= STRING CONTAINS =================
    private boolean compareContains(String actual, String value) {

        if (actual == null || value == null)
            return false;

        return actual.toLowerCase()
                .contains(value.toLowerCase().trim());
    }

    // ================= AGGREGATE =================
    public List<StudentGrade> aggregate(
            List<StudentGrade> students,
            String field,
            String type
    ) {

        if (students == null || students.isEmpty())
            return List.of();

        field = normalize(field);

        List<StudentGrade> result =
                new ArrayList<>();

        double bestValue =
                getValue(students.get(0), field);

        // tìm max/min
        for (StudentGrade s : students) {

            double value =
                    getValue(s, field);

            if ("max".equalsIgnoreCase(type)
                    && value > bestValue) {

                bestValue = value;
            }

            if ("min".equalsIgnoreCase(type)
                    && value < bestValue) {

                bestValue = value;
            }
        }

        // lấy tất cả người đồng điểm
        for (StudentGrade s : students) {

            double value =
                    getValue(s, field);

            if (value == bestValue) {
                result.add(s);
            }
        }

        return result;
    }

    // ================= GET VALUE =================
    private double getValue(StudentGrade s,
                            String field) {

        return switch (field) {

            case "total" ->
                    s.getTotal();

            case "project" ->
                    s.getProject();

            case "finalexam" ->
                    s.getFinalExam();

            case "practical" ->
                    s.getPractical();

            case "pt1" ->
                    s.getPt1();

            case "pt2" ->
                    s.getPt2();

            case "pt3" ->
                    s.getPt3();

            default -> 0;
        };
    }

    // ================= NORMALIZE =================
    private String normalize(String field) {

        if (field == null)
            return "";

        return field.toLowerCase()
                .replace("_", "")
                .replace(" ", "")
                .trim();
    }
}