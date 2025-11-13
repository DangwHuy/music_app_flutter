import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentScreen extends StatefulWidget {
  final DocumentSnapshot postDocument;
  final ScrollController scrollController;
  final VoidCallback onCommentPosted;
  const CommentScreen({
    super.key,
    required this.postDocument,
    required this.scrollController,
    required this.onCommentPosted,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  DocumentSnapshot? _replyingToComment;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    // Cấu hình ngôn ngữ tiếng Việt cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final newComment = {
      'text': _commentController.text.trim(),
      'username': userData.data()!['username'],
      'userId': currentUser.uid,
      'avatarUrl': userData.data()!['avatarUrl'] ?? '',
      'likes': [],
      'timestamp': Timestamp.now(),
      'replyTo': _replyingToComment?.id,
      'replyToUsername': _replyingToComment != null
          ? _replyingToComment!['username']
          : null,
    };

    await widget.postDocument.reference.collection('comments').add(newComment);
    widget.onCommentPosted();

    setState(() {
      _commentController.clear();
      _replyingToComment = null;
    });

    _focusNode.unfocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bình luận',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.postDocument.reference
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Comments List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.postDocument.reference
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có bình luận nào',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy là người đầu tiên bình luận!',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final comments = snapshot.data!.docs;
                  final topLevelComments = comments.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return !data.containsKey('replyTo') || data['replyTo'] == null;
                  }).toList();

                  return ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                    ),
                    itemCount: topLevelComments.length,
                    itemBuilder: (context, index) {
                      final parentComment = topLevelComments[index];
                      final parentReplies = comments.where((reply) {
                        final replyData = reply.data() as Map<String, dynamic>;
                        return replyData.containsKey('replyTo') &&
                            replyData['replyTo'] == parentComment.id;
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CommentTile(
                            commentDoc: parentComment,
                            onReply: () {
                              setState(() => _replyingToComment = parentComment);
                              _focusNode.requestFocus();
                            },
                          ),
                          if (parentReplies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 56.0),
                              child: Column(
                                children: parentReplies
                                    .map(
                                      (reply) => _CommentTile(
                                    commentDoc: reply,
                                    onReply: () {
                                      setState(() =>
                                      _replyingToComment = parentComment);
                                      _focusNode.requestFocus();
                                    },
                                    isReply: true,
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Reply indicator
            if (_replyingToComment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang trả lời @${_replyingToComment!['username']}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                      onPressed: _cancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Input Field - Luôn ở trên bàn phím
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar người dùng hiện tại
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      final avatarUrl = snapshot.data?.data() != null
                          ? (snapshot.data!.data() as Map<String, dynamic>)['avatarUrl'] ?? ''
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildAvatar(avatarUrl, 20),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Text Field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Bạn nghĩ gì về nội dung này?',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[600]!,
                            Colors.blue[400]!,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _postComment,
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, double radius) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: Colors.grey[800],
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: radius,
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final DocumentSnapshot commentDoc;
  final VoidCallback onReply;
  final bool isReply;

  const _CommentTile({
    required this.commentDoc,
    required this.onReply,
    this.isReply = false,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _isLiking = false;

  Future<void> _likeComment() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLiking = false);
      return;
    }

    try {
      final likes = List<String>.from(widget.commentDoc['likes'] ?? []);
      if (likes.contains(currentUser.uid)) {
        likes.remove(currentUser.uid);
      } else {
        likes.add(currentUser.uid);
      }
      await widget.commentDoc.reference.update({'likes': likes});
    } finally {
      if (mounted) {
        setState(() => _isLiking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentData = widget.commentDoc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (commentData['likes'] as List).contains(currentUserId);
    final likesCount = (commentData['likes'] as List).length;
    final timestamp = commentData['timestamp'] as Timestamp?;
    final avatarUrl = commentData['avatarUrl'] ?? '';
    final replyToUsername = commentData['replyToUsername'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatar(avatarUrl, 20),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username và text với reply mention
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      // Tên người comment
                      TextSpan(
                        text: commentData['username'] ?? 'unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Xuống dòng nếu có reply
                      if (replyToUsername != null) ...[
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: '@$replyToUsername ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[400],
                          ),
                        ),
                      ] else
                        const TextSpan(text: ' '),
                      // Nội dung comment
                      TextSpan(
                        text: commentData['text'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Actions row
                Row(
                  children: [
                    Text(
                      timestamp != null
                          ? timeago.format(timestamp.toDate(), locale: 'vi')
                          : '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (likesCount > 0) ...[
                      Text(
                        '$likesCount ${likesCount == 1 ? 'thích' : 'lượt thích'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        'Trả lời',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Like button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _likeComment,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey[600],
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, double radius) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: Colors.grey[800],
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: radius,
      ),
    );
  }
}