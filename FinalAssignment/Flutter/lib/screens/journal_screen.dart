import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_sender_service.dart';

class JournalScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const JournalScreen({
    super.key,
    required this.analyticsService,
    required this.remoteConfigService,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _reminderTimer;
  StreamSubscription<List<QueryDocumentSnapshot>>? _journalSubscription;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Đăng ký nhận thông báo từ topic nhắc nhở
    FirebaseMessaging.instance.subscribeToTopic('reminder_journal').then((_) {
      print('FCM: Đăng ký thành công topic reminder_journal');
    });

    // Lắng nghe danh sách nhật ký thời gian thực để bật/tắt nhắc nhở
    _journalSubscription = _firestoreService.getJournalEntriesStream().listen((
      docs,
    ) {
      final now = DateTime.now();
      // Lọc các nhật ký được viết trong ngày hôm nay
      final todayDocs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp == null) return true; // Bản ghi mới tạo chưa đồng bộ xong
        final date = timestamp.toDate();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).toList();

      if (todayDocs.isEmpty) {
        _startReminderTimer();
      } else {
        _stopReminderTimer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _journalSubscription?.cancel();
    _reminderTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lifecycleState = state;
    });
    print('FCM Reminder: Trạng thái vòng đời App thay đổi -> $state');
  }

  void _startReminderTimer() {
    // Nếu Timer đang hoạt động thì không tạo thêm
    if (_reminderTimer != null && _reminderTimer!.isActive) return;

    print(
      'FCM Reminder: Bật Timer nhắc nhở định kỳ vì chưa có nhật ký hôm nay.',
    );
    // Tự động gửi thông báo nhắc nhở đầu tiên ngay khi kích hoạt (chỉ gửi khi app chạy ngầm)
    if (_lifecycleState != AppLifecycleState.resumed) {
      FcmSenderService.sendJournalReminderNotification();
    } else {
      print(
        'FCM Reminder: App đang hiển thị (Foreground), bỏ qua gửi thông báo tức thời.',
      );
    }

    // Thiết lập lặp lại định kỳ mỗi 1 phút để test trực quan
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      print('FCM Reminder: Đang quét và kiểm tra gửi thông báo nhắc nhở...');
      // Chỉ gửi khi app đang ở background/chạy ngầm
      if (_lifecycleState != AppLifecycleState.resumed) {
        FcmSenderService.sendJournalReminderNotification();
      } else {
        print(
          'FCM Reminder: App đang hiển thị (Foreground), không gửi thông báo nhắc nhở.',
        );
      }
    });
  }

  void _stopReminderTimer() {
    if (_reminderTimer != null) {
      print('FCM Reminder: Tắt Timer nhắc nhở vì hôm nay đã có nhật ký.');
      _reminderTimer!.cancel();
      _reminderTimer = null;
    }
  }

  bool _isCreatedToday(Timestamp? timestamp) {
    if (timestamp == null) return true;
    final date = timestamp.toDate();
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _addJournal(String title, String content) async {
    try {
      // 1. Lưu bản ghi lên Cloud Firestore
      await _firestoreService.addJournalEntry(title, content);

      // 2. Gửi sự kiện ghi nhật ký lên Firebase Analytics
      widget.analyticsService.logCustomEvent(
        name: 'create_journal',
        parameters: {
          'title_length': title.length,
          'content_length': content.length,
          'source': 'firestore',
        },
      );
      widget.analyticsService.logButtonClick(
        buttonId: 'add_journal_btn',
        screenName: 'Journal',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu nhật ký thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editJournal(String docId, String title, String content) async {
    try {
      // 1. Cập nhật bản ghi trên Cloud Firestore
      await _firestoreService.updateJournalEntry(docId, title, content);

      // 2. Gửi sự kiện cập nhật lên Firebase Analytics
      widget.analyticsService.logCustomEvent(
        name: 'update_journal',
        parameters: {
          'title_length': title.length,
          'content_length': content.length,
          'source': 'firestore',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật nhật ký thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteJournal(String docId) async {
    try {
      // 1. Xóa bản ghi trên Cloud Firestore
      await _firestoreService.deleteJournalEntry(docId);

      // 2. Gửi sự kiện xóa lên Firebase Analytics
      widget.analyticsService.logCustomEvent(
        name: 'delete_journal',
        parameters: {'source': 'firestore'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa nhật ký thành công!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddJournalBottomSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final primaryColor = widget.remoteConfigService.getPrimaryColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Thêm Nhật Ký Mới',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Nhập tiêu đề nhật ký...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Nhập nội dung nhật ký...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng nhập đầy đủ tiêu đề và nội dung!',
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _addJournal(title, content);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lưu Nhật Ký',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditJournalBottomSheet(
    String docId,
    String currentTitle,
    String currentContent,
    Timestamp? timestamp,
  ) {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);
    final primaryColor = widget.remoteConfigService.getPrimaryColor();
    final bool isToday = _isCreatedToday(timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chi Tiết Nhật Ký',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isToday) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade800,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhật ký từ các ngày trước có thể chỉnh sửa nhưng không thể xóa.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Nhập tiêu đề nhật ký...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Nhập nội dung nhật ký...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isToday) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          // Hiển thị dialog xác nhận xóa
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa bản ghi nhật ký này không?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Đóng dialog
                                    Navigator.pop(context); // Đóng bottom sheet
                                    _deleteJournal(docId);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: isToday ? 3 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isEmpty || content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng nhập đầy đủ tiêu đề và nội dung!',
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _editJournal(docId, title, content);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cập Nhật',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddJournalBottomSheet,
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhật ký của tôi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ghi lại những suy nghĩ và hoạt động hàng ngày của bạn.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lịch sử nhật ký',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Danh sách nhật ký từ Firestore (StreamBuilder)
                Expanded(
                  child: StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: _firestoreService.getJournalEntriesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Đã xảy ra lỗi: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        );
                      }

                      final docs = snapshot.data ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_note,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có bản ghi nhật ký nào.\nHãy nhấn nút + để tạo mới!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        padding: const EdgeInsets.only(
                          bottom: 80,
                        ), // Chừa khoảng trống cho FAB
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? 'Không có tiêu đề';
                          final content = data['content'] ?? '';
                          final timestamp = data['createdAt'] as Timestamp?;

                          // Định dạng ngày giờ đơn giản
                          String dateStr = 'Đang đồng bộ...';
                          if (timestamp != null) {
                            final date = timestamp.toDate();
                            dateStr =
                                '${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            color: Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showEditJournalBottomSheet(
                                doc.id,
                                title,
                                content,
                                timestamp,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.wb_sunny_outlined,
                                      color: primaryColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            content,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
}
