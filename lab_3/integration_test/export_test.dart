// Mục 8 — Test Case 9 (Xuất PDF và tải lên Firebase Storage).
import 'package:flutter_test/flutter_test.dart' show expect;
import 'package:patrol/patrol.dart';

import 'config.dart';

void main() {
  // ── Test Case 9 – PDF Export ───────────────────────────────────────────────
  // Yêu cầu: Firebase Storage đã được khởi tạo (Console → Storage → Get started)
  // và thiết bị có mạng. Việc tải lên có thể mất vài giây.
  patrolTest(
    'TC9 - Xuất báo cáo PDF và tải lên Firebase Storage thành công',
    config: kPatrolConfig,
    ($) async {
      await launchApp($);
      await ensureLoggedIn($);
      // Tìm một chủ đề để chắc chắn có dữ liệu bài báo cho báo cáo.
      await searchTopic($, kTestTopic);

      await openTab($, 'Profile');
      await $('Cá nhân').waitUntilVisible(timeout: const Duration(seconds: 20));

      // Nhấn nút xuất PDF & tải lên Storage.
      await $('Xuất PDF & Tải lên Firebase Storage').scrollTo().tap();

      // Khi tải lên thành công, giao diện hiển thị liên kết tải báo cáo.
      // Timeout rộng vì phải sinh PDF + upload lên Storage qua mạng.
      await $(
        'Báo cáo vừa xuất:',
      ).waitUntilVisible(timeout: const Duration(seconds: 90));
      await pauseForDataPreview($);
      expect($('Báo cáo vừa xuất:').exists, true);
    },
  );
}
