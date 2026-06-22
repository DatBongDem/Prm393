import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/analytics_provider.dart';
import '../widgets/publication_card.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback? onOpenAnalysis;

  const SearchScreen({super.key, this.onOpenAnalysis});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<AnalyticsProvider>().searchTopic(trimmedQuery);
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    setState(() {});
    _handleSearch(query);
  }

  void _clearCurrentSearch() {
    _searchController.clear();
    context.read<AnalyticsProvider>().clearSearch();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          'Search',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(provider, isDark),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(AnalyticsProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('search_topic_input'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _handleSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Nhập từ khóa nghiên cứu...',
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa nội dung',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Colors.blueAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (provider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Lịch sử tìm kiếm',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('clear_search_history'),
                  onPressed: provider.clearRecentSearches,
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: provider.recentSearches
                  .map(
                    (query) => InputChip(
                      key: ValueKey('recent_search_$query'),
                      avatar: const Icon(Icons.north_west, size: 15),
                      label: Text(query),
                      onPressed: () => _searchFromHistory(query),
                      onDeleted: () => provider.removeRecentSearch(query),
                      deleteButtonTooltipMessage: 'Xóa $query khỏi lịch sử',
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AnalyticsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return _SearchState(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể tìm kiếm',
        message: _cleanErrorMessage(provider.errorMessage!),
        actionLabel: 'Thử lại',
        onAction: () => _handleSearch(provider.currentQuery),
      );
    }

    if (!provider.hasSearchQuery) {
      return const _SearchState(
        icon: Icons.manage_search_rounded,
        title: 'Tìm kiếm nghiên cứu',
        message:
            'Nhập một từ khóa để tìm bài báo. Các lần tìm gần đây sẽ được lưu ngay bên trên.',
      );
    }

    if (provider.publications.isEmpty) {
      return _SearchState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy kết quả',
        message: 'Không có công bố phù hợp với “${provider.currentQuery}”.',
        actionLabel: 'Xóa tìm kiếm',
        onAction: _clearCurrentSearch,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${provider.currentQuery}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.blueAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${provider.publications.length} bài trong mẫu phân tích',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: widget.onOpenAnalysis,
                icon: const Icon(Icons.insights, size: 18),
                label: const Text('Phân tích'),
              ),
              IconButton(
                tooltip: 'Xóa kết quả tìm kiếm',
                onPressed: _clearCurrentSearch,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                provider.searchTopic(provider.currentQuery, addToRecent: false),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: provider.publications.length,
              itemBuilder: (context, index) =>
                  PublicationCard(publication: provider.publications[index]),
            ),
          ),
        ),
      ],
    );
  }

  String _cleanErrorMessage(String raw) =>
      raw.replaceAll('Exception: ', '').trim();
}

class _SearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SearchState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76, color: Colors.blueAccent.withOpacity(0.45)),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
