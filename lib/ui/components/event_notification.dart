// file: ui/components/event_notification.dart
import 'package:flutter/material.dart';

class EventNotification extends StatelessWidget {
  const EventNotification({super.key});

  // Hàm tính số ngày còn lại đến 20/11
  int _getDaysUntilEvent() {
    final now = DateTime.now();
    final currentYear = now.year;

    // Tạo DateTime cho ngày 20/11 năm nay
    final eventDate = DateTime(currentYear, 11, 20);

    // Nếu ngày 20/11 năm nay đã qua, tính đến năm sau
    final targetDate = now.isAfter(eventDate)
        ? DateTime(currentYear + 1, 11, 20)
        : eventDate;

    return targetDate.difference(now).inDays;
  }

  // Hàm tạo thông báo dựa trên số ngày còn lại
  String _getEventMessage(int daysLeft) {
    if (daysLeft == 0) {
      return 'Hôm nay là ngày Nhà giáo Việt Nam 20/11! 🎉';
    } else if (daysLeft == 1) {
      return 'Ngày mai là ngày Nhà giáo Việt Nam 20/11!';
    } else if (daysLeft <= 7) {
      return 'Chỉ còn $daysLeft ngày nữa là đến 20/11!';
    } else if (daysLeft <= 30) {
      return 'Chuẩn bị cho ngày Nhà giáo Việt Nam 20/11 - Còn $daysLeft ngày';
    } else {
      return 'Chuẩn bị cho ngày Nhà giáo Việt Nam 20/11 - Còn $daysLeft ngày nữa';
    }
  }

  // Hàm kiểm tra có nên hiển thị thông báo không
  bool _shouldShowNotification(int daysLeft) {
    // Hiển thị thông báo trong vòng 60 ngày trước sự kiện
    return daysLeft <= 60 && daysLeft >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _getDaysUntilEvent();

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
              ? [const Color(0xFFE94560), const Color(0xFFFF6B6B)] // Màu đỏ nổi bật khi gần đến ngày
              : [const Color(0xFF533483), const Color(0xFFE94560)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hình ảnh sự kiện - thay đổi icon khi gần đến ngày
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              daysLeft <= 7 ? Icons.celebration : Icons.event,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // Nội dung thông báo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysLeft <= 7 ? 'Sự kiện đặc biệt!' : 'Sự kiện sắp tới!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getEventMessage(daysLeft),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Hiển thị thanh progress khi gần đến ngày
                if (daysLeft <= 30)
                  LinearProgressIndicator(
                    value: 1 - (daysLeft / 30),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
              ],
            ),
          ),

          // Hiển thị số ngày còn lại nổi bật
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$daysLeft',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Phiên bản đơn giản hơn nếu bạn muốn
class SimpleEventNotification extends StatelessWidget {
  const SimpleEventNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eventDate = DateTime(now.year, 11, 20);
    final daysLeft = eventDate.difference(now).inDays;

    if (daysLeft > 30 || daysLeft < 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE94560), Color(0xFF533483)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chuẩn bị cho 20/11 - Còn $daysLeft ngày',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}