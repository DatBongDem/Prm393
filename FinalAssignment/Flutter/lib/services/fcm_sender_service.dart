import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_config.dart';

/// Dịch vụ gửi thông báo đẩy (push) THẬT qua FCM HTTP v1 API.
///
/// App mobile tự đăng ký (subscribe) topic `reminder_journal` khi khởi tạo
/// (xem [FirebaseMessagingService.initialize]). Khi gọi các hàm dưới đây,
/// một thông báo thật sẽ được FCM đẩy tới mọi thiết bị đã đăng ký topic đó;
/// thiết bị nhận sẽ hiển thị push và lưu vào Firestore qua listener onMessage.
class FcmSenderService {
  /// Sinh Access Token OAuth2 ngắn hạn từ Service Account để gọi FCM v1.
  static Future<String?> _getAccessToken() async {
    final email = FirebaseConfig.serviceAccountClientEmail;
    final privateKey = FirebaseConfig.serviceAccountPrivateKey;
    final clientId = FirebaseConfig.serviceAccountClientId;

    if (email.isEmpty || privateKey.isEmpty || clientId.isEmpty) {
      debugPrint(
        'FCM Sender: Vui lòng cấu hình Service Account trong lib/config/firebase_config.dart',
      );
      return null;
    }

    // Chuẩn hóa Private Key: đổi ký tự "\n" thành ký tự xuống dòng thực tế.
    final formattedPrivateKey = privateKey.replaceAll('\\n', '\n');

    final credentials = ServiceAccountCredentials.fromJson({
      'type': 'service_account',
      'client_id': clientId,
      'private_key': formattedPrivateKey,
      'client_email': email,
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
      debugPrint('FCM Sender: Lỗi lấy Access Token từ Google OAuth2: $e');
      return null;
    }
  }

  /// Gửi thông báo nhắc nhở viết nhật ký (push thật) tới topic reminder_journal.
  static Future<void> sendJournalReminderNotification() async {
    await sendCustomNotification(
      'Nhắc nhở viết nhật ký 📝',
      'Hôm nay bạn chưa viết nhật ký. Hãy dành 1 phút ghi lại suy nghĩ của mình nhé!',
    );
  }

  /// Gửi thông báo tùy chỉnh (push thật) qua FCM HTTP v1 API tới [topic].
  ///
  /// Trả về true nếu FCM nhận yêu cầu thành công (HTTP 200), ngược lại false.
  static Future<bool> sendCustomNotification(
    String title,
    String body, {
    String topic = 'reminder_journal',
    String? campaignId,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      debugPrint(
        'FCM Sender (v1): Không thể gửi thông báo vì không có Access Token.',
      );
      return false;
    }

    final projectId = FirebaseConfig.androidProjectId;
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> messagePayload = {
      'topic': topic,
      'notification': {
        'title': title,
        'body': body,
      },
      'android': {
        'notification': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'sound': 'default',
        },
      },
    };

    if (campaignId != null) {
      messagePayload['data'] = {
        'campaignId': campaignId,
      };
    }

    final jsonBody = jsonEncode({'message': messagePayload});

    try {
      final response = await http.post(url, headers: headers, body: jsonBody);
      if (response.statusCode == 200) {
        debugPrint('FCM Sender (v1): Đã gửi thông báo "$title" thành công!');
        return true;
      } else {
        debugPrint(
          'FCM Sender (v1): Gửi thất bại mã ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('FCM Sender (v1): Đã xảy ra lỗi khi gửi request: $e');
      return false;
    }
  }
}
