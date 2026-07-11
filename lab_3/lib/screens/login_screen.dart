import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';

class LoginScreen extends StatefulWidget {
  final FirebaseAnalyticsService analyticsService;
  final FirebaseRemoteConfigService remoteConfigService;

  const LoginScreen({
    Key? key,
    required this.analyticsService,
    required this.remoteConfigService,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUpMode = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ email và mật khẩu.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUpMode) {
        // 1. Đăng ký tài khoản mới trên Firebase Auth
        widget.analyticsService.logButtonClick(
          buttonId: 'register_submit_btn',
          screenName: 'Login',
        );
        
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Ghi nhận hành vi Đăng ký thành công lên Analytics
        widget.analyticsService.logCustomEvent(
          name: 'user_register_success',
          parameters: {'email': email},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký tài khoản thành công!')),
          );
        }
      } else {
        // 2. Đăng nhập tài khoản cũ trên Firebase Auth
        widget.analyticsService.logButtonClick(
          buttonId: 'login_submit_btn',
          screenName: 'Login',
        );

        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Ghi nhận hành vi Đăng nhập thành công lên Analytics
        widget.analyticsService.logCustomEvent(
          name: 'user_login_success',
          parameters: {'email': email},
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đã xảy ra lỗi xác thực.';
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản với email này.';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không chính xác.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng bởi một tài khoản khác.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu (phải chứa tối thiểu 6 ký tự).';
      } else if (e.code == 'invalid-email') {
        message = 'Định dạng email không hợp lệ.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.remoteConfigService.getPrimaryColor();
    final welcomeMessage = widget.remoteConfigService.getWelcomeMessage();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.15),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor,
                    child: const Icon(
                      Icons.lock_person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Welcome message from remote config
                  Text(
                    welcomeMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUpMode 
                        ? 'Tạo tài khoản thật trên Firebase Authentication'
                        : 'Đăng nhập vào tài khoản thật của bạn',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  // Email Input
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password Input
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isSignUpMode ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Toggle Mode Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                      });
                    },
                    child: Text(
                      _isSignUpMode
                          ? 'Đã có tài khoản? Đăng nhập ngay'
                          : 'Chưa có tài khoản? Đăng ký tại đây',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
