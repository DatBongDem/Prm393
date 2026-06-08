import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/analytics_provider.dart';

class TrendScreen extends StatelessWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalyticsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Phân tích xu hướng',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Xu hướng năm', icon: Icon(Icons.show_chart)),
              Tab(text: 'Top Tạp chí', icon: Icon(Icons.menu_book)),
              Tab(text: 'Top Tác giả', icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: provider.publications.isEmpty
            ? _buildEmptyState()
            : TabBarView(
                children: [
                  _buildYearTrendTab(context, provider),
                  _buildTopJournalsTab(context, provider),
                  _buildTopAuthorsTab(context, provider),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu để hiển thị.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // TAB 1: BIỂU ĐỒ XU HƯỚNG THEO NĂM
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

    // Chuẩn bị dữ liệu cho fl_chart
    final sortedYears = yearData.keys.toList();
    final spots = sortedYears.map((year) {
      return FlSpot(year.toDouble(), yearData[year]!.toDouble());
    }).toList();

    // Tìm giá trị min/max để thiết lập giới hạn cho trục
    double minX = sortedYears.first.toDouble();
    double maxX = sortedYears.last.toDouble();
    double minY = 0;
    double maxY = (yearData.values.reduce(max).toDouble() * 1.2).ceilToDouble();

    // Khoảng chia trục X (Ví dụ: cách nhau 2-5 năm tùy độ rộng dữ liệu)
    double xInterval = max(1.0, ((maxX - minX) / 5).roundToDouble());
    // Khoảng chia trục Y
    double yInterval = max(1.0, (maxY / 5).roundToDouble());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tốc độ tăng trưởng nghiên cứu',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Biểu đồ số lượng công bố khoa học theo từng năm.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          // Container chứa biểu đồ fl_chart
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
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
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
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    getTooltipColor: (spot) => isDark ? const Color(0xFF334155) : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        return LineTooltipItem(
                          'Năm ${touchedSpot.x.toInt()}: ${touchedSpot.y.toInt()} bài',
                          GoogleFonts.inter(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      color: Colors.blueAccent.withOpacity(0.12),
                    ),
                    dotData: const FlDotData(
                      show: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách thống kê chi tiết theo năm
          Text(
            'Chi tiết công bố qua các năm',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedYears.length,
            itemBuilder: (context, index) {
              final year = sortedYears[sortedYears.length - 1 - index]; // Sắp xếp năm mới nhất lên đầu
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
                        const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Năm $year',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.12),
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

  // TAB 2: CÁC TẠP CHÍ ĐÓNG GÓP NHIỀU NHẤT
  Widget _buildTopJournalsTab(BuildContext context, AnalyticsProvider provider) {
    final journals = provider.topJournals;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      itemCount: min(20, journals.length), // Giới hạn top 20 tạp chí
      itemBuilder: (context, index) {
        final journal = journals[index];
        final count = journal.value;
        final name = journal.key;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thứ hạng
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
                    color: index < 3 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Chi tiết tạp chí và thanh tỷ lệ phần trăm
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
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
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
        );
      },
    );
  }

  // TAB 3: CÁC TÁC GIẢ ĐÓNG GÓP NHIỀU NHẤT
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

    final maxCount = authors.first.value;

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: min(20, authors.length), // Giới hạn top 20 tác giả
      itemBuilder: (context, index) {
        final author = authors[index];
        final count = author.value;
        final name = author.key;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thứ hạng
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
                    color: index < 3 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Tên tác giả và tiến trình đóng góp
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
                      maxLines: 1,
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
                              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
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
        );
      },
    );
  }
}
