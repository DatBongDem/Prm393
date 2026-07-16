import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/pdf_report_service.dart';
import '../state/analytics_provider.dart';

class ProfileScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const ProfileScreen({
    super.key,
    required this.analyticsService,
    required this.remoteConfigService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isExporting = false;
  String? _pdfUrl;
  late StreamSubscription<List<Map<String, String>>> _notificationSubscription;
  List<Map<String, String>> _notifications = List.from(
    FirebaseMessagingService.notificationHistory,
  );

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe sự kiện thông báo mới để cập nhật UI
    _notificationSubscription = FirebaseMessagingService.notificationStream
        .listen((list) {
          if (mounted) {
            setState(() {
              _notifications = list;
            });
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }


  Future<void> _exportPdfReport(AnalyticsProvider provider) async {
    final topic = provider.hasSearchQuery
        ? provider.currentQuery
        : 'General Analytics';
    final publications = provider.analysisPublications;

    if (publications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có dữ liệu bài báo để xuất báo cáo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _pdfUrl = null;
    });

    // Log Analytics event: export_pdf
    widget.analyticsService.logCustomEvent(
      name: 'export_pdf',
      parameters: {'topic': topic},
    );

    String? url;
    String? errorMessage;
    try {
      url = await PdfReportService.generateAndUploadReport(
        topic: topic,
        publications: publications,
      );
    } catch (e) {
      errorMessage = e.toString();
      print('Lỗi xuất và upload PDF: $e');
    }

    if (!mounted) return;

    setState(() {
      _isExporting = false;
      _pdfUrl = url;
    });

    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất báo cáo PDF và tải lên Storage thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xuất báo cáo thất bại: ${errorMessage ?? "Lỗi không xác định"}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

    Future.delayed(const Duration(seconds: 1), () {
      FirebaseCrashlytics.instance
          .crash(); // Kích hoạt lỗi sập app (fatal crash)
    });
  }

  void _triggerHandledException() {
    widget.analyticsService.logButtonClick(
      buttonId: 'simulate_handled_exception_btn',
      screenName: 'Profile',
    );

    try {
      throw Exception(
        'Lỗi giả lập được xử lý bởi Crashlytics (Non-fatal error)',
      );
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Nút nhấn kiểm thử lỗi xử lý',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã ghi nhận lỗi xử lý thành công! Kiểm tra trên Firebase Console.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user?.email?.split('@').first ?? 'Người dùng';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cá nhân',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cấu hình ứng dụng và quản lý các tính năng Firebase.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Avatar và thông tin User
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        backgroundImage: photoUrl == null || photoUrl.isEmpty
                            ? null
                            : NetworkImage(photoUrl),
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Icon(Icons.person, color: primaryColor, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? 'Chưa có email',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Panel Xuất Báo Cáo PDF (Storage)
                _buildReportExportPanel(provider, primaryColor, isDark),
                const SizedBox(height: 24),

                // 2. Panel Remote Config
                Text(
                  'Firebase Remote Config',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: widget.remoteConfigService,
                  builder: (context, _) {
                    final welcomeMessage =
                        widget.remoteConfigService.getWelcomeMessage();
                    final maxJournals =
                        widget.remoteConfigService.getMaxJournals();
                    final maxKeywords =
                        widget.remoteConfigService.getMaxKeywords();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConfigTile(
                          icon: Icons.message_outlined,
                          label: 'welcome_message',
                          value: welcomeMessage,
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildConfigTile(
                          icon: Icons.menu_book_outlined,
                          label: 'max_journals',
                          value: '$maxJournals tạp chí',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        _buildConfigTile(
                          icon: Icons.tag_outlined,
                          label: 'max_keywords',
                          value: '$maxKeywords từ khóa',
                          primaryColor: primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sync, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Tự động đồng bộ theo thời gian thực',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 3. Notification Center (FCM)
                Text(
                  'Trung tâm thông báo (FCM)',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNotificationCenter(isDark),
                const SizedBox(height: 24),

                // 4. Crashlytics & Đăng xuất
                Text(
                  'Hệ thống & Kiểm thử',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCrashlyticsActions(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      widget.analyticsService.logButtonClick(
                        buttonId: 'logout_btn',
                        screenName: 'Profile',
                      );
                      widget.analyticsService.logCustomEvent(
                        name: 'logout',
                        parameters: {
                          if (FirebaseAuth.instance.currentUser?.email != null)
                            'email': FirebaseAuth.instance.currentUser!.email!,
                        },
                      );
                      try {
                        await FirebaseMessaging.instance.unsubscribeFromTopic(
                          'reminder_journal',
                        );
                        print(
                          'FCM: Hủy đăng ký topic reminder_journal thành công do đăng xuất.',
                        );
                      } catch (e) {
                        print('FCM: Lỗi hủy đăng ký topic: $e');
                      }
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: Icon(Icons.logout, color: primaryColor),
                    label: Text(
                      'ĐĂNG XUẤT TÀI KHOẢN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  Widget _buildCrashlyticsActions() {
    final fatalButton = SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _triggerCrash,
        icon: const Icon(Icons.flash_on),
        label: const Text(
          'Lỗi Fatal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );

    final handledButton = SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _triggerHandledException,
        icon: const Icon(Icons.bug_report, color: Colors.redAccent),
        label: const Text(
          'Lỗi Non-Fatal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fatalButton, const SizedBox(height: 12), handledButton],
          );
        }

        return Row(
          children: [
            Expanded(child: fatalButton),
            const SizedBox(width: 12),
            Expanded(child: handledButton),
          ],
        );
      },
    );
  }

  Widget _buildReportExportPanel(
    AnalyticsProvider provider,
    Color primaryColor,
    bool isDark,
  ) {
    final topic = provider.hasSearchQuery
        ? provider.currentQuery
        : 'Danh sách bài báo chung';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo phân tích (PDF)',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chủ đề: $topic',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : () => _exportPdfReport(provider),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: const Text(
                'Xuất PDF & Tải lên Firebase Storage',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF10B981,
                ), // Màu xanh lục emerald
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_pdfUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Link tải báo cáo PDF:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(_pdfUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                _pdfUrl!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCenter(bool isDark) {
    if (_notifications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            'Không có thông báo mới nào.',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.blueAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] ?? '',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          notif['time'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
