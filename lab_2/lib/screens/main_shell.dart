import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/analytics_provider.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'trend_screen.dart';

class MainShell extends StatefulWidget {
  final bool autoLoadHotTopic;

  const MainShell({super.key, this.autoLoadHotTopic = true});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _items = [
    _ShellNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _ShellNavItem(
      label: 'Search',
      icon: Icons.search,
      selectedIcon: Icons.manage_search,
    ),
    _ShellNavItem(
      label: 'Phân tích',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    _ShellNavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoLoadHotTopic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AnalyticsProvider>().loadGeneralData();
      });
    }
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          SearchScreen(onOpenAnalysis: () => _selectTab(2)),
          const TrendScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildFloatingNav(isDark),
    );
  }

  Widget _buildFloatingNav(bool isDark) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF111827).withOpacity(0.97)
              : Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = index == _selectedIndex;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == _items.length - 1 ? 0 : 4,
                ),
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: item.label,
                  child: InkWell(
                    key: ValueKey('nav_${item.label}'),
                    onTap: () => _selectTab(index),
                    borderRadius: BorderRadius.circular(19),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 21,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _ShellNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
