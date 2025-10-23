import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  // New function to create notifications for followers
  Future<void> _notifyFollowers(String postId, String postImageUrl, String caption) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
    final username = userDoc.data()?['username'] ?? 'someone';

    // Use a batch write to create all notifications at once for efficiency
    final WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String followerId in followers) {
      final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notificationRef, {
        'recipientId': followerId,
        'actorId': currentUser.uid,
        'actorUsername': username,
        'type': 'new_post',
        'postId': postId,
        'postImageUrl': postImageUrl, 
        'caption': caption, // Include the caption
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    await batch.commit();
  }

  Future<void> _handlePost() async {
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a caption.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      final String randomImageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400';
      final String caption = _captionController.text;

      // Create the post first
      final newPostRef = await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'imageUrl': randomImageUrl,
        'caption': caption,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Then, notify followers about the new post
      await _notifyFollowers(newPostRef.id, randomImageUrl, caption);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextButton(
              onPressed: _handlePost,
              child: const Text('Post', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              autofocus: true, 
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: InputBorder.none,
              ),
              maxLines: 8,
            ),
          ],
        ),
      ),
    );
  }
}
