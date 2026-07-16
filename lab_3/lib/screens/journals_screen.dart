import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/openalex_service.dart';
import '../viewmodels/analytics_provider.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import 'author_detail_screen.dart';
import 'journal_detail_screen.dart';

class JournalsScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;
  final OpenAlexService? authorService;

  const JournalsScreen({
    super.key,
    required this.analyticsService,
    required this.remoteConfigService,
    this.authorService,
  });

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Phân tích',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
            Tab(text: 'Xu hướng năm', icon: Icon(Icons.show_chart)),
            Tab(text: 'Top Tạp chí', icon: Icon(Icons.menu_book)),
            Tab(text: 'Top Tác giả', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _buildAnalysisBody(context, provider),
    );
  }

  Widget _buildAnalysisBody(BuildContext context, AnalyticsProvider provider) {
    final maxJournals = widget.remoteConfigService.getMaxJournals();
    if (provider.isAnalysisLoading && provider.analysisPublications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.analysisErrorMessage != null &&
        provider.analysisPublications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể tải dữ liệu phân tích',
        actionLabel: 'Thử lại',
        onAction: () {
          if (provider.hasSearchQuery) {
            provider.searchTopic(provider.currentQuery, addToRecent: false);
          } else {
            provider.loadGeneralData(force: true);
          }
        },
      );
    }

    if (provider.analysisPublications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.analytics_outlined,
        title: provider.hasSearchQuery
            ? 'Không có dữ liệu cho “${provider.currentQuery}”'
            : 'Chưa có dữ liệu xếp hạng chung',
        actionLabel: provider.hasSearchQuery ? null : 'Tải dữ liệu chung',
        onAction: provider.hasSearchQuery
            ? null
            : () => provider.loadGeneralData(force: true),
      );
    }

    return Column(
      children: [
        Container(
          key: const Key('analysis_mode_banner'),
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: provider.hasSearchQuery
                  ? const [Color(0xFF2563EB), Color(0xFF7C3AED)]
                  : const [Color(0xFF0F766E), Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                _tabController.index == 0
                    ? Icons.show_chart_rounded
                    : (_tabController.index == 1
                        ? Icons.menu_book_rounded
                        : Icons.people_alt_rounded),
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tabController.index == 0
                          ? (provider.hasSearchQuery ? 'Xu hướng từ khóa' : 'Xu hướng nghiên cứu')
                          : (_tabController.index == 1
                              ? (provider.hasSearchQuery ? 'Tạp chí theo từ khóa' : 'Xếp hạng Tạp chí')
                              : (provider.hasSearchQuery ? 'Tác giả theo từ khóa' : 'Xếp hạng Tác giả')),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _tabController.index == 0
                          ? (provider.hasSearchQuery
                              ? 'Biểu đồ xu hướng cho “${provider.currentQuery}” • ${provider.analysisPublications.length} bài mẫu'
                              : 'Xu hướng nổi bật trong 10 năm gần đây • ${provider.analysisPublications.length} bài mẫu')
                          : (_tabController.index == 1
                              ? (provider.hasSearchQuery
                                  ? 'Top $maxJournals tạp chí hoạt động nhiều nhất về “${provider.currentQuery}” • ${provider.analysisPublications.length} bài mẫu'
                                  : 'Top $maxJournals tạp chí công bố nhiều nghiên cứu nổi bật nhất • ${provider.analysisPublications.length} bài mẫu')
                              : (provider.hasSearchQuery
                                  ? 'Top 20 tác giả đóng góp nhiều nhất về “${provider.currentQuery}” • ${provider.analysisPublications.length} bài mẫu'
                                  : 'Top 20 tác giả có nhiều công bố nổi bật nhất • ${provider.analysisPublications.length} bài mẫu')),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildYearTrendTab(context, provider),
              _buildTopJournalsTab(context, provider),
              _buildTopAuthorsTab(context, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  Widget _buildYearTrendTab(BuildContext context, AnalyticsProvider provider) {
    final yearData = provider.publicationsByYear;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (yearData.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy thông tin năm xuất bản.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    final sortedYears = yearData.keys.toList();
    final spots = sortedYears.map((year) {
      return FlSpot(year.toDouble(), yearData[year]!.toDouble());
    }).toList();

    double minX = sortedYears.first.toDouble();
    double maxX = sortedYears.last.toDouble();
    if (minX == maxX) {
      minX = minX - 1;
      maxX = maxX + 1;
    }
    const minY = 0.0;
    final maxY = (yearData.values.reduce(max).toDouble() * 1.2).ceilToDouble();
    final xInterval = max(1.0, ((maxX - minX) / 5).roundToDouble());
    final yInterval = max(1.0, (maxY / 5).roundToDouble());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tốc độ tăng trưởng nghiên cứu',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Biểu đồ số lượng công bố khoa học theo từng năm.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                    color: isDark ? Colors.white10 : Colors.grey[200]!,
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
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 10,
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
                    barWidth: 4,
                    color: Colors.blueAccent,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withValues(alpha: 0.12),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chi tiết công bố qua các năm',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedYears.length,
            itemBuilder: (context, index) {
              final year = sortedYears[sortedYears.length - 1 - index];
              final count = yearData[year]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Năm $year',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count bài báo',
                        style: GoogleFonts.inter(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopJournalsTab(
    BuildContext context,
    AnalyticsProvider provider,
  ) {
    final journals = provider.topJournals;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxJournalsLimit = widget.remoteConfigService.getMaxJournals();

    if (journals.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy thông tin tạp chí.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    final maxCount = journals.first.value;

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: min(maxJournalsLimit, journals.length),
      itemBuilder: (context, index) {
        final journal = journals[index];
        final count = journal.value;
        final name = journal.key;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Card(
          key: ValueKey('journal_rank_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Log event: view_journal
              widget.analyticsService.logCustomEvent(
                name: 'view_journal',
                parameters: {'journal_name': name},
              );

              // Navigate to JournalDetailScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JournalDetailScreen(
                    journalName: name,
                    publications: provider.analysisPublications,
                    analyticsService: widget.analyticsService,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.amber
                          : index == 1
                          ? Colors.grey[400]
                          : index == 2
                          ? Colors.brown[300]
                          : isDark
                          ? const Color(0xFF334155)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.outfit(
                        color: index < 3
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.blueAccent,
                                      ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$count bài',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAuthorsTab(BuildContext context, AnalyticsProvider provider) {
    final authors = provider.topAuthors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authors.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy thông tin tác giả.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    final maxCount = authors.first.publicationCount;

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: min(20, authors.length),
      itemBuilder: (context, index) {
        final author = authors[index];
        final count = author.publicationCount;
        final name = author.displayName;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuthorDetailScreen(
                      authorId: author.authorId,
                      authorName: author.displayName,
                      service: widget.authorService,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                            ? Colors.grey[400]
                            : index == 2
                            ? Colors.brown[300]
                            : isDark
                            ? const Color(0xFF334155)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          color: index < 3
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                author.hasStableProfile
                                    ? Icons.open_in_new
                                    : Icons.arrow_forward_ios,
                                size: author.hasStableProfile ? 16 : 12,
                                color: author.hasStableProfile
                                    ? Colors.blueAccent
                                    : Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: isDark
                                        ? Colors.white10
                                        : Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.deepPurpleAccent,
                                        ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$count bài viết',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
