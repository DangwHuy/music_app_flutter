import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharePostDialog extends StatefulWidget {
  final String postId;
  final String postImageUrl;
  final String postCaption;

  const SharePostDialog({
    super.key,
    required this.postId,
    required this.postImageUrl,
    required this.postCaption,
  });

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _filteredFollowers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _sharingInProgress = {};

  @override
  void initState() {
    super.initState();
    _loadFollowers();
    _searchController.addListener(_filterFollowers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Lấy danh sách followers
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = currentUserDoc.data() as Map<String, dynamic>;
      final followerIds = List<String>.from(userData['followers'] ?? []);

      if (followerIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _followers = [];
          _filteredFollowers = [];
        });
        return;
      }

      // Lấy thông tin của từng follower
      final followersList = <Map<String, dynamic>>[];

      for (String followerId in followerIds) {
        final followerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(followerId)
            .get();

        if (followerDoc.exists) {
          final followerData = followerDoc.data() as Map<String, dynamic>;
          followerData['uid'] = followerId;
          followersList.add(followerData);
        }
      }

      // Sắp xếp theo tên
      followersList.sort((a, b) {
        final nameA = a['displayName'] ?? a['username'] ?? '';
        final nameB = b['displayName'] ?? b['username'] ?? '';
        return nameA.compareTo(nameB);
      });

      setState(() {
        _followers = followersList;
        _filteredFollowers = followersList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading followers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterFollowers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFollowers = _followers;
      } else {
        _filteredFollowers = _followers.where((follower) {
          final username = (follower['username'] ?? '').toLowerCase();
          final displayName = (follower['displayName'] ?? '').toLowerCase();
          return username.contains(query) || displayName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _shareToUser(String recipientId, String recipientName) async {
    if (_sharingInProgress.contains(recipientId)) return;

    setState(() => _sharingInProgress.add(recipientId));

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Lấy thông tin user hiện tại
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUsername = currentUserData['username'] ?? 'Someone';

      // Tạo hoặc lấy conversation ID
      final conversationId = _getConversationId(currentUser.uid, recipientId);

      // Kiểm tra conversation đã tồn tại chưa
      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        // Tạo conversation mới
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .set({
          'participants': [currentUser.uid, recipientId],
          'lastMessage': 'Đã chia sẻ một bài viết',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Gửi tin nhắn với thông tin post
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'text': 'Đã chia sẻ một bài viết',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'post_share',
        'sharedPost': {
          'postId': widget.postId,
          'imageUrl': widget.postImageUrl,
          'caption': widget.postCaption,
        },
      });

      // Update lastMessage trong conversation
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': 'Đã chia sẻ một bài viết',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      setState(() => _sharingInProgress.remove(recipientId));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chia sẻ đến $recipientName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sharing post: $e');
      setState(() => _sharingInProgress.remove(recipientId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chia sẻ. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getConversationId(String userId1, String userId2) {
    // Tạo ID duy nhất cho conversation (sắp xếp để đảm bảo consistency)
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text(
                  'Chia sẻ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Followers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFollowers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Chưa có người theo dõi nào'
                        : 'Không tìm thấy kết quả',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredFollowers.length,
              itemBuilder: (context, index) {
                final follower = _filteredFollowers[index];
                final userId = follower['uid'] as String;
                final isSharing = _sharingInProgress.contains(userId);

                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: follower['avatarUrl'] != null
                        ? NetworkImage(follower['avatarUrl'])
                        : null,
                    child: follower['avatarUrl'] == null
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                  title: Text(
                    follower['displayName']?.isNotEmpty == true
                        ? follower['displayName']
                        : follower['username'] ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: follower['displayName']?.isNotEmpty == true
                      ? Text(
                    '@${follower['username'] ?? ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  )
                      : null,
                  trailing: isSharing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : ElevatedButton(
                    onPressed: () => _shareToUser(
                      userId,
                      follower['displayName'] ?? follower['username'] ?? 'User',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Gửi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function để show dialog
void showSharePostDialog(BuildContext context, {
  required String postId,
  required String postImageUrl,
  required String postCaption,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SharePostDialog(
      postId: postId,
      postImageUrl: postImageUrl,
      postCaption: postCaption,
    ),
  );
}