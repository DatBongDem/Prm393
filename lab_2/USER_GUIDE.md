# HƯỚNG DẪN SỬ DỤNG: JOURNAL TREND ANALYZER (LAB 2)

**Môn học**: PRM393 - Lập trình Thiết bị Di động
**Nhóm thực hiện**: Nhóm 01
**Phiên bản ứng dụng**: 1.0.0

Tài liệu này hướng dẫn người dùng cuối sử dụng ứng dụng **Journal Trend Analyzer** — ứng dụng tìm kiếm và phân tích xu hướng bài báo khoa học dựa trên dữ liệu OpenAlex.

> Cần đóng gói APK và cài lên điện thoại? Xem tài liệu riêng: [build_instructions.md](./build_instructions.md).

---

## 1. Chuẩn bị trước khi sử dụng

| Yêu cầu | Chi tiết |
| :--- | :--- |
| Thiết bị | Điện thoại Android (khuyên dùng Android 8.0 trở lên) hoặc máy ảo Android |
| Kết nối mạng | **Bắt buộc**. Toàn bộ dữ liệu được tải trực tiếp từ OpenAlex API, ứng dụng không có dữ liệu offline |
| Tệp `.env` | Chứa email liên hệ để OpenAlex xếp yêu cầu vào Polite Pool (xem mục 2) |

---

## 2. Cài đặt và khởi chạy

### Cách 1: Cài đặt bằng file APK (dành cho người dùng thông thường)
Xem chi tiết trong [build_instructions.md](./build_instructions.md). Sau khi cài xong, mở ứng dụng **Journal Trend Analyzer** từ màn hình chính của điện thoại.

### Cách 2: Chạy trực tiếp từ mã nguồn (dành cho người chấm bài / lập trình viên)

1. Mở Terminal tại thư mục `lab_2`.
2. Tạo tệp `.env` từ tệp mẫu `.env.example` và điền email liên hệ:
   ```bash
   cp .env.example .env
   ```
   Nội dung tệp `.env`:
   ```text
   OPENALEX_EMAIL=your_email@fpt.edu.vn
   ```
   *Nếu bỏ qua bước này, ứng dụng vẫn chạy được với email mặc định trong mã nguồn, nhưng có thể bị OpenAlex giới hạn lượt gọi khi dùng liên tục.*
3. Tải các thư viện phụ thuộc và chạy ứng dụng:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 3. Tổng quan giao diện

Ứng dụng mặc định hiển thị **giao diện tối (Dark Mode)**. Thanh điều hướng nổi ở cạnh dưới màn hình gồm **4 tab**:

| Tab | Biểu tượng | Chức năng chính |
| :--- | :---: | :--- |
| **Home** | 🏠 | Khám phá các công bố nổi bật và mới cập nhật mà không cần nhập từ khóa |
| **Search** | 🔍 | Tìm kiếm bài báo theo từ khóa, xem lịch sử tìm kiếm |
| **Phân tích** | 📈 | Biểu đồ xu hướng theo năm, xếp hạng Tạp chí và Tác giả |
| **Profile** | 👤 | Giới thiệu ứng dụng, tính năng và nguồn dữ liệu |

Chạm vào một tab để chuyển màn hình. Dữ liệu của từng tab được giữ nguyên khi bạn chuyển qua lại.

---

## 4. Hướng dẫn từng chức năng

### 4.1. Tab Home — Khám phá nghiên cứu nổi bật

Ngay khi mở ứng dụng, tab Home tự động tải dữ liệu chung từ OpenAlex và hiển thị:

* **Thẻ RESEARCH PULSE** (trên cùng): tóm tắt số lượng bài trong mẫu nổi bật, số bài mới cập nhật và nguồn dữ liệu.
* **Đang được quan tâm**: 6 công bố có lượt trích dẫn cao nhất trong 10 năm gần đây, kèm số lượt trích dẫn (ví dụ `12.4K trích dẫn`).
* **Mới cập nhật**: 6 công bố mới nhất trên OpenAlex, kèm ngày xuất bản.

**Các thao tác:**
* **Xem chi tiết bài báo**: chạm vào một thẻ bài viết bất kỳ.
* **Làm mới dữ liệu**: chạm nút 🔄 ở góc phải thanh tiêu đề, hoặc **vuốt màn hình từ trên xuống** (kéo để làm mới).
* **Khi lỗi mạng**: màn hình hiển thị thông báo "Chưa tải được dữ liệu chung" — kiểm tra kết nối rồi chạm **Thử lại**.

### 4.2. Tab Search — Tìm kiếm bài báo theo từ khóa

1. Chạm vào ô **"Nhập từ khóa nghiên cứu..."** và gõ chủ đề bạn quan tâm (ví dụ: `machine learning`, `blockchain`, `climate change`).
2. Nhấn phím **Tìm kiếm (Search)** trên bàn phím để chạy tìm kiếm.
3. Ứng dụng tải về **tối đa 80 bài báo** phù hợp nhất và **sắp xếp giảm dần theo số lượt trích dẫn**.

**Kết quả tìm kiếm** hiển thị dạng danh sách thẻ, mỗi thẻ gồm: tiêu đề bài báo (tối đa 2 dòng), danh sách tác giả (rút gọn thành "và cs." nếu quá 3 người), huy hiệu năm xuất bản, huy hiệu số lượt trích dẫn và tên tạp chí.

