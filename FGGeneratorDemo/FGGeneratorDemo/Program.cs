using FGGeneratorDemo;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Xml.Linq;

const string FuGradeKey = "l10ca968o8e4133tyne2ea2315g19377";

var projectFolder = ResolveProjectFolder();
var inputPath = args.Length > 0 ? args[0] : Path.Combine(projectFolder, "input");
var outputFolder = args.Length > 1 ? args[1] : Path.Combine(projectFolder, "output");

Directory.CreateDirectory(outputFolder);

var files = Directory.Exists(inputPath)
    ? Directory.GetFiles(inputPath, "*.xls")
    : File.Exists(inputPath)
        ? [inputPath]
        : [];

foreach (var file in files)
{
    ProcessExcel(file, outputFolder);
}

Console.WriteLine("DONE!");

static void ProcessExcel(string path, string outputFolder)
{
    var fileInfo = ParseFileName(path);
    var doc = XDocument.Load(path);
    XNamespace ss = "urn:schemas-microsoft-com:office:spreadsheet";

    var teacherGrade = new TeacherGrade
    {
        Version = "1.1",
        Semester = fileInfo.Semester,
        Login = fileInfo.TeacherLogin,
        Password = ""
    };

    var subjectClasses = new Dictionary<string, SubjectClassGrade>(StringComparer.OrdinalIgnoreCase);

    foreach (var worksheet in doc.Descendants(ss + "Worksheet"))
    {
        var sheetName = worksheet.Attribute(ss + "Name")?.Value.Trim() ?? "";
        var rows = worksheet
            .Descendants(ss + "Row")
            .Select(row => ReadRow(row, ss))
            .Where(row => row.Any(value => !string.IsNullOrWhiteSpace(value)))
            .ToList();

        if (rows.Count < 2)
        {
            continue;
        }

        var headers = rows[0];
        var headerMap = BuildHeaderMap(headers);
        var components = GetGradingComponents(headers);

        foreach (var row in rows.Skip(1))
        {
            var roll = GetCell(row, headerMap, "RollNumber", "Roll");
            if (string.IsNullOrWhiteSpace(roll))
            {
                continue;
            }

            var className = GetCell(row, headerMap, "Class");
            if (string.IsNullOrWhiteSpace(className))
            {
                className = !string.IsNullOrWhiteSpace(sheetName) ? sheetName : fileInfo.ClassName;
            }

            var key = $"{fileInfo.SubjectCode}/{className}";
            if (!subjectClasses.TryGetValue(key, out var subjectClass))
            {
                subjectClass = new SubjectClassGrade
                {
                    Subject = fileInfo.SubjectCode,
                    Class = className,
                    Components = new List<string>(components)
                };

                subjectClasses.Add(key, subjectClass);
                teacherGrade.SubjectClassGrades.Add(subjectClass);
            }

            subjectClass.Students.Add(MapStudent(row, headerMap, components));
        }
    }

    foreach (var subjectClass in teacherGrade.SubjectClassGrades)
    {
        subjectClass.Students.Sort();
        ShowStatistics(subjectClass);
    }

    ExportFG(path, outputFolder, teacherGrade);
}

static Student MapStudent(
    IReadOnlyList<string> row,
    IReadOnlyDictionary<string, int> headerMap,
    IReadOnlyList<string> components)
{
    return new Student
    {
        Roll = GetCell(row, headerMap, "RollNumber", "Roll"),
        Name = GetCell(row, headerMap, "FullName", "Name"),
        Comment = BuildStudentComment(row, headerMap, components),
        Grades = components
            .Select(component => new GradeComponent
            {
                Component = component,
                Grade = ParseNullableFloat(GetCell(row, headerMap, component))
            })
            .ToList()
    };
}

static List<string> ReadRow(XElement row, XNamespace ss)
{
    var values = new List<string>();
    var nextIndex = 1;

    foreach (var cell in row.Elements(ss + "Cell"))
    {
        if (int.TryParse(cell.Attribute(ss + "Index")?.Value, out var cellIndex) && cellIndex > nextIndex)
        {
            while (nextIndex < cellIndex)
            {
                values.Add("");
                nextIndex++;
            }
        }

        values.Add(cell.Element(ss + "Data")?.Value.Trim() ?? "");
        nextIndex++;
    }

    return values;
}

static Dictionary<string, int> BuildHeaderMap(IReadOnlyList<string> headers)
{
    var result = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

    for (var i = 0; i < headers.Count; i++)
    {
        var normalized = Normalize(headers[i]);
        if (!string.IsNullOrWhiteSpace(normalized))
        {
            result[normalized] = i;
        }
    }

    return result;
}

static List<string> GetGradingComponents(IReadOnlyList<string> headers)
{
    return headers
        .Where(header => !string.IsNullOrWhiteSpace(header))
        .Where(header => !IsStudentInfoColumn(header))
        .Where(header => !IsCommentColumn(header))
        .ToList();
}

