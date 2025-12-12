// file: ui/components/christmas_notification.dart
import 'package:flutter/material.dart';

class ChristmasNotification extends StatelessWidget {
  const ChristmasNotification({super.key});

  // Hàm tính số ngày còn lại đến 25/12
  int _getDaysUntilChristmas() {
    final now = DateTime.now();
    final currentYear = now.year;

    // Tạo DateTime cho ngày 25/12 năm nay
    final christmasDate = DateTime(currentYear, 12, 25);

    // Nếu Giáng Sinh năm nay đã qua, tính đến năm sau
    final targetDate = now.isAfter(christmasDate)
        ? DateTime(currentYear + 1, 12, 25)
        : christmasDate;

    return targetDate.difference(now).inDays;
  }

  // Hàm tạo thông báo dựa trên số ngày còn lại
  String _getChristmasMessage(int daysLeft) {
    if (daysLeft == 0) {
      return 'Chúc Mừng Giáng Sinh! Merry Christmas! 🎄🎅';
    } else if (daysLeft == 1) {
      return 'Ngày mai là Giáng Sinh rồi! 🎁';
    } else if (daysLeft <= 7) {
      return 'Giáng Sinh đang đến gần - Chỉ còn $daysLeft ngày! ⛄';
    } else if (daysLeft <= 14) {
      return 'Chuẩn bị đón Giáng Sinh thôi - Còn $daysLeft ngày nữa! 🔔';
    } else if (daysLeft <= 30) {
      return 'Mùa Giáng Sinh đang đến - Còn $daysLeft ngày! ❄️';
    } else {
      return 'Đếm ngược đến Giáng Sinh - Còn $daysLeft ngày nữa! 🎄';
    }
  }

  // Hàm kiểm tra có nên hiển thị thông báo không
  bool _shouldShowNotification(int daysLeft) {
    // Hiển thị thông báo trong vòng 60 ngày trước Giáng Sinh
    return daysLeft <= 60 && daysLeft >= 0;
  }

  // Hàm chọn icon phù hợp theo số ngày
  IconData _getChristmasIcon(int daysLeft) {
    if (daysLeft == 0) return Icons.card_giftcard;
    if (daysLeft <= 7) return Icons.celebration;
    if (daysLeft <= 14) return Icons.cake;
    return Icons.event_available;
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _getDaysUntilChristmas();

    // Chỉ hiển thị nếu trong khoảng thời gian cho phép
    if (!_shouldShowNotification(daysLeft)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: daysLeft <= 7
              ? [
            const Color(0xFFD32F2F), // Đỏ Giáng Sinh đậm
            const Color(0xFFC62828),
            const Color(0xFF1B5E20), // Xanh cây thông
          ]
              : [
            const Color(0xFFE53935), // Đỏ Giáng Sinh
            const Color(0xFF2E7D32), // Xanh lá
            const Color(0xFFFFB300), // Vàng kim
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hiệu ứng tuyết rơi (các chấm trắng mờ)
          Positioned(
            top: 5,
            right: 20,
            child: Icon(
              Icons.ac_unit,
              color: Colors.white.withOpacity(0.2),
              size: 40,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 60,
            child: Icon(
              Icons.ac_unit,
              color: Colors.white.withOpacity(0.15),
              size: 25,
            ),
          ),

          // Nội dung chính
          Row(
            children: [
              // Icon Giáng Sinh với viền sáng
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _getChristmasIcon(daysLeft),
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),

              // Nội dung thông báo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        daysLeft <= 7 ? '🎅 SỰ KIỆN ĐẶC BIỆT' : '🎄 SỰ KIỆN SẮP TỚI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Thông điệp chính
                    Text(
                      _getChristmasMessage(daysLeft),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Thanh tiến trình khi gần đến ngày
                    if (daysLeft <= 30) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: 1 - (daysLeft / 30),
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${((1 - (daysLeft / 30)) * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Số ngày còn lại với thiết kế đẹp
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '$daysLeft',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: daysLeft <= 7
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NGÀY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Phiên bản đơn giản với hiệu ứng tuyết rơi
class SimpleChristmasNotification extends StatelessWidget {
  const SimpleChristmasNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final christmasDate = DateTime(now.year, 12, 25);
    final daysLeft = christmasDate.difference(now).inDays;

    if (daysLeft > 30 || daysLeft < 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE53935),
            Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎄 Giáng Sinh đang đến',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Còn $daysLeft ngày nữa!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysLeft',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }
}