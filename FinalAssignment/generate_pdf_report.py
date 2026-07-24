import os
from PIL import Image as PILImage
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, HRFlowable, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# 1. Register Fonts (Supports full Vietnamese Unicode characters)
font_dir = "C:/Windows/Fonts/"
pdfmetrics.registerFont(TTFont("Arial", os.path.join(font_dir, "arial.ttf")))
pdfmetrics.registerFont(TTFont("Arial-Bold", os.path.join(font_dir, "arialbd.ttf")))
pdfmetrics.registerFont(TTFont("Arial-Italic", os.path.join(font_dir, "ariali.ttf")))

# 2. Document Setup
pdf_filename = "d:/FPTU/Summer2026/PRM393/Prm393/BAO_CAO_DU_AN_FINAL_ASSIGNMENT.pdf"
doc = SimpleDocTemplate(
    pdf_filename,
    pagesize=A4,
    leftMargin=36,
    rightMargin=36,
    topMargin=36,
    bottomMargin=36
)

styles = getSampleStyleSheet()

# 3. Custom Color Palette
PRIMARY_COLOR = colors.HexColor("#0F766E")   # Dark Teal
SECONDARY_COLOR = colors.HexColor("#EC4899") # Magenta Pink (Accent)
DARK_TEXT = colors.HexColor("#1E293B")       # Slate 800
BG_LIGHT = colors.HexColor("#F8FAFC")        # Slate 50
BORDER_COLOR = colors.HexColor("#CBD5E1")    # Slate 300

# 4. Typography Styles
title_style = ParagraphStyle(
    "DocTitle",
    parent=styles["Normal"],
    fontName="Arial-Bold",
    fontSize=22,
    leading=26,
    textColor=PRIMARY_COLOR,
    alignment=1,
    spaceAfter=8
)

subtitle_style = ParagraphStyle(
    "DocSubtitle",
    parent=styles["Normal"],
    fontName="Arial-Bold",
    fontSize=13,
    leading=16,
    textColor=SECONDARY_COLOR,
    alignment=1,
    spaceAfter=14
)

h1_style = ParagraphStyle(
    "H1",
    parent=styles["Normal"],
    fontName="Arial-Bold",
    fontSize=13.5,
    leading=17.5,
    textColor=PRIMARY_COLOR,
    spaceBefore=14,
    spaceAfter=6,
    keepWithNext=True
)

h2_style = ParagraphStyle(
    "H2",
    parent=styles["Normal"],
    fontName="Arial-Bold",
    fontSize=11,
    leading=14,
    textColor=colors.HexColor("#0284C7"), # Sky Blue Accent
    spaceBefore=10,
    spaceAfter=4,
    keepWithNext=True
)

body_style = ParagraphStyle(
    "Body",
    parent=styles["Normal"],
    fontName="Arial",
    fontSize=9.5,
    leading=13.5,
    textColor=DARK_TEXT,
    spaceAfter=6
)

body_bold = ParagraphStyle(
    "BodyBold",
    parent=body_style,
    fontName="Arial-Bold"
)

code_style = ParagraphStyle(
    "CodeText",
    parent=styles["Normal"],
    fontName="Arial",
    fontSize=8.5,
    leading=11,
    textColor=colors.HexColor("#0F172A")
)

caption_style = ParagraphStyle(
    "CaptionText",
    parent=styles["Normal"],
    fontName="Arial-Bold",
    fontSize=9,
    leading=12,
    textColor=PRIMARY_COLOR,
    alignment=1,
    spaceAfter=10
)

story = []

# =========================================================================
# HEADER & TITLE
# =========================================================================
story.append(Paragraph("BÁO CÁO ĐỒ ÁN FINAL ASSIGNMENT (PRM393)", title_style))
story.append(Paragraph("Hệ thống Phân tích Báo chí Học thuật & Cổng Quản trị Web Admin Portal<br/>(The News Thing & Admin Portal)", subtitle_style))

# Meta Info Table
meta_data = [
    [Paragraph("<b>Môn học:</b> PRM393 - Lập trình Thiết bị Di động", body_style), Paragraph("<b>Kiến trúc:</b> MVVM + Provider State Management", body_style)],
    [Paragraph("<b>Trường:</b> Đại học FPT (FPT University)", body_style), Paragraph("<b>Hệ thống:</b> Mobile Client (Flutter) & Web Admin (Web)", body_style)],
    [Paragraph("<b>API Tích hợp:</b> OpenAlex REST API", body_style), Paragraph("<b>Hạ tầng:</b> Firebase (Auth, Firestore, FCM v1, Storage)", body_style)]
]
t_meta = Table(meta_data, colWidths=[260, 263])
t_meta.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, -1), BG_LIGHT),
    ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
    ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
    ('PADDING', (0, 0), (-1, -1), 5),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
]))
story.append(t_meta)
story.append(Spacer(1, 10))

