import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lan2tesst/ui/home/home.dart'; // Import trang home

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Danh sách slide (tùy chỉnh theo app của bạn)
  final List<Map<String, String>> _slides = [
    {
      'title': 'Chào mừng đến với Viewly!',
      'description': 'Ứng dụng chia sẻ khoảnh khắc. Khám phá và kết nối.',
      'image': 'assets/images/onboarding1.png', // Thay bằng ảnh thật hoặc dùng Icon
    },
    {
      'title': 'Tạo bài viết',
      'description': 'Đăng ảnh và tương tác với bạn bè.',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Khám phá',
      'description': 'Xem story và reels thú vị.',
      'image': 'assets/images/onboarding3.png',
    },
  ];

  // Hàm hoàn thành onboarding và chuyển sang home
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true); // Lưu trạng thái
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MusicHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hiển thị ảnh hoặc icon placeholder
                      slide['image']!.startsWith('assets')
                          ? Image.asset(slide['image']!, height: 200)
                          : Icon(Icons.image, size: 200, color: Colors.grey),
                      const SizedBox(height: 40),
                      Text(
                        slide['title']!,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        slide['description']!,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Phần dưới: Indicator và nút
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút bỏ qua
                TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Bỏ qua'),
                ),
                // Indicator trang
                Row(
                  children: List.generate(
                    _slides.length,
                        (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Nút tiếp hoặc bắt đầu
                ElevatedButton(
                  onPressed: _currentPage == _slides.length - 1
                      ? _completeOnboarding
                      : () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  ),
                  child: Text(_currentPage == _slides.length - 1 ? 'Bắt đầu' : 'Tiếp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}