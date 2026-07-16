// Cấu hình và các hàm tiện ích dùng chung cho toàn bộ Patrol E2E test (Mục 8).
//
// TRƯỚC KHI CHẠY TEST: điền tài khoản thật đã tạo trên Firebase Authentication.
// Các test (trừ đăng nhập Google) dùng tài khoản Email/Mật khẩu này để vào được
// màn hình chính, vì đăng nhập Google cần thao tác native khó tự động hóa ổn định.
import 'package:flutter/material.dart';
import 'package:lab_3/main.dart' as app;
import 'package:patrol/patrol.dart';

/// Tài khoản test — HÃY THAY bằng tài khoản Email/Password thật của bạn
/// đã bật trong Firebase Console → Authentication.
const String kTestEmail = 'test@fpt.edu.vn';
const String kTestPassword = '123456';

/// Từ khóa dùng cho các kịch bản tìm kiếm.
const String kTestTopic = 'machine learning';

/// Cấu hình mặc định cho patrolTest (timeout rộng vì có gọi mạng Firebase + OpenAlex).
final PatrolTesterConfig kPatrolConfig = PatrolTesterConfig(
  settleTimeout: const Duration(seconds: 30),
);

/// Khởi động ứng dụng thật (gọi main() để Firebase được khởi tạo đầy đủ).
Future<void> launchApp(PatrolIntegrationTester $) async {
  app.main();
  // Không await main() vì kiểu trả về là void; thay vào đó chờ UI thực sự xuất hiện.
  await $.pump(const Duration(seconds: 3));
}

/// Đảm bảo đang ở màn hình Home. Nếu app đang ở màn Đăng nhập thì tự đăng nhập
/// bằng Email/Mật khẩu. Dùng ở đầu mọi test cần trạng thái đã đăng nhập.
Future<void> ensureLoggedIn(PatrolIntegrationTester $) async {
  // Chờ tối đa 40s cho tới khi thấy Home ('Trang chủ') hoặc màn Đăng nhập ('ĐĂNG NHẬP').
  await _waitForEither($, 'Trang chủ', 'ĐĂNG NHẬP',
      timeout: const Duration(seconds: 40));

  if ($('Trang chủ').exists) return; // Đã đăng nhập sẵn (session còn lưu).

  // Đang ở màn Đăng nhập → nhập tài khoản test.
  await $(TextField).at(0).enterText(kTestEmail); // Ô Email
  await $(TextField).at(1).enterText(kTestPassword); // Ô Mật khẩu
  await $('ĐĂNG NHẬP').tap();

  // Chờ điều hướng sang Home sau khi Firebase xác thực xong.
  await $('Trang chủ').waitUntilVisible(timeout: const Duration(seconds: 40));
}

/// Mở một tab ở Bottom Navigation Bar theo nhãn ('Home'/'Journals'/'Keywords'/'Profile').
Future<void> openTab(PatrolIntegrationTester $, String label) async {
  await $(label).tap();
  await $.pumpAndSettle();
}

/// Thực hiện tìm kiếm một chủ đề tại màn hình Home.
Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  final searchField = $(#dashboard_topic_search);
  await searchField.enterText(topic);
  await $.tester.testTextInput.receiveAction(TextInputAction.search);
  await $.pumpAndSettle();
}

/// Chờ cho tới khi một trong hai chuỗi văn bản xuất hiện trên màn hình.
Future<void> _waitForEither(
  PatrolIntegrationTester $,
  String textA,
  String textB, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await $.pump(const Duration(milliseconds: 500));
    if ($(textA).exists || $(textB).exists) return;
  }
}
