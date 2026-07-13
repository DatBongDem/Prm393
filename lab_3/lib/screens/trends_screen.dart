import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firestore_service.dart';
import 'trends_detail_screen.dart';

class TrendsScreen extends StatelessWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;
  final FirestoreService _firestoreService = FirestoreService();

  TrendsScreen({
    Key? key,
    required this.analyticsService,
    required this.remoteConfigService,
  }) : super(key: key);

  void _viewDetails(BuildContext context, int totalActiveUsers) {
    analyticsService.logCustomEvent(
      name: 'view_trends_chart',
      parameters: {
        'chart_type': 'bar_chart',
        'total_active_users_recorded': totalActiveUsers,
      },
    );
    analyticsService.logButtonClick(
      buttonId: 'view_chart_details_btn',
      screenName: 'Trends',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrendsDetailScreen(
          remoteConfigService: remoteConfigService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = remoteConfigService.getPrimaryColor();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Trends',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Biểu đồ thống kê số lượng người dùng hoạt động hàng ngày (DAU) thực tế.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                // Real-time Chart Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getWeeklyActiveUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Lỗi tải biểu đồ: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                       final docs = snapshot.data?.docs ?? [];
                      
                      final now = DateTime.now();
                      // Ngày Thứ 2 đầu tuần này (00:00:00)
                      final mondayThisWeek = DateTime(now.year, now.month, now.day)
                          .subtract(Duration(days: now.weekday - 1));
                      // Ngày Chủ Nhật cuối tuần này (23:59:59)
                      final sundayThisWeek = mondayThisWeek
                          .add(const Duration(days: 7))
                          .subtract(const Duration(microseconds: 1));

                      // Khởi tạo danh sách đếm user độc nhất cho từng thứ trong tuần
                      // Key 1 (Monday) -> 7 (Sunday)
                      Map<int, Set<String>> dailyUniqueUsers = {
                        1: {}, // Thứ 2
                        2: {}, // Thứ 3
                        3: {}, // Thứ 4
                        4: {}, // Thứ 5
                        5: {}, // Thứ 6
                        6: {}, // Thứ 7
                        7: {}, // Chủ Nhật
                      };

                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final dateStr = data['date'] as String?;
                        final dayOfWeek = data['dayOfWeek'] as int?;
                        final userId = data['userId'] as String?;
                        
                        if (dateStr != null && dayOfWeek != null && userId != null) {
                          try {
                            final docDate = DateTime.parse(dateStr);
                            // Chỉ đếm nếu bản ghi nằm trong tuần này (từ Thứ 2 đến Chủ Nhật tuần này)
                            if (docDate.isAfter(mondayThisWeek.subtract(const Duration(seconds: 1))) &&
                                docDate.isBefore(sundayThisWeek.add(const Duration(seconds: 1)))) {
                              if (dailyUniqueUsers.containsKey(dayOfWeek)) {
                                dailyUniqueUsers[dayOfWeek]!.add(userId);
                              }
                            }
                          } catch (e) {
                            print('Lỗi parse ngày active user: $e');
                          }
                        }
                      }

                      // Tính số lượng DAU và tìm lượng DAU lớn nhất trong tuần để làm mốc tỷ lệ cột
                      Map<int, int> dauCount = {};
                      int maxDau = 1;
                      int totalRecords = 0;
                      
                      dailyUniqueUsers.forEach((day, users) {
                        dauCount[day] = users.length;
                        totalRecords += users.length;
                        if (users.length > maxDau) {
                          maxDau = users.length;
                        }
                      });

                      // Đặt mốc tỷ lệ tối thiểu là 5 để biểu đồ cân đối khi số lượng user ít (tránh 1 user cột cao 100%)
                      final double chartMax = maxDau < 5 ? 5.0 : maxDau.toDouble();

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Active Users Tracker',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tổng: $totalRecords lượt',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Bars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('Th2', dauCount[1]! / chartMax, primaryColor, count: dauCount[1]!),
                              _buildBar('Th3', dauCount[2]! / chartMax, primaryColor, count: dauCount[2]!),
                              _buildBar('Th4', dauCount[3]! / chartMax, primaryColor, count: dauCount[3]!),
                              _buildBar('Th5', dauCount[4]! / chartMax, primaryColor, count: dauCount[4]!),
                              _buildBar('Th6', dauCount[5]! / chartMax, primaryColor, count: dauCount[5]!),
                              _buildBar('T7', dauCount[6]! / chartMax, primaryColor, count: dauCount[6]!),
                              _buildBar('CN', dauCount[7]! / chartMax, primaryColor, count: dauCount[7]!),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewDetails(context, totalRecords),
                              icon: const Icon(Icons.analytics, color: Colors.white),
                              label: const Text('Xem Chi Tiết Phân Tích'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double fillPercentage, Color primaryColor, {required int count}) {
    return Column(
      children: [
        // Hiển thị số lượng DAU trên đỉnh cột
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: count > 0 ? primaryColor : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 120,
          width: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (count > 0)
                FractionallySizedBox(
                  heightFactor: fillPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
