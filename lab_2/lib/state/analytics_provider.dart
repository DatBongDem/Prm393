import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();

  String _currentQuery = '';
  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get currentQuery => _currentQuery;
  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Search logic
  Future<void> searchTopic(String query) async {
    if (query.trim().isEmpty) return;
    
    _isLoading = true;
    _currentQuery = query;
    _errorMessage = null;
    _publications = [];
    notifyListeners();

    try {
      final results = await _apiService.fetchPublications(query);
      _publications = results;
      
      // Sắp xếp danh sách bài báo mặc định theo số lượng trích dẫn giảm dần
      _publications.sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search state
  void clearSearch() {
    _currentQuery = '';
    _publications = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // --- ANALYTICS GETTERS ---

  // 1. Tổng số bài báo
  int get totalPublications => _publications.length;

  // 2. Số trích dẫn trung bình
  double get averageCitations {
    if (_publications.isEmpty) return 0.0;
    double total = 0;
    for (var pub in _publications) {
      total += pub.citedByCount;
    }
    return total / _publications.length;
  }

  // 3. Bài báo có ảnh hưởng nhất (Xếp theo trích dẫn)
  Publication? get mostInfluentialPaper {
    if (_publications.isEmpty) return null;
    return _publications.reduce((curr, next) => curr.citedByCount > next.citedByCount ? curr : next);
  }

  // 4. Các tạp chí đóng góp nhiều nhất
  List<MapEntry<String, int>> get topJournals {
    final Map<String, int> counts = {};
    for (var pub in _publications) {
      final name = pub.journalName;
      if (name != 'Unknown Journal' && name.isNotEmpty) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  // 5. Tạp chí hàng đầu (Tên tạp chí đóng góp nhiều nhất)
  String get topJournalName {
    final journals = topJournals;
    if (journals.isEmpty) return 'N/A';
    return journals.first.key;
  }

  // 6. Các tác giả đóng góp nhiều nhất
  List<MapEntry<String, int>> get topAuthors {
    final Map<String, int> counts = {};
    for (var pub in _publications) {
      for (var author in pub.authors) {
        if (author.isNotEmpty) {
          counts[author] = (counts[author] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  // 7. Tác giả hàng đầu (Tác giả đóng góp nhiều nhất)
  String get topAuthorName {
    final authors = topAuthors;
    if (authors.isEmpty) return 'N/A';
    return '${authors.first.key} (${authors.first.value} bài)';
  }

  // 8. Thống kê bài báo theo năm (Phục vụ vẽ biểu đồ xu hướng)
  Map<int, int> get publicationsByYear {
    final Map<int, int> counts = {};
    for (var pub in _publications) {
      if (pub.publicationYear > 0) {
        counts[pub.publicationYear] = (counts[pub.publicationYear] ?? 0) + 1;
      }
    }
    final sortedKeys = counts.keys.toList()..sort();
    return {for (var k in sortedKeys) k: counts[k]!};
  }

  // 9. Năm sôi động nhất (Năm có nhiều bài viết nhất)
  int get mostActiveYear {
    final counts = publicationsByYear;
    if (counts.isEmpty) return 0;
    int activeYear = 0;
    int maxCount = -1;
    counts.forEach((year, count) {
      if (count > maxCount) {
        maxCount = count;
        activeYear = year;
      }
    });
    return activeYear;
  }
}
