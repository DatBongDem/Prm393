// Mục 8 — Test Case 2 (Tìm kiếm chủ đề) và Test Case 3 (Chi tiết bài báo).
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 2 – Topic Search ─────────────────────────────────────────────
  patrolTest(
    'TC2 - Tìm kiếm chủ đề hiển thị kết quả bài báo',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);

      await searchTopic($, kTestTopic);

      // Sau khi tìm, dashboard hiển thị các thẻ chỉ số phân tích của mẫu bài báo.
      // 'Top author' và 'Top journal' chỉ xuất hiện khi đã có kết quả.
      expect($('Top author').exists, true);
      expect($('Top journal').exists, true);
    },
  );

  // ── Test Case 3 – Publication Details ──────────────────────────────────────
  patrolTest(
    'TC3 - Mở một bài báo hiển thị thông tin chi tiết',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      await searchTopic($, kTestTopic);

      // Mở bài báo có sức ảnh hưởng nhất — thẻ này mang nhãn 'Top Citations'
      // và có sự kiện onTap điều hướng sang màn hình chi tiết.
      await $('Top Citations').scrollTo().tap();

      // Màn hình Chi tiết bài báo phải hiển thị tiêu đề màn và mục Abstract.
      await $(
        'Chi tiết bài báo',
      ).waitUntilVisible(timeout: const Duration(seconds: 20));
      await pauseForDataPreview($);
      expect($('Chi tiết bài báo').exists, true);
      expect($('Tóm tắt bài báo (Abstract)').exists, true);
    },
  );
}
