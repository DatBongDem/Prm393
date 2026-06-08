package be.business.dtos;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

public class FgStudent implements Comparable<FgStudent> {

    @JsonProperty("Roll")
    private String roll;

    @JsonProperty("Name")
    private String name;

    @JsonProperty("Grades")
    private List<FgGradeComponent> grades = new ArrayList<>();

    @JsonProperty("Comment")
    private String comment;

    @JsonIgnore
    private String email;

    @JsonIgnore
    private String memberCode;

    @JsonIgnore
    private String examDate;

    @JsonIgnore
    private String examNote;

    @JsonIgnore
    private String finalExamComment;

    @JsonIgnore
    private String finalExamResitComment;

    @JsonIgnore
    private String practicalExamComment;

    @JsonIgnore
    private String progressTest1Comment;

    @JsonIgnore
    private String progressTest2Comment;

    @JsonIgnore
    private String progressTest3Comment;

    @JsonIgnore
    private String projectComment;

    @Override
    public int compareTo(FgStudent other) {
        if (other == null) {
            return 1;
        }

        return nullToEmpty(roll).compareTo(nullToEmpty(other.roll));
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    public String getRoll() {
        return roll;
    }

    public void setRoll(String roll) {
        this.roll = roll;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<FgGradeComponent> getGrades() {
        return grades;
    }

    public void setGrades(List<FgGradeComponent> grades) {
        this.grades = grades;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
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

    public String getFinalExamComment() {
        return finalExamComment;
    }

    public void setFinalExamComment(String finalExamComment) {
        this.finalExamComment = finalExamComment;
    }

    public String getFinalExamResitComment() {
        return finalExamResitComment;
    }

    public void setFinalExamResitComment(
            String finalExamResitComment
    ) {
        this.finalExamResitComment = finalExamResitComment;
    }

    public String getPracticalExamComment() {
        return practicalExamComment;
    }

    public void setPracticalExamComment(
            String practicalExamComment
    ) {
        this.practicalExamComment = practicalExamComment;
    }

    public String getProgressTest1Comment() {
        return progressTest1Comment;
    }

    public void setProgressTest1Comment(
            String progressTest1Comment
    ) {
        this.progressTest1Comment = progressTest1Comment;
    }

    public String getProgressTest2Comment() {
        return progressTest2Comment;
    }

    public void setProgressTest2Comment(
            String progressTest2Comment
    ) {
        this.progressTest2Comment = progressTest2Comment;
    }

    public String getProgressTest3Comment() {
        return progressTest3Comment;
    }

    public void setProgressTest3Comment(
            String progressTest3Comment
    ) {
        this.progressTest3Comment = progressTest3Comment;
    }

    public String getProjectComment() {
        return projectComment;
    }

    public void setProjectComment(String projectComment) {
        this.projectComment = projectComment;
    }
}
