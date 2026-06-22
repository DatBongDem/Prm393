import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../state/analytics_provider.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'trend_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool autoLoadHotTopic;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenTrend;

  const DashboardScreen({
    super.key,
    this.autoLoadHotTopic = false,
    this.onOpenSearch,
    this.onOpenTrend,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _defaultHotTopic = 'Artificial Intelligence';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, dynamic>> _suggestedTopics = [
    {'name': 'Artificial Intelligence', 'icon': Icons.psychology},
    {'name': 'Software Engineering', 'icon': Icons.code},
    {'name': 'Data Science', 'icon': Icons.analytics},
    {'name': 'Cybersecurity', 'icon': Icons.security},
    {'name': 'Internet of Things', 'icon': Icons.settings_input_antenna},
    {'name': 'Blockchain', 'icon': Icons.currency_bitcoin},
  ];

  @override
  void initState() {
    super.initState();
    final currentQuery = context.read<AnalyticsProvider>().currentQuery;
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autoLoadHotTopic) return;

      final provider = context.read<AnalyticsProvider>();
      if (provider.currentQuery.isEmpty &&
          provider.publications.isEmpty &&
          !provider.isLoading) {
        _searchController.text = _defaultHotTopic;
        provider.searchTopic(_defaultHotTopic, addToRecent: false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    FocusScope.of(context).unfocus();
    _searchController.text = trimmedQuery;
    context.read<AnalyticsProvider>().searchTopic(trimmedQuery);
  }

  void _openTrendScreen() {
    if (widget.onOpenTrend != null) {
      widget.onOpenTrend!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrendScreen()),
    );
  }

  void _openSearchScreen() {
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_searchFocusNode.hasFocus &&
        provider.currentQuery.isNotEmpty &&
        _searchController.text != provider.currentQuery) {
      _searchController.text = provider.currentQuery;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Trang chủ',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Danh sách bài báo',
            onPressed: _openSearchScreen,
            icon: const Icon(Icons.article_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.blueAccent,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        onRefresh: () async {
          if (provider.currentQuery.isNotEmpty) {
            await context.read<AnalyticsProvider>().searchTopic(
              provider.currentQuery,
              addToRecent: false,
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchPanel(context, provider, isDark),
              const SizedBox(height: 22),
              if (provider.isLoading)
                _buildLoadingState(isDark)
              else if (provider.errorMessage != null)
                _buildErrorState(provider, isDark)
              else if (provider.publications.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildDashboardContent(context, provider, isDark),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -40,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 180,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.08 : 0.28),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            left: -44,
            bottom: 38,
            child: Transform.rotate(
              angle: -0.42,
              child: Container(
                width: 128,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.06 : 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.auto_graph,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'RESEARCH PULSE',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.currentQuery.isEmpty
                              ? 'Khám phá nghiên cứu'
                              : provider.currentQuery,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildHeroSubtitle(provider),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.84),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildHeroStats(provider),
              const SizedBox(height: 16),
              TextField(
                key: const Key('dashboard_topic_search'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                onSubmitted: _handleSearch,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm chủ đề nghiên cứu',
                  hintStyle: GoogleFonts.inter(color: Colors.white60),
                  prefixIcon: IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: () => _handleSearch(_searchController.text),
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Xóa',
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.16),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (provider.recentSearches.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildRecentSearches(provider),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.explore_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Khám phá chủ đề',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestedTopics.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final topic = _suggestedTopics[index];
                    final topicName = topic['name'].toString();
                    final isSelected =
                        provider.currentQuery.toLowerCase() ==
                        topicName.toLowerCase();

                    return _buildTopicCard(
                      topicName: topicName,
                      icon: topic['icon'] as IconData,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Tìm kiếm gần đây',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              key: const Key('clear_recent_searches'),
              onPressed: provider.clearRecentSearches,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: Text(
                'Xóa tất cả',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: provider.recentSearches.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final query = provider.recentSearches[index];
              return InputChip(
                key: ValueKey('recent_search_$query'),
                avatar: const Icon(Icons.schedule, size: 16),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onPressed: () => _handleSearch(query),
                onDeleted: () => provider.removeRecentSearch(query),
                deleteButtonTooltipMessage: 'Xóa $query khỏi lịch sử',
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Colors.white.withOpacity(0.14),
                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                iconTheme: const IconThemeData(color: Colors.white70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildHeroSubtitle(AnalyticsProvider provider) {
    if (provider.isLoading) {
      return 'Đang lấy dữ liệu OpenAlex và dựng bản đồ xu hướng cho chủ đề này.';
    }

    if (provider.publications.isEmpty) {
      return 'Nhập hoặc chọn một chủ đề để xem xu hướng, tác giả, tạp chí và những bài viết đáng chú ý từ OpenAlex.';
    }

    final total = provider.openAlexTotalResults == null
        ? '${provider.totalPublications} bài mẫu'
        : '${_formatNumber(provider.openAlexTotalResults!)} kết quả OpenAlex';
    return '$total được quét để tạo snapshot nghiên cứu. Các chỉ số bên dưới dùng mẫu ${provider.totalPublications} bài đầu tiên.';
  }

  Widget _buildHeroStats(AnalyticsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildHeroStatChip(
            label: 'OpenAlex',
            value: provider.openAlexTotalResults == null
                ? 'N/A'
                : _formatCompactNumber(provider.openAlexTotalResults!),
            icon: Icons.public,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHeroStatChip(
            label: 'Mẫu',
            value: provider.totalPublications == 0
                ? '--'
                : '${provider.totalPublications}',
            icon: Icons.dataset_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHeroStatChip(
            label: 'Cite TB',
            value: provider.publications.isEmpty
                ? '--'
                : provider.averageCitations.toStringAsFixed(1),
            icon: Icons.bolt,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStatChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard({
    required String topicName,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _handleSearch(topicName),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.24)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            Text(
              topicName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                height: 1.15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    final mostInfluential = provider.mostInfluentialPaper;
    final hotPapers = provider.publications.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHotInsightBanner(provider, mostInfluential),
        const SizedBox(height: 22),
        Text(
          'Tổng quan nhanh',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _buildSampleSummary(provider),
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        _buildCommandTiles(),
        const SizedBox(height: 22),
        _buildDataSourceCard(context, provider, isDark),
        const SizedBox(height: 16),
        _buildMiniTrendCard(context, provider, isDark),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
            final childAspectRatio = constraints.maxWidth >= 700 ? 1.25 : 1.18;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspectRatio,
              children: [
                _buildMetricCard(
                  context: context,
                  title: 'Mẫu phân tích',
                  value: provider.totalPublications.toString(),
                  icon: Icons.science,
                  color: Colors.blueAccent,
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Trích dẫn TB',
                  value: provider.averageCitations.toStringAsFixed(1),
                  icon: Icons.star_half_rounded,
                  color: Colors.amber,
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Năm sôi động',
                  value: provider.mostActiveYear == 0
                      ? 'N/A'
                      : provider.mostActiveYear.toString(),
                  icon: Icons.calendar_today_rounded,
                  color: Colors.orange,
                ),
                _buildMetricCard(
                  context: context,
                  title: 'Tạp chí top',
                  value: provider.topJournalName,
                  icon: Icons.menu_book,
                  color: Colors.green,
                  isLongText: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _buildAuthorHighlightCard(context, provider.topAuthorName, isDark),
        const SizedBox(height: 24),
        if (hotPapers.isNotEmpty) ...[
          Text(
            'Top bài viết hot',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...hotPapers.asMap().entries.map(
            (entry) =>
                _buildHotPaperTile(context, entry.value, entry.key + 1, isDark),
          ),
          const SizedBox(height: 10),
        ],
        if (mostInfluential != null) ...[
          Text(
            'Bài viết nổi bật nhất',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfluentialPaperCard(context, mostInfluential),
        ],
      ],
    );
  }

  Widget _buildCommandTiles() {
    return Row(
      children: [
        Expanded(
          child: _buildCommandTile(
            title: 'Bản đồ xu hướng',
            subtitle: 'Biểu đồ năm, top tạp chí và tác giả',
            icon: Icons.stacked_line_chart,
            colors: const [Color(0xFF2563EB), Color(0xFF7C3AED)],
            onTap: _openTrendScreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCommandTile(
            title: 'Kho bài báo',
            subtitle: 'Danh sách ấn phẩm và chi tiết DOI',
            icon: Icons.article_outlined,
            colors: const [Color(0xFF0F766E), Color(0xFF16A34A)],
            onTap: _openSearchScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildCommandTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 132,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLongText = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: isLongText ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: isLongText ? 15 : 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceCard(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nguồn dữ liệu',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'OpenAlex • cập nhật ${_formatUpdatedAt(provider.lastUpdatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tải lại dữ liệu',
                onPressed: provider.currentQuery.isEmpty
                    ? null
                    : () => _handleSearch(provider.currentQuery),
                icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDataPoint(
                  label: 'Tổng trên OpenAlex',
                  value: provider.openAlexTotalResults == null
                      ? 'N/A'
                      : _formatNumber(provider.openAlexTotalResults!),
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataPoint(
                  label: 'Đang phân tích',
                  value:
                      '${provider.totalPublications}/${provider.sampleSizeLimit}',
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: Text(
              'Các chỉ số citation, tác giả, tạp chí và năm sôi động được tính trên mẫu ${provider.totalPublications} bài đang phân tích.',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPoint({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrendCard(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    final entries = provider.publicationsByYear.entries.toList();
    final visibleEntries = entries.length > 8
        ? entries.sublist(entries.length - 8)
        : entries;
    final maxCount = visibleEntries.isEmpty
        ? 1
        : visibleEntries.map((entry) => entry.value).reduce(math.max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xu hướng gần đây',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openTrendScreen,
                child: const Text('Xem đủ'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleEntries.isEmpty)
            Text(
              'Chưa có dữ liệu năm xuất bản.',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
            )
          else
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visibleEntries.map((entry) {
                  final barHeight = 28 + (entry.value / maxCount) * 64;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            entry.value.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF22C55E), Color(0xFF3B82F6)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            entry.key.toString().substring(2),
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white60 : Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHotInsightBanner(
    AnalyticsProvider provider,
    Publication? mostInfluential,
  ) {
    final topPaperCitations = mostInfluential?.citedByCount ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Điểm nhấn nghiên cứu',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Snapshot nổi bật từ mẫu dữ liệu hiện tại',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài dẫn đầu citation',
                  style: GoogleFonts.inter(
                    color: Colors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mostInfluential?.title ?? provider.currentQuery,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$topPaperCitations trích dẫn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHotMiniStat(
                icon: Icons.person_search,
                label: 'Top author',
                value: provider.topAuthorName,
              ),
              const SizedBox(width: 10),
              _buildHotMiniStat(
                icon: Icons.menu_book,
                label: 'Top journal',
                value: provider.topJournalName,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildHotMiniStat(
                icon: Icons.calendar_month_rounded,
                label: 'Năm sôi động',
                value: provider.mostActiveYear == 0
                    ? 'N/A'
                    : provider.mostActiveYear.toString(),
              ),
              const SizedBox(width: 10),
              _buildHotMiniStat(
                icon: Icons.trending_up,
                label: 'Cite TB',
                value: provider.averageCitations.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.74),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotPaperTile(
    BuildContext context,
    Publication publication,
    int rank,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(publication: publication),
              ),
            );
          },
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.amber
                  : rank == 2
                  ? Colors.blueAccent
                  : Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            publication.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.25,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${publication.publicationYear} • ${publication.citedByCount} trích dẫn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAuthorHighlightCard(
    BuildContext context,
    String topAuthor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              color: Colors.deepPurpleAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tác giả đóng góp hàng đầu',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topAuthor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluentialPaperCard(
    BuildContext context,
    Publication mostInfluential,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailScreen(publication: mostInfluential),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.16),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        'Top Citations',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${mostInfluential.citedByCount} trích dẫn',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mostInfluential.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mostInfluential.authors.isNotEmpty
                  ? 'Tác giả: ${mostInfluential.authors.map((author) => author.name).join(', ')}'
                  : 'Chưa rõ tác giả',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.86),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    mostInfluential.journalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chi tiết',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang tổng hợp thông tin hot...',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lấy dữ liệu OpenAlex và tính toán dashboard',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSkeletonCard(isDark, height: 150),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard(isDark, height: 96)),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard(isDark, height: 96)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard(isDark, height: 96)),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard(isDark, height: 96)),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(bool isDark, {required double height}) {
    final baseColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final lineColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSkeletonLine(lineColor, width: 92, height: 12),
          _buildSkeletonLine(lineColor, width: 54, height: 24),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(
    Color color, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }

  Widget _buildErrorState(AnalyticsProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 14),
          Text(
            'Không tải được dữ liệu',
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _cleanErrorMessage(provider.errorMessage!),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: provider.currentQuery.isEmpty
                ? null
                : () => _handleSearch(provider.currentQuery),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 72,
            color: Colors.blueAccent.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'Dashboard đang chờ chủ đề',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các chỉ số xu hướng, tạp chí, tác giả và bài viết ảnh hưởng sẽ xuất hiện sau khi có dữ liệu từ OpenAlex.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSampleSummary(AnalyticsProvider provider) {
    if (provider.openAlexTotalResults == null) {
      return 'Đang phân tích ${provider.totalPublications} bài mẫu liên quan đến "${provider.currentQuery}".';
    }

    return 'OpenAlex có khoảng ${_formatNumber(provider.openAlexTotalResults!)} kết quả cho "${provider.currentQuery}". Dashboard đang phân tích ${provider.totalPublications} bài đầu tiên.';
  }

  String _formatUpdatedAt(DateTime? value) {
    if (value == null) return 'chưa có';

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/${value.year}';
  }

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _cleanErrorMessage(String raw) {
    final clean = raw
        .replaceAll('Exception: ', '')
        .replaceAll('OpenAlex', 'hệ thống')
        .trim();
    if (clean.contains('503')) {
      return 'Máy chủ dữ liệu đang tạm thời quá tải hoặc bảo trì (Lỗi 503). Vui lòng thử lại sau.';
    }
    if (clean.contains('SocketException') ||
        clean.contains('Failed host lookup') ||
        clean.contains('Network')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động trên thiết bị.';
    }
    return clean;
  }
}
