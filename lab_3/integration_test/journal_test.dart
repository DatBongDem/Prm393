// Mục 8 — Test Case 4 (Vào tab Journals) và Test Case 5 (Chi tiết tạp chí).
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 4 – Journals Navigation ──────────────────────────────────────
  patrolTest(
    'TC4 - Tab Journals hiển thị thống kê và danh sách tạp chí',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      // Tìm trước một chủ đề để bảng xếp hạng có dữ liệu.
      await searchTopic($, kTestTopic);
      await $('Top author').waitUntilVisible(timeout: const Duration(seconds: 40));

      await openTab($, 'Journals');

      // Màn hình 'Phân tích' với 3 tab con.
      await $('Phân tích').waitUntilVisible(timeout: const Duration(seconds: 20));
      expect($('Top Tạp chí').exists, true);
      expect($('Top Tác giả').exists, true);

      // Mở tab con 'Top Tạp chí' để thấy danh sách xếp hạng tạp chí.
      await $('Top Tạp chí').tap();
      await $.pumpAndSettle();
    },
  );

  // ── Test Case 5 – Journal Details ──────────────────────────────────────────
  patrolTest(
    'TC5 - Mở một tạp chí hiển thị thông tin chi tiết',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      await searchTopic($, kTestTopic);
      await $('Top author').waitUntilVisible(timeout: const Duration(seconds: 40));

      await openTab($, 'Journals');
      await $('Top Tạp chí').waitUntilVisible(timeout: const Duration(seconds: 20));
      await $('Top Tạp chí').tap();
      await $.pumpAndSettle();

      // Chạm vào tạp chí đầu tiên trong danh sách (widget ListTile có icon menu_book).
      await $(#journal_rank_0).tap();

      // Màn hình Chi tiết tạp chí: tiêu đề bắt đầu bằng 'Tạp chí:' và có 'Tổng trích dẫn'.
      await $('Tổng trích dẫn').waitUntilVisible(timeout: const Duration(seconds: 20));
      expect($('Tổng trích dẫn').exists, true);
    },
  );
}
