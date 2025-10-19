import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _selectImage() async {
    final XFile? selectedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _imageFile = File(selectedImage.path);
      });
    }
  }

  Future<void> _handlePost() async {
    if (_imageFile == null || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle user not logged in
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      // 1. Upload image to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child('posts').child(fileName);
      await storageRef.putFile(_imageFile!);
      final String imageUrl = await storageRef.getDownloadURL();

      // 2. Create post document in Firestore
      final postsCollection = FirebaseFirestore.instance.collection('posts');
      await postsCollection.add({
        'userId': currentUser.uid,
        'imageUrl': imageUrl,
        'caption': _captionController.text,
        'likes': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Close the screen
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_imageFile == null)
              GestureDetector(
                onTap: _selectImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  ),
                ),
              )
            else
              Image.file(_imageFile!, height: 300, width: double.infinity, fit: BoxFit.cover),
            
            const SizedBox(height: 16),

            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
