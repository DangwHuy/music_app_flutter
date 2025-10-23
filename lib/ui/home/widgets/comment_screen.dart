import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final DocumentSnapshot postDocument;
  final ScrollController scrollController;
  final VoidCallback onCommentPosted;
  const CommentScreen({super.key, required this.postDocument, required this.scrollController, required this.onCommentPosted});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  DocumentSnapshot? _replyingToComment;

  void _postComment() async {
    if (_commentController.text.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();

    final newComment = {
      'text': _commentController.text,
      'username': userData.data()!['username'],
      'userId': currentUser.uid,
      'likes': [],
      'timestamp': Timestamp.now(),
      'replyTo': _replyingToComment?.id,
    };

    await widget.postDocument.reference.collection('comments').add(newComment);
    widget.onCommentPosted();
    setState(() {
      _commentController.clear();
      _replyingToComment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(8.0), child: Text('Bình luận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.postDocument.reference.collection('comments').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No comments yet', style: TextStyle(color: Colors.white)));
                
                final comments = snapshot.data!.docs;
                final topLevelComments = comments.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return !data.containsKey('replyTo') || data['replyTo'] == null;
                }).toList();

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final parentComment = topLevelComments[index];
                    final parentReplies = comments.where((reply) {
                        final replyData = reply.data() as Map<String, dynamic>;
                        return replyData.containsKey('replyTo') && replyData['replyTo'] == parentComment.id;
                    }).toList();

                    return Column(
                      children: [
                        _CommentTile(commentDoc: parentComment, onReply: () => setState(() => _replyingToComment = parentComment)),
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: Column(
                            children: parentReplies.map((reply) => _CommentTile(commentDoc: reply, onReply: () => setState(() => _replyingToComment = parentComment), isReply: true)).toList(),
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _replyingToComment != null ? 'Replying to @${_replyingToComment!['username']}' : 'Bạn nghĩ gì về nội dung này?',
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _postComment),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DocumentSnapshot commentDoc;
  final VoidCallback onReply;
  final bool isReply;
  const _CommentTile({required this.commentDoc, required this.onReply, this.isReply = false});

  Future<void> _likeComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if(currentUser == null) return;
    final likes = List<String>.from(commentDoc['likes'] ?? []);
    if (likes.contains(currentUser.uid)) { likes.remove(currentUser.uid); } else { likes.add(currentUser.uid); }
    await commentDoc.reference.update({'likes': likes});
  }

  @override
  Widget build(BuildContext context) {
    final commentData = commentDoc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (commentData['likes'] as List).contains(currentUserId);

    return ListTile(
      leading: const CircleAvatar(radius: 18, backgroundColor: Colors.grey), 
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [TextSpan(text: '${commentData['username'] ?? 'unknown'} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: commentData['text'] ?? '')],
        ),
      ),
      subtitle: Row(
        children: [
          Text('2w', style: TextStyle(color: Colors.grey[600], fontSize: 12)), 
          const SizedBox(width: 12),
          TextButton(onPressed: onReply, child: Text('Trả lời', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)))
        ],
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('${commentData['likes'].length}', style: TextStyle(color: Colors.grey)),
        IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 18), onPressed: _likeComment)
      ]),
      dense: true,
    );
  }
}
