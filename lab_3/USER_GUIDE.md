# HƯỚNG DẪN SỬ DỤNG: RESEARCH ANALYTICS + FIREBASE (LAB 3)

**Môn học**: PRM393 - Lập trình Thiết bị Di động
**Nhóm thực hiện**: Nhóm 01
**Phiên bản ứng dụng**: 1.0.0

Ứng dụng phân tích xu hướng bài báo khoa học (dữ liệu OpenAlex) tích hợp Firebase: đăng nhập, thông báo đẩy, cấu hình từ xa, báo cáo PDF đám mây và giám sát lỗi.

---

## 1. Chuẩn bị

| Yêu cầu | Chi tiết |
| :--- | :--- |
| Thiết bị | Android 8.0 trở lên, hoặc máy ảo có Google Play Services |
| Kết nối mạng | **Bắt buộc** — cần cho cả OpenAlex API và toàn bộ dịch vụ Firebase |
| Tài khoản | Email bất kỳ để đăng ký, hoặc tài khoản Google có sẵn trên máy |
| Quyền thông báo | Chạm **Cho phép** ở lần mở đầu tiên (bắt buộc trên Android 13+) |

> **Máy ảo**: Google Sign-In và FCM chỉ chạy trên máy ảo có **Google Play Services**; nếu không có, hãy dùng đăng nhập Email/Mật khẩu hoặc máy thật.

**Cài đặt**: xem [build_instructions.md](./build_instructions.md). Nếu chạy từ mã nguồn, dự án cần hai tệp bí mật không có trên Git (`lib/config/firebase_config.dart`, `android/app/google-services.json`) — **thiếu là không biên dịch được**.

---

## 2. Đăng nhập và Đăng ký

Màn hình đầu tiên là xác thực — **bắt buộc đăng nhập** mới vào được các tính năng chính.

* **Đăng ký**: chạm *"Chưa có tài khoản? Đăng ký tại đây"* → nhập Email, Mật khẩu (**tối thiểu 6 ký tự**) → **ĐĂNG KÝ**. Thành công sẽ tự vào Trang chủ.
* **Đăng nhập**: nhập Email, Mật khẩu → **ĐĂNG NHẬP**.
* **Google**: chạm **"Đăng nhập bằng Google"** và chọn tài khoản.

Lỗi thường gặp: *"Không tìm thấy tài khoản với email này"* (chưa đăng ký), *"Mật khẩu không chính xác"*, *"Email này đã được sử dụng"* (hãy đăng nhập thay vì đăng ký), *"Mật khẩu quá yếu"* (dưới 6 ký tự), *"Định dạng email không hợp lệ"*.

---

## 3. Tổng quan giao diện

| Tab | Chức năng chính |
| :--- | :--- |
| **Home** | Tìm kiếm chủ đề và xem dashboard phân tích |
| **Journals** | Xu hướng theo năm, Top Tạp chí, Top Tác giả |
| **Keywords** | Xu hướng từ khóa được cộng đồng tìm kiếm nhiều nhất |
| **Profile** | Tài khoản, xuất PDF, Remote Config, thông báo, kiểm thử lỗi, đăng xuất |

> **Màu chủ đạo** được điều khiển từ xa qua Remote Config và **có thể tự đổi ngay khi bạn đang dùng** — đây là hành vi thiết kế, không phải lỗi.

---

## 4. Hướng dẫn từng chức năng

### 4.1. Tab Home — Tìm kiếm và Dashboard

Mở lần đầu, ứng dụng tự tải sẵn một chủ đề mẫu. Để tìm chủ đề khác: chạm ô *"Tìm chủ đề nghiên cứu"*, gõ từ khóa (ví dụ `machine learning`) rồi nhấn phím **Tìm kiếm**. Ứng dụng tải **tối đa 80 bài báo** phù hợp nhất, sắp giảm dần theo lượt trích dẫn và dựng lại dashboard gồm: cỡ mẫu, trích dẫn trung bình, bài dẫn đầu citation, Top author, Top journal và biểu đồ xu hướng.

Chạm thẻ bài báo để xem chi tiết • vuốt từ trên xuống để tải lại • chạm chip lịch sử để tìm lại từ khóa cũ.

> Mỗi lượt tìm kiếm được ghi lên Firebase và góp vào bảng xếp hạng ở tab **Keywords**.

### 4.2. Tab Journals — Phân tích chuyên sâu

Ba tab con: **Xu hướng năm** (biểu đồ số công bố theo năm), **Top Tạp chí** (chạm để xem bài báo của tạp chí), **Top Tác giả** (chạm để xem hồ sơ). Banner cho biết đang **theo từ khóa** (nếu đã tìm ở Home) hay **xếp hạng chung** (mẫu nổi bật 10 năm gần đây).

> Số dòng bảng Top Tạp chí bị giới hạn bởi `max_journals` (mặc định 5), xem giá trị hiện tại ở tab Profile.

### 4.3. Tab Keywords — Xu hướng từ khóa cộng đồng

Thống kê từ khóa được tìm nhiều nhất **trong 7 ngày gần nhất**, lấy từ Firestore và **tự cập nhật realtime**. Banner cho biết dữ liệu đang lấy từ Firebase hay từ mẫu OpenAlex dự phòng (khi chưa có lượt tìm kiếm nào).

