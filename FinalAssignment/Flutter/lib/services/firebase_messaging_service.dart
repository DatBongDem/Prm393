import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'firestore_service.dart';

// Đây là background handler phải đặt ở mức top-level (ngoài class)
// và được đánh dấu bằng @pragma('vm:entry-point') để chạy khi app ở background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    "Nhận thông báo chạy ngầm (Background Message ID): ${message.messageId}",
  );
  print("Nội dung tiêu đề: ${message.notification?.title}");
  print("Nội dung thân: ${message.notification?.body}");

  if (message.notification != null) {
    FirebaseMessagingService.addNotification(
      message.notification!.title ?? 'Thông báo nhắc nhở',
      message.notification!.body ?? '',
    );
  }

  // Tăng số lượng nhận và hiển thị thực tế cho chiến dịch
  await FirebaseMessagingService._incrementReceivedAndImpressionCount(message.data);
}

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Helper tăng số lượng Nhận và Hiển thị (Impressions) trên Firestore của Campaign
  static Future<void> _incrementReceivedAndImpressionCount(Map<String, dynamic> data) async {
    final campaignId = data['campaignId'] as String?;
    if (campaignId != null && campaignId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(campaignId)
            .update({
          'receivedCount': FieldValue.increment(1),
          'impressionsCount': FieldValue.increment(1),
        });
        print('FCM Tracker: Đã tăng receivedCount và impressionsCount cho campaign $campaignId');
      } catch (e) {
        print('FCM Tracker: Lỗi cập nhật số lượng nhận/hiển thị: $e');
      }
    }
  }

  // Helper tăng số lượng Mở (Open Count) trên Firestore của Campaign
  static Future<void> _incrementOpenedCount(Map<String, dynamic> data) async {
    final campaignId = data['campaignId'] as String?;
    if (campaignId != null && campaignId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(campaignId)
            .update({
          'openedCount': FieldValue.increment(1),
        });
        print('FCM Tracker: Đã tăng openedCount cho campaign $campaignId');
      } catch (e) {
        print('FCM Tracker: Lỗi tăng openedCount: $e');
      }
    }
  }

  // Luu lich su cac thong bao FCM nhan duoc trong phien chay hien tai.
  static final List<Map<String, String>> notificationHistory =
      <Map<String, String>>[];

  static final StreamController<List<Map<String, String>>>
  _notificationStreamController =
      StreamController<List<Map<String, String>>>.broadcast();

  static Stream<List<Map<String, String>>> get notificationStream =>
      _notificationStreamController.stream;

  static void addNotification(String title, String body) {
    notificationHistory.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toLocal().toString().substring(11, 16),
    });
    _notificationStreamController.add(List.from(notificationHistory));
  }

  Future<void> initialize() async {
    // 1. Xin quyền thông báo (đặc biệt cần thiết trên iOS và Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Quyền thông báo của người dùng: ${settings.authorizationStatus}');

    // 2. Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Tự động đăng ký topic nhận thông báo ngay khi khởi tạo
    try {
      await _messaging.subscribeToTopic('reminder_journal');
      print('FCM: Đã tự động đăng ký nhận thông báo qua topic reminder_journal.');
    } catch (e) {
      print('FCM: Lỗi tự động đăng ký topic: $e');
    }

    // 3. Lấy FCM Token phục vụ cho việc gửi thông báo test trực tiếp
    String? token = await _messaging.getToken();
    print('\n======================================================');
    print('FCM Token của thiết bị:');
    print(token);
    print('======================================================\n');

    // 4. Lắng nghe sự kiện thông báo khi app đang mở ở Foreground (tiền cảnh)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Nhận thông báo khi đang mở app (Foreground Message):');
      final title = message.notification?.title ?? 'Thông báo mới';
      final body = message.notification?.body ?? '';
      
      // 1. Lưu thông báo vào Firestore (bền vững)
      FirestoreService().addNotification(title, body);

      // 2. Lưu thông báo vào bộ nhớ RAM (tương thích ngược nếu có widget lắng nghe)
      addNotification(title, body);

      // 3. Tăng số lượng nhận và hiển thị thực tế
      _incrementReceivedAndImpressionCount(message.data);
      
      // Hiển thị SnackBar nổi trực quan thông qua GlobalKey
      MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.indigo.shade800,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.amber,
            onPressed: () {},
          ),
        ),
      );
    });

    // 5. Lắng nghe khi người dùng nhấn vào thông báo để mở app từ Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App được mở từ thông báo chạy ngầm (Message Opened App):');
      final title = message.notification?.title ?? 'Thông báo từ Background';
      final body = message.notification?.body ?? '';
      
      // 1. Lưu thông báo vào Firestore
      FirestoreService().addNotification(title, body);

      // 2. Lưu thông báo vào bộ nhớ RAM
      addNotification(title, body);

      // 3. Tăng số lượng xem/mở (openedCount) thực tế
      _incrementOpenedCount(message.data);
    });

    // 6. Xử lý trường hợp app đã bị tắt hẳn (Terminated) và được mở thông qua click vào thông báo
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App được khởi động từ trạng thái tắt hẳn thông qua thông báo:');
      final title = initialMessage.notification?.title ?? 'Thông báo từ Terminated';
      final body = initialMessage.notification?.body ?? '';
      
      // 1. Lưu thông báo vào Firestore
      FirestoreService().addNotification(title, body);

      // 2. Lưu thông báo vào bộ nhớ RAM
      addNotification(title, body);

      // 3. Tăng số lượng xem/mở (openedCount) thực tế
      _incrementOpenedCount(initialMessage.data);
    }
  }
}
