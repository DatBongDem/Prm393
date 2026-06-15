# HƯỚNG DẪN BUILD VÀ CÀI ĐẶT APK LÊN THIẾT BỊ THẬT (ANDROID)

Tài liệu này hướng dẫn cách đóng gói ứng dụng **Journal Trend Analyzer** thành tệp APK ở chế độ Release (Tối ưu hóa và bảo mật) và cách cài đặt lên thiết bị Android để chấm điểm trên lớp.

---

## 1. Kiểm tra môi trường
Trước khi đóng gói, hãy chắc chắn rằng môi trường Flutter của bạn đã sẵn sàng bằng lệnh:
```bash
flutter doctor
```
*(Nếu tất cả các mục có tích xanh, bạn có thể tiếp tục. Các lỗi liên quan đến Xcode hoặc VS Code có thể bỏ qua nếu bạn chỉ build APK Android)*.

---

## 2. Quy trình đóng gói APK (Release Mode)

Mở Terminal tại thư mục gốc [lab_2](file:///d:/FPTU/Summer2026/PRM393/Prm393/lab_2) và chọn một trong hai phương pháp đóng gói dưới đây:

### Cách 1: Build file APK chung (Fat APK - Khuyên dùng khi copy cho nhiều máy khác nhau)
Lệnh này sẽ tạo ra một file APK duy nhất chứa mã máy cho tất cả cấu trúc chip phổ biến (arm64, armv7, x64).
```bash
flutter build apk --release
```
*   **Đường dẫn file đầu ra**: `build/app/outputs/flutter-apk/app-release.apk`
*   **Ưu điểm**: Chạy được trên mọi điện thoại Android.
*   **Nhược điểm**: Dung lượng file lớn hơn (thường khoảng 20-30MB).

### Cách 2: Build file APK tối ưu (Split per ABI - Khuyên dùng để giảm dung lượng file)
Lệnh này chia nhỏ và sinh ra các file APK riêng biệt phù hợp cho từng loại cấu trúc chip của điện thoại:
```bash
flutter build apk --split-per-abi
```
*   **Đường dẫn các file đầu ra**: `build/app/outputs/flutter-apk/`
    1.  `app-arm64-v8a-release.apk`: Dành cho các dòng điện thoại 64-bit hiện đại (Hầu hết thiết bị thật hiện nay dùng file này). **(Khuyên dùng)**
    2.  `app-armeabi-v7a-release.apk`: Dành cho các dòng điện thoại Android đời cũ 32-bit.
    3.  `app-x86_64-release.apk`: Dành cho các trình giả lập trên máy tính.
*   **Ưu điểm**: Dung lượng cực kỳ nhẹ (chỉ khoảng 8-15MB), cài đặt nhanh hơn.

---

## 3. Cách cài đặt APK lên thiết bị Android thật

Có 3 cách đơn giản để chuyển file APK và cài đặt lên điện thoại:

### Cách 1: Cài đặt trực tiếp qua cáp USB và công cụ ADB (Dành cho Developer)
1. Kết nối điện thoại Android với máy tính bằng cáp USB.
2. Trên điện thoại: Vào **Cài đặt** -> **Thông tin điện thoại** -> Ấn 7 lần vào **Số phiên bản (Build Number)** để kích hoạt *Tùy chọn nhà phát triển (Developer Options)*.
3. Vào *Tùy chọn nhà phát triển* -> Bật **Gỡ lỗi USB (USB Debugging)**.
4. Trên máy tính, chạy lệnh sau để cài đặt trực tiếp file APK:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Cách 2: Chia sẻ qua các ứng dụng Zalo, Google Drive, hoặc Telegram
1. Gửi file APK đã build từ máy tính lên Cloud (ví dụ: Google Drive hoặc truyền file qua Zalo/Telegram).
2. Mở điện thoại thật, tải file APK xuống.
3. Click vào file để bắt đầu cài đặt.
4. *Lưu ý*: Android sẽ hiện cảnh báo bảo mật vì ứng dụng tự phát triển chưa đẩy lên Google Play Store. Hãy chọn **"Vẫn cài đặt" (Install anyway)** và cấp quyền **"Cho phép cài đặt từ nguồn không xác định" (Allow from unknown sources)** nếu hệ thống yêu cầu.

### Cách 3: Copy trực tiếp qua giao thức MTP (USB Transfer)
1. Kết nối điện thoại với máy tính, chọn chế độ kết nối **Truyền file (MTP)**.
2. Copy file `app-release.apk` vào thư mục bất kỳ trên điện thoại (ví dụ: thư mục `Download`).
3. Mở ứng dụng **Trình quản lý tệp (File Manager)** trên điện thoại, tìm đến thư mục chứa file APK và nhấn cài đặt.

---

## 4. Các lưu ý quan trọng khi chấm bài trên lớp
*   **Đảm bảo kết nối mạng**: Điện thoại thật của bạn phải được kết nối Wi-Fi hoặc 3G/4G hoạt động bình thường, vì ứng dụng cần truy vấn dữ liệu từ API OpenAlex.
*   **File cấu hình môi trường**: Đảm bảo tệp `.env` đã được tạo và chứa đúng email để không bị giới hạn số lần tìm kiếm trong buổi chấm bài.
*   **Kiểm tra tính năng**: Trước khi lên chấm bài, hãy kiểm tra kỹ tính năng mở liên kết DOI. Bấm vào nút "Xem bài viết gốc" trên Detail Screen xem có nhảy ra trình duyệt web (Chrome/Samsung Internet) trên điện thoại hay không.
