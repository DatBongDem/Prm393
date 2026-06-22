import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/author.dart';
import '../services/openalex_service.dart';

class AuthorDetailScreen extends StatefulWidget {
  final String? authorId;
  final String authorName;
  final OpenAlexService? service;

  const AuthorDetailScreen({
    super.key,
    required this.authorId,
    required this.authorName,
    this.service,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  late final OpenAlexService _openAlexService;

  late Future<AuthorDetail> _authorFuture;

  @override
  void initState() {
    super.initState();
    _openAlexService = widget.service ?? OpenAlexService();
    _authorFuture = _openAlexService.resolveAuthorDetail(
      authorId: widget.authorId,
      authorName: widget.authorName,
    );
  }

  void _retry() {
    setState(() {
      _authorFuture = _openAlexService.resolveAuthorDetail(
        authorId: widget.authorId,
        authorName: widget.authorName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Chi tiết tác giả',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AuthorDetail>(
        future: _authorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải thông tin tác giả...',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final message = _cleanErrorMessage(snapshot.error.toString());
            final isMissingProfile = message.contains(
              'Không tìm thấy thông tin chi tiết cho tác giả',
            );

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMissingProfile
                        ? Icons.person_off_outlined
                        : Icons.error_outline,
                    size: 64,
                    color: isMissingProfile ? Colors.amber : Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMissingProfile
                        ? 'Chưa có hồ sơ tác giả'
                        : 'Không thể tải thông tin tác giả',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMissingProfile
                        ? 'OpenAlex hiện chưa có đủ dữ liệu để hiển thị chi tiết cho tác giả này.'
                        : message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey, height: 1.4),
                  ),
                  if (isMissingProfile) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bạn vẫn có thể xem tên tác giả trong bài báo, nhưng chưa có thêm thông tin học thuật để hiển thị.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (isMissingProfile)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Quay lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          final author = snapshot.data;
          if (author == null) {
            return Center(
              child: Text(
                'Không có dữ liệu tác giả.',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.displayName.isNotEmpty
                            ? author.displayName
                            : widget.authorName,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (author.orcid != null && author.orcid!.isNotEmpty)
                            _buildInfoChip(
                              icon: Icons.verified_outlined,
                              text: 'ORCID: ${author.orcid}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.12,
                  children: [
                    _buildMetricCard(
                      context,
                      'Tổng số công bố',
                      author.worksCount.toString(),
                      Icons.library_books_outlined,
                      Colors.blueAccent,
                    ),
                    _buildMetricCard(
                      context,
                      'Tổng số trích dẫn',
                      author.citedByCount.toString(),
                      Icons.format_quote,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      context,
                      'Chỉ số ảnh hưởng\n(h-index)',
                      author.hIndex?.toString() ?? 'N/A',
                      Icons.insights_outlined,
                      Colors.deepPurpleAccent,
                    ),
                    _buildMetricCard(
                      context,
                      'Bài có từ 10 trích dẫn\n(i10-index)',
                      author.i10Index?.toString() ?? 'N/A',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMetricsHelpCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  context,
                  'Nơi công tác gần nhất',
                  Icons.apartment_outlined,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    author.lastKnownInstitutionName?.isNotEmpty == true
                        ? author.lastKnownInstitutionName!
                        : 'Chưa có thông tin cơ quan gần nhất.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: author.lastKnownInstitutionName?.isNotEmpty == true
                          ? isDark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black87
                          : Colors.grey,
                      fontStyle:
                          author.lastKnownInstitutionName?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHelpCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Giải thích nhanh các chỉ số',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'h-index: đo mức độ ảnh hưởng học thuật tổng thể của tác giả.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'i10-index: số bài có ít nhất 10 lượt trích dẫn.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  String _cleanErrorMessage(String raw) {
    final clean = raw.replaceAll('Exception: ', '').trim();
    if (clean.contains('503')) {
      return 'Máy chủ dữ liệu tác giả đang tạm thời quá tải hoặc bảo trì.';
    }
    if (clean.contains('SocketException') ||
        clean.contains('Failed host lookup') ||
        clean.contains('Network')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra lại mạng và thử lại.';
    }
    return clean;
  }
}
