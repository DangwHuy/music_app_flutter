import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  late TextEditingController _birthDateController; // Controller cho ngày sinh
  DateTime? _selectedBirthDate; // Ngày sinh đã chọn
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isCheckingUsername = false;
  File? _selectedImageFile;
  String? _validationErrorName;
  String? _validationErrorUsername;
  String? _validationErrorBio;
  String? _validationErrorBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['displayName'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    // Khởi tạo ngày sinh từ userData (nếu có, chuyển từ Timestamp)
    Timestamp? birthTimestamp = widget.userData['birthDate'];
    if (birthTimestamp != null) {
      _selectedBirthDate = birthTimestamp.toDate();
      _birthDateController = TextEditingController(text: _formatDate(_selectedBirthDate!));
    } else {
      _birthDateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Hàm format ngày thành chuỗi dd/MM/yyyy
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Hàm chọn ngày sinh từ lịch
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)), // Mặc định 18 tuổi
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
        _validateBirthDate();
      });
    }
  }

  // Validation cho ngày sinh
  void _validateBirthDate() {
    if (_selectedBirthDate == null) {
      _validationErrorBirthDate = 'Ngày sinh không được để trống';
    } else {
      int age = DateTime.now().year - _selectedBirthDate!.year;
      if (DateTime.now().month < _selectedBirthDate!.month ||
          (DateTime.now().month == _selectedBirthDate!.month && DateTime.now().day < _selectedBirthDate!.day)) {
        age--;
      }
      if (age < 13) {
        _validationErrorBirthDate = 'Bạn phải ít nhất 13 tuổi';
      } else {
        _validationErrorBirthDate = null;
      }
    }
  }

  // Validation cho các trường (bao gồm kiểm tra username duy nhất)
  void _validateFields() async {
    if (!mounted) return;

    setState(() {
      _validationErrorName = _nameController.text.trim().isEmpty
          ? 'Tên không được để trống'
          : _nameController.text.length > 50
          ? 'Tên không quá 50 ký tự'
          : null;
      _validationErrorBio = _bioController.text.length > 150
          ? 'Tiểu sử không quá 150 ký tự'
          : null;
    });

    // Kiểm tra username
    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _validationErrorUsername = 'Username không được để trống';
        _isCheckingUsername = false;
      });
      return;
    }
    if (username.length > 20) {
      setState(() {
        _validationErrorUsername = 'Username không quá 20 ký tự';
        _isCheckingUsername = false;
      });
      return;
    }

    // Kiểm tra duy nhất nếu username thay đổi
    if (username != (widget.userData['username'] ?? '')) {
      setState(() {
        _isCheckingUsername = true;
        _validationErrorUsername = null;
      });

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _validationErrorUsername = 'Username đã tồn tại';
          });
        } else {
          setState(() {
            _validationErrorUsername = null;
          });
        }
      } catch (e) {
        setState(() {
          _validationErrorUsername = 'Lỗi kiểm tra username';
        });
      } finally {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    } else {
      setState(() {
        _validationErrorUsername = null;
        _isCheckingUsername = false;
      });
    }

    // Validation ngày sinh
    _validateBirthDate();
  }

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (mounted) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
    }
  }

  // Hàm xóa ảnh đại diện
  void _removeImage() {
    if (mounted) {
      setState(() {
        _selectedImageFile = null;
      });
    }
  }

  // Hàm đặt lại (reset) về dữ liệu ban đầu
  void _resetProfile() {
    setState(() {
      _nameController.text = widget.userData['displayName'] ?? '';
      _usernameController.text = widget.userData['username'] ?? '';
      _bioController.text = widget.userData['bio'] ?? '';
      Timestamp? birthTimestamp = widget.userData['birthDate'];
      if (birthTimestamp != null) {
        _selectedBirthDate = birthTimestamp.toDate();
        _birthDateController.text = _formatDate(_selectedBirthDate!);
      } else {
        _selectedBirthDate = null;
        _birthDateController.text = '';
      }
      _selectedImageFile = null;
      _validationErrorName = null;
      _validationErrorUsername = null;
      _validationErrorBio = null;
      _validationErrorBirthDate = null;
    });
  }

  // Hàm tải ảnh lên Storage
  Future<String?> _uploadImageToStorage(File imageFile, String userId) async {
    if (mounted) setState(() => _isUploadingImage = true);
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
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // Hàm lưu hồ sơ
  Future<void> _saveProfile() async {
    _validateFields();
    // Chờ kiểm tra username hoàn thành
    await Future.delayed(const Duration(milliseconds: 100));
    if (_validationErrorName != null || _validationErrorUsername != null || _validationErrorBio != null || _validationErrorBirthDate != null || _isCheckingUsername) {
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

    if (mounted) setState(() => _isLoading = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      String? newAvatarUrl = widget.userData['avatarUrl'];
      if (_selectedImageFile != null) {
        final uploadedUrl = await _uploadImageToStorage(_selectedImageFile!, currentUser.uid);
        if (uploadedUrl != null) {
          newAvatarUrl = uploadedUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tải ảnh đại diện mới.')),
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'birthDate': _selectedBirthDate != null ? Timestamp.fromDate(_selectedBirthDate!) : null,
        'avatarUrl': newAvatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hồ sơ đã được cập nhật!'), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentAvatarUrl = widget.userData['avatarUrl'];

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.grey.shade200, // AppBar sáng
        foregroundColor: Colors.black,
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetProfile,
            tooltip: 'Đặt lại',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Phần Avatar
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _selectedImageFile != null
                          ? FileImage(_selectedImageFile!)
                          : (currentAvatarUrl != null ? NetworkImage(currentAvatarUrl) : null),
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
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Thay đổi ảnh'),
                ),
                if (_selectedImageFile != null || currentAvatarUrl != null)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete),
                    label: const Text('Xóa ảnh'),
                  ),
              ],
            ),
            const Divider(height: 40),

            // Trường Tên
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bo tròn
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị',
                    hintText: 'Nhập tên của bạn',
                    errorText: _validationErrorName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15), // Bo tròn
                    ),
                  ),
                  onChanged: (_) => _validateFields(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trường Username
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Nhập username duy nhất',
                    errorText: _validationErrorUsername,
                    suffixIcon: _isCheckingUsername ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onChanged: (_) => _validateFields(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trường Ngày sinh
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _birthDateController,
                  readOnly: true, // Không cho nhập tay
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh',
                    hintText: 'Chọn ngày sinh',
                    errorText: _validationErrorBirthDate,
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onTap: _selectBirthDate, // Mở lịch khi tap
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trường Bio
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Tiểu sử',
                    hintText: 'Viết gì đó về bạn...',
                    errorText: _validationErrorBio,
                    helperText: 'Còn lại ${_bioController.text.length}/150 ký tự',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (_) => _validateFields(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}