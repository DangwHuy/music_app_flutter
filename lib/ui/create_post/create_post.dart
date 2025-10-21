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

      // We no longer add a 'comments' field here as it is now a subcollection.
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'imageUrl': randomImageUrl,
        'caption': _captionController.text,
        'likes': [], // The 'likes' for the post itself
        'timestamp': FieldValue.serverTimestamp(),
      });

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
              autofocus: true, // Automatically focus the text field
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
