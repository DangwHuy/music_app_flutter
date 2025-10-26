import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:story_view/story_view.dart';
// TODO: Thêm import video_player nếu muốn hỗ trợ video

class StoryViewScreen extends StatefulWidget {
  final String userId; // ID của người có story cần xem
  final List<QueryDocumentSnapshot> stories; // Danh sách các document story của người đó

  const StoryViewScreen({
    super.key,
    required this.userId,
    required this.stories,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController _storyController = StoryController();
  final List<StoryItem> _storyItems = [];

  @override
  void initState() {
    super.initState();
    _loadStoryItems();
  }

  // Hàm để chuyển đổi dữ liệu Firestore thành các StoryItem
  void _loadStoryItems() {
    // Sắp xếp lại story theo thời gian tăng dần (từ cũ đến mới) để hiển thị đúng thứ tự
    widget.stories.sort((a, b) {
      final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return (aTimestamp ?? Timestamp(0,0)).compareTo(bTimestamp ?? Timestamp(0,0));
    });


    for (var storyDoc in widget.stories) {
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final mediaUrl = storyData['mediaUrl'] as String?;
      final mediaType = storyData['mediaType'] as String? ?? 'image'; // Mặc định là image
      // Thời gian hiển thị story (ví dụ: 5 giây cho ảnh)
      final duration = Duration(seconds: (mediaType == 'image' ? 50 : 10)); // Video có thể dài hơn

      if (mediaUrl != null) {
        if (mediaType == 'image') {
          _storyItems.add(
            StoryItem.pageImage(
              url: mediaUrl,
              controller: _storyController,
              caption: Text(storyData['caption'] ?? '', // TODO: Thêm caption nếu có
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              duration: duration,
            ),
          );
        } else if (mediaType == 'video') {
          _storyItems.add(
            StoryItem.pageVideo(
              mediaUrl, // URL video
              controller: _storyController,
              caption: Text(storyData['caption'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18)),
              duration: duration, // Thời gian tối đa hiển thị video (hoặc để null nếu muốn tự động)
              // imageFit: BoxFit.contain, // Có thể chỉnh fit cho video
            ),
          );
          // Lưu ý: Để video hoạt động, bạn cần thêm gói video_player
          // và cấu hình thêm cho iOS/Android theo hướng dẫn của gói video_player
        }
      }
    }
    // Thêm một item "rỗng" cuối cùng để xử lý khi xem xong
    // _storyItems.add(StoryItem.text(title: "", backgroundColor: Colors.transparent));
  }

  // Hàm được gọi khi xem xong tất cả story
  void _onComplete() {
    if (mounted) {
      Navigator.of(context).pop(); // Quay lại màn hình trước đó
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin người đăng story (để hiển thị avatar/tên ở góc trên)
    final firstStoryData = widget.stories.isNotEmpty
        ? widget.stories.first.data() as Map<String, dynamic>
        : null;
    final username = firstStoryData?['username'] ?? 'User';
    final userAvatarUrl = firstStoryData?['userAvatarUrl'] as String?;
    // final timestamp = firstStoryData?['timestamp'] as Timestamp?; // Thời gian đăng story đầu tiên

    return Scaffold(
      body: Stack( // Stack để đặt thông tin user lên trên StoryView
        children: [
          // Phần hiển thị Story chính
          (_storyItems.isNotEmpty)
              ? StoryView(
            storyItems: _storyItems,
            controller: _storyController,
            onComplete: _onComplete,
            onVerticalSwipeComplete: (direction) { // Cho phép vuốt xuống để thoát
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            },
            // progressPosition: ProgressPosition.top, // Thanh thời gian ở trên
            // repeat: false, // Không lặp lại
            // inline: false, // Hiển thị toàn màn hình
          )
              : const Center( // Hiển thị nếu không load được story item nào
            child: Text("Không thể tải story", style: TextStyle(color: Colors.white)),
          ),

          // Phần thông tin người đăng (Avatar, Tên, Thời gian) ở góc trên bên trái
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // Dưới thanh status bar
            left: 10,
            right: 10, // Thêm right để giới hạn chiều rộng Text
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl) : null,
                  child: userAvatarUrl == null ? const Icon(Icons.person, size: 18, color: Colors.white70) : null,
                ),
                const SizedBox(width: 8),
                Expanded( // Expanded để tên không bị tràn
                  child: Text(
                    username,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                    overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu tên quá dài
                  ),
                ),
                // TODO: Hiển thị thời gian đăng story (ví dụ: 2h)
                // Text(
                //   _formatStoryTime(timestamp), // Cần hàm format thời gian
                //   style: const TextStyle(color: Colors.white70, fontSize: 12, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                // ),
                const Spacer(), // Đẩy nút close sang phải
                IconButton( // Nút đóng story
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}