package be.business;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import be.business.dtos.StudentGrade;

@Service
public class GradeService {

    // cache dữ liệu mới upload
    private Map<String, List<StudentGrade>> latestClasses;

    // ================= READ EXCEL =================
    public Map<String, List<StudentGrade>> processExcel(
            InputStream inputStream
    ) throws Exception {

        Map<String, List<StudentGrade>> result =
                new LinkedHashMap<>();

        DocumentBuilderFactory factory =
                DocumentBuilderFactory.newInstance();

        factory.setNamespaceAware(false);

        DocumentBuilder builder =
                factory.newDocumentBuilder();

        Document document =
                builder.parse(inputStream);

        NodeList worksheets =
                document.getElementsByTagName("Worksheet");

        // ================= LOOP SHEET =================
        for (int s = 0; s < worksheets.getLength(); s++) {

            Element worksheet =
                    (Element) worksheets.item(s);

            // tên sheet = class
            String className =
                    worksheet.getAttribute("ss:Name");

            List<StudentGrade> students =
                    new ArrayList<>();

            NodeList rows =
                    worksheet.getElementsByTagName("Row");

            // bỏ header
            for (int i = 1; i < rows.getLength(); i++) {

                Element row =
                        (Element) rows.item(i);

                NodeList cellNodes =
                        row.getElementsByTagName("Cell");

                Map<Integer, String> dataMap =
                        new HashMap<>();

                int currentIndex = 1;

                // ================= READ CELL =================
                for (int j = 0; j < cellNodes.getLength(); j++) {

                    Element cell =
                            (Element) cellNodes.item(j);

                    String indexAttr =
                            cell.getAttribute("ss:Index");

                    if (!indexAttr.isBlank()) {

                        currentIndex =
                                Integer.parseInt(indexAttr);
                    }

                    NodeList dataList =
                            cell.getElementsByTagName("Data");

                    String value = "";

                    if (dataList.getLength() > 0) {

                        value =
                                dataList.item(0)
                                        .getTextContent()
                                        .trim();
                    }

                    dataMap.put(currentIndex, value);

                    currentIndex++;
                }

                // ================= BASIC =================

                String rollNumber =
                        dataMap.getOrDefault(2, "");

                if (rollNumber.isBlank()) {
                    continue;
                }

                String email =
                        dataMap.getOrDefault(3, "");

                String memberCode =
                        dataMap.getOrDefault(4, "");

                String fullName =
                        dataMap.getOrDefault(5, "");

                String examDate =
                        dataMap.getOrDefault(6, "");

                String examNote =
                        dataMap.getOrDefault(7, "");

                // ================= FINAL =================

                double finalExam =
                        parseDouble(
                                dataMap.getOrDefault(8, "0")
                        );

                String finalExamComment =
                        dataMap.getOrDefault(9, "");

                double finalExamResit =
                        parseDouble(
                                dataMap.getOrDefault(10, "0")
                        );

                String finalExamResitComment =
                        dataMap.getOrDefault(11, "");

                // ================= PRACTICAL =================

                double practicalExam =
                        parseDouble(
                                dataMap.getOrDefault(12, "0")
                        );

                String practicalExamComment =
                        dataMap.getOrDefault(13, "");

                // ================= PT =================

                double pt1 =
                        parseDouble(
                                dataMap.getOrDefault(14, "0")
                        );

                String pt1Comment =
                        dataMap.getOrDefault(15, "");

                double pt2 =
                        parseDouble(
                                dataMap.getOrDefault(16, "0")
                        );

                String pt2Comment =
                        dataMap.getOrDefault(17, "");

                double pt3 =
                        parseDouble(
                                dataMap.getOrDefault(18, "0")
                        );

                String pt3Comment =
                        dataMap.getOrDefault(19, "");

                // ================= PROJECT =================

                double project =
                        parseDouble(
                                dataMap.getOrDefault(20, "0")
                        );

                String projectComment =
                        dataMap.getOrDefault(21, "");

                // ================= CALCULATE =================

                double finalUsed =
                        finalExamResit > 0
                                ? finalExamResit
                                : finalExam;

                double practicalUsed =
                        practicalExam;

                double progressAvg =
                        (pt1 + pt2 + pt3) / 3.0;

                double total =
                        finalUsed * 0.30
                                + practicalUsed * 0.25
                                + progressAvg * 0.15
                                + project * 0.30;

                total = round(total);

                // ================= RESULT =================

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

                // ================= CREATE DTO =================

                StudentGrade student = new StudentGrade();

student.setClassName(className);

student.setRollNumber(rollNumber);
student.setEmail(email);
student.setMemberCode(memberCode);
student.setFullName(fullName);

student.setExamDate(examDate);
student.setExamNote(examNote);

student.setFinalExam(finalExam);
student.setFinalComment(finalExamComment);

student.setFinalResit(finalExamResit);
student.setFinalResitComment(finalExamResitComment);

student.setPractical(practicalExam);
student.setPracticalComment(practicalExamComment);

student.setPt1(pt1);
student.setPt1Comment(pt1Comment);

student.setPt2(pt2);
student.setPt2Comment(pt2Comment);

student.setPt3(pt3);
student.setPt3Comment(pt3Comment);

student.setProject(project);
student.setProjectComment(projectComment);

student.setTotal(total);
student.setResult(resultStatus);
student.setComment(comment);

                students.add(student);
            }

            result.put(className, students);
        }

        // cache
        latestClasses = result;

        return result;
    }

    // ================= GENERATE FG =================
    public String generateFGContent(
            Map<String, List<StudentGrade>> data
    ) {

        StringBuilder builder =
                new StringBuilder();

        builder.append("STUDENT_GRADE_FILE\n");

        for (String className : data.keySet()) {

            builder.append("CLASS:")
                    .append(className)
                    .append("\n");

            for (StudentGrade student :
                    data.get(className)) {

                builder.append(
                        String.format(
                                "%s|%s|%.2f|%s\n",
                                student.getRollNumber(),
                                student.getFullName(),
                                student.getTotal(),
                                student.getResult()
                        )
                );
            }
        }

        return builder.toString();
    }

    // ================= SAFE PARSE =================
    private double parseDouble(String value) {

        try {

            if (value == null || value.isBlank()) {
                return 0;
            }

            return Double.parseDouble(value);

        } catch (Exception e) {

            return 0;
        }
    }

    // ================= ROUND =================
    private double round(double value) {

        return Math.round(value * 100.0) / 100.0;
    }

    // ================= CACHE =================

    public void setLatestClasses(
            Map<String, List<StudentGrade>> classes
    ) {
        this.latestClasses = classes;
    }

    public Map<String, List<StudentGrade>> getLatestClasses() {
        return latestClasses;
    }
}