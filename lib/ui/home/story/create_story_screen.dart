import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart'; // Thêm import cho video preview

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _mediaFile;
  String _mediaType = 'image'; // 'image' hoặc 'video'
  bool _isUploading = false;
  VideoPlayerController? _videoController; // Controller cho video preview

  @override
  void dispose() {
    _videoController?.dispose(); // Cleanup video controller
    super.dispose();
  }

  // Hàm chọn loại media và pick
  Future<void> _pickMedia(String type) async {
    try {
      XFile? pickedFile;
      if (type == 'image') {
        pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      } else if (type == 'video') {
        pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _mediaType = type;
        });

        // Khởi tạo video controller nếu là video
        if (_mediaType == 'video') {
          _videoController?.dispose(); // Dispose cũ nếu có
          _videoController = VideoPlayerController.file(_mediaFile!)
            ..initialize().then((_) {
              setState(() {}); // Cập nhật UI sau khi init
            });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn media: $e')),
      );
    }
  }

  // Hàm tải file lên Storage và trả về URL
  Future<String?> _uploadMediaToStorage(File mediaFile, String userId) async {
    try {
      String fileExtension = _mediaType == 'image' ? 'jpg' : 'mp4';
      String fileName = 'stories_media/$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: _mediaType == 'image' ? 'image/jpeg' : 'video/mp4',
      );

      UploadTask uploadTask = storageRef.putFile(mediaFile, metadata);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Lỗi tải media lên Storage: $e");
      return null;
    }
  }

  // Hàm đăng Tin (giữ nguyên logic, thêm validation cho video)
  Future<void> _handlePostStory() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh hoặc video.')),
      );
      return;
    }

    // Validation cơ bản: Kích thước file (tối đa 100MB cho video)
    if (_mediaType == 'video' && _mediaFile!.lengthSync() > 100 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video quá lớn (tối đa 100MB).')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final String? mediaUrl = await _uploadMediaToStorage(_mediaFile!, currentUser.uid);
      if (mediaUrl == null) throw Exception("Không thể tải media lên.");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      final Timestamp now = Timestamp.now();
      final Timestamp expiresAt = Timestamp.fromDate(now.toDate().add(const Duration(hours: 24)));

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': currentUser.uid,
        'username': userData['username'] ?? 'User',
        'userAvatarUrl': userData['avatarUrl'],
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType,
        'timestamp': now,
        'expiresAt': expiresAt,
        'viewers': [],
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print("Lỗi đăng tin: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đăng tin: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _handlePostStory,
              child: const Text(
                'Đăng Tin',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: OrientationBuilder( // Hỗ trợ xoay màn hình
        builder: (context, orientation) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Khu vực preview
                GestureDetector(
                  onTap: () => _showMediaTypeDialog(), // Nhấn để chọn loại media
                  child: Container(
                    width: MediaQuery.of(context).size.width * (orientation == Orientation.portrait ? 0.8 : 0.6),
                    height: MediaQuery.of(context).size.height * (orientation == Orientation.portrait ? 0.5 : 0.7),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[700]!, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: _mediaFile == null
                        ? const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.grey,
                        size: 80,
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _mediaType == 'image'
                          ? Image.file(_mediaFile!, fit: BoxFit.contain)
                          : (_videoController != null && _videoController!.value.isInitialized
                          ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                          : const Center(child: CircularProgressIndicator())),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Nút chọn loại media
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickMedia('image'),
                      icon: const Icon(Icons.photo),
                      label: const Text('Chọn Ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => _pickMedia('video'),
                      icon: const Icon(Icons.videocam),
                      label: const Text('Chọn Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Có thể thêm nút chỉnh sửa (vẽ, text) ở đây
              ],
            ),
          );
        },
      ),
    );
  }

  // Dialog chọn loại media
  void _showMediaTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn loại media'),
        content: const Text('Bạn muốn chọn ảnh hay video?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () { Navigator.pop(context); _pickMedia('image'); }, child: const Text('Ảnh')),
          TextButton(onPressed: () { Navigator.pop(context); _pickMedia('video'); }, child: const Text('Video')),
        ],
      ),
    );
  }
}