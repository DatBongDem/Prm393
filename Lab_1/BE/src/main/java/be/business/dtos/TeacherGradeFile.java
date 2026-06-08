package be.business.dtos;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TeacherGradeFile {

    @JsonProperty("Version")
    private String version;

    @JsonProperty("Semester")
    private String semester;

    @JsonProperty("Login")
    private String login;

    @JsonProperty("Password")
    private String password;

    @JsonProperty("SubjectClassGrades")
    private List<FgSubjectClassGrade> subjectClassGrades = new ArrayList<>();

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getSemester() {
        return semester;
    }

    public void setSemester(String semester) {
        this.semester = semester;
    }

    public String getLogin() {
        return login;
    }

    public void setLogin(String login) {
        this.login = login;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public List<FgSubjectClassGrade> getSubjectClassGrades() {
        return subjectClassGrades;
    }

    public void setSubjectClassGrades(
            List<FgSubjectClassGrade> subjectClassGrades
    ) {
        this.subjectClassGrades = subjectClassGrades;
    }
}
