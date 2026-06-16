import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/analytics_provider.dart';
import '../widgets/publication_card.dart';
import 'dashboard_screen.dart';
import 'trend_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _suggestedTopics = [
    {'name': 'Artificial Intelligence', 'icon': Icons.psychology},
    {'name': 'Software Engineering', 'icon': Icons.code},
    {'name': 'Data Science', 'icon': Icons.analytics},
    {'name': 'Cybersecurity', 'icon': Icons.security},
    {'name': 'Internet of Things', 'icon': Icons.settings_input_antenna},
    {'name': 'Blockchain', 'icon': Icons.currency_bitcoin},
  ];

  void _handleSearch(String query) {
    if (query.trim().isNotEmpty) {
      FocusScope.of(context).unfocus();
      Provider.of<AnalyticsProvider>(context, listen: false).searchTopic(query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalyticsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Journal Trend Analyzer',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          // Phần tìm kiếm
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input tìm kiếm
                TextField(
                  controller: _searchController,
                  onSubmitted: _handleSearch,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập chủ đề nghiên cứu (ví dụ: AI, IoT...)',
                    hintStyle: GoogleFonts.inter(color: Colors.white60),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.blueAccent),
                      onPressed: () => _handleSearch(_searchController.text),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                
                // Gợi ý chủ đề
                Text(
                  'Gợi ý chủ đề:',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestedTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _suggestedTopics[index];
                      final isSelected = provider.currentQuery.toLowerCase() == topic['name'].toString().toLowerCase();
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(
                            topic['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : Colors.blueAccent,
                          ),
                          label: Text(
                            topic['name'],
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: isSelected ? Colors.blueAccent : const Color(0xFF334155),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            _searchController.text = topic['name'];
                            _handleSearch(topic['name']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Phần hiển thị kết quả
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
      // Phím tắt truy cập nhanh Dashboard & Trend khi đã có dữ liệu
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: provider.publications.isNotEmpty && !provider.isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'dashboard_btn',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard_outlined),
                    label: Text(
                      'Dashboard',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'trend_btn',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrendScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.trending_up),
                    label: Text(
                      'Xem Phân Tích',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody(AnalyticsProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu nghiên cứu...',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _cleanErrorMessage(provider.errorMessage!),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleSearch(provider.currentQuery),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.publications.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 100,
                  color: Colors.blueAccent.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bắt đầu phân tích xu hướng',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập từ khóa nghiên cứu vào ô tìm kiếm ở trên hoặc chọn các từ khóa gợi ý phổ biến để xem phân tích số liệu.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Hiển thị danh sách kết quả bài viết
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chủ đề: "${provider.currentQuery}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tìm thấy: ${provider.totalPublications} bài viết',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (provider.currentQuery.isNotEmpty) {
                await provider.searchTopic(provider.currentQuery);
              }
            },
            color: Colors.blueAccent,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80), // Chừa khoảng trống cho FloatingActionButton
              itemCount: provider.publications.length,
              itemBuilder: (context, index) {
                final pub = provider.publications[index];
                return PublicationCard(publication: pub);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _cleanErrorMessage(String raw) {
    String clean = raw.replaceAll('Exception: ', '').replaceAll('OpenAlex', 'hệ thống').trim();
    if (clean.contains('503')) {
      return 'Máy chủ dữ liệu đang tạm thời quá tải hoặc bảo trì (Lỗi 503). Vui lòng vuốt kéo để tải lại hoặc nhấn nút "Thử lại".';
    }
    if (clean.contains('SocketException') || clean.contains('Failed host lookup') || clean.contains('Network')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động (3G/4G) trên thiết bị của bạn.';
    }
    return clean;
  }
}
