import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/author.dart';
import '../models/publication.dart';
import '../services/openalex_service.dart';
import 'author_detail_screen.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;
  final OpenAlexService? authorService;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
    this.authorService,
  });

  Future<void> _openDoiLink(BuildContext context, String? doiUrl) async {
    if (doiUrl == null || doiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài viết này không có liên kết DOI.')),
      );
      return;
    }

    final url = Uri.parse(doiUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi mở liên kết: $e')));
    }
  }

  void _openAuthorDetail(BuildContext context, AuthorInfo author) {
    if (author.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có đủ dữ liệu để mở chi tiết tác giả.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorDetailScreen(
          authorId: author.id,
          authorName: author.name,
          service: authorService,
        ),
      ),
    );
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
          'Chi tiết bài báo',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickStat(
                        context,
                        Icons.calendar_month_outlined,
                        'Năm xuất bản',
                        publication.publicationYear.toString(),
                        Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        context,
                        Icons.star_outline_rounded,
                        'Trích dẫn',
                        publication.citedByCount.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    context,
                    'Tạp chí và đơn vị xuất bản',
                    Icons.menu_book,
                  ),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey[200]!,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.school, color: Colors.white),
                      ),
                      title: Text(
                        publication.journalName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: publication.doi != null
                          ? Text(
                              'DOI: ${publication.doi}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: publication.doi != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.open_in_new,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () =>
                                  _openDoiLink(context, publication.doi),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(
                    context,
                    'Danh sách tác giả (${publication.authors.length})',
                    Icons.people_outline,
                  ),
                  if (publication.authors.isEmpty)
                    Text(
                      'Thông tin tác giả đang được cập nhật.',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: publication.authors.map((author) {
                        final canOpenDetail = author.name.trim().isNotEmpty;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: canOpenDetail
                                ? () => _openAuthorDetail(context, author)
                                : null,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width - 64,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: canOpenDetail
                                    ? Colors.blueAccent.withValues(alpha: 0.08)
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: canOpenDetail
                                      ? Colors.blueAccent.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      author.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: canOpenDetail
                                            ? isDark
                                                  ? Colors.blue[300]
                                                  : Colors.blue[800]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (author.hasOpenAlexId) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 14,
                                      color: Colors.blueAccent,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    context,
                    'Tóm tắt bài báo (Abstract)',
                    Icons.description_outlined,
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
                      publication.abstractText ??
                          'Không tìm thấy thông tin tóm tắt cho bài báo này trong hệ thống dữ liệu.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: publication.abstractText == null
                            ? Colors.grey
                            : isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87,
                        fontStyle: publication.abstractText == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (publication.doi != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _openDoiLink(context, publication.doi),
                        icon: const Icon(Icons.launch_outlined),
                        label: Text(
                          'Xem bài viết gốc (Publisher Website)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
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
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
}
