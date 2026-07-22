import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_config.dart';
import '../viewmodels/profile_viewmodel.dart';

class FcmSenderService {
  // Hàm sinh mã Access Token ngắn hạn bằng Service Account (OAuth2)
  static Future<String?> _getAccessToken() async {
    final email = FirebaseConfig.serviceAccountClientEmail;
    final privateKey = FirebaseConfig.serviceAccountPrivateKey;
    final clientId = FirebaseConfig.serviceAccountClientId;

    if (email == 'YOUR_SERVICE_ACCOUNT_EMAIL_HERE' ||
        privateKey == 'YOUR_SERVICE_ACCOUNT_PRIVATE_KEY_HERE' ||
        clientId == 'YOUR_SERVICE_ACCOUNT_CLIENT_ID_HERE') {
      print('FCM Sender: Vui lòng cấu hình Service Account trong lib/config/firebase_config.dart');
      return null;
    }

    // Định dạng lại Private Key (thay thế các ký tự gõ dòng \n bằng dấu xuống dòng thực tế)
    final formattedPrivateKey = privateKey.replaceAll('\\n', '\n');

    final credentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "client_id": clientId,
      "private_key": formattedPrivateKey,
      "client_email": email,
    });

    try {
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('FCM Sender: Lỗi lấy Access Token từ Google OAuth2: $e');
      return null;
    }
  }

  // Gửi thông báo nhắc nhở qua FCM HTTP v1 API
  static Future<void> sendJournalReminderNotification() async {
    await sendCustomNotification(
      'Nhắc nhở viết nhật ký 📝',
      'Hôm nay bạn chưa viết nhật ký. Hãy dành 1 phút ghi lại suy nghĩ của mình nhé!',
    );
  }

  // Gửi thông báo tùy chỉnh qua mô phỏng cục bộ (không qua FCM / Firestore)
  static Future<void> sendCustomNotification(String title, String body, {String? topic}) async {
    print('Local Notification Simulator: $title - $body');
    ProfileViewModel.addMockNotification(title, body);
  }
}
