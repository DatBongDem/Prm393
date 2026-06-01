import 'dart:convert';

import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:http/http.dart' as http;

class AiChatApiService {
  AiChatApiService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri get _chatUri => Uri.parse('$baseUrl/ai/chat');

  Future<AiChatResult> ask(String message) async {
    final response = await _client.post(
      _chatUri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI chat failed (${response.statusCode}). Body: $body');
    }

    return _parseResponse(jsonDecode(body));
  }

  AiChatResult _parseResponse(dynamic decoded) {
    if (decoded is String) return AiChatResult(message: decoded);

    if (decoded is List) {
      final students = decoded
          .whereType<Map<String, dynamic>>()
          .map(StudentGrade.fromJson)
          .toList();

      return AiChatResult.fromStudents(students);
    }

    if (decoded is Map<String, dynamic>) {
      final rawClasses = decoded['classes'];
      if (rawClasses is Map<String, dynamic>) {
        final students = <StudentGrade>[];

        rawClasses.forEach((className, value) {
          if (value is! List) return;

          students.addAll(
            value.whereType<Map<String, dynamic>>().map(
              (json) =>
                  StudentGrade.fromJson(json, fallbackClassName: className),
            ),
          );
        });

        return AiChatResult.fromStudents(students);
      }
    }

    return AiChatResult(message: decoded.toString());
  }

  void dispose() {
    _client.close();
  }
}

class AiChatResult {
  const AiChatResult({this.students = const [], required this.message});

  factory AiChatResult.fromStudents(List<StudentGrade> students) {
    return AiChatResult(
      students: students,
      message: students.isEmpty
          ? 'No students matched your question.'
          : 'Found ${students.length} matching student(s).',
    );
  }

  final List<StudentGrade> students;
  final String message;
}
