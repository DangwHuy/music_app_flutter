import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // *** THÊM: Import SharedPreferences ***
import 'package:lan2tesst/ui/home/home.dart'; // Import MusicHomePage
import 'package:lan2tesst/ui/onboarding/onboarding_screen.dart'; // *** THÊM: Import OnboardingScreen ***

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // *** THÊM: Controller cho xác nhận mật khẩu ***
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login logic
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // *** THÊM: Kiểm tra trạng thái onboarding sau login ***
        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => hasSeenOnboarding
                  ? const MusicHomePage()  // Đã xem hướng dẫn -> Home
                  : const OnboardingScreen(),  // Chưa xem -> Onboarding
            ),
          );
        }
      } else {
        // Sign up logic
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Create a user document in Firestore
        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'username': user.email!.split('@')[0], // a default username
            'email': user.email,
            'displayName': '',
            'bio': '',
            'avatarUrl': null,
            'posts': 0,
            'followers': [],
            'following': [],
          });
        }

        // Switch to login view after successful sign up
        setState(() {
          _isLogin = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Không tìm thấy tài khoản với email này.';
          break;
        case 'wrong-password':
          errorMessage = 'Mật khẩu không đúng.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email này đã được sử dụng.';
          break;
        case 'weak-password':
          errorMessage = 'Mật khẩu quá yếu.';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ.';
          break;
        default:
          errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // *** THÊM: Dispose controller mới ***
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 60),
                  const Text(
                    'Viewly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 60,
                      fontFamily: 'Billabong',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email', // Giữ nguyên vì là thuật ngữ chung
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Vui lòng nhập email hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        if (!_isLogin) ...[ // *** THÊM: Chỉ hiển thị khi đăng ký ***
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              hintText: 'Xác nhận mật khẩu',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value != _passwordController.text) {
                                return 'Mật khẩu xác nhận không khớp';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? "),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Đăng ký.' : 'Đăng nhập.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}