import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/home/widgets/comment_screen.dart';
import 'package:lan2tesst/ui/home/widgets/post_options_menu.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = true;
  DocumentSnapshot? _postDocument;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!postDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài viết không tồn tại')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        _postDocument = postDoc;
        _isLiked = (postData['likes'] as List? ?? []).contains(currentUserId);
        _likeCount = (postData['likes'] as List? ?? []).length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bài viết: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createNotification(String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_postDocument == null) return;

    final postData = _postDocument!.data() as Map<String, dynamic>;
    final postOwnerId = postData['userId'];

    if (currentUser!.uid == postOwnerId) return;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final username = userData.data()!['username'] ?? 'someone';

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': postOwnerId,
      'actorId': currentUser.uid,
      'actorUsername': username,
      'type': type,
      'postId': widget.postId,
      'postImageUrl': postData['imageUrl'],
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _likePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _postDocument == null) return;

    final postRef = _postDocument!.reference;

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
      _createNotification('like');
    } else {
      await postRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
    }
  }

  void _showCommentSheet() {
    if (_postDocument == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) => CommentScreen(
            postDocument: _postDocument!,
            scrollController: controller,
            onCommentPosted: () => _createNotification('comment'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Bài viết', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildPostContent(),
    );
  }

  Widget _buildPostContent() {
    if (_postDocument == null) {
      return const Center(
        child: Text(
          'Không thể tải bài viết',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final postData = _postDocument!.data() as Map<String, dynamic>;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header (author info)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(postData['userId'])
                .get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final authorData = userSnapshot.data!.data() as Map<String, dynamic>;

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: postData['userId'],
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: authorData['avatarUrl'] != null
                      ? NetworkImage(authorData['avatarUrl'])
                      : null,
                  child: authorData['avatarUrl'] == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(
                  authorData['displayName']?.isNotEmpty == true
                      ? authorData['displayName']
                      : authorData['username'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () => showPostOptionsMenu(context, _postDocument!),
                ),
              );
            },
          ),

          // Post image
          if (postData['imageUrl'] != null)
            Image.network(
              postData['imageUrl'],
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 400,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 400,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.white, size: 50),
                  ),
                );
              },
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                AnimatedScale(
                  scale: _isLiked ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: _likePost,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                  onPressed: _showCommentSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Like count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '$_likeCount lượt thích',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(postData['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final authorData = userSnapshot.data!.data() as Map<String, dynamic>;

                return RichText(
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
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // View comments button
          StreamBuilder<QuerySnapshot>(
            stream: _postDocument!.reference.collection('comments').snapshots(),
            builder: (context, snapshot) {
              final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: _showCommentSheet,
                  child: Text(
                    'Xem tất cả $commentCount bình luận',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Comments section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              'Bình luận',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Comments list
          StreamBuilder<QuerySnapshot>(
            stream: _postDocument!.reference
                .collection('comments')
                .orderBy('timestamp', descending: false)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Chưa có bình luận nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final comments = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final commentData = comments[index].data() as Map<String, dynamic>;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(commentData['userId'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: userData['avatarUrl'] != null
                              ? NetworkImage(userData['avatarUrl'])
                              : null,
                          child: userData['avatarUrl'] == null
                              ? const Icon(Icons.person, size: 18, color: Colors.white)
                              : null,
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '${userData['username']} ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: commentData['text'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}