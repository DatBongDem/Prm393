import 'dart:convert';
import 'dart:typed_data';

import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

enum GradeExportFormat {
  excel(
    endpoint: '/grade/export-excel',
    defaultFileName: 'grades.xlsx',
    extension: 'xlsx',
  ),
  fg(
    endpoint: '/grade/export-fg',
    defaultFileName: 'grade.fg',
    extension: 'fg',
  );

  const GradeExportFormat({
    required this.endpoint,
    required this.defaultFileName,
    required this.extension,
  });

  final String endpoint;
  final String defaultFileName;
  final String extension;
}

class GradeExportFile {
  const GradeExportFile({
    required this.bytes,
    required this.fileName,
    required this.extension,
  });

  final Uint8List bytes;
  final String fileName;
  final String extension;
}

class GradeApiService {
  GradeApiService({
    required this.baseUrl,
    this.fileFieldName = 'file',
    http.Client? client,
  }) : _client = client ?? http.Client();
  final String baseUrl;
  // Tên field multipart mà BE nhận.
  final String fileFieldName;

  final http.Client _client;

  Future<GradeUploadResponse> uploadGradeFile(PlatformFile pickedFile) async {
    final request = http.MultipartRequest(
      'POST',
      _uploadUriForFile(pickedFile),
    );

    if (pickedFile.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, pickedFile.path!),
      );
    } else if (pickedFile.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileFieldName,
          pickedFile.bytes!,
          filename: pickedFile.name,
        ),
      );
    } else {
      throw Exception('Không đọc được dữ liệu file để upload.');
    }

    request.headers['Accept'] = 'application/json';

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Upload thất bại (${response.statusCode}). Body: ${response.body}',
      );
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return GradeUploadResponse.fromJson(jsonMap);
  }

  Uri _uploadUriForFile(PlatformFile pickedFile) {
    final extension = (pickedFile.extension ?? _extensionOf(pickedFile.name))
        .toLowerCase();

    return switch (extension) {
      'fg' => Uri.parse('$baseUrl/grade/upload-fg'),
      'xls' || 'xlsx' || 'xml' => Uri.parse('$baseUrl/grade/upload-excel'),
      _ => throw Exception(
        'File không được hỗ trợ. Vui lòng chọn file .fg, .xls, .xlsx hoặc .xml.',
      ),
    };
  }

  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1);
  }

  Future<StudentGrade> createStudent(StudentGradeRequest request) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/student'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Tạo sinh viên thất bại: ${response.body}');
    }

    return StudentGrade.fromJson(jsonDecode(response.body));
  }

  Future<StudentGrade> updateStudent(
    String rollNumber,
    StudentGradeRequest request,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/student/$rollNumber'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cập nhật sinh viên thất bại: ${response.body}');
    }

    return StudentGrade.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteStudent(String rollNumber) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/student/$rollNumber'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Xoá sinh viên thất bại: ${response.body}');
    }
  }

  Future<GradeExportFile> exportGradeFile(GradeExportFormat format) async {
    final response = await _client.get(
      Uri.parse('$baseUrl${format.endpoint}'),
      headers: {'Accept': '*/*'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Export failed (${response.statusCode}): ${response.body}',
      );
    }

    return GradeExportFile(
      bytes: response.bodyBytes,
      fileName:
          _fileNameFromContentDisposition(
            response.headers['content-disposition'],
          ) ??
          format.defaultFileName,
      extension: format.extension,
    );
  }

  String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;

    final match = RegExp(
      r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(header);

    if (match == null) return null;

    final fileName = Uri.decodeFull(match.group(1)?.trim() ?? '');
    return fileName.isEmpty ? null : fileName;
  }

  void dispose() {
    _client.close();
  }
}
