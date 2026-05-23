namespace FGGeneratorDemo;

public sealed class TeacherGrade
{
    public string Version { get; set; } = "1.1";

    public string Semester { get; set; } = "";

    public string Login { get; set; } = "";

    public string Password { get; set; } = "";

    public List<SubjectClassGrade> SubjectClassGrades { get; set; } = new();
}
