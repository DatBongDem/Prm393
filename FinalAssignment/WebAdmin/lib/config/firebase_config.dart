class FirebaseConfig {
  // ==========================================
  // 1. FIREBASE SERVICE ACCOUNT (MỚI - DÙNG CHO FCM V1)
  // Lấy các thông số này trong file JSON private key tải từ Firebase
  // ==========================================
  static const String serviceAccountClientEmail = 'firebase-adminsdk-fbsvc@prm393-lab3-app-8faff.iam.gserviceaccount.com';
  static const String serviceAccountPrivateKey = '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDgi6wOFiGgVX7W\n5KxhIpomYuzsLGS+AXDNdJ4UkJdJiDV6XWD5x3Rr4s/RkkN4vGzVNrQi+3g1Rxpe\nDRW0ypOFjKpMcoaP85LebdERGMZ8yNQafO6U2OJNqIeC3PoODQz4Cy+uRpa9s9t9\nHY5qtHKjcQbsih6dQWOxd375+pcBDL5UtnthWe4/HwsUXVapO0Im451Vf2CSuUCT\nQ8vx4hBGn0iLphktmJTkc7uB7708WkRRdsX22QAyitfU3GwztGtolARq8x5isN7x\nV1iXSsDBW1Drw9rXhKEOz4/Mwa4ws4FfZR+aPIkhZfknU3HSjOZ9JxL10Mk9ATp4\ntWmzbCifAgMBAAECggEAYNic6q5s7mQxgqm6F2L/LVM5cFttT+37IwILND9woMxY\nlGA19UUrV2TJ0U/OPgK2xfcEFppzLDdwjeQC2qkMm2siADrdArVBQSIIK+GNqkBM\nCuibViN855WqbKy2RN0oHMtmUzoqxcMPBZV72VXeo9OZ8udXcOfFAcPSRiroehCg\nDBfDIxhn0rP+9UDu4hlqePMYuUHWdPOr7nkJKcp6JweHORSybkUL75ui27y+PVz9\nIJio/ugYpJwEBcrbJoJ46xYh78VgDycdQmPsqzoMnz/7HsWDQ1MzAaO9G0wf3q0i\n028ZNaGzxxcr/7FSkw+EyaGbS5DT8FPY8CB0hXrEAQKBgQD4aUYsRN+tiqlkGjYE\nbkATIwLenifNv5x2efEyHHGPia6wJEO29iHkE+5zMW9vRzWgM3T3zVBHjWXLwYP/\nq37vSR3uSWTXmiEhhJs7wAiXm5j3ei6RMLnPsDPPpZCsc3VZySpi9eMfx2XLodGc\nB+71FKFSHEtZyI6UX1GM69cjAQKBgQDnZ8EaUgHqYich+bzrpL52KYWeRX4ofY+D\nYclbcWIMeJmX338dxktcasxf0EKgt8NUh5fmCjlMDCanT6fl5i+VwfegOvUSqm2J\npHEO603BPGVQfR2llrilmXPuGRZ++DrThCu7o53QX+7xH3FnVMAt3HbbA2Yab+c8\nHdVbSSxrnwKBgBCh29Ty95cDBbxyFNPPHfMqEPMe28Nm5O750zBrvx7BNTUN+Iqz\niClhPEHyOWfV+L01NMuyr4Fa8knmNxRTQzh6SMq/l0ToSPeZjVs+zFR6Uo+fWqbW\nAFrrjUyF5V3mjSDp2zCtDfv+uc4ck5BC57j5HKQGyPTF/OXqS+eHkuwBAoGBAIJy\nKpj7wbiuvACbF7R+mh9iKMCfzA5nOY+GgEvcDrmZAnxqsO3H6pOeYLdiXyzaanIs\nPaSf/syvzNpkPPGMYSa6wSzCD4UGLdl5qYIPgzV7JmHJJf1CibRQXNnLqrLIm+DA\nkSalhUEB02B5qSPm0q8HqLitodElY+SvrKZZCYFhAoGAX7KBcjDYy9v9XeZzgjPx\nO+kJjdPozPh5sNDOl01NqTYBalsfn8JQ+D9AJGlNt2F6MFlvuUARwic4dowh3Did\nnEVFqvlkzIrHby926cAN2j0kCfTkqbqwY49tPeuRBSkwJanE3dF0TP7PlWAv5Mbr\nqnyaH5Mg92aS0161o4AAKAA=\n-----END PRIVATE KEY-----\n';
  static const String serviceAccountClientId = '107591106143076538346';

  // OpenAlex contact email configuration
  static const String openAlexEmail = 'prm393lab2@fpt.edu.vn';

  // ==========================================
  // 2. ANDROID CONFIGURATION (Để kết nối client Firebase)
  // Lấy các thông số này trong file google-services.json mới
  // ==========================================
  static const String androidApiKey = 'AIzaSyDKJ3wfuvQs9TBlPdo3tJ-UPvTiONs56yQ';
  static const String androidAppId = '1:1075626945411:android:a05f104ed1ae8f825fe4b6';
  static const String androidMessagingSenderId = '1075626945411';
  static const String androidProjectId = 'prm393-lab3-app-8faff';
  static const String androidStorageBucket = 'prm393-lab3-app-8faff.firebasestorage.app';

  // ==========================================
  // 3. IOS CONFIGURATION (Có thể để mặc định nếu chỉ build Android)
  // ==========================================
  static const String iosApiKey = 'YOUR_IOS_API_KEY_HERE';
  static const String iosAppId = 'YOUR_IOS_APP_ID_HERE';
  static const String iosMessagingSenderId = 'YOUR_IOS_SENDER_ID_HERE';
  static const String iosProjectId = 'YOUR_IOS_PROJECT_ID_HERE';
  static const String iosStorageBucket = 'YOUR_IOS_STORAGE_BUCKET_HERE';
  static const String iosBundleId = 'com.example.lab3';
}
