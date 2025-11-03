import 'package:cloud_firestore/cloud_firestore.dart';

/// Class này giúp cache thông tin user để tránh fetch liên tục từ Firebase
class UserDataCache {
  // Map lưu trữ data của user theo userId
  static final Map<String, Map<String, dynamic>> _cache = {};

  // Map lưu thời gian cache để biết khi nào cần refresh
  static final Map<String, DateTime> _cacheTime = {};

  // Cache tồn tại 5 phút
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Lấy thông tin user từ cache hoặc Firebase
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    // Kiểm tra xem đã có trong cache chưa
    if (_cache.containsKey(userId)) {
      final cacheAge = DateTime.now().difference(_cacheTime[userId]!);

      // Nếu cache còn mới (dưới 5 phút), trả về luôn
      if (cacheAge < _cacheDuration) {
        print('✅ Cache hit for user: $userId');
        return _cache[userId];
      }
    }

    // Cache hết hạn hoặc chưa có, fetch từ Firebase
    print('🔄 Fetching user data from Firebase: $userId');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Lưu vào cache
        _cache[userId] = data;
        _cacheTime[userId] = DateTime.now();

        return data;
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }

    return null;
  }

  /// Xóa cache (dùng khi cần refresh)
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    print('🗑️ User cache cleared');
  }

  /// Xóa cache của 1 user cụ thể
  static void clearUserCache(String userId) {
    _cache.remove(userId);
    _cacheTime.remove(userId);
    print('🗑️ Cache cleared for user: $userId');
  }
}