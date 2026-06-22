import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/author.dart';
import '../models/publication.dart';

class OpenAlexService {
  static const String baseUrl = 'api.openalex.org';

  String get _contactEmail => dotenv.env['OPENALEX_EMAIL'] ??
      const String.fromEnvironment(
        'OPENALEX_EMAIL',
        defaultValue: 'prm393lab2@fpt.edu.vn',
      );

  Future<List<Publication>> fetchPublications(String query) async {
    final queryParameters = <String, String>{
      'search': query,
      'per_page': '80',
      'mailto': _contactEmail,
    };

    final uri = Uri.https(baseUrl, '/works', queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? const [];
        return results
            .whereType<Map<String, dynamic>>()
            .map(Publication.fromJson)
            .toList();
      }

      throw Exception('Lỗi khi tải dữ liệu (Status Code: ${response.statusCode})');
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ dữ liệu. Chi tiết: $e');
    }
  }

  Future<AuthorDetail> fetchAuthorDetail(String authorId) async {
    final normalizedAuthorId = authorId.trim();
    final uri = Uri.https(baseUrl, '/authors/$normalizedAuthorId', {
      'mailto': _contactEmail,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return AuthorDetail.fromJson(data);
      }

      throw Exception('Lỗi khi tải thông tin tác giả (Status Code: ${response.statusCode})');
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ dữ liệu tác giả. Chi tiết: $e');
    }
  }

  Future<AuthorDetail> resolveAuthorDetail({
    String? authorId,
    required String authorName,
  }) async {
    if (authorId != null && authorId.trim().isNotEmpty) {
      return fetchAuthorDetail(authorId);
    }

    final uri = Uri.https(baseUrl, '/authors', {
      'search': authorName,
      'per-page': '10',
      'mailto': _contactEmail,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Lỗi khi tìm tác giả (Status Code: ${response.statusCode})');
      }

      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      final normalizedTarget = authorName.trim().toLowerCase();

      Map<String, dynamic>? matchedAuthor;
      for (final item in results.whereType<Map<String, dynamic>>()) {
        final displayName = item['display_name']?.toString().trim().toLowerCase() ?? '';
        if (displayName == normalizedTarget) {
          matchedAuthor = item;
          break;
        }
      }

      matchedAuthor ??= results.whereType<Map<String, dynamic>>().isNotEmpty
          ? results.whereType<Map<String, dynamic>>().first
          : null;

      if (matchedAuthor == null) {
        throw Exception('Không tìm thấy thông tin chi tiết cho tác giả "$authorName".');
      }

      return AuthorDetail.fromJson(matchedAuthor);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể tìm tác giả theo tên. Chi tiết: $e');
    }
  }
}
