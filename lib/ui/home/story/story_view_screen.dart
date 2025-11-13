import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:story_view/story_view.dart';

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

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  final StoryController _storyController = StoryController();
  final List<StoryItem> _storyItems = [];

  // Thêm các biến mới
  int _currentStoryIndex = 0;
  bool _isLiked = false;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _loadStoryItems();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkIfLiked();
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  // Kiểm tra xem có phải chính chủ không
  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  // Lấy ID của story hiện tại
  String? get _currentStoryId =>
      widget.stories.isNotEmpty && _currentStoryIndex < widget.stories.length
          ? widget.stories[_currentStoryIndex].id
          : null;

  // Kiểm tra đã like chưa
  Future<void> _checkIfLiked() async {
    if (_currentStoryId == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final storyDoc = await FirebaseFirestore.instance
          .collection('stories')
          .doc(_currentStoryId)
          .get();

      if (storyDoc.exists && mounted) {
        final likes = List<String>.from(storyDoc.data()?['likes'] ?? []);
        setState(() {
          _isLiked = likes.contains(currentUser.uid);
        });
      }
    } catch (e) {
      // Không làm gì nếu lỗi
    }
  }

  // Hàm để chuyển đổi dữ liệu Firestore thành các StoryItem (GIỮ NGUYÊN)
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
      final duration = Duration(seconds: (mediaType == 'image' ? 50 : 300));

      if (mediaUrl != null) {
        if (mediaType == 'image') {
          _storyItems.add(
            StoryItem.pageImage(
              url: mediaUrl,
              controller: _storyController,
              caption: Text(storyData['caption'] ?? '',
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
              duration: duration,
            ),
          );
        }
      }
    }
  }

  // Toggle like
  Future<void> _toggleLike() async {
    if (_currentStoryId == null || _isOwner) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLiked = !_isLiked;
    });

    _likeAnimationController.forward().then((_) => _likeAnimationController.reverse());

    try {
      final storyRef = FirebaseFirestore.instance.collection('stories').doc(_currentStoryId);
      if (_isLiked) {
        await storyRef.update({'likes': FieldValue.arrayUnion([currentUser.uid])});
      } else {
        await storyRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
      }
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
      });
    }
  }

  // Xóa story
  Future<void> _deleteStory() async {
    if (!_isOwner || _currentStoryId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Story?'),
        content: const Text('Story này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('stories').doc(_currentStoryId).delete();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Không làm gì
      }
    }
  }

  // Format thời gian
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final storyTime = timestamp.toDate();
    final difference = now.difference(storyTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}ph';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}ng';
    }
  }

  // Hàm được gọi khi xem xong tất cả story (GIỮ NGUYÊN)
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
    final timestamp = firstStoryData?['timestamp'] as Timestamp?;

    return Scaffold(
      body: Stack( // Stack để đặt thông tin user lên trên StoryView
        children: [
          // Phần hiển thị Story chính (GIỮ NGUYÊN)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                        ),
                    ],
                  ),
                ),
                // Nút xóa (chỉ hiện với chính chủ)
                if (_isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                    onPressed: _deleteStory,
                  ),
                // Nút đóng story (GIỮ NGUYÊN)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Nút like (chỉ hiện khi không phải chính chủ)
          if (!_isOwner)
            Positioned(
              bottom: 100,
              right: 20,
              child: GestureDetector(
                onTap: _toggleLike,
                child: AnimatedBuilder(
                  animation: _likeAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_likeAnimationController.value * 0.3),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}