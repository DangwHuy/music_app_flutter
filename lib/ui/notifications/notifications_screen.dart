import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/post_detail/post_detail_screen.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago; // Thêm package này vào pubspec.yaml nếu chưa có

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // UPGRADED: Function dịch sang tiếng Việt và thêm icon cho loại thông báo.
  Widget _buildNotificationMessage(Map<String, dynamic> notification) {
    final String actorUsername = notification['actorUsername'] ?? 'Ai đó';
    final String type = notification['type'] ?? '';

    String message;
    IconData icon;
    switch (type) {
      case 'like':
        message = 'đã thích bài viết của bạn.';
        icon = Icons.favorite;
        break;
      case 'comment':
        message = 'đã bình luận về bài viết của bạn.';
        icon = Icons.comment;
        break;
      case 'follow':
        message = 'đã bắt đầu theo dõi bạn.';
        icon = Icons.person_add;
        break;
      default:
        message = 'đã tương tác với bạn.';
        icon = Icons.notifications;
    }

    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: [
                TextSpan(
                  text: actorUsername,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' $message'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // UPGRADED: Function giữ nguyên, chỉ dịch SnackBar.
  void _handleTap(BuildContext context, Map<String, dynamic> notification) async {
    final String? postId = notification['postId'];
    final String? actorId = notification['actorId'];
    final String type = notification['type'] ?? '';

    if (type == 'like' || type == 'comment') {
      if (postId != null) {
        try {
          // Fetch the full post document from Firestore.
          final DocumentSnapshot postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
          if (postDoc.exists) {
            // Navigate by passing the entire document, which is now required.
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PostDetailScreen(postDocument: postDoc)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bài đăng này không còn tồn tại.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể tải bài đăng: $e')),
          );
        }
      }
    } else if (type == 'follow') {
      if (actorId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserProfileScreen(userId: actorId)),
        );
      }
    }
  }

  // NEW: Widget giữ nguyên, nhưng có thể thêm cache nếu cần (tùy chọn: dùng cached_network_image).
  Widget _buildLeadingAvatar(String? actorId) {
    if (actorId == null) {
      return const CircleAvatar(child: Icon(Icons.person));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(actorId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const CircleAvatar(child: Icon(Icons.person));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String? avatarUrl = userData['avatarUrl']; // Giả sử trường này tồn tại trong user doc

        return CircleAvatar(
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person) : null,
        );
      },
    );
  }

  // UPGRADED: Build method với UI đẹp hơn (Card, padding, divider) và text tiếng Việt.
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: const Center(child: Text('Vui lòng đăng nhập.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        elevation: 2, // Thêm shadow nhẹ cho AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1), // Thêm divider giữa item
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notification = notificationDoc.data() as Map<String, dynamic>;
              final type = notification['type'] ?? '';
              final Timestamp? timestamp = notification['timestamp'];
              final String? actorId = notification['actorId'];

              return Dismissible(
                key: Key(notificationDoc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await notificationDoc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thông báo đã bị xóa')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  elevation: 2, // Bóng đổ nhẹ cho card
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Margin cho card
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Bo góc
                  child: ListTile(
                    leading: _buildLeadingAvatar(actorId), // Avatar đồng bộ
                    title: _buildNotificationMessage(notification), // Message với icon
                    subtitle: timestamp != null
                        ? Text(timeago.format(timestamp.toDate(), locale: 'vi')) // Hiển thị thời gian, hỗ trợ tiếng Việt nếu cấu hình
                        : null,
                    trailing: type == 'follow'
                        ? null // Không có hình ảnh cho follow
                        : (notification['postImageUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0), // Bo góc cho hình ảnh
                      child: Image.network(notification['postImageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                    )
                        : null),
                    contentPadding: const EdgeInsets.all(16.0), // Padding lớn hơn cho card
                    onTap: () => _handleTap(context, notification),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}