import 'dart:convert';

import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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

  Uri get _uploadUri => Uri.parse('$baseUrl/grade/upload');

  Future<GradeUploadResponse> uploadGradeFile(PlatformFile pickedFile) async {
    final request = http.MultipartRequest('POST', _uploadUri);

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

  void dispose() {
    _client.close();
  }
}
