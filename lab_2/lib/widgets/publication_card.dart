import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../screens/detail_screen.dart';
import 'info_badge.dart';

class PublicationCard extends StatelessWidget {
  final Publication publication;

  const PublicationCard({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    // Tạo chuỗi danh sách tác giả
    final authorsText = publication.authors.isEmpty
        ? 'Chưa rõ tác giả'
        : publication.authors.length <= 3
            ? publication.authors.join(', ')
            : '${publication.authors.take(3).join(', ')} và cs.';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(publication: publication),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                publication.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authorsText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Huy hiệu năm
                  InfoBadge(
                    icon: Icons.calendar_month,
                    text: publication.publicationYear.toString(),
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  // Huy hiệu trích dẫn
                  InfoBadge(
                    icon: Icons.format_quote,
                    text: '${publication.citedByCount} trích dẫn',
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Hiển thị Journal Name
              Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 14,
                    color: Colors.blueAccent.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      publication.journalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
