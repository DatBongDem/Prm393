namespace FGGeneratorDemo;

public sealed class Student : IComparable<Student>
{
    public string Roll { get; set; } = "";

    public string Name { get; set; } = "";

    public List<GradeComponent> Grades { get; set; } = new();

    public string? Comment { get; set; }

    public int CompareTo(Student? other)
    {
        return other is null
            ? 1
            : string.Compare(Roll, other.Roll, StringComparison.Ordinal);
    }
}

public sealed class GradeComponent
{
    public string Component { get; set; } = "";

    public float? Grade { get; set; }
}
