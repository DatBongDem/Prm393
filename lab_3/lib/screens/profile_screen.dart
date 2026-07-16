import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_sender_service.dart';


class ProfileScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const ProfileScreen({
    Key? key,
    required this.analyticsService,
    required this.remoteConfigService,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFetching = false;
  // Điểm số sẽ được đếm trực tiếp dựa trên số lượng nhật ký thật của user nhân với 10!

  Future<void> _fetchNewConfig() async {
    setState(() {
      _isFetching = true;
    });

    widget.analyticsService.logButtonClick(
      buttonId: 'fetch_remote_config_btn',
      screenName: 'Profile',
    );

    // Thực hiện fetch dữ liệu Remote Config từ Firebase
    bool updated = await widget.remoteConfigService.fetchAndActivate();

    if (mounted) {
      // Rebuild lại toàn bộ cây widget để cập nhật Theme Color mới của ứng dụng
      MyApp.of(context)?.refreshApp();
    }

    setState(() {
      _isFetching = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated 
          ? 'Đã tải thành công cấu hình mới từ Firebase!' 
          : 'Cấu hình đã ở phiên bản mới nhất.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerCrash() {
    widget.analyticsService.logButtonClick(
      buttonId: 'simulate_crash_btn',
      screenName: 'Profile',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang giả lập crash... Ứng dụng sẽ tắt ngay lập tức.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Đợi 1 giây để snackbar hiển thị và log được flush trước khi crash
    Future.delayed(const Duration(seconds: 1), () {
      FirebaseCrashlytics.instance.crash(); // Lệnh kích hoạt crash ứng dụng
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();
    final welcomeMessage = widget.remoteConfigService.getWelcomeMessage();
    final requiredPoints = widget.remoteConfigService.getRequiredPoints();
    final bonusPoints = widget.remoteConfigService.getBonusPoints();

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cấu hình Remote Config và kiểm thử lỗi ứng dụng (Crashlytics).',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                // Profile Avatar Card
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: primaryColor, size: 50),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sinh viên PRM393',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'student@fpt.edu.vn',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Promotion Card (Using real journal entries count * 10 + bonusPoints for points!)
                StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: FirestoreService().getJournalEntriesStream(),
                  builder: (context, snapshot) {
                    final journalCount = snapshot.data?.length ?? 0;
                    final userPoints = bonusPoints + (journalCount * 10);
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.coffee, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Chương Trình Khuyến Mãi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bạn đang tích lũy được $userPoints điểm ($bonusPoints điểm thưởng + 10 điểm / bài viết).',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cần đạt $requiredPoints điểm để đổi ly cà phê miễn phí tiếp theo!',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: requiredPoints > 0 
                                  ? (userPoints / requiredPoints).clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: Colors.white24,
                              color: Colors.yellow,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),

                // Remote Config values display list
                const Text(
                  'Thông Số Remote Config Hiện Tại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildConfigTile(
                  icon: Icons.message,
                  label: 'welcome_message',
                  value: welcomeMessage,
                  primaryColor: primaryColor,
                ),
                _buildConfigTile(
                  icon: Icons.color_lens,
                  label: 'primary_color',
                  value: '#${primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  primaryColor: primaryColor,
                ),
                _buildConfigTile(
                  icon: Icons.military_tech,
                  label: 'required_points',
                  value: '$requiredPoints điểm',
                  primaryColor: primaryColor,
                ),
                _buildConfigTile(
                  icon: Icons.card_giftcard,
                  label: 'bonus_points',
                  value: '$bonusPoints điểm',
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 24),

                // Operations buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isFetching ? null : _fetchNewConfig,
                        icon: _isFetching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync, color: Colors.white),
                        label: const Text('Fetch Config'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _triggerCrash,
                        icon: const Icon(Icons.bug_report, color: Colors.white),
                        label: const Text('Simulate Crash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ==========================================
                // PHẦN GIẢ LẬP GỬI THÔNG BÁO FCM (DEMO)
                // ==========================================
                const SizedBox(height: 32),
                const Text(
                  'Giả Lập Gửi Thông Báo FCM (Demo)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bấm vào các nút dưới đây để hệ thống tự động đẩy thông báo từ máy chủ FCM về thiết bị này.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Nhắc nhở viết'),
                        onPressed: () {
                          FcmSenderService.sendJournalReminderNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang gửi thông báo nhắc nhở viết nhật ký...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.trending_up, size: 16),
                        label: const Text('Xu hướng mới'),
                        onPressed: () {
                          FcmSenderService.sendCustomNotification(
                            'Xu hướng nghiên cứu mới 📈',
                            'Chủ đề AI và học sâu (Deep Learning) đang tăng trưởng 150% tuần này!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang gửi thông báo xu hướng mới...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.star, size: 16),
                        label: const Text('Bài báo hot'),
                        onPressed: () {
                          FcmSenderService.sendCustomNotification(
                            'Bài viết nổi bật tuần này ⭐',
                            'Nghiên cứu về thế hệ AI tiếp theo đã đạt hơn 1000 lượt tải!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang gửi thông báo bài báo hot...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // PHẦN NOTIFICATION CENTER
                // ==========================================
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notification Center 🔔',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: FirestoreService().getNotificationsStream(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return TextButton(
                          onPressed: () async {
                            await FirestoreService().clearAllNotifications();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa tất cả thông báo.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Xóa tất cả'),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: FirestoreService().getNotificationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Lỗi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không có thông báo nào.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length > 5 ? 5 : docs.length, // Hiển thị tối đa 5 thông báo gần nhất
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Thông báo';
                        final body = data['body'] ?? '';
                        final timestamp = data['receivedAt'] as Timestamp?;

                        String timeStr = 'Đang nhận...';
                        if (timestamp != null) {
                          final date = timestamp.toDate();
                          timeStr =
                              '${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Icon(Icons.notifications, color: primaryColor, size: 20),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  timeStr,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () async {
                                await FirestoreService().deleteNotification(doc.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa thông báo.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      widget.analyticsService.logButtonClick(
                        buttonId: 'logout_btn',
                        screenName: 'Profile',
                      );
                      try {
                        await FirebaseMessaging.instance.unsubscribeFromTopic('reminder_journal');
                        print('FCM: Hủy đăng ký topic reminder_journal thành công do đăng xuất.');
                      } catch (e) {
                        print('FCM: Lỗi hủy đăng ký topic: $e');
                      }
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: Icon(Icons.logout, color: primaryColor),
                    label: Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
