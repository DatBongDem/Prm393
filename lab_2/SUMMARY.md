# Báo cáo Tổng kết Dự án: Journal Trend Analyzer

Dự án phát triển ứng dụng di động **Journal Trend Analyzer** sử dụng **Flutter** và **OpenAlex API** để tìm kiếm và phân tích xu hướng nghiên cứu bài báo khoa học.

---

## 📊 Bảng tổng hợp nhiệm vụ (Task Checklist)

| STT | Nhiệm vụ | Trạng thái | Mô tả chi tiết |
| :--- | :--- | :---: | :--- |
| 1 | Cấu hình Thư viện (Dependencies) | **ĐÃ XONG** (100%) | Đã thêm và cài đặt thành công: `http`, `provider`, `fl_chart`, `google_fonts`, `url_launcher`. |
| 2 | Thiết lập Kiến trúc Dự án | **ĐÃ XONG** (100%) | Phân chia thư mục khoa học: `models/`, `services/`, `state/`, `screens/`. |
| 3 | Xây dựng Model Bài báo | **ĐÃ XONG** (100%) | Hoàn thành lớp dữ liệu [Publication](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/models/publication.dart) cùng thuật toán tự giải mã tóm tắt bài báo (`abstract_inverted_index`). |
| 4 | Xây dựng Dịch vụ API | **ĐÃ XONG** (100%) | Hoàn thành dịch vụ kết nối mạng [OpenAlexService](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/services/openalex_service.dart) tích hợp tham gia "Polite Pool". |
| 5 | Quản lý Trạng thái & Tính toán | **ĐÃ XONG** (100%) | Xây dựng lớp quản lý trạng thái [AnalyticsProvider](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/state/analytics_provider.dart) tự động tính toán các chỉ số thống kê. |
| 6 | Giao diện Tìm kiếm (Search Screen) | **ĐÃ XONG** (100%) | Hoàn thành [SearchScreen](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/screens/search_screen.dart) hỗ trợ gợi ý nhanh chủ đề và hiển thị danh sách bài báo. |
| 7 | Màn hình Chi tiết (Detail Screen) | **ĐÃ XONG** (100%) | Hoàn thành [DetailScreen](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/screens/detail_screen.dart) hiển thị chi tiết tác giả, abstract và mở liên kết DOI. |
| 8 | Màn hình Phân tích Xu hướng (Trend) | **ĐÃ XONG** (100%) | Hoàn thành [TrendScreen](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/screens/trend_screen.dart) hiển thị biểu đồ năm (`fl_chart`), bảng xếp hạng Tác giả và Tạp chí. |
| 9 | Màn hình Dashboard Tổng hợp | **ĐÃ XONG** (100%) | Hoàn thành [DashboardScreen](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/screens/dashboard_screen.dart) hiển thị các chỉ số tóm tắt và bài báo ảnh hưởng nhất. |
| 10 | Tích hợp & Cấu hình Giao diện | **ĐÃ XONG** (100%) | Chỉnh sửa [main.dart](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/lib/main.dart) để áp dụng giao diện tối Dark Mode cao cấp và kết nối Provider. |
| 11 | Khắc phục Lỗi Biên dịch Android | **ĐÃ XONG** (100%) | Tắt tính năng biên dịch gia tăng của Kotlin trong [gradle.properties](file:///e:/ki8/PRM393/github/Prm393_Lab1/lab_2/android/gradle.properties) để sửa lỗi build chéo ổ đĩa Windows. |

---

## 🛠️ Kiến trúc Thư mục Dự án

Mã nguồn được tổ chức theo mô hình **Separation of Concerns** giúp dễ bảo trì và mở rộng:

```text
lib/
├── models/
│   └── publication.dart          # Lớp định nghĩa dữ liệu bài báo khoa học và parser JSON
├── services/
│   └── openalex_service.dart     # Service kết nối và xử lý yêu cầu HTTP tới OpenAlex API
├── state/
│   └── analytics_provider.dart   # Quản lý State toàn cục và tính toán logic thống kê
├── screens/
│   ├── search_screen.dart        # Màn hình tìm kiếm chủ đề nghiên cứu khoa học
│   ├── detail_screen.dart        # Màn hình chi tiết bài viết và mở liên kết DOI
│   ├── trend_screen.dart         # Màn hình phân tích biểu đồ năm xuất bản, tạp chí và tác giả
│   └── dashboard_screen.dart     # Màn hình Dashboard tổng hợp các dữ liệu nghiên cứu khoa học
└── main.dart                     # Tệp khởi chạy ứng dụng, cấu hình Theme tối Dark Mode
```

---

## 🐛 Các lỗi kỹ thuật đã khắc phục thành công

1. **Lỗi bất đồng bộ BuildContext (Async Gaps)**:
   - *Vấn đề*: Sử dụng `BuildContext` trong `_openDoiLink` sau câu lệnh `await` mà không kiểm tra độ khả dụng của widget dẫn đến rủi ro crash.
   - *Cách sửa*: Bổ sung kiểm tra `if (!context.mounted) return;` trước khi sử dụng context.

2. **Lỗi biên dịch Kotlin chéo ổ đĩa trên Windows (Gradle build failed)**:
   - *Vấn đề*: Dự án chạy trên ổ đĩa `E:` trong khi Pub cache nằm ở ổ đĩa `C:`, gây ra lỗi biên dịch `java.lang.IllegalArgumentException: this and base files have different roots` ở bộ nhớ đệm của Kotlin compiler.
   - *Cách sửa*: Thêm `kotlin.incremental=false` vào `gradle.properties` để tắt tính năng biên dịch gia tăng và dọn dẹp cache bằng `flutter clean`.

3. **Lỗi hiển thị màu sắc và từ khóa const**:
   - *Vấn đề*: Trình phân tích tĩnh báo lỗi do gọi `Colors.violetAccent` (không tồn tại trong Material Colors) và khai báo `const` đối với widget Icon chứa màu sắc động.
   - *Cách sửa*: Thay thế sang màu `Colors.deepPurpleAccent` và xóa bỏ từ khóa `const` ở những chỗ sử dụng màu động.
