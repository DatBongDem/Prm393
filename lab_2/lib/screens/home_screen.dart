import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/publication.dart';
import '../state/analytics_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          'Home',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: provider.isGeneralLoading
                ? null
                : () => provider.loadGeneralData(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, provider, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    if (provider.isGeneralLoading && provider.generalPublications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.generalErrorMessage != null &&
        provider.generalPublications.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Chưa tải được dữ liệu chung',
        message: _cleanError(provider.generalErrorMessage!),
        actionLabel: 'Thử lại',
        onAction: () => provider.loadGeneralData(force: true),
      );
    }

    if (provider.generalPublications.isEmpty) {
      return _StateMessage(
        icon: Icons.explore_outlined,
        title: 'Khám phá nghiên cứu nổi bật',
        message: 'Home hiển thị các công bố hot và mới mà không cần từ khóa.',
        actionLabel: 'Tải dữ liệu',
        onAction: () => provider.loadGeneralData(force: true),
      );
    }

    final hotPublications = provider.generalPublications.take(6).toList();
    final latestPublications = provider.latestPublications.take(6).toList();

    return RefreshIndicator(
      onRefresh: () => provider.loadGeneralData(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          _buildHero(provider),
          const SizedBox(height: 24),
          _SectionHeader(
            key: const Key('home_hot_section'),
            icon: Icons.local_fire_department_rounded,
            color: Colors.orangeAccent,
            title: 'Đang được quan tâm',
            subtitle: 'Các công bố nổi bật trong 10 năm gần đây',
          ),
          const SizedBox(height: 12),
          ...hotPublications.map(
            (publication) => _PublicationTile(
              publication: publication,
              accent: Colors.orangeAccent,
              trailingText:
                  '${_formatNumber(publication.citedByCount)} trích dẫn',
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader(
            icon: Icons.auto_awesome,
            color: Colors.blueAccent,
            title: 'Mới cập nhật',
            subtitle: 'Những công bố mới nhất trên OpenAlex',
          ),
          const SizedBox(height: 12),
          if (latestPublications.isEmpty)
            _InlineNotice(
              message: 'Chưa có dữ liệu công bố mới.',
              isDark: isDark,
            )
          else
            ...latestPublications.map(
              (publication) => _PublicationTile(
                publication: publication,
                accent: Colors.blueAccent,
                trailingText: publication.publicationDate.isEmpty
                    ? publication.publicationYear.toString()
                    : publication.publicationDate,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(AnalyticsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'RESEARCH PULSE',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Khám phá tri thức\nkhông cần từ khóa',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Theo dõi những nghiên cứu nổi bật và công bố mới trong một nơi.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                label: 'Mẫu nổi bật',
                value: '${provider.generalPublications.length}',
              ),
              const SizedBox(width: 10),
              _HeroStat(
                label: 'Mới cập nhật',
                value: '${provider.latestPublications.length}',
              ),
              const SizedBox(width: 10),
              _HeroStat(label: 'Nguồn', value: 'OpenAlex'),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  static String _cleanError(String raw) =>
      raw.replaceAll('Exception: ', '').trim();
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicationTile extends StatelessWidget {
  final Publication publication;
  final Color accent;
  final String trailingText;

  const _PublicationTile({
    required this.publication,
    required this.accent,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(publication: publication),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${publication.journalName} • $trailingText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.blueAccent.withOpacity(0.5)),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final bool isDark;

  const _InlineNotice({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: GoogleFonts.inter(color: Colors.grey)),
    );
  }
}
