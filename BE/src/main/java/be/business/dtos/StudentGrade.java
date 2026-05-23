package be.business.dtos;

public class StudentGrade {

    // ================= BASIC =================
    private String className;
    private String rollNumber;
    private String email;
    private String memberCode;
    private String fullName;

    // ================= EXAM INFO =================
    private String examDate;
    private String examNote;

    // ================= FINAL =================
    private double finalExam;
    private String finalComment;

    private double finalResit;
    private String finalResitComment;

    // ================= PRACTICAL =================
    private double practical;
    private String practicalComment;

    // ================= PT =================
    private double pt1;
    private String pt1Comment;

    private double pt2;
    private String pt2Comment;

    private double pt3;
    private String pt3Comment;

    // ================= PROJECT =================
    private double project;
    private String projectComment;

    // ================= CALCULATED =================
    private double total;
    private String result;
    private String comment;

    // ================= CONSTRUCTOR =================
    public StudentGrade() {
    }

    // ================= GETTER / SETTER =================

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

    public String getFinalComment() {
        return finalComment;
    }

    public void setFinalComment(String finalComment) {
        this.finalComment = finalComment;
    }

    public double getFinalResit() {
        return finalResit;
    }

    public void setFinalResit(double finalResit) {
        this.finalResit = finalResit;
    }

    public String getFinalResitComment() {
        return finalResitComment;
    }

    public void setFinalResitComment(String finalResitComment) {
        this.finalResitComment = finalResitComment;
    }

    public double getPractical() {
        return practical;
    }

    public void setPractical(double practical) {
        this.practical = practical;
    }

    public String getPracticalComment() {
        return practicalComment;
    }

    public void setPracticalComment(String practicalComment) {
        this.practicalComment = practicalComment;
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

    public double getTotal() {
        return total;
    }

    public void setTotal(double total) {
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
}