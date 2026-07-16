// Mục 8 — Test Case 1 (Đăng nhập) và Test Case 11 (Đăng xuất).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 1 – Google Sign-In ──────────────────────────────────────────
  // Đăng nhập bằng Google cần thao tác trên hộp thoại chọn tài khoản NATIVE của
  // hệ điều hành, nên thiết bị/máy ảo phải có sẵn ít nhất một tài khoản Google.
  // Nếu môi trường không có, hãy dùng Test Case 1b (Email/Password) bên dưới.
  patrolTest(
    'TC1 - Đăng nhập bằng Google điều hướng tới Home',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await $('ĐĂNG NHẬP').waitUntilVisible(timeout: const Duration(seconds: 40));

      await $('Đăng nhập bằng Google').tap();

      // Chọn tài khoản Google đầu tiên trong hộp thoại native (chứa ký tự '@').
      await $.native.tap(Selector(textContains: '@'));

      // Xác minh đã vào Home.
      await $('Trang chủ').waitUntilVisible(timeout: const Duration(seconds: 40));
      expect($('Trang chủ').exists, true);
    },
  );

  // ── Test Case 1b – Email/Password (phương án chạy được không cần Google) ────
  patrolTest(
    'TC1b - Đăng nhập bằng Email/Mật khẩu điều hướng tới Home',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await $('ĐĂNG NHẬP').waitUntilVisible(timeout: const Duration(seconds: 40));

      await $(TextField).at(0).enterText(kTestEmail);
      await $(TextField).at(1).enterText(kTestPassword);
      await $('ĐĂNG NHẬP').tap();

      await $('Trang chủ').waitUntilVisible(timeout: const Duration(seconds: 40));
      expect($('Trang chủ').exists, true);
    },
  );

  // ── Test Case 11 – Logout ──────────────────────────────────────────────────
  patrolTest(
    'TC11 - Đăng xuất quay về màn hình Đăng nhập',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);

      await openTab($, 'Profile');
      await $('Cá nhân').waitUntilVisible();

      // Cuộn tới nút đăng xuất rồi nhấn.
      await $('ĐĂNG XUẤT TÀI KHOẢN').scrollTo().tap();

      // Xác minh đã quay về màn hình Đăng nhập.
      await $('ĐĂNG NHẬP').waitUntilVisible(timeout: const Duration(seconds: 20));
      expect($('ĐĂNG NHẬP').exists, true);
    },
  );
}