**Chạm một từ khóa** để mở Chi tiết từ khóa (3 tab: Bài báo liên quan, Xu hướng & Tạp chí, Xếp hạng Tác giả). Kéo **Bộ lọc thời gian** dạng thanh trượt để lọc theo năm — danh sách và biểu đồ cập nhật ngay lập tức.

### 4.4. Tab Profile — Trung tâm điều khiển Firebase

**a. Thông tin tài khoản** — ảnh đại diện, tên, email đang đăng nhập.

**b. Báo cáo phân tích (PDF)** — chạm **"Xuất PDF & Tải lên Firebase Storage"**: ứng dụng sinh báo cáo (thống kê tổng hợp + Top 10 bài báo), tải lên đám mây và hiện liên kết tải.
> Chưa có dữ liệu sẽ báo *"Không có dữ liệu bài báo để xuất báo cáo."* — hãy tìm kiếm ở tab Home trước.

**Lịch sử báo cáo đã xuất (tối đa 5 báo cáo gần nhất)** — nằm ngay dưới nút xuất, hiện tên chủ đề và thời gian xuất. Danh sách **tự cập nhật ngay** khi xuất báo cáo mới và **không mất khi tắt ứng dụng**. Mỗi dòng có nút **Mở PDF** (↗) và nút **Xóa** (thùng rác — có hộp thoại xác nhận, xóa khỏi **cả lịch sử lẫn Firebase Storage**, không hoàn tác được).

**c. Firebase Remote Config** — hiển thị giá trị đang có hiệu lực của `welcome_message`, `max_journals`, `max_keywords`. Bảng **tự đồng bộ realtime**: admin publish cấu hình mới trên Console thì giá trị ở đây và màu sắc toàn app đổi ngay, không cần khởi động lại.

**d. Giả lập gửi thông báo FCM** — ba chip **Nhắc nhở viết**, **Xu hướng mới**, **Bài báo hot** tự gửi thông báo về chính thiết bị. Đang mở app sẽ hiện SnackBar ở đáy màn hình; app chạy ngầm hoặc đã tắt sẽ hiện ở khay thông báo hệ thống.

**e. Trung tâm thông báo** — liệt kê thông báo đã nhận (lưu bền vững trên Firestore). Xóa từng cái hoặc **"Xóa tất cả"**.

**f. Hệ thống & Kiểm thử (Crashlytics)** — **Lỗi Non-Fatal**: ghi nhận lỗi mẫu, app vẫn chạy. **Lỗi Fatal**: ⚠️ **app sẽ SẬP sau 1 giây** — hành vi cố ý để kiểm thử; mở lại app thì báo cáo sẽ gửi lên Console.

**g. Đăng xuất** — hủy đăng ký nhận thông báo và quay về màn hình Đăng nhập.

### 4.5. Chi tiết bài viết

Hiển thị tiêu đề, năm, lượt trích dẫn, tạp chí, danh sách tác giả (**chạm tên** để xem hồ sơ), tóm tắt (Abstract) và nút mở liên kết **DOI** bằng trình duyệt.

---

## 5. Mẹo và lưu ý

* **Thống kê tính trên mẫu tối đa 80 bài** tiêu biểu nhất, không phải toàn bộ kho OpenAlex — đủ để nhận diện xu hướng nhưng không phải con số tuyệt đối của toàn ngành.
* **Từ khóa tiếng Anh cho kết quả tốt hơn nhiều** so với tiếng Việt.
* Dữ liệu OpenAlex **không lưu offline**; ngược lại thông báo, lịch sử tìm kiếm và lịch sử báo cáo được lưu bền vững trên Firestore.
* Trên một số máy Xiaomi/Oppo/Vivo, đừng vuốt xóa app khỏi đa nhiệm nếu muốn nhận thông báo khi app đã tắt.

---

## 6. Xử lý sự cố

| Hiện tượng | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| Không đăng nhập được bằng Google | Máy ảo thiếu Google Play Services, hoặc SHA-1 chưa khai báo | Dùng Email/Mật khẩu, hoặc máy thật (mục 5 của `build_instructions.md`) |
| Chạm chip FCM nhưng không nhận được thông báo | Chưa cấp quyền, hoặc Service Account chưa cấu hình | Bật quyền thông báo trong Cài đặt; kiểm tra `firebase_config.dart` |
| Xuất PDF lỗi hoặc quay vòng lâu rồi thất bại | Storage chưa khởi tạo, hoặc mất mạng | Firebase Console → Storage → **Get started**; kiểm tra mạng |
| "Không có dữ liệu bài báo để xuất báo cáo." | Chưa tìm kiếm chủ đề nào | Sang tab Home tìm một từ khóa rồi quay lại |
| Tab Keywords trống hoặc hiện dữ liệu OpenAlex | Firestore chưa có lượt tìm kiếm nào trong 7 ngày | Tìm kiếm vài lần ở tab Home rồi quay lại |
| Màu ứng dụng tự đổi | Admin đã publish `primary_color` mới | Đây là tính năng, không phải lỗi |
| App sập sau khi chạm nút đỏ ở Profile | Bạn vừa chạm **Lỗi Fatal** — kiểm thử Crashlytics | Mở lại app bình thường |
| Không tải được dữ liệu bài báo | Mất mạng hoặc OpenAlex không phản hồi | Kiểm tra mạng rồi chạm **Thử lại** |
