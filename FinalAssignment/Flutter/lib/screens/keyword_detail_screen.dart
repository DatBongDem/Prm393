import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
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
  
  int _minAvailableYear = 2013;
  int _maxAvailableYear = DateTime.now().year;
  late int _startYear;
  late int _endYear;

  @override
  void initState() {
    super.initState();
    _pubs = [];
    _startYear = _minAvailableYear;
    _endYear = _maxAvailableYear;
    _fetchPublicationsFromApi();
  }

  Future<void> _fetchPublicationsFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _openAlexService.fetchPublications(widget.keyword);
      if (mounted) {
        int minYear = _minAvailableYear;
        int maxYear = _maxAvailableYear;
        if (result.publications.isNotEmpty) {
          final years = result.publications
              .map((p) => p.publicationYear)
              .where((y) => y > 0)
              .toList();
          if (years.isNotEmpty) {
            minYear = years.reduce(min);
            maxYear = years.reduce(max);
          }
        }
        
        // Safety guard for RangeSlider constraints
        if (minYear >= maxYear) {
          minYear = maxYear - 1;
        }

        setState(() {
          _pubs = result.publications;
          _minAvailableYear = minYear;
          _maxAvailableYear = maxYear;
          _startYear = minYear;
          _endYear = maxYear;
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

  String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter publications locally based on the selected year range
    final filteredPubs = _pubs
        .where((pub) =>
            pub.publicationYear >= _startYear &&
            pub.publicationYear <= _endYear)
        .toList();

    // Group publications by year
    final Map<int, int> yearlyCounts = {};
    for (final pub in filteredPubs) {
      if (pub.publicationYear > 0) {
        yearlyCounts[pub.publicationYear] =
            (yearlyCounts[pub.publicationYear] ?? 0) + 1;
      }
    }
    
    // Sort years chronologically for the chart
    final sortedYearsForChart = yearlyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
      
    // Sort years descending for the list
    final sortedYearsForList = yearlyCounts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    // Group publications by journal name
    final Map<String, int> journalCounts = {};
    for (final pub in filteredPubs) {
      journalCounts[pub.journalName] =
          (journalCounts[pub.journalName] ?? 0) + 1;
    }
    final sortedJournals = journalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Group publications by author name
    final Map<String, int> authorCounts = {};
    for (final pub in filteredPubs) {
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
            isScrollable: MediaQuery.sizeOf(context).width < 600 ? false : true,
            tabAlignment: MediaQuery.sizeOf(context).width < 600
                ? TabAlignment.fill
                : TabAlignment.center,
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
            : Column(
                children: [
                  _buildYearFilterCard(isDark, filteredPubs.length),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Danh sách bài báo
                        _buildPublicationsTab(context, filteredPubs, isDark),
                        // Tab 2: Xu hướng và tạp chí
                        _buildTrendsTab(sortedYearsForChart, sortedYearsForList, sortedJournals, isDark),
                        // Tab 3: Tác giả đóng góp hàng đầu
                        _buildAuthorsTab(sortedAuthors, isDark),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildYearFilterCard(bool isDark, int totalCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.filter_alt_outlined,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bộ lọc thời gian',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_startYear - $_endYear ($totalCount bài)',
                  style: GoogleFonts.inter(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RangeSlider(
            values: RangeValues(_startYear.toDouble(), _endYear.toDouble()),
            min: _minAvailableYear.toDouble(),
            max: _maxAvailableYear.toDouble(),
            divisions: max(1, _maxAvailableYear - _minAvailableYear),
            labels: RangeLabels('$_startYear', '$_endYear'),
            activeColor: Colors.blueAccent,
            inactiveColor: isDark ? Colors.white10 : Colors.grey.shade100,
            onChanged: (values) {
              setState(() {
                _startYear = values.start.round();
                _endYear = values.end.round();
              });
            },
          ),
        ],
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
    List<MapEntry<int, int>> yearsForChart,
    List<MapEntry<int, int>> yearsForList,
    List<MapEntry<String, int>> journals,
    bool isDark,
  ) {
    // Convert to spots for LineChart
    final spots = yearsForChart.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();

    Widget chartWidget;
    if (spots.isEmpty) {
      chartWidget = const SizedBox(
        height: 160,
        child: Center(child: Text('Không có dữ liệu biểu đồ thời gian.')),
      );
    } else {
      double minX = yearsForChart.first.key.toDouble();
      double maxX = yearsForChart.last.key.toDouble();
      if (minX == maxX) {
        minX = minX - 1;
        maxX = maxX + 1;
      }
      const minY = 0.0;
      final maxY = (yearsForChart.map((e) => e.value).reduce(max).toDouble() * 1.2).ceilToDouble();
      final xInterval = max(1.0, ((maxX - minX) / 5).roundToDouble());
      final yInterval = max(1.0, (maxY / 5).roundToDouble());

      chartWidget = Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) =>
                    isDark ? const Color(0xFF334155) : Colors.white,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    return LineTooltipItem(
                      'Năm ${touchedSpot.x.toInt()}: ${touchedSpot.y.toInt()} bài',
                      GoogleFonts.inter(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: Colors.blueAccent,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                ),
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      );
    }

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
          const SizedBox(height: 8),
          chartWidget,
          const SizedBox(height: 24),
          Text(
            'Các tạp chí đăng bài nhiều nhất',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          journals.isEmpty
              ? const Center(child: Text('Không có tạp chí liên quan.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(min(5, journals.length), (index) {
                    final entry = journals[index];
                    final rank = index + 1;
                    Color badgeColor = Colors.grey;
                    if (rank == 1) badgeColor = Colors.amber;
                    if (rank == 2) badgeColor = Colors.grey.shade300;
                    if (rank == 3) badgeColor = Colors.orangeAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$rank',
                              style: GoogleFonts.inter(
                                color: rank == 1 ? Colors.amber.shade800 : (isDark ? Colors.white70 : Colors.grey.shade700),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value} bài',
                            style: GoogleFonts.inter(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
        final rank = index + 1;

        Color badgeColor = Colors.grey;
        if (rank == 1) badgeColor = Colors.amber;
        if (rank == 2) badgeColor = Colors.grey.shade300;
        if (rank == 3) badgeColor = Colors.orangeAccent;

        final initials = getInitials(name);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank Badge
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    color: rank == 1 ? Colors.amber.shade800 : (isDark ? Colors.white70 : Colors.grey.shade700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar with initials
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$count bài',
                          style: GoogleFonts.inter(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
