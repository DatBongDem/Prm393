// ĐÂY LÀ FILE MẪU CẤU HÌNH (TEMPLATE)
// Hãy sao chép file này, đổi tên thành "firebase_config.dart" và điền các thông tin của bạn.
// File "firebase_config.dart" thật sẽ được bảo mật cục bộ và tự động bỏ qua khi push lên Git.

class FirebaseConfig {
  // ==========================================
  // 1. FIREBASE SERVICE ACCOUNT (FCM V1)
  // Lấy từ file JSON private key tải từ Firebase Console -> Project Settings -> Service accounts
  // ==========================================
  static const String serviceAccountClientEmail = 'YOUR_SERVICE_ACCOUNT_EMAIL_HERE';
  static const String serviceAccountPrivateKey = 'YOUR_SERVICE_ACCOUNT_PRIVATE_KEY_HERE';
  static const String serviceAccountClientId = 'YOUR_SERVICE_ACCOUNT_CLIENT_ID_HERE';

  // ==========================================
  // 2. ANDROID CONFIGURATION
  // Lấy từ file google-services.json mới
  // ==========================================
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY_HERE';
  static const String androidAppId = 'YOUR_ANDROID_APP_ID_HERE';
  static const String androidMessagingSenderId = 'YOUR_ANDROID_SENDER_ID_HERE';
  static const String androidProjectId = 'YOUR_ANDROID_PROJECT_ID_HERE';
  static const String androidStorageBucket = 'YOUR_ANDROID_STORAGE_BUCKET_HERE';

  // ==========================================
  // 3. IOS CONFIGURATION
  // ==========================================
  static const String iosApiKey = 'YOUR_IOS_API_KEY_HERE';
  static const String iosAppId = 'YOUR_IOS_APP_ID_HERE';
  static const String iosMessagingSenderId = 'YOUR_IOS_SENDER_ID_HERE';
  static const String iosProjectId = 'YOUR_IOS_PROJECT_ID_HERE';
  static const String iosStorageBucket = 'YOUR_IOS_STORAGE_BUCKET_HERE';
  static const String iosBundleId = 'com.example.lab3';
}
