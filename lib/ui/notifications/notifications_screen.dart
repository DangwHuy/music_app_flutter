import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/post_detail/post_detail_screen.dart'; // Import the new screen

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
              final String actorUsername = notification['actorUsername'] ?? 'Someone';
              final String type = notification['type'] ?? ''; // 'like' or 'comment'

              String message;
              if (type == 'like') {
                message = 'liked your post.';
              } else if (type == 'comment') {
                message = 'commented on your post.';
              } else {
                message = 'interacted with your post.';
              }

              return Dismissible(
                key: Key(notificationDoc.id), // Unique key for each item
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  // Delete the notification from Firestore
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
                  leading: const CircleAvatar(child: Icon(Icons.person)), // Placeholder avatar
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: actorUsername,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' $message'),
                      ],
                    ),
                  ),
                  trailing: notification['postImageUrl'] != null
                      ? Image.network(notification['postImageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : null,
                  onTap: () {
                    final String? postId = notification['postId'];
                    if (postId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(postId: postId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
