import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Đây là background handler phải đặt ở mức top-level (ngoài class)
// và được đánh dấu bằng @pragma('vm:entry-point') để chạy khi app ở background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đảm bảo Firebase được khởi tạo trước khi sử dụng các dịch vụ của nó trong background isolate
  await Firebase.initializeApp();
  print("Nhận thông báo chạy ngầm (Background Message ID): ${message.messageId}");
  print("Nội dung tiêu đề: ${message.notification?.title}");
  print("Nội dung thân: ${message.notification?.body}");
}

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

    // 3. Lấy FCM Token phục vụ cho việc gửi thông báo test trực tiếp
    String? token = await _messaging.getToken();
    print('\n======================================================');
    print('FCM Token của thiết bị:');
    print(token);
    print('======================================================\n');

    // 4. Lắng nghe sự kiện thông báo khi app đang mở ở Foreground (tiền cảnh)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Nhận thông báo khi đang mở app (Foreground Message):');
      print('Tiêu đề: ${message.notification?.title}');
      print('Nội dung: ${message.notification?.body}');
      print('Dữ liệu kèm theo (Data): ${message.data}');
      
      // Bạn có thể xử lý hiển thị thông báo nội bộ ở đây (ví dụ: dùng flutter_local_notifications)
    });

    // 5. Lắng nghe khi người dùng nhấn vào thông báo để mở app từ Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App được mở từ thông báo chạy ngầm (Message Opened App):');
      print('Tiêu đề: ${message.notification?.title}');
      print('Dữ liệu kèm theo (Data): ${message.data}');
      
      // Bạn có thể điều hướng màn hình dựa trên dữ liệu thông báo ở đây
    });

    // 6. Xử lý trường hợp app đã bị tắt hẳn (Terminated) và được mở thông qua click vào thông báo
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App được khởi động từ trạng thái tắt hẳn thông qua thông báo:');
      print('Tiêu đề: ${initialMessage.notification?.title}');
      print('Dữ liệu kèm theo (Data): ${initialMessage.data}');
    }
  }
}
