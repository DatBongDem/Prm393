package be.business.dtos;

import java.util.List;

public class StudentGrade {

    // ================= BASIC =================
    private String subject;
    private String className;
    private String rollNumber;
    private String email;
    private String memberCode;
    private String fullName;

    // ================= EXAM INFO =================
    private String examDate;
    private String examNote;

    // ================= FINAL =================
    private Double finalExam;
    private String finalComment;

    private Double finalResit;
    private String finalResitComment;

    // ================= PRACTICAL =================
    private Double practical;
    private String practicalComment;

    // ================= PT =================
    private Double pt1;
    private String pt1Comment;

    private Double pt2;
    private String pt2Comment;

    private Double pt3;
    private String pt3Comment;

    // ================= PROJECT =================
    private Double project;
    private String projectComment;

    // ================= CALCULATED =================
    private Double total;
    private String result;
    private String comment;
    private List<FgGradeComponent> gradeComponents;

    // ================= CONSTRUCTOR =================
    public StudentGrade() {
    }

    // ================= GETTER / SETTER =================

    public String getSubject() {
        return subject;
    }

    public void setSubject(String subject) {
        this.subject = subject;
    }

    public String getClassName() {
        return className;
    }

    public void setClassName(String className) {
        this.className = className;
    }

    public String getRollNumber() {
        return rollNumber;
    }

    public void setRollNumber(String rollNumber) {
        this.rollNumber = rollNumber;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getMemberCode() {
        return memberCode;
    }

    public void setMemberCode(String memberCode) {
        this.memberCode = memberCode;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getExamDate() {
        return examDate;
    }

    public void setExamDate(String examDate) {
        this.examDate = examDate;
    }

    public String getExamNote() {
        return examNote;
    }

    public void setExamNote(String examNote) {
        this.examNote = examNote;
    }

    public Double getFinalExam() {
        return finalExam;
    }

    public void setFinalExam(Double finalExam) {
        this.finalExam = finalExam;
    }

    public String getFinalComment() {
        return finalComment;
    }

    public void setFinalComment(String finalComment) {
        this.finalComment = finalComment;
    }

    public Double getFinalResit() {
        return finalResit;
    }

    public void setFinalResit(Double finalResit) {
        this.finalResit = finalResit;
    }

    public String getFinalResitComment() {
        return finalResitComment;
    }

    public void setFinalResitComment(String finalResitComment) {
        this.finalResitComment = finalResitComment;
    }

    public Double getPractical() {
        return practical;
    }

    public void setPractical(Double practical) {
        this.practical = practical;
    }

    public String getPracticalComment() {
        return practicalComment;
    }

    public void setPracticalComment(String practicalComment) {
        this.practicalComment = practicalComment;
    }

    public Double getPt1() {
        return pt1;
    }

    public void setPt1(Double pt1) {
        this.pt1 = pt1;
    }

    public String getPt1Comment() {
        return pt1Comment;
    }

    public void setPt1Comment(String pt1Comment) {
        this.pt1Comment = pt1Comment;
    }

    public Double getPt2() {
        return pt2;
    }

    public void setPt2(Double pt2) {
        this.pt2 = pt2;
    }

    public String getPt2Comment() {
        return pt2Comment;
    }

    public void setPt2Comment(String pt2Comment) {
        this.pt2Comment = pt2Comment;
    }

    public Double getPt3() {
        return pt3;
    }

    public void setPt3(Double pt3) {
        this.pt3 = pt3;
    }

    public String getPt3Comment() {
        return pt3Comment;
    }

    public void setPt3Comment(String pt3Comment) {
        this.pt3Comment = pt3Comment;
    }

    public Double getProject() {
        return project;
    }

    public void setProject(Double project) {
        this.project = project;
    }

    public String getProjectComment() {
        return projectComment;
    }

    public void setProjectComment(String projectComment) {
        this.projectComment = projectComment;
    }

    public Double getTotal() {
        return total;
    }

    public void setTotal(Double total) {
        this.total = total;
    }

    public String getResult() {
        return result;
    }

    public void setResult(String result) {
        this.result = result;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public List<FgGradeComponent> getGradeComponents() {
        return gradeComponents;
    }

    public void setGradeComponents(
            List<FgGradeComponent> gradeComponents
    ) {
        this.gradeComponents = gradeComponents;
    }
}
