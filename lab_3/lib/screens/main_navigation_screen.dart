import 'package:flutter/material.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'trends_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const MainNavigationScreen({
    Key? key,
    required this.analyticsService,
    required this.remoteConfigService,
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  final List<String> _screenNames = ['Home', 'Journal', 'Trends', 'Profile'];

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        analyticsService: widget.analyticsService,
        remoteConfigService: widget.remoteConfigService,
      ),
      JournalScreen(
        analyticsService: widget.analyticsService,
        remoteConfigService: widget.remoteConfigService,
      ),
      TrendsScreen(
        analyticsService: widget.analyticsService,
        remoteConfigService: widget.remoteConfigService,
      ),
      ProfileScreen(
        analyticsService: widget.analyticsService,
        remoteConfigService: widget.remoteConfigService,
      ),
    ];

    // Log screen view cho màn hình mặc định ban đầu
    _logCurrentScreen(_selectedIndex);

    // Ghi nhận hoạt động hàng ngày (DAU) cho người dùng đăng nhập hiện tại
    FirestoreService().logDailyActivity();
  }

  void _logCurrentScreen(int index) {
    widget.analyticsService.logScreenView(screenName: _screenNames[index]);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    _logCurrentScreen(index);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Trends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
