// Mục 8 — Test Case 10 (Đọc và hiển thị giá trị Remote Config).
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 10 – Remote Config ───────────────────────────────────────────
  patrolTest(
    'TC10 - Hiển thị các giá trị Firebase Remote Config',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);

      await openTab($, 'Profile');
      await $('Cá nhân').waitUntilVisible(timeout: const Duration(seconds: 20));

      // Panel Remote Config hiển thị (ít nhất) hai khóa cấu hình theo yêu cầu đề.
      await $('Firebase Remote Config').scrollTo();
      expect($('max_journals').exists, true);
      expect($('max_keywords').exists, true);
      expect($('welcome_message').exists, true);
    },
  );
}