# =========================================================================
# PHẦN 1: TỔNG QUAN HỆ THỐNG LIÊN THÔNG
# =========================================================================
story.append(Paragraph("1. Tổng quan Hệ thống (Mobile Client & Web Admin Portal)", h1_style))
story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceAfter=8))

intro_p = (
    "Đồ án môn học PRM393 được thiết kế như một giải pháp liên thông hoàn chỉnh gồm <b>2 ứng dụng chạy song song</b> "
    "kết nối trực tiếp qua hạ tầng đám mây Firebase. Hệ thống này bao gồm ứng dụng di động dành cho người dùng cuối và cổng quản trị web dành cho Admin:"
)
story.append(Paragraph(intro_p, body_style))

proj_summary_data = [
    [Paragraph("<b>Thành phần</b>", body_bold), Paragraph("<b>Nền tảng</b>", body_bold), Paragraph("<b>Nhiệm vụ & Chức năng trọng tâm</b>", body_bold)],
    [
        Paragraph("<b>1. Web Admin Portal</b><br/>(FinalAssignment/WebAdmin)", body_style),
        Paragraph("Flutter Web", body_style),
        Paragraph("<b>Hệ thống Quản trị trung tâm</b>:<br/>"
                  "• Đăng nhập quản trị, kiểm soát tài khoản người dùng và hoạt động DAU.<br/>"
                  "• <b>Giám sát Sự cố (Crash Monitoring)</b>: Lắng nghe realtime các báo cáo lỗi Fatal/Non-fatal tự động gửi lên từ client di động qua Firestore.<br/>"
                  "• <b>Quản lý Storage & PDF</b>: Xem trực tuyến và dọn dẹp các tệp PDF báo cáo học thuật do người dùng xuất bản.<br/>"
                  "• <b>Chiến dịch thông báo FCM</b>: Phát thông báo đẩy Push Broadcast hàng loạt sử dụng FCM HTTP v1 API, theo dõi tỉ lệ Nhận/Đọc.", body_style)
    ],
    [
        Paragraph("<b>2. Flutter Mobile App</b><br/>(FinalAssignment/Flutter)", body_style),
        Paragraph("Android / iOS", body_style),
        Paragraph("<b>Ứng dụng dành cho Người dùng cuối</b>:<br/>"
                  "• Xác thực qua Email/Password & Google Sign-In.<br/>"
                  "• Tra cứu bài báo khoa học từ OpenAlex API, thống kê biểu đồ xu hướng xuất bản, Top Tác giả, Top Tạp chí.<br/>"
                  "• Xuất tệp PDF báo cáo và tự động đồng bộ hóa lên Firebase Storage.<br/>"
                  "• <b>Tự động gửi báo cáo lỗi (Auto Crash Reporter)</b> lên Firestore khi gặp sự cố Fatal/Non-fatal.", body_style)
    ]
]
t_proj = Table(proj_summary_data, colWidths=[135, 95, 293])
t_proj.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor("#FCE7F3")), # Web Admin Highlight
    ('BACKGROUND', (0, 2), (-1, 2), colors.white),
    ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
    ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
    ('PADDING', (0, 0), (-1, -1), 6),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
for i in range(3):
    proj_summary_data[0][i].style.textColor = colors.white

story.append(t_proj)
story.append(Spacer(1, 10))

# =========================================================================
# PHẦN 2: CẤU TRÚC SOURCE CODE CHI TIẾT
# =========================================================================
story.append(Paragraph("2. Cấu trúc Source Code (Mô hình MVVM)", h1_style))
story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceAfter=8))

story.append(Paragraph("Cấu trúc mã nguồn của 2 dự án được phân tách rõ ràng theo mô hình MVVM (Model-View-ViewModel) kết hợp Provider:", body_style))

