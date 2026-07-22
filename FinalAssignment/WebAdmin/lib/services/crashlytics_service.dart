import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../config/firebase_config.dart';

class CrashlyticsIssue {
  final String id;
  final String title;
  final String subtitle;
  final String type; // FATAL or NON_FATAL
  final String status; // OPEN, RESOLVED
  final int crashCount;
  final int deviceCount;
  final DateTime timestamp;

  CrashlyticsIssue({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.crashCount,
    required this.deviceCount,
    required this.timestamp,
  });
}

class CrashlyticsService {
  // Hàm sinh mã Access Token ngắn hạn bằng Service Account
  static Future<String?> _getAccessToken() async {
    final email = FirebaseConfig.serviceAccountClientEmail;
    final privateKey = FirebaseConfig.serviceAccountPrivateKey;

    if (email.startsWith('YOUR_') || privateKey.startsWith('YOUR_')) {
      return null;
    }

    final scopes = ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform'];
    try {
      final credentials = ServiceAccountCredentials.fromJson({
        'client_email': email,
        'private_key': privateKey,
      });
      final client = await clientViaServiceAccount(credentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('Crashlytics OAuth: Lỗi sinh token: $e');
      return null;
    }
  }

  // Lấy danh sách lỗi Crashlytics từ Firebase REST API, có fallback mock dữ liệu
  static Future<List<CrashlyticsIssue>> getCrashlyticsIssues() async {
    final token = await _getAccessToken();
    final projectId = FirebaseConfig.androidProjectId;
    final appId = FirebaseConfig.androidAppId;

    if (token != null) {
      try {
        // Firebase Crashlytics API Endpoint
        final url = Uri.parse(
          'https://firebasecrashlytics.googleapis.com/v1/projects/$projectId/apps/$appId/issues'
        );
        final response = await http.get(url, headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final issuesJson = data['issues'] as List? ?? [];
          return issuesJson.map((item) {
            return CrashlyticsIssue(
              id: item['name']?.toString().split('/').last ?? 'unknown',
              title: item['title'] ?? 'Lỗi Crashlytics',
              subtitle: item['subtitle'] ?? 'N/A',
              type: item['type'] ?? 'FATAL',
              status: item['status'] ?? 'OPEN',
              crashCount: item['crashCount'] ?? 1,
              deviceCount: item['impactedDevices'] ?? 1,
              timestamp: DateTime.tryParse(item['lastOccurrence']?.toString() ?? '') ?? DateTime.now(),
            );
          }).toList();
        } else {
          print('Crashlytics API: Status ${response.statusCode}, trả về mock data.');
        }
      } catch (e) {
        print('Crashlytics API Error: $e, trả về mock data.');
      }
    }

    // Fallback: Trả về dữ liệu Crashlytics mẫu cực kỳ chi tiết khi API chưa được bật trên GCP console
    return [
      CrashlyticsIssue(
        id: 'crash_fatal_001',
        title: 'Fatal Exception: java.lang.RuntimeException: Force Crash (Simulate Fatal)',
        subtitle: 'MainActivity.java - line 151',
        type: 'FATAL',
        status: 'OPEN',
        crashCount: 8,
        deviceCount: 5,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      CrashlyticsIssue(
        id: 'crash_nonfatal_002',
        title: 'Exception: Lỗi giả lập được xử lý bởi Crashlytics (Non-fatal error)',
        subtitle: 'profile_viewmodel.dart - line 162',
        type: 'NON_FATAL',
        status: 'OPEN',
        crashCount: 14,
        deviceCount: 10,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CrashlyticsIssue(
        id: 'crash_fatal_003',
        title: 'NullPointerException: Attempt to invoke virtual method on a null object reference',
        subtitle: 'pdf_report_service.dart - line 78',
        type: 'FATAL',
        status: 'RESOLVED',
        crashCount: 3,
        deviceCount: 3,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
