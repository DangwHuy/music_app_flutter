import 'dart:io'; // <-- THÊM IMPORT
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // <-- THÊM IMPORT
import 'package:firebase_storage/firebase_storage.dart'; // <-- THÊM IMPORT
// import 'package:image_cropper/image_cropper.dart'; // <-- Bỏ comment nếu bạn muốn dùng cắt ảnh

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  File? _selectedImageFile; // <-- Biến lưu ảnh mới

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    // KHÔNG cần load ảnh cũ vào _selectedImageFile ban đầu
  }

  // --- THÊM HÀM CHỌN ẢNH (Tương tự Create Post) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // // --- (TÙY CHỌN) BỎ COMMENT ĐOẠN NÀY ĐỂ DÙNG CẮT ẢNH ---
    // final CroppedFile? croppedFile = await ImageCropper().cropImage(
    //   sourcePath: image.path,
    //   aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Tỷ lệ vuông
    //   shape: CropShape.circle, // Cắt thành hình tròn (tùy chọn)
    //   compressQuality: 70, // Nén ảnh một chút
    //   uiSettings: [
    //     AndroidUiSettings(
    //         toolbarTitle: 'Cắt ảnh đại diện',
    //         toolbarColor: Colors.blue,
    //         toolbarWidgetColor: Colors.white,
    //         initAspectRatio: CropAspectRatioPreset.square,
    //         lockAspectRatio: true), // Khóa tỷ lệ vuông
    //     IOSUiSettings(
    //       title: 'Cắt ảnh đại diện',
    //       aspectRatioLockEnabled: true,
    //     ),
    //   ],
    // );
    // if (croppedFile != null) {
    //   setState(() {
    //     _selectedImageFile = File(croppedFile.path);
    //   });
    // }
    // --- KẾT THÚC PHẦN CẮT ẢNH ---

    // --- (BẮT BUỘC) NẾU KHÔNG DÙNG CẮT ẢNH, DÙNG ĐOẠN NÀY ---
    // (Nếu dùng cắt ảnh thì comment đoạn này lại)
    setState(() {
      _selectedImageFile = File(image.path);
    });
    // --- KẾT THÚC PHẦN KHÔNG CẮT ---
  }

  // --- THÊM HÀM TẢI ẢNH (Tương tự Create Post, nhưng lưu vào thư mục khác) ---
  Future<String?> _uploadImageToStorage(File imageFile, String userId) async {
    try {
      // Lưu ảnh đại diện vào thư mục 'avatars'
      String fileName = 'avatars/$userId/profile.jpg'; // Dùng tên cố định để ghi đè ảnh cũ
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Lỗi tải ảnh đại diện: $e");
      return null; // Trả về null nếu có lỗi
    }
  }


  // --- NÂNG CẤP HÀM LƯU HỒ SƠ ---
  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      String? newAvatarUrl = widget.userData['avatarUrl']; // Giữ URL cũ làm mặc định

      // 1. Nếu người dùng có chọn ảnh mới -> Tải lên và lấy URL mới
      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImageToStorage(_selectedImageFile!, currentUser.uid);
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl; // Cập nhật URL nếu tải lên thành công
        } else {
          // Xử lý lỗi nếu tải ảnh thất bại (ví dụ: hiển thị SnackBar)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tải ảnh đại diện mới.')),
            );
          }
          setState(() { _isLoading = false; });
          return; // Dừng lại nếu không tải được ảnh
        }
      }

      // 2. Cập nhật Firestore với tên, bio, và URL ảnh (mới hoặc cũ)
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'displayName': _nameController.text,
        'bio': _bioController.text,
        'avatarUrl': newAvatarUrl, // <-- Cập nhật URL ảnh
      });

      if (mounted) { Navigator.of(context).pop(); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu hồ sơ: $e')),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy URL ảnh đại diện hiện tại để hiển thị
    String? currentAvatarUrl = widget.userData['avatarUrl'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
              : IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView( // <-- Bọc trong SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- THÊM PHẦN HIỂN THỊ VÀ THAY ĐỔI AVATAR ---
              Center(
                child: Stack( // Stack để đặt icon lên trên ảnh
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade800,
                      // Hiển thị ảnh mới nếu đã chọn, ngược lại hiển thị ảnh cũ
                      backgroundImage: _selectedImageFile != null
                          ? FileImage(_selectedImageFile!) // Ảnh mới từ file
                          : (currentAvatarUrl != null ? NetworkImage(currentAvatarUrl) : null) as ImageProvider?, // Ảnh cũ từ URL
                      child: (_selectedImageFile == null && currentAvatarUrl == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.white70) // Icon mặc định
                          : null,
                    ),
                    // Icon nhỏ để người dùng biết là có thể nhấn đổi ảnh
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2)
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    )
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Thay đổi ảnh hồ sơ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24), // Tăng khoảng cách
              // --- KẾT THÚC PHẦN AVATAR ---

              // Các trường nhập liệu cũ
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tên', // Đổi thành 'Tên'
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // Màu nhạt hơn
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tiểu sử', // Đổi thành 'Tiểu sử'
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // Màu nhạt hơn
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}