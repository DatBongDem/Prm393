import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/firebase_analytics_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/firebase_remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase với cấu hình tự động được sinh ra
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Cấu hình Firebase Crashlytics để bắt toàn bộ các lỗi Flutter/Dart
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Bắt các lỗi xảy ra bất đồng bộ bên ngoài luồng giao diện (Async/Background Errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // 3. Khởi tạo các Service
  final analyticsService = FirebaseAnalyticsService();
  final messagingService = FirebaseMessagingService();
  final remoteConfigService = FirebaseRemoteConfigService();

  // Chạy cấu hình FCM và Remote Config trước khi hiển thị App
  await messagingService.initialize();
  await remoteConfigService.initialize();

  runApp(MyApp(
    analyticsService: analyticsService,
    remoteConfigService: remoteConfigService,
  ));
}

class MyApp extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  // Khóa ScaffoldMessenger tĩnh toàn cục để hiển thị SnackBar từ background service
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const MyApp({
    Key? key,
    required this.analyticsService,
    required this.remoteConfigService,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  // Hàm helper tĩnh để giúp các Widget con yêu cầu app rebuild lại (ví dụ khi fetch config thành công)
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  // Hàm trigger rebuild lại toàn bộ cây Widget (bao gồm cả theme)
  void refreshApp() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();

    return MaterialApp(
      scaffoldMessengerKey: MyApp.scaffoldMessengerKey,
      title: 'Lab 3 Firebase App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );
          }
          if (snapshot.hasData) {
            // Đã đăng nhập -> Vào Dashboard chính
            return MainNavigationScreen(
              analyticsService: widget.analyticsService,
              remoteConfigService: widget.remoteConfigService,
            );
          } else {
            // Chưa đăng nhập -> Vào màn hình Login
            return LoginScreen(
              analyticsService: widget.analyticsService,
              remoteConfigService: widget.remoteConfigService,
            );
          }
        },
      ),
    );
  }
}
