import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// TODO: Thêm import video_player nếu muốn hỗ trợ video

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _mediaFile; // File ảnh hoặc video đã chọn
  String _mediaType = 'image'; // Mặc định là ảnh
  bool _isUploading = false;

  // Hàm chọn ảnh/video
  Future<void> _pickMedia() async {
    // TODO: Cho phép chọn cả video (pickVideo)
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _mediaFile = File(image.path);
        _mediaType = 'image'; // Cập nhật loại media
      });
    }
    // TODO: Xử lý chọn video
  }

  // Hàm tải file lên Storage và trả về URL
  Future<String?> _uploadMediaToStorage(File mediaFile, String userId) async {
    try {
      // Đặt tên file duy nhất trong thư mục stories_media
      String fileExtension = _mediaType == 'image' ? 'jpg' : 'mp4'; // Lấy đuôi file
      String fileName = 'stories_media/$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Metadata (quan trọng cho video)
      SettableMetadata metadata = SettableMetadata(contentType: _mediaType == 'image' ? 'image/jpeg' : 'video/mp4');

      UploadTask uploadTask = storageRef.putFile(mediaFile, metadata); // Truyền metadata
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Lỗi tải media lên Storage: $e");
      return null;
    }
  }

  // Hàm đăng Tin
  Future<void> _handlePostStory() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh hoặc video.')),
      );
      return;
    }

    setState(() { _isUploading = true; });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() { _isUploading = false; });
      return; // Nên xử lý tốt hơn
    }

    try {
      // 1. Tải media lên Storage
      final String? mediaUrl = await _uploadMediaToStorage(_mediaFile!, currentUser.uid);

      if (mediaUrl == null) {
        throw Exception("Không thể tải media lên."); // Ném lỗi nếu URL là null
      }

      // 2. Lấy thông tin user hiện tại (username, avatar)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {}; // Lấy dữ liệu an toàn

      // 3. Tạo document mới trong collection 'stories'
      final Timestamp now = Timestamp.now();
      final Timestamp expiresAt = Timestamp.fromDate(now.toDate().add(const Duration(hours: 24))); // Hết hạn sau 24h

      await FirebaseFirestore.instance.collection('stories').add({
        'userId': currentUser.uid,
        'username': userData['username'] ?? 'User', // Lấy username
        'userAvatarUrl': userData['avatarUrl'],      // Lấy avatar
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType,
        'timestamp': now,
        'expiresAt': expiresAt,
        'viewers': [], // Khởi tạo danh sách người xem rỗng
      });

      if (mounted) {
        Navigator.of(context).pop(); // Quay lại màn hình trước đó
      }

    } catch (e) {
      print("Lỗi đăng tin: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể đăng tin: $e')),
        );
      }
    } finally {
      if (mounted) { setState(() { _isUploading = false; }); }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen cho story
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar trong suốt
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
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
        ],
      ),
      body: Center( // Căn giữa nội dung
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            // --- Khu vực xem trước ảnh/video ---
            GestureDetector(
              onTap: _pickMedia, // Nhấn để chọn media
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8, // Chiếm 80% chiều rộng
                height: MediaQuery.of(context).size.height * 0.6, // Chiếm 60% chiều cao
                decoration: BoxDecoration(
                  color: Colors.grey[900], // Màu nền tối
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: _mediaFile == null
                    ? const Center( // Hiển thị icon nếu chưa chọn
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.grey,
                    size: 80,
                  ),
                )
                    : ClipRRect( // Hiển thị ảnh đã chọn
                  borderRadius: BorderRadius.circular(10), // Bo góc ảnh
                  child: _mediaType == 'image'
                      ? Image.file( _mediaFile!, fit: BoxFit.contain ) // Dùng contain để xem toàn bộ ảnh
                      : const Center(child: Text("Video preview not implemented yet", style: TextStyle(color: Colors.white))), // TODO: Hiển thị video preview
                ),
              ),
            ),

            const SizedBox(height: 20), // Khoảng cách

            // Có thể thêm các nút để vẽ, thêm text, sticker vào đây sau
          ],
        ),
      ),
    );
  }
}