import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/publication.dart';
import '../services/fcm_sender_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_report_service.dart';

/// ViewModel cho màn hình Cá nhân (MVVM).
///
/// Gói toàn bộ nghiệp vụ Firebase của Profile: xuất báo cáo PDF lên Storage,
/// lịch sử báo cáo, trung tâm thông báo, đăng xuất và kiểm thử Crashlytics.
/// View chỉ quan sát [isExporting]/[pdfUrl] và hiển thị thông báo kết quả.
class ProfileViewModel extends ChangeNotifier {
  final FirebaseAnalyticsService analyticsService;
  final FirestoreService _firestoreService;

  ProfileViewModel({
    required this.analyticsService,
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _pdfUrl;
  String? get pdfUrl => _pdfUrl;

  /// Thông tin người dùng hiện tại cho phần header của màn hình.
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Stream lịch sử báo cáo PDF (đọc realtime từ collection pdf_reports).
  Stream<List<QueryDocumentSnapshot>> get pdfReportsStream =>
      _firestoreService.getPdfReportsStream();

  /// Stream danh sách thông báo đã nhận của user hiện tại.
  Stream<List<QueryDocumentSnapshot>> get notificationsStream =>
      _firestoreService.getNotificationsStream();

  /// Xuất báo cáo PDF cho [topic] rồi tải lên Firebase Storage và lưu
  /// siêu dữ liệu vào Firestore. Trả về null nếu thành công, ngược lại
  /// trả về thông báo lỗi để View hiển thị.
  Future<String?> exportPdfReport({
    required String topic,
    required List<Publication> publications,
  }) async {
    if (publications.isEmpty) {
      return 'Không có dữ liệu bài báo để xuất báo cáo.';
    }

    _isExporting = true;
    _pdfUrl = null;
    notifyListeners();

    analyticsService.logCustomEvent(
      name: 'export_pdf',
      parameters: {'topic': topic},
    );

    String? errorMessage;
    try {
      final uploadResult = await PdfReportService.generateAndUploadReport(
        topic: topic,
        publications: publications,
      );
      final url = uploadResult['url'];
      final fileName = uploadResult['fileName'];

      if (url != null && fileName != null) {
        await _firestoreService.savePdfReportInfo(
          topic: topic,
          url: url,
          fileName: fileName,
        );
        _pdfUrl = url;
      } else {
        throw Exception('Không nhận được thông tin phản hồi từ Storage.');
      }
    } catch (e) {
      debugPrint('Lỗi xuất và upload PDF: $e');
      errorMessage = 'Xuất báo cáo thất bại: $e';
    }

    _isExporting = false;
    notifyListeners();
    return errorMessage;
  }

  /// Xóa một báo cáo khỏi lịch sử Firestore lẫn tệp vật lý trên Storage.
  Future<void> deletePdfReport(String docId, String pdfUrl) =>
      _firestoreService.deletePdfReport(docId, pdfUrl);

  /// Xóa một thông báo đã nhận.
  Future<void> deleteNotification(String docId) =>
      _firestoreService.deleteNotification(docId);

  /// Xóa toàn bộ thông báo của user hiện tại.
  Future<void> clearAllNotifications() =>
      _firestoreService.clearAllNotifications();

  /// Đánh dấu một thông báo đã đọc.
  Future<void> markNotificationAsRead(String docId) =>
      _firestoreService.markNotificationAsRead(docId);

  /// Đăng xuất: ghi sự kiện Analytics, hủy đăng ký topic FCM rồi signOut.
  Future<void> signOut() async {
    analyticsService.logButtonClick(
      buttonId: 'logout_btn',
      screenName: 'Profile',
    );
    final email = FirebaseAuth.instance.currentUser?.email;
    analyticsService.logCustomEvent(
      name: 'logout',
      parameters: {'email': ?email},
    );

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('reminder_journal');
      debugPrint('FCM: Hủy đăng ký topic reminder_journal thành công.');
    } catch (e) {
      debugPrint('FCM: Lỗi hủy đăng ký topic: $e');
    }
    await FirebaseAuth.instance.signOut();
  }

  /// Gửi push thật "nhắc nhở viết nhật ký" qua FCM tới topic reminder_journal.
  Future<void> sendJournalReminderNotification() =>
      FcmSenderService.sendJournalReminderNotification();

  /// Gửi push thật tùy chỉnh qua FCM tới topic reminder_journal.
  Future<void> sendCustomNotification(String title, String body) =>
      FcmSenderService.sendCustomNotification(title, body);

  /// Kiểm thử Crashlytics: gây crash thật (fatal) sau khi lưu lỗi lên Firestore.
  void triggerFatalCrash() {
    analyticsService.logButtonClick(
      buttonId: 'simulate_crash_btn',
      screenName: 'Profile',
    );
    // Lưu thông tin crash giả lập lên Firestore trước để Admin có thể xem được
    FirestoreService().reportBug(
      title: 'Fatal Exception: java.lang.RuntimeException: Force Crash (Simulate Fatal)',
      description: 'MainActivity.java - line 151\nTriggered from Profile Screen Simulate Crash Button',
      deviceInfo: 'Simulated Fatal Crash Device',
      type: 'Crash (Fatal)',
    ).then((_) {
      print('ProfileVM: Đã lưu fatal crash lên Firestore. Gây sập ứng dụng...');
      FirebaseCrashlytics.instance.crash();
    }).catchError((err) {
      print('ProfileVM: Lỗi lưu Firestore: $err. Vẫn gây sập ứng dụng...');
      FirebaseCrashlytics.instance.crash();
    });
  }

  /// Kiểm thử Crashlytics: ghi nhận một lỗi được xử lý (non-fatal) và lưu lên Firestore.
  void recordHandledException() {
    analyticsService.logButtonClick(
      buttonId: 'simulate_handled_exception_btn',
      screenName: 'Profile',
    );
    // Lưu thông tin non-fatal crash lên Firestore
    FirestoreService().reportBug(
      title: 'Exception: Lỗi giả lập được xử lý bởi Crashlytics (Non-fatal error)',
      description: 'profile_viewmodel.dart - line 162\nTriggered from Profile Screen Simulate Handled Exception Button',
      deviceInfo: 'Simulated Non-Fatal Crash Device',
      type: 'Crash (Non-Fatal)',
    ).catchError((err) {
      print('ProfileVM: Lỗi lưu non-fatal crash lên Firestore: $err');
    });

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
    }
  }
}
