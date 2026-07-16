import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/firebase_analytics_service.dart';

/// ViewModel cho luồng xác thực (MVVM).
///
/// Chứa toàn bộ nghiệp vụ đăng nhập/đăng ký với Firebase Authentication;
/// View (LoginScreen) chỉ quan sát [isLoading] và hiển thị thông báo lỗi
/// mà các phương thức trả về (null = thành công, chuỗi = thông báo lỗi).
class AuthViewModel extends ChangeNotifier {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseAuth _auth;

  AuthViewModel({required this.analyticsService, FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// Đăng nhập bằng Google. Trả về null nếu thành công hoặc người dùng tự hủy;
  /// trả về thông báo lỗi tiếng Việt nếu thất bại.
  Future<String?> signInWithGoogle() async {
    analyticsService.logButtonClick(
      buttonId: 'google_signin_btn',
      screenName: 'Login',
    );
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Buộc hiện hộp thoại chọn tài khoản

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy — không phải lỗi

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      analyticsService.logCustomEvent(
        name: 'login',
        parameters: {'method': 'google', 'email': googleUser.email},
      );
      return null;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      return 'Lỗi đăng nhập Google: $e\nVui lòng thử lại hoặc đăng nhập bằng Email.';
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng nhập bằng Email/Mật khẩu. Trả về null nếu thành công.
  Future<String?> signInWithEmail(String email, String password) async {
    final validationError = _validate(email, password);
    if (validationError != null) return validationError;

    analyticsService.logButtonClick(
      buttonId: 'login_submit_btn',
      screenName: 'Login',
    );
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      analyticsService.logCustomEvent(
        name: 'user_login_success',
        parameters: {'email': email},
      );
      analyticsService.logCustomEvent(
        name: 'login',
        parameters: {'method': 'email_password', 'email': email},
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'Lỗi: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng ký tài khoản mới. Trả về null nếu thành công.
  Future<String?> register(String email, String password) async {
    final validationError = _validate(email, password);
    if (validationError != null) return validationError;

    analyticsService.logButtonClick(
      buttonId: 'register_submit_btn',
      screenName: 'Login',
    );
    _setLoading(true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      analyticsService.logCustomEvent(
        name: 'user_register_success',
        parameters: {'email': email},
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      return 'Lỗi: $e';
    } finally {
      _setLoading(false);
    }
  }

  String? _validate(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return 'Vui lòng điền đầy đủ email và mật khẩu.';
    }
    return null;
  }

  /// Ánh xạ mã lỗi Firebase Auth sang thông báo tiếng Việt dễ hiểu.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (phải chứa tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      default:
        return 'Đã xảy ra lỗi xác thực.';
    }
  }
}
