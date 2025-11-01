import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_cropper/image_cropper.dart'; // Uncomment nếu dùng cắt ảnh
// import 'package:shimmer/shimmer.dart'; // Uncomment nếu dùng shimmer cho loading

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  bool _isUploadingImage = false; // Loading riêng cho upload ảnh
  File? _selectedImageFile;
  String? _validationErrorName;
  String? _validationErrorUsername;
  String? _validationErrorBio;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Validation cho các trường
  void _validateFields() {
    setState(() {
      _validationErrorName = _nameController.text.trim().isEmpty
          ? 'Tên không được để trống'
          : _nameController.text.length > 50
          ? 'Tên không quá 50 ký tự'
          : null;
      _validationErrorUsername = _usernameController.text.trim().isEmpty
          ? 'Username không được để trống'
          : _usernameController.text.length > 20
          ? 'Username không quá 20 ký tự'
          : null;
      _validationErrorBio = _bioController.text.length > 150
          ? 'Tiểu sử không quá 150 ký tự'
          : null;
    });
  }

  // Hàm chọn ảnh (giữ nguyên, nhưng thêm loading)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Uncomment nếu dùng image_cropper
    // final CroppedFile? croppedFile = await ImageCropper().cropImage(...);
    // if (croppedFile != null) {
    //   setState(() { _selectedImageFile = File(croppedFile.path); });
    // }

    setState(() {
      _selectedImageFile = File(image.path);
    });
  }

  // Hàm xóa ảnh đại diện
  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
    });
  }

  // Hàm tải ảnh lên Storage (giữ nguyên)
  Future<String?> _uploadImageToStorage(File imageFile, String userId) async {
    setState(() { _isUploadingImage = true; });
    try {
      String fileName = 'avatars/$userId/profile.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Lỗi tải ảnh đại diện: $e");
      return null;
    } finally {
      if (mounted) setState(() { _isUploadingImage = false; });
    }
  }

  // Hàm lưu hồ sơ (nâng cấp với validation và confirm)
  Future<void> _saveProfile() async {
    _validateFields();
    if (_validationErrorName != null || _validationErrorUsername != null || _validationErrorBio != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng sửa lỗi trước khi lưu.')),
      );
      return;
    }

    // Dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lưu'),
        content: const Text('Bạn có chắc muốn lưu thay đổi hồ sơ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Lưu')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _isLoading = true; });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      String? newAvatarUrl = widget.userData['avatarUrl'];
      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImageToStorage(_selectedImageFile!, currentUser.uid);
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải ảnh đại diện mới.')),
          );
          setState(() { _isLoading = false; });
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatarUrl': newAvatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hồ sơ đã được cập nhật!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu hồ sơ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentAvatarUrl = widget.userData['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
          else
            AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _saveProfile,
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Phần Avatar với animation
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AnimatedOpacity(
                      opacity: _isUploadingImage ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImageFile != null
                            ? FileImage(_selectedImageFile!)
                            : (currentAvatarUrl != null ? NetworkImage(currentAvatarUrl) : null) as ImageProvider?,
                        child: (_selectedImageFile == null && currentAvatarUrl == null)
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_isUploadingImage)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Thay đổi ảnh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (_selectedImageFile != null || currentAvatarUrl != null)
                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: const Text('Xóa ảnh', style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
              const Divider(color: Colors.white54, thickness: 1, height: 40),

              // Trường Tên
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Tên hiển thị',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Nhập tên của bạn',
                          errorText: _validationErrorName,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => _validateFields(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trường Username
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Nhập username duy nhất',
                          errorText: _validationErrorUsername,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (_) => _validateFields(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Trường Bio
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Tiểu sử',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintText: 'Viết gì đó về bạn...',
                          errorText: _validationErrorBio,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 3,
                        onChanged: (_) => _validateFields(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}