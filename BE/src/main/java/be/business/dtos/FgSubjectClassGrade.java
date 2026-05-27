package be.business.dtos;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

public class FgSubjectClassGrade {

    @JsonProperty("Subject")
    private String subject;

    @JsonProperty("Class")
    private String className;

    @JsonProperty("Students")
    private List<FgStudent> students = new ArrayList<>();

    @JsonProperty("Components")
    private List<String> components = new ArrayList<>();

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

    public List<FgStudent> getStudents() {
        return students;
    }

    public void setStudents(List<FgStudent> students) {
        this.students = students;
    }

    public List<String> getComponents() {
        return components;
    }

    public void setComponents(List<String> components) {
        this.components = components;
    }
}
