import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.24),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Journal Trend Analyzer',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PRM393 • Lab 2',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _AboutCard(
            isDark: isDark,
            icon: Icons.groups_2_outlined,
            title: 'About us',
            child: Text(
              'Chúng tôi xây dựng Journal Trend Analyzer để giúp người học và nhà nghiên cứu khám phá công bố khoa học, theo dõi xu hướng và nhận diện các tác giả, tạp chí nổi bật.',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AboutCard(
            isDark: isDark,
            icon: Icons.bolt_outlined,
            title: 'Tính năng chính',
            child: const Column(
              children: [
                _FeatureRow(
                  icon: Icons.home_outlined,
                  text: 'Khám phá công bố hot và mới',
                ),
                _FeatureRow(
                  icon: Icons.search,
                  text: 'Tìm kiếm và lưu lịch sử từ khóa',
                ),
                _FeatureRow(
                  icon: Icons.insights_outlined,
                  text: 'Phân tích xu hướng, tạp chí và tác giả',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AboutCard(
            isDark: isDark,
            icon: Icons.storage_outlined,
            title: 'Nguồn dữ liệu',
            child: Text(
              'Dữ liệu công bố khoa học được tổng hợp từ OpenAlex. Kết quả phân tích được tính trên mẫu dữ liệu tải về tại thời điểm sử dụng.',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final Widget child;

  const _AboutCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blueAccent, size: 21),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurpleAccent),
          const SizedBox(width: 11),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
