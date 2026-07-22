import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/analytics_provider.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firestore_service.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatelessWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const KeywordsScreen({
    super.key,
    required this.analyticsService,
    required this.remoteConfigService,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = remoteConfigService.getPrimaryColor();
    final maxKeywordsLimit = remoteConfigService.getMaxKeywords();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Xu hướng tìm kiếm',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getTopSearchedKeywordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final firebaseKeywords = snapshot.data ?? [];
          final openAlexKeywords = _buildOpenAlexKeywordStats(provider);
          final useFirebaseKeywords = firebaseKeywords.isNotEmpty;
          final displayKeywords =
              (useFirebaseKeywords ? firebaseKeywords : openAlexKeywords)
                  .take(maxKeywordsLimit)
                  .toList();

          if (displayKeywords.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // Chuyển đổi dữ liệu sang MapEntry để vẽ biểu đồ
          final chartData = displayKeywords.map((item) {
            return MapEntry(item['keyword'] as String, item['count'] as int);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner thông tin giới hạn Remote Config
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          useFirebaseKeywords
                              ? 'Hiển thị top $maxKeywordsLimit từ khóa được tìm kiếm nhiều nhất trong 7 ngày qua từ Firebase.'
                              : 'Hiển thị top $maxKeywordsLimit từ khóa phổ biến trong dữ liệu OpenAlex hiện tại.',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  useFirebaseKeywords
                      ? 'Biểu đồ số lượt tìm kiếm (7 ngày)'
                      : 'Biểu đồ tần suất từ khóa OpenAlex',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildKeywordChart(chartData, primaryColor, isDark),
                const SizedBox(height: 24),
                Text(
                  'Danh sách từ khóa phổ biến',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...displayKeywords.map((item) {
                  final keyword = item['keyword'] as String;
                  final count = item['count'] as int;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.trending_up, color: primaryColor),
                      ),
                      title: Text(
                        keyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        useFirebaseKeywords
                            ? '$count lượt tìm kiếm gần đây'
                            : '$count bài báo liên quan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Log Analytics event: view_keyword
                        analyticsService.logCustomEvent(
                          name: 'view_keyword',
                          parameters: {'keyword': keyword},
                        );

                        // Chuyển sang màn hình chi tiết từ khóa
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KeywordDetailScreen(
                              keyword: keyword,
                              publications:
                                  provider.analysisPublications.isNotEmpty
                                  ? provider.analysisPublications
                                  : provider.publications,
                              analyticsService: analyticsService,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _buildOpenAlexKeywordStats(
    AnalyticsProvider provider,
  ) {
    final counts = <String, int>{};
    for (final publication in provider.analysisPublications) {
      for (final concept in publication.concepts) {
        final keyword = concept.trim();
        if (keyword.isEmpty) continue;
        counts[keyword] = (counts[keyword] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .map((entry) => {'keyword': entry.key, 'count': entry.value})
        .toList();
  }

  Widget _buildKeywordChart(
    List<MapEntry<String, int>> keywords,
    Color color,
    bool isDark,
  ) {
    if (keywords.isEmpty) return const SizedBox();
    final maxCount = keywords.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: keywords.map((entry) {
          final keyword = entry.key;
          final count = entry.value;
          final percentage = maxCount > 0 ? count / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    keyword,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.8), color],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 72,
              color: Colors.blueAccent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 18),
            Text(
              'Không có dữ liệu xu hướng',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có lịch sử tìm kiếm Firebase hoặc dữ liệu keyword OpenAlex để phân tích.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
