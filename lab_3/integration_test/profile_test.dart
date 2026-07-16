// Mục 8 — Test Case 8 (Vào tab Profile).
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 8 – Profile Navigation ───────────────────────────────────────
  patrolTest(
    'TC8 - Tab Profile hiển thị thông tin người dùng',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);

      await openTab($, 'Profile');

      // Màn hình 'Cá nhân' hiển thị email tài khoản đang đăng nhập và các panel Firebase.
      await $('Cá nhân').waitUntilVisible(timeout: const Duration(seconds: 20));
      await pauseForDataPreview($);
      expect($('Cá nhân').exists, true);
      // Email tài khoản test phải xuất hiện trong phần thông tin người dùng.
      expect($(kTestEmail).exists, true);
      // Panel xuất báo cáo và Remote Config là bằng chứng các dịch vụ Firebase.
      expect($('Xuất PDF & Tải lên Firebase Storage').exists, true);
      expect($('Firebase Remote Config').exists, true);
    },
  );
}
