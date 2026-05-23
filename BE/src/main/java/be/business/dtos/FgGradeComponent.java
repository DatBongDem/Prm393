package be.business.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;

public class FgGradeComponent {

    @JsonProperty("Component")
    private String component = "";

    @JsonProperty("Grade")
    private Float grade;

    public String getComponent() {
        return component;
    }

    public void setComponent(String component) {
        this.component = component;
    }

    public Float getGrade() {
        return grade;
    }

    public void setGrade(Float grade) {
        this.grade = grade;
    }
}
