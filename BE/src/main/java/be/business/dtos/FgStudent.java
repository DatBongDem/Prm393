package be.business.dtos;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

public class FgStudent implements Comparable<FgStudent> {

    @JsonProperty("Roll")
    private String roll = "";

    @JsonProperty("Name")
    private String name = "";

    @JsonProperty("Grades")
    private List<FgGradeComponent> grades = new ArrayList<>();

    @JsonProperty("Comment")
    private String comment;

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
}
