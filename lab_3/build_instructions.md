# HƯỚNG DẪN BUILD VÀ CÀI ĐẶT APK LÊN THIẾT BỊ THẬT (ANDROID)

Hướng dẫn cấu hình Firebase, đóng gói ứng dụng **Lab 3** thành APK Release và cài lên thiết bị Android.

---

## 1. Kiểm tra môi trường

```bash
flutter doctor
```
*(Tất cả tích xanh là được. Lỗi Xcode/VS Code bỏ qua được nếu chỉ build APK Android.)*

---

## 2. ⚠️ Cấu hình bắt buộc trước khi build

Dự án **không biên dịch được nếu thiếu hai tệp bí mật** dưới đây. Cả hai nằm trong `.gitignore` nên **không có sẵn khi clone từ Git** — phải tự tạo.

### 2.1. Tệp `lib/config/firebase_config.dart`

Tệp bị thiếu phổ biến nhất; không có nó, build dừng ngay với lỗi `Couldn't resolve the package 'firebase_config.dart'`.

```bash
cp lib/config/firebase_config.example.dart lib/config/firebase_config.dart
```

Mở tệp vừa tạo và điền giá trị thật:

| Nhóm giá trị | Lấy ở đâu |
| :--- | :--- |
| `serviceAccountClientEmail`, `serviceAccountPrivateKey`, `serviceAccountClientId` | Firebase Console → **Project settings** → **Service accounts** → **Generate new private key** → copy từ tệp JSON |
| `androidApiKey`, `androidAppId`, `androidMessagingSenderId`, `androidProjectId`, `androidStorageBucket` | Tệp `google-services.json` (mục 2.2) |
| Nhóm `ios*` | Project settings → **Your apps** → ứng dụng iOS |

**Bổ sung thêm khóa email OpenAlex** (tệp mẫu chưa có nhưng mã nguồn có dùng):
```dart
static const String openAlexEmail = 'your_email@fpt.edu.vn';
```
Email này giúp OpenAlex xếp yêu cầu vào **Polite Pool**, giảm rủi ro bị giới hạn lượt gọi khi demo.

> **Private Key**: dán nguyên văn cả chuỗi kể cả ký tự `\n` — mã nguồn đã tự xử lý.

> **Bảo mật**: tuyệt đối **không commit** `firebase_config.dart`. Private Key cho phép gửi thông báo dưới danh nghĩa dự án của bạn — nếu lỡ đẩy lên Git, vào Console thu hồi khóa cũ và tạo khóa mới ngay.

### 2.2. Tệp `android/app/google-services.json`

Firebase Console → **Project settings** → **Your apps** → chọn ứng dụng Android (`applicationId` là **`com.example.lab_3`**) → tải về, đặt vào `android/app/`.

*Dùng dự án Firebase riêng thì nhanh nhất là chạy `flutterfire configure` — tự sinh cả `google-services.json` lẫn `firebase_options.dart`.*

### 2.3. Bật các dịch vụ trên Firebase Console

| Dịch vụ | Thao tác |
| :--- | :--- |
| **Authentication** | Bật **Email/Password** và **Google** |
| **Cloud Firestore** | Tạo database (Test mode khi demo) |
| **Storage** | Chạm **Get started** — bỏ qua thì tính năng xuất PDF sẽ thất bại |
| **Cloud Messaging** | Mặc định đã bật |
| **Crashlytics** | Bật trong mục Crashlytics |
| **Remote Config** | Tạo 4 tham số: `welcome_message`, `primary_color`, `max_journals`, `max_keywords` |

---

## 3. Đóng gói APK (Release Mode)

Mở Terminal tại thư mục gốc `lab_3`:

| Cách | Lệnh | Kết quả |
| :--- | :--- | :--- |
| **Script có sẵn** (khuyên dùng) | `.\build_apk.ps1` | `build/app/outputs/flutter-apk/lab3.apk` |
| **Fat APK** — chạy mọi máy, ~30-45MB | `flutter build apk --release` | `.../app-release.apk` |
| **Split per ABI** — nhẹ hơn nhiều | `flutter build apk --split-per-abi` | `app-arm64-v8a-release.apk` (máy 64-bit hiện đại — **khuyên dùng**), `app-armeabi-v7a-release.apk` (máy cũ), `app-x86_64-release.apk` (máy ảo) |

---

## 4. Cài đặt APK lên thiết bị thật

**Cách 1 — ADB qua cáp USB**: bật *Tùy chọn nhà phát triển* (Cài đặt → Thông tin điện thoại → ấn 7 lần vào **Số phiên bản**) → bật **Gỡ lỗi USB** → nối cáp và chạy:
```bash
adb install build/app/outputs/flutter-apk/lab3.apk
```

**Cách 2 — Zalo/Drive/Telegram**: gửi APK lên cloud, tải về máy, chạm để cài. Android cảnh báo vì app chưa lên Play Store → chọn **"Vẫn cài đặt"** và cấp quyền **"Cho phép cài đặt từ nguồn không xác định"**.

**Cách 3 — Copy qua MTP**: nối cáp, chọn **Truyền file (MTP)**, copy APK vào `Download`, mở **Trình quản lý tệp** trên điện thoại và chạm để cài.

---

## 5. ⚠️ Khai báo SHA-1 để Google Sign-In chạy trên bản Release

Lỗi rất dễ gặp: **đăng nhập Google chạy tốt ở Debug nhưng thất bại im lặng trên APK Release**, do Firebase chưa biết chứng chỉ ký của bản release.

1. Lấy SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Copy giá trị **SHA1** của variant tương ứng (`debug` và/hoặc `release`).
3. Firebase Console → **Project settings** → chọn ứng dụng Android → **Add fingerprint** → dán mã vào.
4. **Tải lại `google-services.json` mới**, thay tệp cũ trong `android/app/`, build lại.

---

## 6. Lưu ý khi chấm bài trên lớp

* **Mạng ổn định** — app cần mạng cho cả OpenAlex API lẫn toàn bộ dịch vụ Firebase.
* **Cấp quyền thông báo** ở lần mở đầu tiên (bắt buộc trên Android 13+ để demo FCM).
* **Chuẩn bị sẵn tài khoản demo** để không mất thời gian đăng ký khi đang trình bày.
* **Chạy thử trước kịch bản demo**: đăng nhập (cả Email và Google) → tìm kiếm chủ đề, kiểm tra Home/Journals/Keywords có dữ liệu → chip **Nhắc nhở viết** nhận được thông báo → **Xuất PDF** có liên kết tải và xuất hiện trong lịch sử → **Lỗi Non-Fatal** lên được Crashlytics Console → nút **Xem bài viết gốc** mở trình duyệt.
* **Demo Remote Config ấn tượng nhất** khi mở sẵn Firebase Console trên máy tính, đổi `primary_color` rồi **Publish changes** — app trên điện thoại đổi màu ngay trước mắt hội đồng.
* **Cẩn thận với nút Lỗi Fatal**: nó làm app sập thật. Chỉ nhấn khi cố ý trình diễn Crashlytics, nhớ mở lại app sau đó để báo cáo được gửi lên Console.
