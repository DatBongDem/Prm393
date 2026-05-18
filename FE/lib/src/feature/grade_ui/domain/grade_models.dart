class GradeUploadResponse {
  GradeUploadResponse({required this.classes, required this.message});

  final Map<String, List<StudentGrade>> classes;
  final String message;

  factory GradeUploadResponse.fromJson(Map<String, dynamic> json) {
    final rawClasses = (json['classes'] as Map<String, dynamic>? ?? {});

    final parsedClasses = <String, List<StudentGrade>>{};
    rawClasses.forEach((className, value) {
      final list = (value as List<dynamic>? ?? []);
      parsedClasses[className] = list
          .map((e) => StudentGrade.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    return GradeUploadResponse(
      classes: parsedClasses,
      message: json['message']?.toString() ?? '',
    );
  }
}

class StudentGrade {
  StudentGrade({
    required this.rollNumber,
    required this.fullName,
    required this.finalExam,
    required this.finalComment,
    required this.finalResit,
    required this.practical,
    required this.practicalResit,
    required this.pt1,
    required this.pt1Comment,
    required this.pt2,
    required this.pt2Comment,
    required this.pt3,
    required this.pt3Comment,
    required this.project,
    required this.projectComment,
    required this.total,
    required this.result,
    required this.comment,
  });
  final String rollNumber;
  final String fullName;
  final double finalExam;
  final String finalComment;
  final double finalResit;

  final double practical;
  final double practicalResit;

  final double pt1;
  final String pt1Comment;

  final double pt2;
  final String pt2Comment;

  final double pt3;
  final String pt3Comment;

  final double project;
  final String projectComment;

  final double total;
  final String result;
  final String comment;
  factory StudentGrade.fromJson(Map<String, dynamic> json) {
    return StudentGrade(
      rollNumber: _asString(json['rollNumber']),
      fullName: _asString(json['fullName']),
      finalExam: _asDouble(json['finalExam']),
      finalComment: _asString(json['finalComment']),
      finalResit: _asDouble(json['finalResit']),
      practical: _asDouble(json['practical']),
      practicalResit: _asDouble(json['practicalResit']),
      pt1: _asDouble(json['pt1']),
      pt1Comment: _asString(json['pt1Comment']),
      pt2: _asDouble(json['pt2']),
      pt2Comment: _asString(json['pt2Comment']),
      pt3: _asDouble(json['pt3']),
      pt3Comment: _asString(json['pt3Comment']),
      project: _asDouble(json['project']),
      projectComment: _asString(json['projectComment']),
      total: _asDouble(json['total']),
      result: _asString(json['result']),
      comment: _asString(json['comment']),
    );
  }

  bool get isPass => result.toUpperCase() == 'PASS';

  static String _asString(dynamic value) => value?.toString() ?? '';

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
