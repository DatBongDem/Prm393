import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/fcm_sender_service.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Search controllers
  final _userSearchController = TextEditingController();
  final _pdfSearchController = TextEditingController();
  final _bugSearchController = TextEditingController();
  String _selectedBugFilter = 'All';

  // Notification form controllers
  final _notificationFormKey = GlobalKey<FormState>();
  final _notiTitleController = TextEditingController();
  final _notiBodyController = TextEditingController();
  bool _isSendingNotification = false;



  @override
  void dispose() {
    _userSearchController.dispose();
    _pdfSearchController.dispose();
    _bugSearchController.dispose();
    _notiTitleController.dispose();
    _notiBodyController.dispose();
    super.dispose();
  }

  // Hàm Đăng xuất
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Đăng xuất', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống quản trị?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.outfit(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Đăng xuất', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              title: Text('Admin Portal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
          : null,
      drawer: !isDesktop ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      body: Row(
        children: [
          // Sidebar cố định nếu ở Desktop
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // Slate 800
                border: Border(right: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: _buildSidebar(isDrawer: false),
            ),
          
          // Nội dung hiển thị bên phải
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar UI
  Widget _buildSidebar({required bool isDrawer}) {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard},
      {'title': 'Người dùng', 'icon': Icons.people},
      {'title': 'Tài liệu PDF', 'icon': Icons.picture_as_pdf},
      {'title': 'Báo cáo Bug', 'icon': Icons.bug_report},
      {'title': 'Gửi Thông báo', 'icon': Icons.campaign},
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.pinkAccent, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    'WEB ADMIN',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _currentUser?.email ?? 'admin@fpt.edu.vn',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF334155), height: 1),
        const SizedBox(height: 16),
        
        // Navigation List
        Expanded(
          child: ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final isSelected = _selectedTab == index;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.pinkAccent.withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.pinkAccent : Colors.white60,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTab = index;
                    });
                    if (isDrawer) {
                      Navigator.pop(context); // Đóng drawer
                    }
                  },
                ),
              );
            },
          ),
        ),
        
        // Footer (Đăng xuất)
        const Divider(color: Color(0xFF334155), height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'ĐĂNG XUẤT',
              style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: _handleLogout,
          ),
        ),
      ],
    );
  }

  // Điều hướng hiển thị nội dung chính
  Widget _buildMainContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildPdfTab();
      case 3:
        return _buildBugsTab();
      case 4:
        return _buildCampaignsTab();
      default:
        return const Center(child: Text('Tab không hợp lệ'));
    }
  }

  // ==========================================
  // TAB 1: DASHBOARD
  // ==========================================
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeader('Dashboard', 'Thống kê tổng quan hoạt động ứng dụng'),
          const SizedBox(height: 24),
          
          // Thẻ chỉ số tổng quan
          _buildStatsCardsGrid(),
          const SizedBox(height: 32),

          // Layout 2 cột cho Biểu đồ
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDauChartCard()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSearchTrendsCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDauChartCard(),
                    const SizedBox(height: 24),
                    _buildSearchTrendsCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCardsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('active_users').snapshots(),
      builder: (context, snapshotUsers) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pdf_reports').snapshots(),
          builder: (context, snapshotPdfs) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bugs').snapshots(),
              builder: (context, snapshotBugs) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
                  builder: (context, snapshotCampaigns) {
                    // Tính số user duy nhất từ active_users
                    final userEmails = <String>{};
                    if (snapshotUsers.hasData) {
                      for (var doc in snapshotUsers.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>?;
                        final email = data?['email'] as String?;
                        if (email != null && email.isNotEmpty) {
                          userEmails.add(email);
                        }
                      }
                    }

                    final totalUsers = userEmails.length;
                    final totalPdfs = snapshotPdfs.hasData ? snapshotPdfs.data!.docs.length : 0;
                    final activeBugs = snapshotBugs.hasData
                        ? snapshotBugs.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            return data?['status'] != 'Đã giải quyết';
                          }).length
                        : 0;
                    final totalCampaigns = snapshotCampaigns.hasData ? snapshotCampaigns.data!.docs.length : 0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 550
                                ? 2
                                : 1;
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                          children: [
                            _buildStatCard(
                              'Người dùng đăng ký',
                              totalUsers.toString(),
                              Icons.people,
                              Colors.pinkAccent,
                            ),
                            _buildStatCard(
                              'Báo cáo PDF đã xuất',
                              totalPdfs.toString(),
                              Icons.picture_as_pdf,
                              Colors.purpleAccent,
                            ),
                            _buildStatCard(
                              'Bug chưa xử lý',
                              activeBugs.toString(),
                              Icons.bug_report,
                              Colors.redAccent,
                            ),
                            _buildStatCard(
                              'Campaign thông báo',
                              totalCampaigns.toString(),
                              Icons.campaign,
                              Colors.orangeAccent,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  // Biểu đồ DAU tự vẽ bằng các Container thanh đứng (an toàn, đẹp, không lỗi plugin)
  Widget _buildDauChartCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('active_users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            color: Color(0xFF1E293B),
            child: SizedBox(height: 350, child: Center(child: CircularProgressIndicator())),
          );
        }

        // Thống kê active user theo thứ trong tuần (1: thứ 2 -> 7: chủ nhật)
        final dauByDay = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
        final dayNames = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final day = data?['dayOfWeek'] as int?;
          if (day != null && day >= 1 && day <= 7) {
            dauByDay[day] = (dauByDay[day] ?? 0) + 1;
          }
        }

        int maxVal = 1;
        dauByDay.forEach((key, val) {
          if (val > maxVal) maxVal = val;
        });

        return Container(
          padding: const EdgeInsets.all(24),
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoạt động hàng ngày (DAU)',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Tổng lượt truy cập theo các thứ trong tuần',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
              ),
              const Expanded(child: SizedBox(height: 20)),
              
              // Biểu đồ
              SizedBox(
                height: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final dayNum = index + 1;
                    final count = dauByDay[dayNum] ?? 0;
                    final pct = count / maxVal;
                    final barHeight = pct * 160 + 8.0; // chiều cao tối đa 168px

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.pinkAccent, Colors.purpleAccent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayNames[dayNum] ?? '',
                          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget hiển thị Top Search Keywords kèm thanh phần trăm phần trăm đẹp mắt
  Widget _buildSearchTrendsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('search_history').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            color: Color(0xFF1E293B),
            child: SizedBox(height: 350, child: Center(child: CircularProgressIndicator())),
          );
        }

        // Tính tần suất các từ khóa
        final counts = <String, int>{};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final query = data?['query'] as String?;
          if (query != null && query.isNotEmpty) {
            final formatted = query.trim().split(' ').map((word) {
              if (word.isEmpty) return '';
              return '${word[0].toUpperCase()}${word.substring(1)}';
            }).join(' ');
            counts[formatted] = (counts[formatted] ?? 0) + 1;
          }
        }

        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();

        int maxVal = 1;
        if (top5.isNotEmpty) maxVal = top5.first.value;

        return Container(
          padding: const EdgeInsets.all(24),
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xu hướng tìm kiếm nổi bật',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Top 5 từ khóa được tìm kiếm nhiều nhất trên Mobile',
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              if (top5.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu tìm kiếm.',
                      style: GoogleFonts.outfit(color: Colors.white38),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: top5.length,
                    itemBuilder: (context, index) {
                      final item = top5[index];
                      final pct = item.value / maxVal;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${index + 1}. ${item.key}',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item.value} lượt',
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334155),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: pct,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.purpleAccent, Colors.pinkAccent],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: QUẢN LÝ NGƯỜI DÙNG
  // ==========================================
  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabHeader('Quản lý người dùng', 'Xem danh sách và lịch sử hoạt động của người dùng'),
        const SizedBox(height: 24),
        
        // Search bar
        _buildSearchBar(_userSearchController, 'Tìm kiếm user theo email...', () => setState(() {})),
        const SizedBox(height: 16),
        
        // Table Card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('active_users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Nhóm và đếm số lượt hoạt động của từng người dùng
                final usersData = <String, Map<String, dynamic>>{};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final email = data?['email'] as String?;
                  final userId = data?['userId'] as String?;
                  final timestamp = data?['timestamp'] as Timestamp?;

                  if (email != null && email.isNotEmpty) {
                    if (!usersData.containsKey(email)) {
                      usersData[email] = {
                        'email': email,
                        'userId': userId ?? 'N/A',
                        'activeDays': 1,
                        'lastActive': timestamp,
                      };
                    } else {
                      usersData[email]!['activeDays'] += 1;
                      final currentLast = usersData[email]!['lastActive'] as Timestamp?;
                      if (timestamp != null && (currentLast == null || timestamp.compareTo(currentLast) > 0)) {
                        usersData[email]!['lastActive'] = timestamp;
                      }
                    }
                  }
                }

                final searchText = _userSearchController.text.trim().toLowerCase();
                var list = usersData.values.toList();
                if (searchText.isNotEmpty) {
                  list = list.where((u) => u['email'].toString().toLowerCase().contains(searchText)).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Text('Không tìm thấy người dùng nào.', style: GoogleFonts.outfit(color: Colors.white60)),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 40,
                            columns: [
                              DataColumn(label: Text('Email', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('User ID', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Số ngày Active', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Hoạt động cuối', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                            rows: list.map((user) {
                              final lastActiveTs = user['lastActive'] as Timestamp?;
                              final formattedDate = lastActiveTs != null
                                  ? DateFormat('HH:mm dd/MM/yyyy').format(lastActiveTs.toDate())
                                  : 'Không xác định';

                              return DataRow(
                                cells: [
                                  DataCell(Text(user['email'] as String, style: const TextStyle(color: Colors.white70))),
                                  DataCell(Text(user['userId'] as String, style: const TextStyle(color: Colors.white54, fontSize: 12))),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.pinkAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${user['activeDays']} ngày',
                                      style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  )),
                                  DataCell(Text(formattedDate, style: const TextStyle(color: Colors.white70))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        )
      ],
    );
  }

  // ==========================================
  // TAB 3: QUẢN LÝ PDF
  // ==========================================
  Widget _buildPdfTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabHeader('Quản lý tài liệu PDF', 'Xem, tải xuống và dọn dẹp các báo cáo PDF do người dùng xuất bản'),
        const SizedBox(height: 24),
        
        _buildSearchBar(_pdfSearchController, 'Tìm kiếm PDF theo chủ đề...', () => setState(() {})),
        const SizedBox(height: 16),
        
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pdf_reports').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                final query = _pdfSearchController.text.trim().toLowerCase();
                if (query.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final topic = data?['topic']?.toString().toLowerCase() ?? '';
                    final file = data?['fileName']?.toString().toLowerCase() ?? '';
                    return topic.contains(query) || file.contains(query);
                  }).toList();
                }

                // Sắp xếp giảm dần theo thời gian tạo
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Text('Không tìm thấy tài liệu PDF nào.', style: GoogleFonts.outfit(color: Colors.white60)),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 40,
                            columns: [
                              DataColumn(label: Text('Chủ đề (Topic)', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Tên tệp (File Name)', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Ngày tạo', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Hành động', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
                            ],
                            rows: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>? ?? {};
                              final docId = doc.id;
                              final topic = data['topic'] ?? 'N/A';
                              final fileName = data['fileName'] ?? 'N/A';
                              final pdfUrl = data['pdfUrl'] ?? '';
                              final createdAt = data['createdAt'] as Timestamp?;
                              final formattedDate = createdAt != null
                                  ? DateFormat('HH:mm dd/MM/yyyy').format(createdAt.toDate())
                                  : 'N/A';

                              return DataRow(
                                cells: [
                                  DataCell(Text(topic, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                                  DataCell(Text(fileName, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                                  DataCell(Text(formattedDate, style: const TextStyle(color: Colors.white60))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new, color: Colors.pinkAccent),
                                        tooltip: 'Mở / Xem PDF',
                                        onPressed: () async {
                                          if (pdfUrl.isNotEmpty) {
                                            final uri = Uri.parse(pdfUrl);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Không thể mở đường dẫn PDF này.')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        tooltip: 'Xóa tài liệu',
                                        onPressed: () => _deletePdf(docId, pdfUrl),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        )
      ],
    );
  }

  // Hàm xóa PDF
  Future<void> _deletePdf(String docId, String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Xác nhận xóa', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa tài liệu này khỏi hệ thống? Thao tác này sẽ xóa bản ghi Firestore.', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.outfit(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Xóa trên Firestore
        await FirebaseFirestore.instance.collection('pdf_reports').doc(docId).delete();

        // 2. Xóa trên Storage (nếu có URL hợp lệ)
        if (url.isNotEmpty) {
          try {
            final storageRef = FirebaseStorage.instance.refFromURL(url);
            await storageRef.delete();
            print('FStore Storage: Đã xóa file thành công.');
          } catch (e) {
            // Có thể lỗi CORS hoặc file đã bị xóa trước đó
            print('Storage Delete Error (CORS/Not Found): $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu PDF thành công.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  // ==========================================
  // TAB 4: BÁO CÁO BUG
  // ==========================================
  Widget _buildBugsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bugs').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;

        // 1. Tính toán thống kê từ Crashlytics và User Reports
        int totalCrashes = 0;
        int fatalCrashes = 0;
        int userReports = 0;
        int unresolvedBugs = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final type = data['type']?.toString() ?? '';
          final status = data['status']?.toString() ?? 'Mới';

          if (type.contains('Crash')) {
            totalCrashes++;
            if (type.contains('Fatal')) {
              fatalCrashes++;
            }
          } else if (type == 'User Report') {
            userReports++;
          }

          if (status != 'Đã giải quyết') {
            unresolvedBugs++;
          }
        }

        // 2. Lọc danh sách theo filter dropdown và search query
        var filteredDocs = List<DocumentSnapshot>.from(docs);

        // Lọc theo bộ lọc dropdown
        if (_selectedBugFilter == 'Crashlytics') {
          filteredDocs = filteredDocs.where((doc) {
            final type = (doc.data() as Map<String, dynamic>?)?['type']?.toString() ?? '';
            return type.contains('Crash');
          }).toList();
        } else if (_selectedBugFilter == 'Fatal') {
          filteredDocs = filteredDocs.where((doc) {
            final type = (doc.data() as Map<String, dynamic>?)?['type']?.toString() ?? '';
            return type == 'Crash (Fatal)';
          }).toList();
        } else if (_selectedBugFilter == 'UserReport') {
          filteredDocs = filteredDocs.where((doc) {
            final type = (doc.data() as Map<String, dynamic>?)?['type']?.toString() ?? '';
            return type == 'User Report';
          }).toList();
        }

        // Lọc theo search query
        final query = _bugSearchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          filteredDocs = filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final title = data?['title']?.toString().toLowerCase() ?? '';
            final desc = data?['description']?.toString().toLowerCase() ?? '';
            final email = data?['userEmail']?.toString().toLowerCase() ?? '';
            return title.contains(query) || desc.contains(query) || email.contains(query);
          }).toList();
        }

        // Sắp xếp theo timestamp giảm dần
        filteredDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>?)?['timestamp'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabHeader(
              'Báo cáo Bug & Crashlytics',
              'Giám sát lỗi Crashlytics tự động từ thiết bị và phản hồi từ người dùng',
            ),
            const SizedBox(height: 20),

            // Hàng Thẻ Thống Kê Mini
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 900 ? 2.5 : 3.0,
                  children: [
                    _buildMiniStatCard(
                      'TỔNG SỐ CRASH',
                      totalCrashes.toString(),
                      'Lỗi hệ thống tự bắt',
                      Icons.offline_bolt,
                      Colors.orangeAccent,
                    ),
                    _buildMiniStatCard(
                      'CRASH NGHIÊM TRỌNG (FATAL)',
                      fatalCrashes.toString(),
                      'Làm sập ứng dụng',
                      Icons.dangerous,
                      Colors.redAccent,
                    ),
                    _buildMiniStatCard(
                      'BÁO CÁO NGƯỜI DÙNG',
                      userReports.toString(),
                      'Phản hồi thủ công',
                      Icons.rate_review,
                      Colors.blueAccent,
                    ),
                    _buildMiniStatCard(
                      'BUG CHƯA XỬ LÝ',
                      unresolvedBugs.toString(),
                      'Cần kiểm tra lại',
                      Icons.bug_report,
                      Colors.yellowAccent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Thanh Bộ Lọc & Tìm Kiếm
            Row(
              children: [
                Expanded(
                  child: _buildSearchBar(
                    _bugSearchController,
                    'Tìm kiếm theo mô tả lỗi hoặc email...',
                    () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBugFilter,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.filter_alt, color: Colors.pinkAccent),
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('Tất cả lỗi')),
                        DropdownMenuItem(value: 'Crashlytics', child: Text('Chỉ lỗi Crashlytics')),
                        DropdownMenuItem(value: 'Fatal', child: Text('Chỉ lỗi sập app (Fatal)')),
                        DropdownMenuItem(value: 'UserReport', child: Text('Chỉ báo cáo người dùng')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBugFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bảng Danh Sách Lỗi
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy báo cáo lỗi nào phù hợp.',
                          style: GoogleFonts.outfit(color: Colors.white60),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columnSpacing: 40,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        'Nguồn / Loại Lỗi',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Người Gửi / Email',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Tiêu Đề / Sự Cố',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Trạng Thái',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Thời Gian',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Hành Động',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: filteredDocs.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>? ?? {};
                                    final type = data['type'] ?? 'User Report';
                                    final email = data['userEmail'] ?? 'anonymous';
                                    final title = data['title'] ?? 'N/A';
                                    final status = data['status'] ?? 'Mới';
                                    final timestamp = data['timestamp'] as Timestamp?;
                                    final formattedDate = timestamp != null
                                        ? DateFormat('HH:mm dd/MM/yyyy').format(timestamp.toDate())
                                        : 'N/A';

                                    Color statusColor = Colors.orangeAccent;
                                    if (status == 'Đang xử lý') statusColor = Colors.cyanAccent;
                                    if (status == 'Đã giải quyết') statusColor = Colors.greenAccent;

                                    // Badge thiết kế nguồn lỗi chuyên nghiệp
                                    Widget sourceBadge;
                                    if (type.toString().contains('Fatal')) {
                                      sourceBadge = Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.flash_on, color: Colors.redAccent, size: 13),
                                            SizedBox(width: 4),
                                            Text(
                                              'Fatal Crashlytics',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (type.toString().contains('Crash')) {
                                      sourceBadge = Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bug_report, color: Colors.orangeAccent, size: 13),
                                            SizedBox(width: 4),
                                            Text(
                                              'Crashlytics',
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      sourceBadge = Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person, color: Colors.blueAccent, size: 13),
                                            SizedBox(width: 4),
                                            Text(
                                              'User Report',
                                              style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(sourceBadge),
                                        DataCell(Text(email, style: const TextStyle(color: Colors.white70))),
                                        DataCell(Text(
                                          title.length > 30 ? '${title.substring(0, 30)}...' : title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        )),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child:
                                              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                        )),
                                        DataCell(Text(formattedDate, style: const TextStyle(color: Colors.white60))),
                                        DataCell(ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                                            side: const BorderSide(color: Colors.pinkAccent, width: 1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _showBugDetailDialog(doc),
                                          child: const Text(
                                            'Chi Tiết',
                                            style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                                          ),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      )
              ),
            ),
          ],
        );
      },
    );
  }

  // Hộp thoại xem chi tiết Bug và cập nhật trạng thái
  void _showBugDetailDialog(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final type = data['type'] ?? 'User Report';
            final email = data['userEmail'] ?? 'anonymous';
            final title = data['title'] ?? 'N/A';
            final description = data['description'] ?? '';
            final deviceInfo = data['deviceInfo'] ?? 'N/A';
            final status = data['status'] ?? 'Mới';
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('HH:mm:ss dd/MM/yyyy').format(timestamp.toDate())
                : 'N/A';

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chi tiết lỗi / Crash',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Loại báo cáo:', type, isBoldValue: true),
                      const SizedBox(height: 10),
                      _buildDetailRow('Người gửi:', email),
                      const SizedBox(height: 10),
                      _buildDetailRow('Thiết bị:', deviceInfo),
                      const SizedBox(height: 10),
                      _buildDetailRow('Thời gian:', formattedDate),
                      const SizedBox(height: 10),
                      _buildDetailRow('Trạng thái hiện tại:', status, isStatus: true),
                      const Divider(color: Color(0xFF334155), height: 30),
                      Text(
                        'Tiêu đề / Sự cố:',
                        style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Mô tả chi tiết / Stack Trace:',
                        style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: SelectableText(
                          description,
                          style: GoogleFonts.sourceCodePro(color: Colors.redAccent.shade100, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cập nhật trạng thái xử lý:',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusUpdateBtn(doc.id, 'Mới', Colors.orangeAccent, status, setDialogState),
                          _buildStatusUpdateBtn(doc.id, 'Đang xử lý', Colors.cyanAccent, status, setDialogState),
                          _buildStatusUpdateBtn(doc.id, 'Đã giải quyết', Colors.greenAccent, status, setDialogState),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Đóng', style: GoogleFonts.outfit(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusUpdateBtn(
    String docId,
    String targetStatus,
    Color color,
    String currentStatus,
    StateSetter setDialogState,
  ) {
    final isCurrent = currentStatus == targetStatus;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrent ? color : const Color(0xFF334155),
        foregroundColor: isCurrent ? Colors.black87 : Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () async {
        if (isCurrent) return;
        await FirebaseFirestore.instance.collection('bugs').doc(docId).update({
          'status': targetStatus,
        });
        setDialogState(() {
          // Cập nhật local state của dialog
        });
        setState(() {
          // Cập nhật dashboard state
        });
      },
      child: Text(targetStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false, bool isStatus = false}) {
    Color valColor = Colors.white70;
    if (isStatus) {
      if (value == 'Mới') valColor = Colors.orangeAccent;
      if (value == 'Đang xử lý') valColor = Colors.cyanAccent;
      if (value == 'Đã giải quyết') valColor = Colors.greenAccent;
    } else if (isBoldValue) {
      valColor = Colors.white;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: valColor,
              fontSize: 13,
              fontWeight: isBoldValue || isStatus ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 5: GỬI THÔNG BÁO & CHIẾN DỊCH
  // ==========================================
  Widget _buildCampaignsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildNotificationSenderFormCard()),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: _buildCampaignsHistoryCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildNotificationSenderFormCard(),
              const SizedBox(height: 24),
              _buildCampaignsHistoryCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildNotificationSenderFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Form(
        key: _notificationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gửi Thông Báo FCM',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Gửi thông báo đẩy đến tất cả các thiết bị Mobile đã đăng ký topic "reminder_journal"',
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
            ),
            const Divider(color: Color(0xFF334155), height: 30),
            
            // Notification Title
            TextFormField(
              controller: _notiTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tiêu đề thông báo',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Notification Body
            TextFormField(
              controller: _notiBodyController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nội dung thông báo',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập nội dung';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSendingNotification ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.pinkAccent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSendingNotification
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSendingNotification ? 'ĐANG GỬI...' : 'GỬI THÔNG BÁO HÀNG LOẠT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm gửi thông báo thật qua FCM v1 và lưu Firestore
  Future<void> _sendNotification() async {
    if (!_notificationFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingNotification = true;
    });

    final title = _notiTitleController.text.trim();
    final body = _notiBodyController.text.trim();

    try {
      // 1. Tính tổng số active users đăng ký trong hệ thống
      final activeUsersSnap = await FirebaseFirestore.instance.collection('active_users').get();
      final userEmails = <String>{};
      for (var doc in activeUsersSnap.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        if (email != null && email.isNotEmpty) {
          userEmails.add(email);
        }
      }
      final int sent = userEmails.isNotEmpty ? userEmails.length : 1;

      // 2. Tạo bản ghi chiến dịch gửi trên Firestore 'campaigns' ở trạng thái 'Đang gửi'
      final docRef = await FirebaseFirestore.instance.collection('campaigns').add({
        'title': title,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
        'targetTopic': 'reminder_journal',
        'status': 'Đang gửi',
        'sentCount': sent,
        'receivedCount': 0,
        'impressionsCount': 0,
        'openedCount': 0,
      });
      final campaignId = docRef.id;

      // 3. Gọi FCM service gửi thông báo đến topic reminder_journal thật kèm payload campaignId
      final success = await FcmSenderService.sendCustomNotification(
        title,
        body,
        topic: 'reminder_journal',
        campaignId: campaignId,
      );

      // 4. Cập nhật trạng thái chiến dịch trong Firestore
      await docRef.update({
        'status': success ? 'Thành công' : 'Lỗi gửi',
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi thông báo thành công đến các thiết bị di động!'), backgroundColor: Colors.green),
          );
          _notiTitleController.clear();
          _notiBodyController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gửi thông báo qua FCM thất bại. Vui lòng kiểm tra Service Account.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingNotification = false;
        });
      }
    }
  }

  Widget _buildCampaignsHistoryCard() {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử chiến dịch gửi tin',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Thống kê chiến dịch gửi thông báo và tỷ lệ Nhận / Xem của người dùng thực tế',
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
          ),
          const Divider(color: Color(0xFF334155), height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('campaigns').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                // Sắp xếp giảm dần theo thời gian gửi
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>?)?['sentAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>?)?['sentAt'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Text('Chưa có chiến dịch nào được gửi.', style: GoogleFonts.outfit(color: Colors.white60)),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data() as Map<String, dynamic>? ?? {};
                    final title = item['title'] ?? 'N/A';
                    final body = item['body'] ?? '';
                    final sentAt = item['sentAt'] as Timestamp?;
                    final formattedDate = sentAt != null
                        ? DateFormat('HH:mm dd/MM/yyyy').format(sentAt.toDate())
                        : 'N/A';

                    final int sent = item['sentCount'] ?? 0;
                    final int received = item['receivedCount'] ?? 0;
                    final int impressions = item['impressionsCount'] ?? 0;
                    final int opened = item['openedCount'] ?? 0;

                    final double receivedPct = sent > 0 ? (received / sent) : 0.0;
                    final double impressionsPct = received > 0 ? (impressions / received) : 0.0;
                    final double openedPct = impressions > 0 ? (opened / impressions) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.outfit(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(color: Color(0xFF1E293B), height: 20),
                          
                          // Hàng chỉ số Sends / Received / Impressions / Open count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCampaignStatCol('SENDS', sent.toString(), 'Gửi từ Firebase', Colors.white),
                              _buildCampaignStatCol('RECEIVED', received.toString(), '${(receivedPct * 100).toStringAsFixed(1)}% tỷ lệ', Colors.blueAccent),
                              _buildCampaignStatCol('IMPRESSIONS', impressions.toString(), '${(impressionsPct * 100).toStringAsFixed(1)}% hiển thị', Colors.greenAccent),
                              _buildCampaignStatCol('OPEN COUNT', opened.toString(), '${(openedPct * 100).toStringAsFixed(1)}% mở', Colors.orangeAccent),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Thanh so sánh tiến trình trực quan 4 tầng
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(3)),
                              ),
                              FractionallySizedBox(
                                widthFactor: receivedPct.clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.4), borderRadius: BorderRadius.circular(3)),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (receivedPct * impressionsPct).clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.4), borderRadius: BorderRadius.circular(3)),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (receivedPct * impressionsPct * openedPct).clamp(0.0, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent]),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignStatCol(String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  // ==========================================
  // WIDGET HỖ TRỢ CHUNG
  // ==========================================
  Widget _buildTabHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TextEditingController controller, String hintText, VoidCallback onSearchChanged) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60),
                  onPressed: () {
                    controller.clear();
                    onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) {
          onSearchChanged();
        },
      ),
    );
  }
}
