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
    required this.className,
    required this.rollNumber,
    required this.email,
    required this.memberCode,
    required this.fullName,
    required this.examDate,
    required this.examNote,
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
    required this.gradeComponents,
  });
  final String className;
  final String rollNumber;
  final String email;
  final String memberCode;
  final String fullName;
  final String examDate;
  final String examNote;

  final double? finalExam;
  final String finalComment;
  final double? finalResit;

  final double? practical;
  final double? practicalResit;

  final double? pt1;
  final String pt1Comment;

  final double? pt2;
  final String pt2Comment;

  final double? pt3;
  final String pt3Comment;

  final double? project;
  final String projectComment;

  final double? total;
  final String result;
  final String comment;
  final List<GradeComponent> gradeComponents;

  factory StudentGrade.fromJson(
    Map<String, dynamic> json, {
    String fallbackClassName = '',
  }) {
    return StudentGrade(
      className: _asString(json['className']).isNotEmpty
          ? _asString(json['className'])
          : fallbackClassName,
      rollNumber: _asString(json['rollNumber']),
      email: _asString(json['email']),
      memberCode: _asString(json['memberCode']),
      fullName: _asString(json['fullName']),
      examDate: _asString(json['examDate']),
      examNote: _asString(json['examNote']),
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
      gradeComponents: (json['gradeComponents'] as List<dynamic>? ?? [])
          .map((e) => GradeComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isPass => result.toUpperCase() == 'PASS';

  static String _asString(dynamic value) => value?.toString() ?? '';

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class GradeComponent {
  GradeComponent({required this.component, required this.grade});

  final String component;
  final double? grade;

  factory GradeComponent.fromJson(Map<String, dynamic> json) {
    return GradeComponent(
      component: StudentGrade._asString(json['component'] ?? json['Component']),
      grade: StudentGrade._asDouble(json['grade'] ?? json['Grade']),
    );
  }
}

class StudentGradeRequest {
  StudentGradeRequest({
    required this.className,
    required this.rollNumber,
    required this.email,
    required this.memberCode,
    required this.fullName,
    this.examDate = '',
    this.examNote = '',
    this.finalExam = 0,
    this.finalExamComment = '',
    this.finalExamResit = 0,
    this.finalExamResitComment = '',
    this.practicalExam = 0,
    this.practicalExamComment = '',
    this.pt1 = 0,
    this.pt1Comment = '',
    this.pt2 = 0,
    this.pt2Comment = '',
    this.pt3 = 0,
    this.pt3Comment = '',
    this.project = 0,
    this.projectComment = '',
  });

  final String className;
  final String rollNumber;
  final String email;
  final String memberCode;
  final String fullName;
  final String examDate;
  final String examNote;
  final double finalExam;
  final String finalExamComment;
  final double finalExamResit;
  final String finalExamResitComment;
  final double practicalExam;
  final String practicalExamComment;
  final double pt1;
  final String pt1Comment;
  final double pt2;
  final String pt2Comment;
  final double pt3;
  final String pt3Comment;
  final double project;
  final String projectComment;

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'rollNumber': rollNumber,
      'email': email,
      'memberCode': memberCode,
      'fullName': fullName,
      'examDate': examDate,
      'examNote': examNote,
      'finalExam': finalExam,
      'finalExamComment': finalExamComment,
      'finalExamResit': finalExamResit,
      'finalExamResitComment': finalExamResitComment,
      'practicalExam': practicalExam,
      'practicalExamComment': practicalExamComment,
      'pt1': pt1,
      'pt1Comment': pt1Comment,
      'pt2': pt2,
      'pt2Comment': pt2Comment,
      'pt3': pt3,
      'pt3Comment': pt3Comment,
      'project': project,
      'projectComment': projectComment,
    };
  }
}
