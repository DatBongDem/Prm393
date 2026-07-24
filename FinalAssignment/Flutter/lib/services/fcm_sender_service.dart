import '../viewmodels/profile_viewmodel.dart';

class FcmSenderService {

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
