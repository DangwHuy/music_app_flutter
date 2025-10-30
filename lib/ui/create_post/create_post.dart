import 'dart:io'; // Cần thiết để sử dụng 'File'
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Gói chọn ảnh/video
import 'package:firebase_storage/firebase_storage.dart'; // Gói tải lên
import 'package:lan2tesst/ui/reels/reels_screen.dart'; // Import ReelsTab

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  File? _selectedFile; // *** THAY ĐỔI: Hỗ trợ cả ảnh và video ***

  // *** THAY ĐỔI: Hàm chọn media (ảnh hoặc video) ***
  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Chọn ảnh'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? file = await picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                setState(() {
                  _selectedFile = File(file.path);
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Chọn video'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
              if (file != null) {
                setState(() {
                  _selectedFile = File(file.path);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // Code cũ của bạn (Notify followers - Giữ nguyên)
  Future<void> _notifyFollowers(String postId, String mediaUrl, String caption, bool isVideo) async {
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
        'type': isVideo ? 'new_reel' : 'new_post',
        'postId': postId,
        'postImageUrl': mediaUrl,
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

  // *** THÊM: Hàm tải video lên Storage ***
  Future<String> _uploadVideoToStorage(File videoFile, String userId) async {
    String fileName = 'videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(videoFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // *** THAY ĐỔI: Hàm xử lý đăng bài với logic kiểm tra video ***
  Future<void> _handlePost() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một file.')),
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
      final isVideo = _selectedFile!.path.endsWith('.mp4') || _selectedFile!.path.endsWith('.mov') || _selectedFile!.path.endsWith('.avi');
      String mediaUrl;
      String collection = isVideo ? 'reels' : 'posts';
      String field = isVideo ? 'videoUrl' : 'imageUrl';

      if (isVideo) {
        mediaUrl = await _uploadVideoToStorage(_selectedFile!, currentUser.uid);
      } else {
        mediaUrl = await _uploadImageToStorage(_selectedFile!, currentUser.uid);
      }

      final String caption = _captionController.text;
      final newPostRef = await FirebaseFirestore.instance.collection(collection).add({
        'userId': currentUser.uid,
        field: mediaUrl,
        'caption': caption,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _notifyFollowers(newPostRef.id, mediaUrl, caption, isVideo);

      if (isVideo && mounted) {
        // *** THÊM: Chuyển sang Reels nếu là video ***
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ReelsTab()));
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() { _isUploading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đăng bài: $e')),
        );
      }
    }
  }

  // Giao diện (UI) của phiên bản trước (Giữ nguyên, chỉ sửa onTap)
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
                onTap: _pickMedia, // *** THAY ĐỔI: Gọi _pickMedia để chọn ảnh/video ***
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedFile == null
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
                      _selectedFile!, // Hiển thị thumbnail (cho cả ảnh và video)
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