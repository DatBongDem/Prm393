import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/publication.dart';

class OpenAlexService {
  static const String baseUrl = 'api.openalex.org';

  Future<List<Publication>> fetchPublications(String query) async {
    final String email = dotenv.env['OPENALEX_EMAIL'] ?? 
        const String.fromEnvironment('OPENALEX_EMAIL', defaultValue: 'prm393lab2@fpt.edu.vn');

    final Map<String, String> queryParameters = {
      'search': query,
      'per_page': '80', // Lấy 80 bài viết để phân tích chính xác và nhanh chóng
      'mailto': email, // Giúp đưa vào "polite pool" của OpenAlex
    };

    final uri = Uri.https(baseUrl, '/works', queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        
        return results.map((json) => Publication.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải dữ liệu từ OpenAlex API (Status Code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến OpenAlex API. Chi tiết: $e');
    }
  }
}
