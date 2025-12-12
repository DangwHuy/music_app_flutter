import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lan2tesst/ui/home/home.dart';
import 'package:lan2tesst/ui/onboarding/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _snowController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Animation cho tuyết rơi
    _snowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

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
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final prefs = await SharedPreferences.getInstance();
        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => hasSeenOnboarding
                  ? const MusicHomePage()
                  : const OnboardingScreen(),
            ),
          );
        }
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'username': user.email!.split('@')[0],
            'email': user.email,
            'displayName': '',
            'bio': '',
            'avatarUrl': null,
            'posts': 0,
            'followers': [],
            'following': [],
          });
        }

        setState(() {
          _isLogin = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.card_giftcard, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('🎄 Đăng ký thành công! Vui lòng đăng nhập.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _snowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFD32F2F), // Đỏ Giáng Sinh
              const Color(0xFFC62828),
              const Color(0xFF1B5E20), // Xanh cây thông
              const Color(0xFF2E7D32),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Hiệu ứng tuyết rơi
            ...List.generate(20, (index) {
              return AnimatedBuilder(
                animation: _snowController,
                builder: (context, child) {
                  final offset = (_snowController.value + index * 0.05) % 1.0;
                  return Positioned(
                    left: (index * 50.0) % MediaQuery.of(context).size.width,
                    top: offset * MediaQuery.of(context).size.height,
                    child: Icon(
                      Icons.ac_unit,
                      color: Colors.white.withOpacity(0.3),
                      size: 15 + (index % 3) * 5,
                    ),
                  );
                },
              );
            }),

            // Nội dung chính
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Giáng Sinh với hiệu ứng
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Vòng sáng phía sau
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              // Logo chính
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 70,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              // Ngôi sao nhỏ trang trí
                              Positioned(
                                top: 0,
                                right: 10,
                                child: Icon(
                                  Icons.star,
                                  color: Colors.yellow.shade300,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // App name với theme Giáng Sinh
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              '🎄 Viewly 🎅',
                              style: TextStyle(
                                fontSize: 48,
                                fontFamily: 'Billabong',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(2, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle Giáng Sinh
                          Text(
                            '✨ Mùa lễ hội vui vẻ! ✨',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Card chứa form với theme Giáng Sinh
                          Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Trang trí góc
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.red.shade300.withOpacity(0.2),
                                    size: 60,
                                  ),
                                ),
                                Positioned(
                                  bottom: -10,
                                  left: -10,
                                  child: Icon(
                                    Icons.ac_unit,
                                    color: Colors.blue.shade200.withOpacity(0.2),
                                    size: 60,
                                  ),
                                ),

                                // Form content
                                Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Header với icon Giáng Sinh
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.celebration,
                                              color: Color(0xFFD32F2F),
                                              size: 28,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.celebration,
                                              color: Color(0xFF2E7D32),
                                              size: 28,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isLogin
                                              ? '🎁 Đăng nhập để tiếp tục'
                                              : '🎄 Điền thông tin để bắt đầu',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 30),

                                        // Email field với theme Giáng Sinh
                                        TextFormField(
                                          controller: _emailController,
                                          decoration: InputDecoration(
                                            hintText: 'Email',
                                            prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              color: Color(0xFFD32F2F),
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFFFF8F8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: Colors.red.shade100,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD32F2F),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || !value.contains('@')) {
                                              return 'Vui lòng nhập email hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Password field
                                        TextFormField(
                                          controller: _passwordController,
                                          decoration: InputDecoration(
                                            hintText: 'Mật khẩu',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: Color(0xFF2E7D32),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey.shade600,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword = !_obscurePassword;
                                                });
                                              },
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF1F8F4),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                color: Colors.green.shade100,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF2E7D32),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          obscureText: _obscurePassword,
                                          validator: (value) {
                                            if (value == null || value.length < 6) {
                                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                                            }
                                            return null;
                                          },
                                        ),

                                        // Confirm password field (only for sign up)
                                        if (!_isLogin) ...[
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller: _confirmPasswordController,
                                            decoration: InputDecoration(
                                              hintText: 'Xác nhận mật khẩu',
                                              prefixIcon: Icon(
                                                Icons.lock_outline,
                                                color: Colors.orange.shade700,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  color: Colors.grey.shade600,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                                  });
                                                },
                                              ),
                                              filled: true,
                                              fillColor: const Color(0xFFFFF8F0),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: Colors.orange.shade100,
                                                  width: 2,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: Colors.orange.shade700,
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            obscureText: _obscureConfirmPassword,
                                            validator: (value) {
                                              if (value == null ||
                                                  value != _passwordController.text) {
                                                return 'Mật khẩu xác nhận không khớp';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                        const SizedBox(height: 28),

                                        // Submit button với gradient Giáng Sinh
                                        _isLoading
                                            ? Center(
                                          child: CircularProgressIndicator(
                                            color: const Color(0xFFD32F2F),
                                          ),
                                        )
                                            : Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFD32F2F),
                                                Color(0xFFC62828),
                                                Color(0xFF2E7D32),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFD32F2F)
                                                    .withOpacity(0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _isLogin
                                                      ? Icons.login
                                                      : Icons.card_giftcard,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _isLogin ? 'Đăng nhập' : 'Đăng ký',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Toggle login/signup
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isLogin
                                                  ? "Chưa có tài khoản? "
                                                  : "Đã có tài khoản? ",
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isLogin = !_isLogin;
                                                  _animationController.reset();
                                                  _animationController.forward();
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFD32F2F),
                                                      Color(0xFF2E7D32),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _isLogin ? 'Đăng ký ngay 🎁' : 'Đăng nhập 🎄',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Footer text
                          Text(
                            '🎅 Chúc bạn một mùa Giáng Sinh an lành! 🎄',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}