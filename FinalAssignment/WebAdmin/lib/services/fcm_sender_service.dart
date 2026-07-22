import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_config.dart';

class FcmSenderService {
  // Hàm sinh mã Access Token ngắn hạn bằng Service Account (OAuth2)
  static Future<String?> _getAccessToken() async {
    final email = FirebaseConfig.serviceAccountClientEmail;
    final privateKey = FirebaseConfig.serviceAccountPrivateKey;
    final clientId = FirebaseConfig.serviceAccountClientId;

    if (email.isEmpty || privateKey.isEmpty || clientId.isEmpty) {
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

  // Gửi thông báo tùy chỉnh qua FCM HTTP v1 API tới topic reminder_journal
  // Gửi thông báo tùy chỉnh qua FCM HTTP v1 API tới topic reminder_journal kèm theo data payload
  static Future<bool> sendCustomNotification(String title, String body, {String topic = 'reminder_journal', String? campaignId}) async {
    final token = await _getAccessToken();
    if (token == null) {
      print('FCM Sender (v1): Không thể gửi thông báo vì không có Access Token.');
      return false;
    }

    final projectId = FirebaseConfig.androidProjectId;
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
    
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
      'webpush': {
        'notification': {
          'title': title,
          'body': body,
          'icon': 'favicon.png',
        }
      },
      'android': {
        'priority': 'high', // Độ ưu tiên cao nhất để hiển thị bên ngoài app khi tắt app
        'notification': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'sound': 'default',
          'channel_id': 'high_importance_channel', // Khớp với cấu hình trong AndroidManifest.xml
        }
      },
      'apns': {
        'headers': {
          'apns-priority': '10', // APNS độ ưu tiên cao nhất cho iOS
        },
        'payload': {
          'aps': {
            'sound': 'default',
            'badge': 1,
          }
        }
      }
    };

    if (campaignId != null) {
      messagePayload['data'] = {
        'campaignId': campaignId,
      };
    }

    final jsonBody = jsonEncode({
      'message': messagePayload
    });

    try {
      final response = await http.post(url, headers: headers, body: jsonBody);
      if (response.statusCode == 200) {
        print('FCM Sender (v1): Đã gửi yêu cầu thông báo "$title" thành công!');
        return true;
      } else {
        print('FCM Sender (v1): Gửi thất bại với mã lỗi ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('FCM Sender (v1): Đã xảy ra lỗi khi gửi request: $e');
      return false;
    }
  }
}
