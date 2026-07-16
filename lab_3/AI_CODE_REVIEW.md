# AI-Assisted Code Review — Mục 9 (PRM393 Lab 03)

**Công cụ sử dụng**: Claude (Anthropic) kết hợp Dart Analyzer (`flutter analyze`).
**Phạm vi review**: toàn bộ mã nguồn `lib/` của dự án Lab 3.
**Quy trình**: (1) chạy phân tích tĩnh để phát hiện lỗi/cảnh báo → (2) AI đọc mã nguồn liên quan, đánh giá mức độ ảnh hưởng → (3) áp dụng bản sửa → (4) chạy lại phân tích tĩnh xác nhận cảnh báo đã hết.

Đề bài yêu cầu tối thiểu **3 phát hiện**; đợt review này tìm ra và xử lý **5 phát hiện**.

---

## Phát hiện 1 — Import trùng lặp (code smell)

* **Vị trí**: `lib/services/firebase_messaging_service.dart` (dòng 5–8)
* **Mã lỗi analyzer**: `duplicate_import` (×2)
* **Mô tả**: hai import `../main.dart` và `firestore_service.dart` bị lặp lại nguyên văn hai lần — dấu vết của việc merge nhánh `feature/notification`.
* **Ảnh hưởng**: không gây lỗi runtime nhưng là code smell, làm nhiễu cảnh báo khi build.
* **Cách sửa**: xóa hai dòng import trùng.

## Phát hiện 2 — Trường dữ liệu chết và listener thừa (dead code)

* **Vị trí**: `lib/screens/profile_screen.dart` (dòng 34–57)
* **Mã lỗi analyzer**: `unused_field`
* **Mô tả**: trường `_notifications` được cập nhật qua một `StreamSubscription` lắng nghe `FirebaseMessagingService.notificationStream`, nhưng **không còn nơi nào đọc giá trị này** — Trung tâm thông báo đã chuyển sang đọc trực tiếp từ Firestore bằng `StreamBuilder` (PR #25). Mỗi lần có thông báo mới, widget vẫn bị `setState()` vẽ lại vô ích.
* **Ảnh hưởng**: render thừa toàn màn hình Profile mỗi khi nhận thông báo; giữ tham chiếu listener không cần thiết.
* **Cách sửa**: xóa trường `_notifications`, subscription, cùng hai override `initState`/`dispose` chỉ tồn tại để phục vụ chúng; gỡ import `dart:async` và `firebase_messaging_service.dart` không còn dùng.

## Phát hiện 3 — Dùng `BuildContext` sau `await` (nguy cơ crash)

* **Vị trí**: `lib/screens/profile_screen.dart` — nút "Xóa tất cả" thông báo và nút xóa từng thông báo
* **Mã lỗi analyzer**: `use_build_context_synchronously` (×2)
* **Mô tả**: sau `await FirestoreService().clearAllNotifications()` / `deleteNotification()`, code gọi ngay `ScaffoldMessenger.of(context)`. Nếu người dùng rời màn hình trong lúc thao tác mạng đang chạy, `context` đã bị hủy → nguy cơ crash thực tế.
* **Ảnh hưởng**: lỗi tiềm ẩn khó tái hiện, đúng loại lỗi Crashlytics hay bắt được ngoài thực địa. (Cùng loại lỗi này từng được sửa ở Lab 2 tại `_openDoiLink`.)
* **Cách sửa**: thêm `if (!context.mounted) return;` ngay sau mỗi `await`, trước khi dùng `context`.

## Phát hiện 4 — Tệp cấu hình mẫu thiếu khóa bắt buộc (lỗi build cho người mới clone)

* **Vị trí**: `lib/config/firebase_config.example.dart`
* **Phát hiện bởi**: AI review khi đối chiếu tệp mẫu với nơi sử dụng
* **Mô tả**: `openalex_service.dart` đọc `FirebaseConfig.openAlexEmail`, nhưng tệp mẫu **không khai báo khóa này**. Ai tạo `firebase_config.dart` bằng cách copy tệp mẫu sẽ gặp lỗi biên dịch `undefined_getter` mà không hiểu vì sao.
* **Ảnh hưởng**: chặn hoàn toàn việc build với thành viên mới hoặc máy chấm bài.
* **Cách sửa**: bổ sung `static const String openAlexEmail = 'YOUR_EMAIL_HERE@fpt.edu.vn';` kèm chú thích vào tệp mẫu.

## Phát hiện 5 — Mã chết ở tầng màn hình (ghi nhận, chưa xử lý)

* **Vị trí**: `lib/screens/journal_screen.dart` (784 dòng), `lib/screens/trends_screen.dart`, `lib/screens/trends_detail_screen.dart`
* **Phát hiện bởi**: AI review khi dò đồ thị tham chiếu giữa các màn hình
* **Mô tả**: ba màn hình này không được điều hướng tới từ bất kỳ màn hình đang hoạt động nào — mã còn sót lại từ giai đoạn phát triển trước.
* **Ảnh hưởng**: tăng kích thước codebase và chi phí bảo trì; dễ gây nhầm lẫn khi đọc mã.
* **Cách xử lý**: **ghi nhận, chưa xóa** — cần cả nhóm xác nhận không còn kế hoạch dùng lại trước khi gỡ (tránh xóa nhầm tính năng đang phát triển dở của thành viên khác).

---

## Kết quả xác minh sau khi sửa

Chạy lại `flutter analyze lib`:

* `duplicate_import`: **0** (trước: 2)
* `unused_field`: **0** (trước: 1)
* `use_build_context_synchronously`: **0** (trước: 2)
* Các lỗi còn lại đều thuộc nhóm "thiếu `lib/config/firebase_config.dart`" — tệp bí mật nằm trong `.gitignore`, sẽ tự hết khi tạo tệp theo hướng dẫn build. Không phải lỗi mã nguồn.

> **Bằng chứng cho báo cáo**: chụp (1) trang này, (2) kết quả `flutter analyze` trước/sau khi sửa, (3) diff các commit sửa lỗi trên GitHub.
