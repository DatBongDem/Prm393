import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../viewmodels/analytics_provider.dart';
import '../viewmodels/profile_viewmodel.dart';

// View thuần theo MVVM: mọi nghiệp vụ Firebase (xuất PDF, thông báo,
// đăng xuất, Crashlytics) nằm trong ProfileViewModel; màn hình này chỉ
// quan sát trạng thái, gọi ViewModel và hiển thị SnackBar/hộp thoại.
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
  Future<void> _exportPdfReport(AnalyticsProvider provider) async {
    final topic = provider.hasSearchQuery
        ? provider.currentQuery
        : 'General Analytics';

    // Toàn bộ nghiệp vụ xuất PDF + upload Storage nằm trong ProfileViewModel.
    final errorMessage = await context.read<ProfileViewModel>().exportPdfReport(
      topic: topic,
      publications: provider.analysisPublications,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất báo cáo PDF và tải lên Storage thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDeleteReport(String docId, String pdfUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa báo cáo này khỏi lịch sử và Firebase Storage không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Hiển thị trạng thái xóa
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang xóa báo cáo...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              try {
                await context.read<ProfileViewModel>().deletePdfReport(
                  docId,
                  pdfUrl,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa báo cáo thành công!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Xóa thất bại: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _triggerCrash() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang giả lập crash... Ứng dụng sẽ tắt ngay lập tức.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.read<ProfileViewModel>().triggerFatalCrash();
  }

  void _triggerHandledException() {
    context.read<ProfileViewModel>().recordHandledException();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã ghi nhận lỗi xử lý thành công! Kiểm tra trên Firebase Console.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();
    final provider = context.watch<AnalyticsProvider>();
    final profileViewModel = context.watch<ProfileViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = profileViewModel.currentUser;
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
                    final welcomeMessage = widget.remoteConfigService
                        .getWelcomeMessage();
                    final maxJournals = widget.remoteConfigService
                        .getMaxJournals();
                    final maxKeywords = widget.remoteConfigService
                        .getMaxKeywords();

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
                            Icon(
                              Icons.sync,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
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

                // ==========================================
                // PHẦN GIẢ LẬP GỬI THÔNG BÁO FCM (DEMO)
                // ==========================================
                const Text(
                  'Giả Lập Gửi Thông Báo FCM (Demo)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Nhắc nhở viết'),
                        onPressed: () {
                          context.read<ProfileViewModel>().sendJournalReminderNotification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đang gửi thông báo nhắc nhở viết nhật ký...',
                              ),
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
                          context.read<ProfileViewModel>().sendCustomNotification(
                            'Xu hướng nghiên cứu mới 📈',
                            'Chủ đề AI và học sâu (Deep Learning) đang tăng trưởng 150% tuần này!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đang gửi thông báo xu hướng mới...',
                              ),
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
                          context.read<ProfileViewModel>().sendCustomNotification(
                            'Bài viết nổi bật tuần này ⭐',
                            'Nghiên cứu về thế hệ AI tiếp theo đã đạt hơn 1000 lượt tải!',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đang gửi thông báo bài báo hot...',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<ProfileViewModel>().signOut(),
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
              onPressed: context.watch<ProfileViewModel>().isExporting
                  ? null
                  : () => _exportPdfReport(provider),
              icon: context.watch<ProfileViewModel>().isExporting
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
          if (context.watch<ProfileViewModel>().pdfUrl != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Báo cáo vừa xuất:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(context.read<ProfileViewModel>().pdfUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                context.watch<ProfileViewModel>().pdfUrl!,
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
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Lịch sử báo cáo đã xuất (Tối đa 5 báo cáo gần nhất)',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: context.read<ProfileViewModel>().pdfReportsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Không thể tải lịch sử: ${snapshot.error}',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Chưa có báo cáo nào được lưu trữ.',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length > 5 ? 5 : reports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final data = report.data() as Map<String, dynamic>? ?? {};
                  final docId = report.id;
                  final topicName = data['topic'] ?? 'N/A';
                  final pdfUrl = data['pdfUrl'] ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;
                  
                  String timeStr = 'N/A';
                  if (createdAt != null) {
                    final dateTime = createdAt.toDate().toLocal();
                    timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}/${dateTime.year}';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.redAccent.shade200,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.open_in_new, color: primaryColor, size: 18),
                          tooltip: 'Mở PDF',
                          onPressed: pdfUrl.isEmpty
                              ? null
                              : () async {
                                  final uri = Uri.parse(pdfUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          tooltip: 'Xóa',
                          onPressed: () => _confirmDeleteReport(docId, pdfUrl),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCenter(bool isDark) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: context.read<ProfileViewModel>().notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                'Lỗi tải thông báo: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
              ),
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
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await context.read<ProfileViewModel>().clearAllNotifications();
                      if (!context.mounted) return;
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
                      minimumSize: const Size(60, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Xóa tất cả',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: docs.length > 5 ? 5 : docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final notif = doc.data() as Map<String, dynamic>;
                    final title = notif['title'] ?? '';
                    final body = notif['body'] ?? '';
                    final timestamp = notif['receivedAt'] as Timestamp?;

                    String timeStr = 'Đang nhận...';
                    if (timestamp != null) {
                      final date = timestamp.toDate();
                      timeStr =
                          '${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
                    }

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await context.read<ProfileViewModel>().deleteNotification(doc.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa thông báo.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
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
