import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/post_detail/post_detail_screen.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // PRESERVED: This function is unchanged.
  Widget _buildNotificationMessage(Map<String, dynamic> notification) {
    final String actorUsername = notification['actorUsername'] ?? 'Someone';
    final String type = notification['type'] ?? '';

    String message;
    switch (type) {
      case 'like':
        message = 'liked your post.';
        break;
      case 'comment':
        message = 'commented on your post.';
        break;
      case 'follow':
        message = 'started following you.';
        break;
      default:
        message = 'interacted with you.';
    }

    return RichText(
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
    );
  }

  // UPGRADED: This function now fetches the full document before navigating.
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
              const SnackBar(content: Text('This post no longer exists.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load post: $e')),
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

  // PRESERVED: The build method is unchanged.
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
            return const Center(child: Text('You have no notifications.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final notification = notificationDoc.data() as Map<String, dynamic>;
              final type = notification['type'] ?? '';

              return Dismissible(
                key: Key(notificationDoc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await notificationDoc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification dismissed')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)), // Placeholder
                  title: _buildNotificationMessage(notification),
                  trailing: type == 'follow' 
                    ? null // No trailing image for follow notifications
                    : (notification['postImageUrl'] != null 
                      ? Image.network(notification['postImageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : null),
                  onTap: () => _handleTap(context, notification),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
