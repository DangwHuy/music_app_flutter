import 'dart:io'; // Cần thiết để sử dụng 'File'
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Gói chọn ảnh
import 'package:firebase_storage/firebase_storage.dart'; // Gói tải ảnh lên

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  File? _selectedImageFile; // Biến để giữ ảnh đã chọn

  // Hàm này để chọn ảnh từ thư viện (KHÔNG CÓ CẮT)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
    }
  }

  // Code cũ của bạn (Notify followers - Giữ nguyên)
  Future<void> _notifyFollowers(String postId, String postImageUrl, String caption) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
    final username = userDoc.data()?['username'] ?? 'someone';
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
        'caption': caption,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit();
  }

  // Hàm tải ảnh lên Storage (Giữ nguyên)
  Future<String> _uploadImageToStorage(File imageFile, String userId) async {
    String fileName = 'post_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // Hàm xử lý đăng bài (Giữ nguyên)
  Future<void> _handlePost() async {
    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một ảnh.')),
      );
      return;
    }
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng viết mô tả.')),
      );
      return;
    }
    setState(() { _isUploading = true; });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() { _isUploading = false; });
      return;
    }
    try {
      final String uploadedImageUrl = await _uploadImageToStorage(_selectedImageFile!, currentUser.uid);
      final String caption = _captionController.text;
      final newPostRef = await FirebaseFirestore.instance.collection('posts').add({
        'userId': currentUser.uid,
        'imageUrl': uploadedImageUrl,
        'caption': caption,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _notifyFollowers(newPostRef.id, uploadedImageUrl, caption);
      if (mounted) { Navigator.of(context).pop(); }
    } catch (e) {
      setState(() { _isUploading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đăng bài: $e')),
        );
      }
    }
  }

  // Giao diện (UI) của phiên bản trước (Giữ nguyên)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết mới'),
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
              child: const Text('Đăng', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage, // <- Hàm pickImage không có cắt
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImageFile == null
                      ? const Center(
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImageFile!, // <- Chỉ hiển thị ảnh đã chọn
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Bạn đang nghĩ gì?',
                    border: InputBorder.none,
                  ),
                  maxLines: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}