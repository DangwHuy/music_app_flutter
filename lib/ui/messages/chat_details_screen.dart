import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // *** THÊM: Cho cập nhật Firestore ***
import 'package:firebase_auth/firebase_auth.dart'; // *** THÊM: Cho currentUser ***
import 'package:firebase_storage/firebase_storage.dart'; // *** THÊM: Cho upload ảnh ***
import 'package:image_picker/image_picker.dart'; // *** THÊM: Cho chọn ảnh ***
import 'dart:io'; // *** THÊM: Cho File ***
import 'package:lan2tesst/ui/messages/nickname_screen.dart'; // Giữ nguyên import cũ

class ChatDetailsScreen extends StatefulWidget { // *** THAY ĐỔI: Chuyển thành Stateful để quản lý state ***
  final String conversationId;
  final bool isGroup;

  const ChatDetailsScreen({super.key, required this.conversationId, required this.isGroup});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  File? _selectedImage; // Lưu ảnh đã chọn
  bool _isUploading = false; // Loading khi upload

  // Hàm chọn ảnh từ gallery hoặc camera
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Tự động upload sau khi chọn
      await _uploadAndUpdateAvatar();
    }
  }

  // Hàm hiển thị dialog chọn nguồn ảnh
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ảnh đại diện nhóm'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Thư viện'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  // Hàm upload ảnh và cập nhật Firestore
  Future<void> _uploadAndUpdateAvatar() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload ảnh lên Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_avatars/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Cập nhật groupAvatarUrl trong Firestore
      await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
        'groupAvatarUrl': downloadUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar nhóm đã được cập nhật!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật Avatar: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImage = null; // Reset sau khi upload
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tùy chọn'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: Colors.white),
            title: const Text('Chủ đề', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white),
            title: const Text('Cảm xúc nhanh', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline, color: Colors.white),
            title: const Text('Biệt danh', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NicknameScreen(conversationId: widget.conversationId),
              ));
            },
          ),
          if (widget.isGroup) // *** THÊM: Chỉ hiển thị cho nhóm ***
            ListTile(
              leading: _isUploading
                  ? const CircularProgressIndicator() // Loading khi upload
                  : const Icon(Icons.photo_camera, color: Colors.white), // Icon thay Avatar
              title: const Text('Thay đổi Avatar', style: TextStyle(color: Colors.white)),
              onTap: _isUploading ? null : _showImageSourceDialog, // Disable khi uploading
            ),
          if (widget.isGroup)
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.white),
              title: const Text('Xem thành viên', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}