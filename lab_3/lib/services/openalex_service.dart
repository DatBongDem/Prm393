import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/firebase_config.dart';
import '../models/author.dart';
import '../models/publication.dart';

class OpenAlexSearchResult {
  final List<Publication> publications;
  final int? totalResults;
  final int pageSize;

  const OpenAlexSearchResult({
    required this.publications,
    required this.totalResults,
    required this.pageSize,
  });
}

class OpenAlexService {
  static const String baseUrl = 'api.openalex.org';
  static const int defaultPageSize = 80;
  static const int latestPageSize = 20;

  String get _contactEmail => FirebaseConfig.openAlexEmail;
  String get _apiKey => FirebaseConfig.openAlexApiKey.trim();

  Map<String, String> _withAuth([
    Map<String, String> queryParameters = const {},
  ]) {
    return {
      ...queryParameters,
      'mailto': _contactEmail,
      if (_apiKey.isNotEmpty && _apiKey != 'YOUR_OPENALEX_API_KEY_HERE')
        'api_key': _apiKey,
    };
  }

  Future<OpenAlexSearchResult> fetchPublications(String query) {
    return _fetchWorks({
      'search': query.trim(),
      'per_page': defaultPageSize.toString(),
    }, pageSize: defaultPageSize);
  }

  Future<OpenAlexSearchResult> fetchGeneralPublications() {
    final fromYear = DateTime.now().year - 9;
    return _fetchWorks({
      'filter': 'from_publication_date:$fromYear-01-01',
      'sort': 'cited_by_count:desc',
      'per_page': defaultPageSize.toString(),
    }, pageSize: defaultPageSize);
  }

  Future<OpenAlexSearchResult> fetchLatestPublications() {
    final fromYear = DateTime.now().year - 1;
    return _fetchWorks({
      'filter': 'from_publication_date:$fromYear-01-01',
      'sort': 'publication_date:desc',
      'per_page': latestPageSize.toString(),
    }, pageSize: latestPageSize);
  }

  Future<OpenAlexSearchResult> _fetchWorks(
    Map<String, String> queryParameters, {
    required int pageSize,
  }) async {
    final uri = Uri.https(baseUrl, '/works', _withAuth(queryParameters));

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Lỗi khi tải dữ liệu (Status Code: ${response.statusCode})',
        );
      }

      final data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final meta = data['meta'] as Map<String, dynamic>?;
      final results = data['results'] as List<dynamic>? ?? const [];

      return OpenAlexSearchResult(
        publications: results
            .whereType<Map<String, dynamic>>()
            .map(Publication.fromJson)
            .toList(),
        totalResults: meta?['count'] is int ? meta!['count'] as int : null,
        pageSize: pageSize,
      );
    } catch (error) {
      throw Exception(
        'Không thể kết nối đến máy chủ dữ liệu. Chi tiết: $error',
      );
    }
  }

  Future<AuthorDetail> fetchAuthorDetail(String authorId) async {
    final normalizedAuthorId = authorId.trim();
    final uri = Uri.https(baseUrl, '/authors/$normalizedAuthorId', _withAuth());

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data =
            json.decode(utf8.decode(response.bodyBytes))
                as Map<String, dynamic>;
        return AuthorDetail.fromJson(data);
      }

      throw Exception(
        'Lỗi khi tải thông tin tác giả (Status Code: ${response.statusCode})',
      );
    } catch (error) {
      throw Exception(
        'Không thể kết nối đến máy chủ dữ liệu tác giả. Chi tiết: $error',
      );
    }
  }

  Future<AuthorDetail> resolveAuthorDetail({
    String? authorId,
    required String authorName,
  }) async {
    if (authorId != null && authorId.trim().isNotEmpty) {
      return fetchAuthorDetail(authorId);
    }

    final uri = Uri.https(
      baseUrl,
      '/authors',
      _withAuth({'search': authorName, 'per-page': '10'}),
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Lỗi khi tìm tác giả (Status Code: ${response.statusCode})',
        );
      }

      final data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      final normalizedTarget = authorName.trim().toLowerCase();

      Map<String, dynamic>? matchedAuthor;
      for (final item in results.whereType<Map<String, dynamic>>()) {
        final displayName =
            item['display_name']?.toString().trim().toLowerCase() ?? '';
        if (displayName == normalizedTarget) {
          matchedAuthor = item;
          break;
        }
      }

      matchedAuthor ??= results.whereType<Map<String, dynamic>>().isNotEmpty
          ? results.whereType<Map<String, dynamic>>().first
          : null;

      if (matchedAuthor == null) {
        throw Exception(
          'Không tìm thấy thông tin chi tiết cho tác giả "$authorName".',
        );
      }

      return AuthorDetail.fromJson(matchedAuthor);
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Không thể tìm tác giả theo tên. Chi tiết: $error');
    }
  }
}
