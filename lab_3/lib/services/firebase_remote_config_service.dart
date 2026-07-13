import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class FirebaseRemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      // 1. Cấu hình cài đặt cho Remote Config
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Trong quá trình phát triển (debug), đặt minimumFetchInterval là 0 giây để cập nhật tức thì khi fetch.
        // Khi chạy production, nên đặt thời gian lớn hơn (ví dụ: 1 giờ hoặc 12 giờ) để tránh quá tải API.
        minimumFetchInterval: const Duration(seconds: 0),
      ));

      // 2. Thiết lập các giá trị cấu hình mặc định (Default Values)
      await _remoteConfig.setDefaults(<String, dynamic>{
        'welcome_message': 'Chào mừng bạn đến với ứng dụng Lab 3!',
        'primary_color': '#6200EE', // Màu tím Material mặc định
        'required_points': 100,      // Ngưỡng điểm mặc định để nhận khuyến mãi
        'bonus_points': 20,          // Điểm thưởng mặc định ban đầu
      });
      
      // 3. Thực hiện tải và kích hoạt cấu hình từ xa
      await fetchAndActivate();
    } catch (e) {
      print('Lỗi khởi tạo Remote Config: $e');
    }
  }

  // Hàm để gọi fetch dữ liệu mới từ Firebase và kích hoạt nó
  Future<bool> fetchAndActivate() async {
    try {
      bool updated = await _remoteConfig.fetchAndActivate();
      print('Remote Config: Đã fetch và kích hoạt thành công (Có cập nhật mới: $updated).');
      return updated;
    } catch (e) {
      print('Lỗi Fetch Remote Config: $e');
      return false;
    }
  }

  // Các phương thức lấy giá trị cấu hình

  String getWelcomeMessage() {
    return _remoteConfig.getString('welcome_message');
  }

  int getRequiredPoints() {
    return _remoteConfig.getInt('required_points');
  }

  int getBonusPoints() {
    return _remoteConfig.getInt('bonus_points');
  }

  // Helper lấy mã màu Hex và chuyển đổi sang đối tượng Color của Flutter
  Color getPrimaryColor() {
    String hexColor = _remoteConfig.getString('primary_color');
    try {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor; // Thêm độ mờ Alpha mặc định (FF là 100% hiển thị)
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      print("Lỗi chuyển đổi mã màu: $hexColor -> dùng màu mặc định");
      return const Color(0xFF6200EE); // Màu tím mặc định khi lỗi
    }
  }
}
