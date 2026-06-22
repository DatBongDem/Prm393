import 'package:flutter/material.dart';

import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final OpenAlexService _apiService = OpenAlexService();

  String _currentQuery = '';
  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  String get currentQuery => _currentQuery;
  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _publications.sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _publications = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  int get totalPublications => _publications.length;

  double get averageCitations {
    if (_publications.isEmpty) return 0.0;
    var total = 0.0;
    for (final pub in _publications) {
      total += pub.citedByCount;
    }
    return total / _publications.length;
  }

  Publication? get mostInfluentialPaper {
    if (_publications.isEmpty) return null;
    return _publications.reduce(
      (curr, next) => curr.citedByCount > next.citedByCount ? curr : next,
    );
  }

  List<MapEntry<String, int>> get topJournals {
    final counts = <String, int>{};
    for (final pub in _publications) {
      final name = pub.journalName;
      if (name != 'Unknown Journal' && name.isNotEmpty) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  String get topJournalName {
    final journals = topJournals;
    if (journals.isEmpty) return 'N/A';
    return journals.first.key;
  }

  List<TopAuthorStat> get topAuthors {
    final counts = <String, _TopAuthorAccumulator>{};

    for (final pub in _publications) {
      for (final author in pub.authors) {
        final normalizedName = author.name.trim();
        if (normalizedName.isEmpty) {
          continue;
        }

        final key = author.hasOpenAlexId
            ? 'id:${author.id}'
            : 'name:${normalizedName.toLowerCase()}';
        final existing = counts[key];

        if (existing == null) {
          counts[key] = _TopAuthorAccumulator(
            authorId: author.id,
            displayName: normalizedName,
            publicationCount: 1,
          );
          continue;
        }

        existing.publicationCount += 1;
        if (existing.displayName.length > normalizedName.length) {
          existing.displayName = normalizedName;
        }
        existing.authorId ??= author.id;
      }
    }

    final sorted = counts.values
        .map(
          (item) => TopAuthorStat(
            authorId: item.authorId,
            displayName: item.displayName,
            publicationCount: item.publicationCount,
          ),
        )
        .toList()
      ..sort((a, b) => b.publicationCount.compareTo(a.publicationCount));

    return sorted;
  }

  String get topAuthorName {
    final authors = topAuthors;
    if (authors.isEmpty) return 'N/A';
    return '${authors.first.displayName} (${authors.first.publicationCount} bài)';
  }

  Map<int, int> get publicationsByYear {
    final counts = <int, int>{};
    for (final pub in _publications) {
      if (pub.publicationYear > 0) {
        counts[pub.publicationYear] = (counts[pub.publicationYear] ?? 0) + 1;
      }
    }
    final sortedKeys = counts.keys.toList()..sort();
    return {for (final k in sortedKeys) k: counts[k]!};
  }

  int get mostActiveYear {
    final counts = publicationsByYear;
    if (counts.isEmpty) return 0;
    var activeYear = 0;
    var maxCount = -1;
    counts.forEach((year, count) {
      if (count > maxCount) {
        maxCount = count;
        activeYear = year;
      }
    });
    return activeYear;
  }
}

class _TopAuthorAccumulator {
  String? authorId;
  String displayName;
  int publicationCount;

  _TopAuthorAccumulator({
    required this.authorId,
    required this.displayName,
    required this.publicationCount,
  });
}
