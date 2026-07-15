import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../services/firebase_analytics_service.dart';
import '../services/openalex_service.dart';
import 'publication_detail_screen.dart';

class KeywordDetailScreen extends StatefulWidget {
  final String keyword;
  final List<Publication> publications;
  final FirebaseAnalyticsService analyticsService;

  const KeywordDetailScreen({
    super.key,
    required this.keyword,
    required this.publications,
    required this.analyticsService,
  });

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  late List<Publication> _pubs;
  bool _isLoading = false;
  String? _error;
  final OpenAlexService _openAlexService = OpenAlexService();

  @override
  void initState() {
    super.initState();
    // Lọc trước các bài báo có sẵn chứa từ khóa này
    final matchingPubs = widget.publications
        .where(
          (pub) => pub.concepts.any(
            (c) => c.toLowerCase() == widget.keyword.toLowerCase(),
          ),
        )
        .toList();

    if (matchingPubs.isEmpty) {
      // Nếu không có bài báo nào khớp, tự động tải dữ liệu trực tiếp từ API cho từ khóa này!
      _pubs = [];
      _fetchPublicationsFromApi();
    } else {
      _pubs = matchingPubs;
    }
  }

  Future<void> _fetchPublicationsFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _openAlexService.fetchPublications(widget.keyword);
      if (mounted) {
        setState(() {
          _pubs = result.publications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tính xu hướng năm
    final Map<int, int> yearlyCounts = {};
    for (final pub in _pubs) {
      if (pub.publicationYear > 0) {
        yearlyCounts[pub.publicationYear] =
            (yearlyCounts[pub.publicationYear] ?? 0) + 1;
      }
    }
    final sortedYears = yearlyCounts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Tính danh sách tạp chí liên quan
    final Map<String, int> journalCounts = {};
    for (final pub in _pubs) {
      journalCounts[pub.journalName] =
          (journalCounts[pub.journalName] ?? 0) + 1;
    }
    final sortedJournals = journalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tính danh sách tác giả đóng góp hàng đầu cho từ khóa này
    final Map<String, int> authorCounts = {};
    for (final pub in _pubs) {
      for (final author in pub.authors) {
        authorCounts[author.name] = (authorCounts[author.name] ?? 0) + 1;
      }
    }
    final sortedAuthors = authorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Từ khóa: ${widget.keyword}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'Bài báo liên quan', icon: Icon(Icons.article)),
              Tab(text: 'Xu hướng & Tạp chí', icon: Icon(Icons.insights)),
              Tab(text: 'Xếp hạng Tác giả', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: Colors.orangeAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPublicationsFromApi,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : TabBarView(
                children: [
                  // Tab 1: Danh sách bài báo
                  _buildPublicationsTab(context, _pubs, isDark),
                  // Tab 2: Xu hướng và tạp chí
                  _buildTrendsTab(sortedYears, sortedJournals, isDark),
                  // Tab 3: Tác giả đóng góp hàng đầu
                  _buildAuthorsTab(sortedAuthors, isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildPublicationsTab(
    BuildContext context,
    List<Publication> pubs,
    bool isDark,
  ) {
    if (pubs.isEmpty) {
      return const Center(child: Text('Không tìm thấy bài viết liên quan.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pubs.length,
      itemBuilder: (context, index) {
        final pub = pubs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Log event: view_publication
              widget.analyticsService.logCustomEvent(
                name: 'view_publication',
                parameters: {
                  'publication_title': pub.title,
                  'publication_year': pub.publicationYear,
                },
              );

              // Điều hướng xem chi tiết bài báo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PublicationDetailScreen(publication: pub),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pub.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pub.authors.map((a) => a.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.blueAccent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pub.publicationYear}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 15,
                            color: Colors.orangeAccent.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pub.citedByCount} trích dẫn',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab(
    List<MapEntry<int, int>> years,
    List<MapEntry<String, int>> journals,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số lượng công bố theo năm',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: years.isEmpty
                ? const Center(child: Text('Không có dữ liệu năm.'))
                : Column(
                    children: years.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Năm ${entry.key}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${entry.value} bài báo',
                              style: GoogleFonts.inter(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Các tạp chí đăng bài nhiều nhất',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: journals.isEmpty
                ? const Center(child: Text('Không có tạp chí liên quan.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: journals.take(5).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.book,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${entry.value} bài',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorsTab(List<MapEntry<String, int>> authors, bool isDark) {
    if (authors.isEmpty) {
      return const Center(child: Text('Không có dữ liệu tác giả.'));
    }

    final maxCount = authors.first.value;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: min(15, authors.length),
      itemBuilder: (context, index) {
        final entry = authors[index];
        final name = entry.key;
        final count = entry.value;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$count công bố',
                    style: GoogleFonts.inter(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.deepPurpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