**Các thao tác:**
* **Xóa nội dung đang gõ**: chạm nút ✕ bên phải ô tìm kiếm.
* **Xem chi tiết**: chạm vào một thẻ bài báo trong danh sách.
* **Chuyển sang phân tích**: chạm nút **"Phân tích"** phía trên danh sách để nhảy thẳng sang tab Phân tích cho từ khóa hiện tại.
* **Xóa kết quả tìm kiếm**: chạm nút ✕ bên phải nút "Phân tích". Tab Phân tích sẽ quay lại chế độ xếp hạng chung.
* **Tải lại kết quả**: vuốt danh sách từ trên xuống.

**Lịch sử tìm kiếm**: mỗi từ khóa đã tìm được lưu thành một chip ngay dưới ô tìm kiếm (**tối đa 6 từ khóa gần nhất**).
* Chạm vào chip để tìm lại từ khóa đó ngay.
* Chạm biểu tượng ✕ trên chip để xóa riêng từ khóa đó.
* Chạm **"Xóa tất cả"** để xóa toàn bộ lịch sử.

> **Lưu ý**: lịch sử tìm kiếm chỉ được lưu trong phiên chạy hiện tại và sẽ mất khi bạn tắt hẳn ứng dụng.

### 4.3. Tab Phân tích — Thống kê xu hướng

Tab Phân tích hoạt động ở **hai chế độ**, được thể hiện bằng banner màu ở đầu màn hình:

| Banner | Khi nào xuất hiện | Ý nghĩa |
| :--- | :--- | :--- |
| **Xếp hạng chung** (xanh ngọc) | Chưa tìm kiếm từ khóa nào | Phân tích trên mẫu công bố nổi bật trong 10 năm gần đây |
| **Xếp hạng theo từ khóa** (xanh–tím) | Đã tìm kiếm ở tab Search | Phân tích trên mẫu bài báo của từ khóa đó |

Màn hình có 3 tab con:

1. **Xu hướng năm** — Biểu đồ thể hiện số lượng công bố theo từng năm, giúp nhận biết chủ đề đang tăng trưởng hay đã bão hòa.
2. **Top Tạp chí** — Bảng xếp hạng các tạp chí có nhiều bài nhất trong mẫu.
3. **Top Tác giả** — Bảng xếp hạng các tác giả đóng góp nhiều bài nhất. **Chạm vào một tác giả** để mở màn hình chi tiết tác giả.

### 4.4. Màn hình Chi tiết bài viết

Mở bằng cách chạm vào bất kỳ thẻ bài báo nào ở tab Home hoặc Search. Màn hình hiển thị:
* Tiêu đề đầy đủ, năm xuất bản, số lượt trích dẫn, tên tạp chí.
* Danh sách toàn bộ tác giả — **chạm vào tên tác giả** để xem hồ sơ chi tiết của họ.
* Phần tóm tắt (Abstract) đầy đủ.
* Nút **"Xem bài viết gốc (Publisher Website)"**: mở trình duyệt hệ thống tới liên kết DOI của bài báo.

> Nếu bài báo không có liên kết DOI, ứng dụng hiển thị thông báo *"Bài viết này không có liên kết DOI."* Tương tự, nếu dữ liệu tác giả không đủ, bạn sẽ nhận thông báo *"Không có đủ dữ liệu để mở chi tiết tác giả."*

### 4.5. Tab Profile — Giới thiệu

Hiển thị thông tin giới thiệu nhóm phát triển (**About us**), danh sách **Tính năng chính**, **Nguồn dữ liệu** (OpenAlex) và số phiên bản ứng dụng.

---

## 5. Mẹo sử dụng và lưu ý quan trọng

* **Số liệu thống kê được tính trên mẫu dữ liệu**, không phải trên toàn bộ kho OpenAlex. Mỗi lượt tìm kiếm lấy tối đa 80 bài báo tiêu biểu nhất — đây là mẫu đủ lớn để nhận diện xu hướng nhưng không phải con số tuyệt đối của toàn ngành.
* **Từ khóa tiếng Anh cho kết quả tốt hơn nhiều** so với tiếng Việt, vì OpenAlex lập chỉ mục chủ yếu các công bố quốc tế.
* Từ khóa càng cụ thể (`deep learning for medical imaging`) thì biểu đồ xu hướng càng có ý nghĩa so với từ khóa quá rộng (`science`).
* Ứng dụng **không lưu dữ liệu offline**: mỗi lần mở lại đều tải mới từ máy chủ.

---

## 6. Xử lý sự cố thường gặp

| Hiện tượng | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| "Chưa tải được dữ liệu chung" hoặc "Không thể tìm kiếm" | Mất kết nối mạng hoặc OpenAlex tạm thời không phản hồi | Kiểm tra Wi-Fi/4G rồi chạm **Thử lại** |
| "Không tìm thấy kết quả" | Từ khóa quá hẹp, sai chính tả hoặc là tiếng Việt | Thử từ khóa tiếng Anh, tổng quát hơn |
| Tìm kiếm bị chậm hoặc thỉnh thoảng lỗi khi dùng liên tục | Bị OpenAlex giới hạn lượt gọi (rate-limit) | Kiểm tra tệp `.env` đã khai báo `OPENALEX_EMAIL` hợp lệ để được xếp vào Polite Pool |
| Nút "Xem bài viết gốc" không mở trình duyệt | Thiết bị chưa có trình duyệt mặc định, hoặc bài báo không có DOI | Cài/đặt lại trình duyệt mặc định; kiểm tra bài báo khác có DOI |
| Biểu đồ hoặc bảng xếp hạng trống | Mẫu dữ liệu hiện tại chưa có bài nào hợp lệ | Chạm **Tải dữ liệu chung** hoặc thực hiện một tìm kiếm mới |
