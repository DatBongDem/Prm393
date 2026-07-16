# Patrol E2E Tests — Mục 8 (PRM393 Lab 03)

Bộ kiểm thử End-to-End tự động hóa bằng **Patrol**, phủ 11 test case theo yêu cầu Mục 8 của đề bài.

## Cấu trúc thư mục

```text
integration_test/
├── config.dart              # Hằng số tài khoản test + các hàm tiện ích dùng chung
├── authentication_test.dart # TC1 (Google), TC1b (Email/Password), TC11 (Logout)
├── publication_test.dart    # TC2 (Tìm kiếm), TC3 (Chi tiết bài báo)
├── journal_test.dart        # TC4 (Tab Journals), TC5 (Chi tiết tạp chí)
├── keyword_test.dart        # TC6 (Tab Keywords), TC7 (Chi tiết từ khóa)
├── profile_test.dart        # TC8 (Tab Profile)
├── export_test.dart         # TC9 (Xuất PDF + upload Storage)
└── remote_config_test.dart  # TC10 (Hiển thị Remote Config)
```

## Bảng ánh xạ 11 test case của đề bài

| Test case | Kịch bản | Xác minh (assert) | File |
| :--- | :--- | :--- | :--- |
| TC1 | Đăng nhập bằng Google | Điều hướng tới màn hình Home | authentication_test |
| TC1b | Đăng nhập Email/Password (dự phòng) | Điều hướng tới màn hình Home | authentication_test |
| TC2 | Tìm kiếm chủ đề | Dashboard hiện Top author / Top journal | publication_test |
| TC3 | Mở chi tiết bài báo | Hiện màn 'Chi tiết bài báo' + mục Abstract | publication_test |
| TC4 | Vào tab Journals | Hiện màn 'Phân tích' + 3 tab con | journal_test |
| TC5 | Mở chi tiết tạp chí | Hiện 'Tổng trích dẫn' của tạp chí | journal_test |
| TC6 | Vào tab Keywords | Hiện 'Danh sách từ khóa phổ biến' | keyword_test |
| TC7 | Mở chi tiết từ khóa | Hiện 'Bộ lọc thời gian' + tab 'Bài báo liên quan' | keyword_test |
| TC8 | Vào tab Profile | Hiện email tài khoản + panel Firebase | profile_test |
| TC9 | Xuất PDF + upload Storage | Hiện 'Link tải báo cáo PDF:' | export_test |
| TC10 | Đọc Remote Config | Hiện các khóa max_journals / max_keywords / welcome_message | remote_config_test |
| TC11 | Đăng xuất | Quay về màn hình 'ĐĂNG NHẬP' | authentication_test |

## Chuẩn bị trước khi chạy

1. **Điền tài khoản test** trong [`config.dart`](./config.dart): sửa `kTestEmail` và `kTestPassword` thành một tài khoản Email/Password thật đã bật trong Firebase Console → Authentication. Các test (trừ TC1) dùng tài khoản này để vào được màn hình chính.

2. **Bật các dịch vụ Firebase** cần cho test: Authentication (Email/Password + Google), Cloud Firestore, **Storage** (bắt buộc để TC9 chạy — Console → Storage → Get started), Remote Config.

3. **Thiết bị/máy ảo có mạng**. Riêng TC1 (Google Sign-In) cần máy đã đăng nhập sẵn một tài khoản Google; nếu không có, dùng TC1b để chứng minh luồng đăng nhập.

## Cài đặt và chạy

```bash
# 1. Cài dependency (nếu báo xung đột phiên bản patrol, chạy: flutter pub add 'dev:patrol')
flutter pub get

# 2. Cài Patrol CLI (chỉ cần một lần trên máy)
dart pub global activate patrol_cli

# 3. Kiểm tra môi trường Patrol
patrol doctor

# 4. Chạy toàn bộ test trên thiết bị/emulator đang kết nối
patrol test

# Chạy riêng một nhóm test:
patrol test --target integration_test/authentication_test.dart
```

## Bằng chứng cần nộp (theo Mục 8 & 10 của đề)

Sau khi chạy `patrol test`, chụp lại để đưa vào báo cáo:
- Ảnh mã nguồn test (các file trong thư mục này).
- Ảnh quá trình chạy test trên terminal / thiết bị.
- Ảnh bảng kết quả (số test pass/fail Patrol in ra cuối phiên).

## Ghi chú kỹ thuật

- **Đăng nhập Google (TC1)** dùng `$.native.tap()` để thao tác trên hộp thoại chọn tài khoản của hệ điều hành — đây là phần khó tự động hóa nhất và phụ thuộc môi trường. TC1b (Email/Password) là phương án ổn định luôn chạy được.
- Mỗi Patrol test khởi động lại ứng dụng độc lập, nên hàm `ensureLoggedIn()` tự đăng nhập ở đầu mỗi test cần trạng thái đã đăng nhập.
- Timeout được đặt rộng (30–60s) vì test gọi mạng thật tới OpenAlex API và Firebase.
