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

@Service
public class GradeService {

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

        for (int s = 0;
             s < worksheets.getLength();
             s++) {

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
            for (int i = 1;
                 i < rows.getLength();
                 i++) {

                Element row =
                        (Element) rows.item(i);

                NodeList cellNodes =
                        row.getElementsByTagName("Cell");

                Map<Integer, String> dataMap =
                        new HashMap<>();

                int currentIndex = 1;

                for (int j = 0;
                     j < cellNodes.getLength();
                     j++) {

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

                    dataMap.put(
                            currentIndex,
                            value
                    );

                    currentIndex++;
                }

                String rollNumber =
                        dataMap.getOrDefault(2, "");

                String fullName =
                        dataMap.getOrDefault(5, "");

                if (rollNumber.isBlank()) {
                    continue;
                }

                // ===== FINAL =====

                double finalExam =
                        parseDouble(
                                dataMap.getOrDefault(8, "0")
                        );

                String finalComment =
                        dataMap.getOrDefault(9, "");

                double finalResit =
                        parseDouble(
                                dataMap.getOrDefault(10, "0")
                        );

                // ===== PRACTICAL =====

                double practical =
                        parseDouble(
                                dataMap.getOrDefault(12, "0")
                        );

                double practicalResit =
                        parseDouble(
                                dataMap.getOrDefault(13, "0")
                        );

                // ===== PT =====

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

                // ===== PROJECT =====

                double project =
                        parseDouble(
                                dataMap.getOrDefault(20, "0")
                        );

                String projectComment =
                        dataMap.getOrDefault(21, "");

                // ===== SCORE USED FOR CALCULATION =====

                double finalUsed =
                        finalResit > 0
                                ? finalResit
                                : finalExam;

                double practicalUsed =
                        practicalResit > 0
                                ? practicalResit
                                : practical;

                // ===== TOTAL =====

                double progressAvg =
                        (pt1 + pt2 + pt3) / 3;

                double total =
                        finalUsed * 0.30
                                + practicalUsed * 0.25
                                + progressAvg * 0.15
                                + project * 0.30;

                total = round(total);

                // ===== RESULT =====

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
                            String.join(
                                    " ",
                                    reasons
                            );
                }

                students.add(
                        new StudentGrade(
                                rollNumber,
                                fullName,

                                finalExam,
                                finalComment,
                                finalResit,

                                practical,
                                practicalResit,

                                pt1,
                                pt1Comment,

                                pt2,
                                pt2Comment,

                                pt3,
                                pt3Comment,

                                project,
                                projectComment,

                                total,
                                resultStatus,
                                comment
                        )
                );
            }

            result.put(
                    className,
                    students
            );
        }

        return result;
    }

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

    private double parseDouble(String value) {

        try {

            if (value == null
                    || value.isBlank()) {

                return 0;
            }

            return Double.parseDouble(value);

        } catch (Exception e) {

            return 0;
        }
    }

    private double round(double value) {

        return Math.round(value * 100.0)
                / 100.0;
    }

    // ===== DTO =====

    public static class StudentGrade {

        private String rollNumber;
        private String fullName;

        private double finalExam;
        private String finalComment;
        private double finalResit;

        private double practical;
        private double practicalResit;

        private double pt1;
        private String pt1Comment;

        private double pt2;
        private String pt2Comment;

        private double pt3;
        private String pt3Comment;

        private double project;
        private String projectComment;

        private double total;
        private String result;

        private String comment;

        public StudentGrade(
                String rollNumber,
                String fullName,

                double finalExam,
                String finalComment,
                double finalResit,

                double practical,
                double practicalResit,

                double pt1,
                String pt1Comment,

                double pt2,
                String pt2Comment,

                double pt3,
                String pt3Comment,

                double project,
                String projectComment,

                double total,
                String result,
                String comment
        ) {

            this.rollNumber = rollNumber;
            this.fullName = fullName;

            this.finalExam = finalExam;
            this.finalComment = finalComment;
            this.finalResit = finalResit;

            this.practical = practical;
            this.practicalResit = practicalResit;

            this.pt1 = pt1;
            this.pt1Comment = pt1Comment;

            this.pt2 = pt2;
            this.pt2Comment = pt2Comment;

            this.pt3 = pt3;
            this.pt3Comment = pt3Comment;

            this.project = project;
            this.projectComment = projectComment;

            this.total = total;
            this.result = result;

            this.comment = comment;
        }

        public String getRollNumber() {
            return rollNumber;
        }

        public String getFullName() {
            return fullName;
        }

        public double getFinalExam() {
            return finalExam;
        }

        public String getFinalComment() {
            return finalComment;
        }

        public double getFinalResit() {
            return finalResit;
        }

        public double getPractical() {
            return practical;
        }

        public double getPracticalResit() {
            return practicalResit;
        }

        public double getPt1() {
            return pt1;
        }

        public String getPt1Comment() {
            return pt1Comment;
        }

        public double getPt2() {
            return pt2;
        }

        public String getPt2Comment() {
            return pt2Comment;
        }

        public double getPt3() {
            return pt3;
        }

        public String getPt3Comment() {
            return pt3Comment;
        }

        public double getProject() {
            return project;
        }

        public String getProjectComment() {
            return projectComment;
        }

        public double getTotal() {
            return total;
        }

        public String getResult() {
            return result;
        }

        public String getComment() {
            return comment;
        }
    }
}