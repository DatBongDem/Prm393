import 'package:flutter/material.dart';

import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  static const int maxRecentSearches = 6;

  final OpenAlexService _apiService;

  AnalyticsProvider({OpenAlexService? apiService})
    : _apiService = apiService ?? OpenAlexService();

  String _currentQuery = '';
  List<Publication> _publications = [];
  final List<String> _recentSearches = [];
  int? _openAlexTotalResults;
  int _sampleSizeLimit = OpenAlexService.defaultPageSize;
  DateTime? _lastUpdatedAt;
  bool _isLoading = false;
  String? _errorMessage;

  List<Publication> _generalPublications = [];
  List<Publication> _latestPublications = [];
  int? _generalTotalResults;
  DateTime? _generalLastUpdatedAt;
  bool _isGeneralLoading = false;
  bool _hasLoadedGeneral = false;
  String? _generalErrorMessage;

  String get currentQuery => _currentQuery;
  List<Publication> get publications => _publications;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  int? get openAlexTotalResults => _openAlexTotalResults;
  int get sampleSizeLimit => _sampleSizeLimit;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Publication> get generalPublications => _generalPublications;
  List<Publication> get latestPublications => _latestPublications;
  int? get generalTotalResults => _generalTotalResults;
  DateTime? get generalLastUpdatedAt => _generalLastUpdatedAt;
  bool get isGeneralLoading => _isGeneralLoading;
  bool get hasLoadedGeneral => _hasLoadedGeneral;
  String? get generalErrorMessage => _generalErrorMessage;

  bool get hasSearchQuery => _currentQuery.trim().isNotEmpty;
  List<Publication> get analysisPublications =>
      hasSearchQuery ? _publications : _generalPublications;
  bool get isAnalysisLoading => hasSearchQuery ? _isLoading : _isGeneralLoading;
  String? get analysisErrorMessage =>
      hasSearchQuery ? _errorMessage : _generalErrorMessage;

  Future<void> loadGeneralData({bool force = false}) async {
    if (_isGeneralLoading || (_hasLoadedGeneral && !force)) return;

    _isGeneralLoading = true;
    _generalErrorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<OpenAlexSearchResult>([
        _apiService.fetchGeneralPublications(),
        _apiService.fetchLatestPublications(),
      ]);

      _generalPublications = results[0].publications;
      _latestPublications = results[1].publications;
      _generalTotalResults = results[0].totalResults;
      _generalLastUpdatedAt = DateTime.now();
      _hasLoadedGeneral = true;
    } catch (error) {
      _generalErrorMessage = error.toString();
    } finally {
      _isGeneralLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchTopic(String query, {bool addToRecent = true}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    if (addToRecent) _rememberSearch(trimmedQuery);

    _isLoading = true;
    _currentQuery = trimmedQuery;
    _errorMessage = null;
    _publications = [];
    _openAlexTotalResults = null;
    _lastUpdatedAt = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchPublications(trimmedQuery);
      _publications = result.publications
        ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
      _openAlexTotalResults = result.totalResults;
      _sampleSizeLimit = result.pageSize;
      _lastUpdatedAt = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeRecentSearch(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final previousLength = _recentSearches.length;
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == normalizedQuery,
    );
    if (_recentSearches.length != previousLength) notifyListeners();
  }

  void clearRecentSearches() {
    if (_recentSearches.isEmpty) return;
    _recentSearches.clear();
    notifyListeners();
  }

  void _rememberSearch(String query) {
    final normalizedQuery = query.toLowerCase();
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == normalizedQuery,
    );
    _recentSearches.insert(0, query);
    if (_recentSearches.length > maxRecentSearches) {
      _recentSearches.removeRange(maxRecentSearches, _recentSearches.length);
    }
  }

  void clearSearch() {
    _currentQuery = '';
    _publications = [];
    _openAlexTotalResults = null;
    _lastUpdatedAt = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  int get totalPublications => analysisPublications.length;

  double get averageCitations {
    if (analysisPublications.isEmpty) return 0;
    final total = analysisPublications.fold<int>(
      0,
      (sum, publication) => sum + publication.citedByCount,
    );
    return total / analysisPublications.length;
  }

  Publication? get mostInfluentialPaper {
    if (analysisPublications.isEmpty) return null;
    return analysisPublications.reduce(
      (current, next) =>
          current.citedByCount > next.citedByCount ? current : next,
    );
  }

  List<MapEntry<String, int>> get topJournals {
    final counts = <String, int>{};
    for (final publication in analysisPublications) {
      final name = publication.journalName.trim();
      if (name.isNotEmpty && name != 'Unknown Journal') {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  String get topJournalName =>
      topJournals.isEmpty ? 'N/A' : topJournals.first.key;

  List<TopAuthorStat> get topAuthors {
    final counts = <String, _TopAuthorAccumulator>{};

    for (final publication in analysisPublications) {
      for (final author in publication.authors) {
        final normalizedName = author.name.trim();
        if (normalizedName.isEmpty) continue;

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
        } else {
          existing.publicationCount += 1;
          existing.authorId ??= author.id;
        }
      }
    }

    return counts.values
        .map(
          (item) => TopAuthorStat(
            authorId: item.authorId,
            displayName: item.displayName,
            publicationCount: item.publicationCount,
          ),
        )
        .toList()
      ..sort((a, b) => b.publicationCount.compareTo(a.publicationCount));
  }

  String get topAuthorName => topAuthors.isEmpty
      ? 'N/A'
      : '${topAuthors.first.displayName} '
            '(${topAuthors.first.publicationCount} bài)';

  Map<int, int> get publicationsByYear {
    final counts = <int, int>{};
    for (final publication in analysisPublications) {
      if (publication.publicationYear > 0) {
        counts[publication.publicationYear] =
            (counts[publication.publicationYear] ?? 0) + 1;
      }
    }
    final sortedKeys = counts.keys.toList()..sort();
    return {for (final year in sortedKeys) year: counts[year]!};
  }

  int get mostActiveYear {
    if (publicationsByYear.isEmpty) return 0;
    return publicationsByYear.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}

class _TopAuthorAccumulator {
  String? authorId;
  final String displayName;
  int publicationCount;

  _TopAuthorAccumulator({
    required this.authorId,
    required this.displayName,
    required this.publicationCount,
  });
}
