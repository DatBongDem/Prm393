import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Getter để truyền observer vào Navigator nếu cần tự động theo dõi màn hình
  FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // 1. Ghi nhận sự kiện khi chuyển màn hình/tab thủ công
  Future<void> logScreenView({required String screenName}) async {
    print('Analytics: Theo dõi màn hình -> $screenName');
    await _analytics.logEvent(
      name: 'screen_view_custom',
      parameters: {
        'screen_name': screenName,
      },
    );
  }

  // 2. Ghi nhận sự kiện tùy chỉnh (Custom Event)
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    print('Analytics: Log sự kiện -> $name với parameters: $parameters');
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // 3. Ghi nhận sự kiện nhấn nút (Button Click)
  Future<void> logButtonClick({required String buttonId, required String screenName}) async {
    await logCustomEvent(
      name: 'button_click',
      parameters: {
        'button_id': buttonId,
        'screen_name': screenName,
      },
    );
  }

  // 4. Ghi nhận bắt đầu Onboarding
  Future<void> logOnboardingStart() async {
    await logCustomEvent(name: 'onboarding_start');
  }

  // 5. Ghi nhận hoàn thành Onboarding
  Future<void> logOnboardingComplete() async {
    await logCustomEvent(name: 'onboarding_complete');
  }
}
