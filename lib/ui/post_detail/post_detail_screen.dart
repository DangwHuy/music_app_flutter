import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:lan2tesst/ui/reels/reels_screen.dart'; // Import ReelsTab
import 'package:lan2tesst/ui/home/widgets/comment_screen.dart'; // Giả định có CommentScreen

class PostDetailScreen extends StatefulWidget {
  final DocumentSnapshot postDocument;
  final bool isFromReels; // *** THÊM: Để biết từ collection nào ***

  const PostDetailScreen({super.key, required this.postDocument, this.isFromReels = false});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _isLiked = (postData['likes'] as List? ?? []).contains(currentUserId);
    _likeCount = (postData['likes'] as List? ?? []).length;

    // *** THÊM: Khởi tạo video nếu là video ***
    final videoUrl = postData['videoUrl'] as String?;
    if (videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _likePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = widget.postDocument.reference;

    setState(() {
      if (_isLiked) {
        _likeCount -= 1;
        _isLiked = false;
      } else {
        _likeCount += 1;
        _isLiked = true;
      }
    });

    if (_isLiked) {
      await postRef.update({'likes': FieldValue.arrayUnion([currentUser.uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
    }
  }

  void _showCommentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentScreen(
          postDocument: widget.postDocument,
          scrollController: controller,
          onCommentPosted: () {}, // Có thể thêm logic notify
        ),
      ),
    );
  }

  void _goToReels() {
    // *** THÊM: Chuyển sang Reels nếu là video ***
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ReelsTab()));
  }

  @override
  Widget build(BuildContext context) {
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final isVideo = postData['videoUrl'] != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chi tiết bài viết'),
        actions: [
          if (isVideo && !widget.isFromReels) // *** THÊM: Button chuyển sang Reels nếu là video từ posts ***
            IconButton(
              icon: const Icon(Icons.video_library),
              onPressed: _goToReels,
              tooltip: 'Xem trong Reels',
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(postData['userId']).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final authorData = userSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // *** THÊM: Header với avatar và tên ***
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: authorData['avatarUrl'] != null ? NetworkImage(authorData['avatarUrl']) : null,
                    child: authorData['avatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(
                    authorData['displayName']?.isNotEmpty == true ? authorData['displayName'] : authorData['username'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    postData['timestamp'] != null ? (postData['timestamp'] as Timestamp).toDate().toString() : '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

                // *** THÊM: Media (ảnh hoặc video) với rounded corners và shadow ***
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16), // *** THÊM: Rounded corners ***
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))], // *** THÊM: Shadow ***
                      ),
                      child: isVideo
                          ? (_isVideoInitialized
                          ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                          : const Center(child: CircularProgressIndicator(color: Colors.white)))
                          : Image.network(
                        postData['imageUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),
                  ),
                ),

                // *** THÊM: Buttons like, comment, share với animation ***
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      AnimatedScale( // *** THÊM: Scale animation cho like ***
                        scale: _isLiked ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.white, size: 32),
                          onPressed: _likePost,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
                        onPressed: _showCommentSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_outlined, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // *** THÊM: Like count và caption với typography đẹp ***
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_likeCount likes',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${authorData['username']} ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: postData['caption'] ?? ''),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // *** THÊM: Comments preview ***
                      StreamBuilder<QuerySnapshot>(
                        stream: widget.postDocument.reference.collection('comments').orderBy('timestamp', descending: true).limit(2).snapshots(),
                        builder: (context, snapshot) {
                          final comments = snapshot.data?.docs ?? [];
                          return Column(
                            children: comments.map((comment) {
                              final commentData = comment.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: '${commentData['username']} ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: commentData['text']),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: _showCommentSheet,
                        child: const Text(
                          'Xem tất cả bình luận',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}