# Thư mục Web Admin
story.append(Paragraph("A. Cấu trúc mã nguồn Cổng Quản trị Web Admin (WebAdmin)", h2_style))
tree_admin_data = [
    [Paragraph("<b>Thư mục / Tệp tin</b>", body_bold), Paragraph("<b>Mô tả vai trò kiến trúc</b>", body_bold)],
    [Paragraph("<code>lib/main.dart</code>", code_style), Paragraph("Entrypoint của Web Admin, thiết lập giao diện ThemeData.dark() với font Outfit, quản lý định tuyến trạng thái đăng nhập qua StreamBuilder.", body_style)],
    [Paragraph("<code>lib/screens/login_screen.dart</code>", code_style), Paragraph("Màn hình đăng nhập Quản trị viên, thực hiện xác thực với thông tin cấu hình admin cố định trong FirebaseConfig.", body_style)],
    [Paragraph("<code>lib/screens/admin_dashboard_screen.dart</code>", code_style), Paragraph("View chính của Web Admin, quản lý thanh Sidebar điều hướng và nạp 5 Tab giao diện (Dashboard, Người dùng, Tài liệu PDF, Báo cáo Bug, Gửi Thông báo).", body_style)],
    [Paragraph("<code>lib/services/fcm_sender_service.dart</code>", code_style), Paragraph("Ký token JWT sử dụng Service Account credentials để gọi HTTP POST gửi tin nhắn hàng loạt qua Google FCM HTTP v1 API.", body_style)],
    [Paragraph("<code>lib/services/crashlytics_service.dart</code>", code_style), Paragraph("Xử lý phân tích và đếm thống kê các loại lỗi Crash từ Firestore.", body_style)]
]
t_tree_admin = Table(tree_admin_data, colWidths=[180, 343])
t_tree_admin.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), SECONDARY_COLOR),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('BACKGROUND', (0, 1), (-1, -1), colors.white),
    ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
    ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
for i in range(2):
    tree_admin_data[0][i].style.textColor = colors.white
story.append(t_tree_admin)
story.append(Spacer(1, 10))

# Thư mục Mobile Client
story.append(Paragraph("B. Cấu trúc mã nguồn Ứng dụng Di động Client (Flutter)", h2_style))
tree_client_data = [
    [Paragraph("<b>Thư mục / Tệp tin</b>", body_bold), Paragraph("<b>Mô tả vai trò kiến trúc</b>", body_bold)],
    [Paragraph("<code>lib/models/</code>", code_style), Paragraph("Chứa cấu trúc dữ liệu thuần như <code>Publication</code>, <code>Author</code>, <code>Journal</code> kèm các phương thức factory parse JSON từ OpenAlex API.", body_style)],
    [Paragraph("<code>lib/services/</code>", code_style), Paragraph("Chứa các Service cô lập: <code>openalex_service.dart</code> (gọi REST API), <code>firestore_service.dart</code> (giao tiếp DB), <code>pdf_report_service.dart</code> (xuất báo cáo PDF).", body_style)],
    [Paragraph("<code>lib/viewmodels/</code>", code_style), Paragraph("Quản lý trạng thái và nghiệp vụ (ChangeNotifier): <code>AuthViewModel</code> (quản lý login/logout), <code>AnalyticsProvider</code> (quản lý tìm kiếm, biểu đồ, top keywords).", body_style)],
    [Paragraph("<code>lib/screens/ & widgets/</code>", code_style), Paragraph("Giao diện người dùng di động (HomeScreen, ProfileScreen, BugReportScreen...), lắng nghe ViewModel qua <code>context.watch()</code>.", body_style)]
]
t_tree_client = Table(tree_client_data, colWidths=[180, 343])
t_tree_client.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('BACKGROUND', (0, 1), (-1, -1), colors.white),
    ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
    ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
    ('PADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
for i in range(2):
    tree_client_data[0][i].style.textColor = colors.white
story.append(t_tree_client)
story.append(Spacer(1, 10))

# =========================================================================
# PHẦN 3: CÁC KỸ THUẬT LẬP TRÌNH & CÔNG NGHỆ CỐT LÕI
# =========================================================================
story.append(PageBreak())
story.append(Paragraph("3. Các Kỹ thuật Lập trình & Công nghệ Sử dụng", h1_style))
story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceAfter=8))

tech_p = (
    "Đồ án tích hợp sâu hệ thống Firebase và kỹ thuật lập trình nâng cao để tạo ra sự liên thông đồng bộ giữa Client và Web Admin:"
)
story.append(Paragraph(tech_p, body_style))

