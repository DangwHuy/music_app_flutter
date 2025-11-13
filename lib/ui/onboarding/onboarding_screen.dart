import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lan2tesst/ui/home/home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Chào mừng đến với Viewly!',
      'description': 'Khám phá thế giới hình ảnh và kết nối với cộng đồng sáng tạo',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': 'Chia sẻ khoảnh khắc',
      'description': 'Đăng tải những bức ảnh đẹp nhất và tương tác với bạn bè',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Thiết kế chuyên nghiệp',
      'description': 'Tận hưởng giao diện được thiết kế tỉ mỉ cho trải nghiệm tốt nhất',
      'image': 'assets/images/onboarding3.png',
    },
    {
      'title': 'Cộng đồng sáng tạo',
      'description': 'Tham gia vào cộng đồng những người yêu thích nhiếp ảnh và sáng tạo',
      'image': 'assets/images/onboarding4.png',
    },
    {
      'title': 'Công nghệ tiên tiến',
      'description': 'Trải nghiệm những tính năng mới nhất với công nghệ hiện đại',
      'image': 'assets/images/onboarding5.png',
    },
    {
      'title': 'Bắt đầu hành trình',
      'description': 'Mọi thứ đã sẵn sàng. Hãy bắt đầu khám phá Viewly ngay bây giờ!',
      'image': 'assets/images/onboarding6.png',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MusicHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final isSquareImage = index >= 2; // Từ slide thứ 3 trở đi dùng hình vuông

                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image Container - hình tròn cho 2 slide đầu, hình vuông bo tròn cho các slide sau
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: isSquareImage ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: isSquareImage ? BorderRadius.circular(20) : null,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE94560),
                                Color(0xFF533483),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: isSquareImage ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: isSquareImage ? BorderRadius.circular(12) : null,
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: isSquareImage ? BorderRadius.circular(12) : BorderRadius.circular(140),
                              child: slide['image']!.startsWith('assets')
                                  ? Image.asset(
                                slide['image']!,
                                width: 240,
                                height: 240,
                                fit: BoxFit.cover,
                              )
                                  : Icon(
                                _getIconForPage(index),
                                size: isSquareImage ? 80 : 100,
                                color: const Color(0xFF533483),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        // Title
                        Text(
                          slide['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Description
                        Text(
                          slide['description']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom section
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Dot indicators - cập nhật cho 6 slide
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 30 : 12,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _currentPage == index
                              ? const Color(0xFFE94560)
                              : Colors.white.withOpacity(0.4),
                          boxShadow: _currentPage == index
                              ? [
                            BoxShadow(
                              color: const Color(0xFFE94560).withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip button - ẩn ở slide cuối
                      _currentPage == _slides.length - 1
                          ? const SizedBox(width: 80) // Placeholder để cân bằng layout
                          : TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Next/Start button
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE94560),
                              Color(0xFF533483),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE94560).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _currentPage == _slides.length - 1
                              ? _completeOnboarding
                              : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? 'Bắt đầu'
                                    : 'Tiếp tục',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _slides.length - 1
                                    ? Icons.rocket_launch
                                    : Icons.arrow_forward_ios,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.explore;
      case 1:
        return Icons.photo_camera;
      case 2:
        return Icons.design_services;
      case 3:
        return Icons.people;
      case 4:
        return Icons.bolt;
      case 5:
        return Icons.flag;
      default:
        return Icons.star;
    }
  }
}