static bool IsStudentInfoColumn(string header)
{
    var normalized = Normalize(header);

    return normalized is "class"
        or "roll"
        or "rollnumber"
        or "email"
        or "membercode"
        or "fullname"
        or "name"
        or "examdate"
        or "examnote";
}

static bool IsCommentColumn(string header)
{
    var normalized = Normalize(header);

    return normalized is "comment" or "comments"
        || normalized.EndsWith("comment", StringComparison.OrdinalIgnoreCase);
}

static string? BuildStudentComment(
    IReadOnlyList<string> row,
    IReadOnlyDictionary<string, int> headerMap,
    IReadOnlyList<string> components)
{
    var directComment = GetCell(row, headerMap, "Comment", "Comments");
    if (!string.IsNullOrWhiteSpace(directComment))
    {
        return directComment;
    }

    var comments = components
        .Select(component =>
        {
            var comment = GetCell(
                row,
                headerMap,
                $"{component}_Comment",
                $"{component} Comment",
                $"{component}Comment");

            return string.IsNullOrWhiteSpace(comment)
                ? ""
                : $"{component}: {comment}";
        })
        .Where(comment => !string.IsNullOrWhiteSpace(comment))
        .ToList();

    return comments.Count == 0 ? null : string.Join("; ", comments);
}

static string GetCell(
    IReadOnlyList<string> row,
    IReadOnlyDictionary<string, int> headerMap,
    params string[] headers)
{
    foreach (var header in headers)
    {
        if (headerMap.TryGetValue(Normalize(header), out var index) && index < row.Count)
        {
            return row[index].Trim();
        }
    }

    return "";
}

static float? ParseNullableFloat(string value)
{
    if (string.IsNullOrWhiteSpace(value))
    {
        return null;
    }

    if (float.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var invariantValue))
    {
        return invariantValue;
    }

    if (float.TryParse(value, NumberStyles.Float, CultureInfo.CurrentCulture, out var currentValue))
    {
        return currentValue;
    }

    return null;
}

static void ExportFG(string excelPath, string outputFolder, TeacherGrade teacherGrade)
{
    var json = JsonSerializer.Serialize(teacherGrade);
    var encrypted = EncryptString(json);
    var fileName = Path.GetFileNameWithoutExtension(excelPath);
    var outputPath = Path.Combine(outputFolder, $"{fileName}.fg");

    try
    {
        File.WriteAllText(outputPath, encrypted);
    }
    catch (IOException) when (File.Exists(outputPath))
    {
        outputPath = Path.Combine(outputFolder, $"{fileName}_new.fg");
        File.WriteAllText(outputPath, encrypted);
    }

    Console.WriteLine($"Generated FG: {outputPath}");
}

static string EncryptString(string plainText)
{
    using var aes = Aes.Create();
    aes.Key = Encoding.UTF8.GetBytes(FuGradeKey);
    aes.IV = new byte[16];

    using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
    using var memoryStream = new MemoryStream();

    using (var cryptoStream = new CryptoStream(memoryStream, encryptor, CryptoStreamMode.Write))
    using (var writer = new StreamWriter(cryptoStream))
    {
        writer.Write(plainText);
    }

    return Convert.ToBase64String(memoryStream.ToArray());
}

static (string ClassName, string SubjectCode, string TeacherLogin, string Semester) ParseFileName(string path)
{
    var fileName = Path.GetFileNameWithoutExtension(path);
    var parts = fileName.Split('_', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    return parts.Length >= 4
        ? (parts[0], parts[1], parts[2].ToLowerInvariant(), string.Join("_", parts.Skip(3)))
        : ("", fileName, "", "");
}

static string ResolveProjectFolder()
{
    var candidates = new[]
    {
        Directory.GetCurrentDirectory(),
        AppContext.BaseDirectory
    };

    foreach (var candidate in candidates)
    {
        var current = new DirectoryInfo(candidate);
        while (current is not null)
        {
            if (Directory.Exists(Path.Combine(current.FullName, "input")))
            {
                return current.FullName;
            }

            var nestedProject = Path.Combine(current.FullName, "FGGeneratorDemo");
            if (Directory.Exists(Path.Combine(nestedProject, "input")))
            {
                return nestedProject;
            }

            current = current.Parent;
        }
    }

    return Directory.GetCurrentDirectory();
}

static void ShowStatistics(SubjectClassGrade subjectClass)
{
    Console.WriteLine();
    Console.WriteLine($"===== {subjectClass.Subject}/{subjectClass.Class} =====");
    Console.WriteLine($"Total Students: {subjectClass.Students.Count}");
    Console.WriteLine($"Components: {string.Join(", ", subjectClass.Components)}");
    Console.WriteLine();
}

static string Normalize(string value)
{
    return value
        .Replace(" ", "")
        .Replace("_", "")
        .Trim()
        .ToLowerInvariant();
}