detailed_tech = [
    [Paragraph("<b>Kỹ thuật / Công nghệ</b>", body_bold), Paragraph("<b>Nguyên lý & Chi tiết triển khai kỹ thuật trong dự án</b>", body_bold)],
    [
        Paragraph("<b>1. Gửi tin FCM hàng loạt (HTTP v1 API)</b>", body_style),
        Paragraph("Phía Web Admin ký OAuth2 JWT Token bằng Service Account JSON thông qua thư viện <code>googleapis_auth</code>. Hệ thống gọi HTTP POST tới FCM v1 endpoint để bắn thông báo Push Broadcast. Phía Mobile sử dụng <code>firebase_messaging</code> lắng nghe thông báo đẩy ở cả 3 trạng thái (Foreground, Background, Terminated) và hiển thị Local Notification.", body_style)
    ],
    [
        Paragraph("<b>2. Giám sát Sự cố (Realtime Crash Reporter)</b>", body_style),
        Paragraph("Phía Mobile Client đánh chặn lỗi toàn cục bằng cách ghi đè <code>FlutterError.onError</code> (cho lỗi UI/Render) và <code>PlatformDispatcher.instance.onError</code> (cho lỗi bất đồng bộ). Lỗi tự động được gửi lên Firestore collection <code>bugs</code>. Phía Web Admin sử dụng <code>StreamBuilder</code> lắng nghe realtime Firestore để cập nhật trực quan danh sách lỗi lên màn hình giám sát sự cố.", body_style)
    ],
    [
        Paragraph("<b>3. Quản lý Cloud Storage & Xuất báo cáo PDF</b>", body_style),
        Paragraph("Mobile Client sử dụng thư viện <code>pdf</code> biên dịch kết quả tìm kiếm và biểu đồ thành tệp PDF chất lượng cao, sau đó tải lên Firebase Cloud Storage thông qua <code>firebase_storage</code>. Web Admin hiển thị danh sách các PDF đã xuất, cung cấp nút tải/xem trực tiếp hoặc xóa tệp đám mây.", body_style)
    ],
    [
        Paragraph("<b>4. Thống kê DAU & Lịch sử Tìm kiếm (Firestore)</b>", body_style),
        Paragraph("Đo lường lượng người dùng hoạt động hàng ngày (DAU) thông qua việc ghi nhận timestamp hoạt động của tài khoản lên Firestore. Thống kê lịch sử tìm kiếm 7 ngày gần nhất để tính toán biểu đồ tần suất từ khóa hot (Top Keywords) hoàn toàn tự động.", body_style)
    ],
    [
        Paragraph("<b>5. Đồng bộ cấu hình Remote Config</b>", body_style),
        Paragraph("Web Admin cho phép thay đổi cấu hình hiển thị (màu chủ đạo, lời chào, giới hạn bài viết). Ứng dụng di động sử dụng <code>firebase_remote_config</code> đăng ký lắng nghe <code>onConfigUpdated</code> để thay đổi màu sắc Theme ứng dụng realtime không cần restart.", body_style)
    ],
    [
        Paragraph("<b>6. Kiểm thử tự động E2E với Patrol</b>", body_style),
        Paragraph("Sử dụng Patrol Framework kết hợp với Android Test Orchestrator (ATO) để chạy cách ly 11 test cases nghiệp vụ tự động từ login, tìm kiếm, xem biểu đồ, xuất báo cáo đến logout.", body_style)
    ]
]
t_tech = Table(detailed_tech, colWidths=[150, 373])
t_tech.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('BACKGROUND', (0, 1), (-1, -1), colors.white),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
    ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
    ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
    ('PADDING', (0, 0), (-1, -1), 5),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
for i in range(2):
    detailed_tech[0][i].style.textColor = colors.white
story.append(t_tech)
story.append(Spacer(1, 10))

# =========================================================================
# PHẦN 4: HÌNH ẢNH MÀN HÌNH THỰC TẾ
# =========================================================================
story.append(PageBreak())
story.append(Paragraph("4. Ảnh chụp các Màn hình Thực tế của WEB ADMIN PORTAL", h1_style))
story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY_COLOR, spaceAfter=10))

img_dir = "d:/FPTU/Summer2026/PRM393/Prm393/FinalAssignment/WebAdmin/image_report"
web_screens = [
    ("real_webadmin_1.png", "Hình 1: Màn hình Đăng nhập Cổng Quản trị Web Admin (Login Screen)"),
    ("real_webadmin_2.png", "Hình 2: Bảng điều khiển Tổng quan (Dashboard Overview, Biểu đồ DAU & Top từ khóa)"),
    ("real_webadmin_3.png", "Hình 3: Quản lý Người dùng & Lịch sử hoạt động (User Management)"),
    ("real_webadmin_4.png", "Hình 4: Quản lý Tài liệu PDF xuất bản (PDF Document Management)"),
    ("real_webadmin_5.png", "Hình 5: Báo cáo Bug & Crashlytics tự động từ thiết bị (Crash Monitoring)"),
    ("real_webadmin_6.png", "Hình 6: Gửi Thông báo FCM Hàng loạt & Lịch sử chiến dịch gửi tin (FCM Campaign Manager)"),
]

target_w = 515.0

for filename, caption in web_screens:
    img_path = os.path.join(img_dir, filename)
    if os.path.exists(img_path):
        with PILImage.open(img_path) as pil_img:
            pw, ph = pil_img.size
            calc_h = target_w * (ph / float(pw))
            
        img_widget = Image(img_path, width=target_w, height=calc_h)
        card_content = [
            Spacer(1, 4),
            img_widget,
            Spacer(1, 4),
            Paragraph(f"<b>{caption}</b>", caption_style),
            Spacer(1, 8)
        ]
        story.append(KeepTogether(card_content))

# =========================================================================
# BUILD DOCUMENT
# =========================================================================
doc.build(story)
print("PDF Report Recompiled successfully with all correct project details!")
