import 'dart:convert';

import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:http/http.dart' as http;

class AiChatApiService {
  AiChatApiService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri get _chatUri => Uri.parse('$baseUrl/ai/chat');

  Future<String> ask(String message) async {
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

    return _formatResponse(jsonDecode(body));
  }

  String _formatResponse(dynamic decoded) {
    if (decoded is String) return decoded;

    if (decoded is List) {
      if (decoded.isEmpty) return 'No students matched your question.';

      final students = decoded
          .whereType<Map<String, dynamic>>()
          .map(StudentGrade.fromJson)
          .toList();

      if (students.isEmpty) return decoded.toString();

      return students.map(_formatStudent).join('\n');
    }

    return decoded.toString();
  }

  String _formatStudent(StudentGrade student) {
    return '${student.rollNumber} - ${student.fullName} | '
        'Total: ${_formatScore(student.total)} | ${student.result}';
  }

  String _formatScore(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  void dispose() {
    _client.close();
  }
}
