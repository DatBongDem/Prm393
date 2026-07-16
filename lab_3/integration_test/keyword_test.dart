// Mục 8 — Test Case 6 (Vào tab Keywords) và Test Case 7 (Chi tiết từ khóa).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 6 – Keywords Navigation ──────────────────────────────────────
  patrolTest(
    'TC6 - Tab Keywords hiển thị thống kê và danh sách từ khóa',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      // Tìm trước để có dữ liệu từ khóa (dù màn hình còn có phương án dự phòng OpenAlex).
      await searchTopic($, kTestTopic);
      await $('Top author').waitUntilVisible(timeout: const Duration(seconds: 40));

      await openTab($, 'Keywords');

      // Màn hình 'Xu hướng tìm kiếm' và danh sách từ khóa phổ biến.
      await $('Xu hướng tìm kiếm').waitUntilVisible(timeout: const Duration(seconds: 20));
      await $('Danh sách từ khóa phổ biến')
          .waitUntilVisible(timeout: const Duration(seconds: 20));
      expect($('Danh sách từ khóa phổ biến').exists, true);
    },
  );

  // ── Test Case 7 – Keyword Details ──────────────────────────────────────────
  patrolTest(
    'TC7 - Mở một từ khóa hiển thị phân tích chi tiết',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      await searchTopic($, kTestTopic);
      await $('Top author').waitUntilVisible(timeout: const Duration(seconds: 40));

      await openTab($, 'Keywords');
      await $('Danh sách từ khóa phổ biến')
          .waitUntilVisible(timeout: const Duration(seconds: 20));

      // Chạm vào từ khóa đầu tiên trong danh sách (ListTile).
      await $(ListTile).first.tap();

      // Màn hình Chi tiết từ khóa có 'Bộ lọc thời gian' và tab 'Bài báo liên quan'.
      await $('Bộ lọc thời gian').waitUntilVisible(timeout: const Duration(seconds: 30));
      expect($('Bộ lọc thời gian').exists, true);
      expect($('Bài báo liên quan').exists, true);
    },
  );
}
