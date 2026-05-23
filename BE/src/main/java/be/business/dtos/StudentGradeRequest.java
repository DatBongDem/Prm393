package be.business.dtos;

public class StudentGradeRequest {

    private String className;
    private String rollNumber;
    private String email;
    private String memberCode;
    private String fullName;

    private String examDate;
    private String examNote;

    private double finalExam;
    private String finalExamComment;

    private double finalExamResit;
    private String finalExamResitComment;

    private double practicalExam;
    private String practicalExamComment;

    private double pt1;
    private String pt1Comment;

    private double pt2;
    private String pt2Comment;

    private double pt3;
    private String pt3Comment;

    private double project;
    private String projectComment;

    // ===== GETTER SETTER =====

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

    public double getFinalExam() {
        return finalExam;
    }

    public void setFinalExam(double finalExam) {
        this.finalExam = finalExam;
    }

    public String getFinalExamComment() {
        return finalExamComment;
    }

    public void setFinalExamComment(String finalExamComment) {
        this.finalExamComment = finalExamComment;
    }

    public double getFinalExamResit() {
        return finalExamResit;
    }

    public void setFinalExamResit(double finalExamResit) {
        this.finalExamResit = finalExamResit;
    }

    public String getFinalExamResitComment() {
        return finalExamResitComment;
    }

    public void setFinalExamResitComment(String finalExamResitComment) {
        this.finalExamResitComment = finalExamResitComment;
    }

    public double getPracticalExam() {
        return practicalExam;
    }

    public void setPracticalExam(double practicalExam) {
        this.practicalExam = practicalExam;
    }

    public String getPracticalExamComment() {
        return practicalExamComment;
    }

    public void setPracticalExamComment(String practicalExamComment) {
        this.practicalExamComment = practicalExamComment;
    }

    public double getPt1() {
        return pt1;
    }

    public void setPt1(double pt1) {
        this.pt1 = pt1;
    }

    public String getPt1Comment() {
        return pt1Comment;
    }

    public void setPt1Comment(String pt1Comment) {
        this.pt1Comment = pt1Comment;
    }

    public double getPt2() {
        return pt2;
    }

    public void setPt2(double pt2) {
        this.pt2 = pt2;
    }

    public String getPt2Comment() {
        return pt2Comment;
    }

    public void setPt2Comment(String pt2Comment) {
        this.pt2Comment = pt2Comment;
    }

    public double getPt3() {
        return pt3;
    }

    public void setPt3(double pt3) {
        this.pt3 = pt3;
    }

    public String getPt3Comment() {
        return pt3Comment;
    }

    public void setPt3Comment(String pt3Comment) {
        this.pt3Comment = pt3Comment;
    }

    public double getProject() {
        return project;
    }

    public void setProject(double project) {
        this.project = project;
    }

    public String getProjectComment() {
        return projectComment;
    }

    public void setProjectComment(String projectComment) {
        this.projectComment = projectComment;
    }
}