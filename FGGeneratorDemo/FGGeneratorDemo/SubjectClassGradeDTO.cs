namespace FGGeneratorDemo;

public sealed class SubjectClassGrade
{
    public string Subject { get; set; } = "";

    public string Class { get; set; } = "";

    public List<Student> Students { get; set; } = new();

    public List<string> Components { get; set; } = new();
}
