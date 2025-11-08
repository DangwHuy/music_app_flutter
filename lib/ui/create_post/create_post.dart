import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lan2tesst/ui/reels/reels_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  File? _selectedFile;
  double _uploadProgress = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn nội dung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text(
                'Chọn ảnh',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Từ thư viện ảnh',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file =
                await picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  setState(() {
                    _selectedFile = File(file.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: Colors.purple),
              ),
              title: const Text(
                'Chọn video',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Từ thư viện video',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file =
                await picker.pickVideo(source: ImageSource.gallery);
                if (file != null) {
                  setState(() {
                    _selectedFile = File(file.path);
                  });
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _notifyFollowers(
      String postId, String mediaUrl, String caption, bool isVideo) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
    final username = userDoc.data()?['username'] ?? 'someone';
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (String followerId in followers) {
      final notificationRef =
      FirebaseFirestore.instance.collection('notifications').doc();
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

  Future<String> _uploadImageToStorage(File imageFile, String userId) async {
    String fileName =
        'post_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> _uploadVideoToStorage(File videoFile, String userId) async {
    String fileName =
        'videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(videoFile);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _handlePost() async {
    if (_selectedFile == null) {
      _showSnackBar('Vui lòng chọn một file.', Icons.warning_amber_rounded,
          Colors.orange);
      return;
    }
    if (_captionController.text.isEmpty) {
      _showSnackBar(
          'Vui lòng viết mô tả.', Icons.edit_note, Colors.orange);
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      final isVideo = _selectedFile!.path.endsWith('.mp4') ||
          _selectedFile!.path.endsWith('.mov') ||
          _selectedFile!.path.endsWith('.avi');
      String mediaUrl;
      String collection = isVideo ? 'reels' : 'posts';
      String field = isVideo ? 'videoUrl' : 'imageUrl';

      if (isVideo) {
        mediaUrl = await _uploadVideoToStorage(_selectedFile!, currentUser.uid);
      } else {
        mediaUrl = await _uploadImageToStorage(_selectedFile!, currentUser.uid);
      }

      final String caption = _captionController.text;
      final newPostRef =
      await FirebaseFirestore.instance.collection(collection).add({
        'userId': currentUser.uid,
        field: mediaUrl,
        'caption': caption,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _notifyFollowers(newPostRef.id, mediaUrl, caption, isVideo);

      if (isVideo && mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ReelsTab()));
      } else if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        _showSnackBar('Không thể đăng bài: $e', Icons.error_outline, Colors.red);
      }
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool get _isVideo =>
      _selectedFile != null &&
          (_selectedFile!.path.endsWith('.mp4') ||
              _selectedFile!.path.endsWith('.mov') ||
              _selectedFile!.path.endsWith('.avi'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tạo bài viết mới',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _handlePost,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text(
                  'Đăng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Selection Area
                  GestureDetector(
                    onTap: _isUploading ? null : _pickMedia,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: _selectedFile == null ? 200 : 300,
                      decoration: BoxDecoration(
                        gradient: _selectedFile == null
                            ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade50,
                            Colors.purple.shade50,
                          ],
                        )
                            : null,
                        color: _selectedFile != null
                            ? Colors.grey[100]
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFile == null
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _selectedFile == null
                          ? FadeTransition(
                        opacity: Tween<double>(begin: 0.5, end: 1.0)
                            .animate(_pulseController),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chọn ảnh hoặc video',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn để thêm nội dung',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                          : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _selectedFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // Video indicator
                          if (_isVideo)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Video',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Change button
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.blue.shade600,
                                ),
                                onPressed: _isUploading ? null : _pickMedia,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Caption Section
                  Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _captionController,
                      autofocus: false,
                      enabled: !_isUploading,
                      decoration: const InputDecoration(
                        hintText: 'Bạn đang nghĩ gì?',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      maxLines: 8,
                      minLines: 4,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Upload Progress Overlay
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Đang tải lên...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng đợi trong giây lát',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}