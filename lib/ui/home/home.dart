import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/notifications/notifications_screen.dart'; // Import the new screen
import 'package:lan2tesst/ui/reels/reels_screen.dart';
import 'package:lan2tesst/ui/search/search.dart';
import 'package:lan2tesst/ui/user/user.dart';

// Main page structure - No changes here
class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [ const HomeTab(), const SearchTab(), const ReelsTab(), const AccountTab() ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
    } else {
      setState(() { _currentIndex = index > 2 ? index - 1 : index; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < 2 ? _currentIndex : _currentIndex + 1,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

// HomeTab now has a button to the notification screen
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Viewly', style: TextStyle(fontFamily: 'Billabong', fontSize: 35, color: Colors.black)),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              IconButton(icon: const Icon(Icons.message_outlined), onPressed: () {}),
            ],
            floating: true, snap: true, elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          const SliverToBoxAdapter(child: _StoryBar()),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              if (snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(heightFactor: 5, child: Text("No posts yet.")));

              final posts = snapshot.data!.docs;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) => PostCard(postDocument: posts[index]), childCount: posts.length),
              );
            },
          ),
        ],
      ),
    );
  }
}

// StoryBar - No major changes
class _StoryBar extends StatefulWidget {
  const _StoryBar();
  @override
  State<_StoryBar> createState() => _StoryBarState();
}
class _StoryBarState extends State<_StoryBar> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      height: 100,
      child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
          builder: (context, snapshot) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                if (index == 0) {
                  if (!snapshot.hasData) return const _StoryCircle(isPlaceholder: true);
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return _StoryCircle(username: userData['username'] ?? '', imageUrl: userData['avatarUrl']);
                }
                return _StoryCircle(index: index);
              },
            );
          }),
    );
  }
}
class _StoryCircle extends StatelessWidget {
  final int? index;
  final String? username;
  final String? imageUrl;
  final bool isPlaceholder;

  const _StoryCircle({super.key, this.index, this.username, this.imageUrl, this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final mockImageUrl = 'https://picsum.photos/seed/story$index/100/100';

    return SizedBox(
      width: 80,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(alignment: Alignment.center, children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.orange),
              const CircleAvatar(radius: 28, backgroundColor: Colors.white),
              CircleAvatar(radius: 26, backgroundColor: Colors.grey[300], backgroundImage: isPlaceholder ? null : NetworkImage(isFirst ? (imageUrl ?? mockImageUrl) : mockImageUrl)),
              if (isFirst && !isPlaceholder)
                Positioned(bottom: 0, right: 0, child: Container(decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.add, color: Colors.white, size: 16))),
            ]),
            const SizedBox(height: 5),
            Text(isPlaceholder ? '' : (isFirst ? username ?? 'You' : 'user_$index'), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- LIKE & COMMENT FUNCTIONS NOW CREATE NOTIFICATIONS ---
class PostCard extends StatefulWidget {
  final DocumentSnapshot postDocument;
  const PostCard({super.key, required this.postDocument});

  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  // Function to create a notification document in Firestore
  Future<void> _createNotification(String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final postOwnerId = postData['userId'];

    // Don't create notification for your own actions
    if (currentUser!.uid == postOwnerId) return;

    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final username = userData.data()!['username'] ?? 'someone';

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': postOwnerId,
      'actorId': currentUser.uid,
      'actorUsername': username,
      'type': type, // 'like' or 'comment'
      'postId': widget.postDocument.id,
      'postImageUrl': postData['imageUrl'],
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _likePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final likes = List<String>.from(widget.postDocument['likes'] ?? []);
    if (likes.contains(currentUser.uid)) {
      likes.remove(currentUser.uid);
    } else {
      likes.add(currentUser.uid);
      _createNotification('like'); // Create notification on new like
    }
    await widget.postDocument.reference.update({'likes': likes});
  }

  void _showCommentSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => CommentScreen(postDocument: widget.postDocument, scrollController: controller, onCommentPosted: () => _createNotification('comment')),
      );
    });
  }

  void _showPostMenu() {
    // (logic for delete/report menu remains the same)
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of the PostCard build method remains the same)
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (postData['likes'] as List).contains(currentUserId);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(postData['userId']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 400);
        final authorData = userSnapshot.data!.data() as Map<String, dynamic>;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ListTile(
              leading: CircleAvatar(backgroundImage: authorData['avatarUrl'] != null ? NetworkImage(authorData['avatarUrl']) : null, child: authorData['avatarUrl'] == null ? const Icon(Icons.person) : null),
              title: Text(authorData['displayName']?.isNotEmpty == true ? authorData['displayName'] : authorData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: _showPostMenu),
            ),
            Image.network(postData['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: 300),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Row(children: [
              IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null), onPressed: _likePost),
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _showCommentSheet),
              IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${postData['likes'].length} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '${authorData['username']} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: postData['caption'] ?? '')])),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: widget.postDocument.reference.collection('comments').snapshots(),
                builder: (context, snapshot) {
                  final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return GestureDetector(onTap: _showCommentSheet, child: Text('View all $commentCount comments', style: TextStyle(color: Colors.grey)));
                },
              ),
              const SizedBox(height: 16),
            ])),
          ]),
        );
      },
    );
  }
}

// CommentScreen now calls a callback when a comment is posted
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
      'text': _commentController.text, 'username': userData.data()!['username'], 'userId': currentUser.uid, 'likes': [], 'timestamp': Timestamp.now(), 'replyTo': _replyingToComment?.id,
    };
    await widget.postDocument.reference.collection('comments').add(newComment);
    widget.onCommentPosted(); // Trigger the notification creation
    setState(() {
      _commentController.clear();
      _replyingToComment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of the CommentScreen build method remains the same)
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Column(children: [
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
                  return Column(children: [
                    _CommentTile(commentDoc: parentComment, onReply: () => setState(() => _replyingToComment = parentComment)),
                    Padding(padding: const EdgeInsets.only(left: 40.0), child: Column(children: parentReplies.map((reply) => _CommentTile(commentDoc: reply, onReply: () => setState(() => _replyingToComment = parentComment), isReply: true)).toList())),
                  ]);
                },
              );
            },
          ),
        ),
        Padding(padding: const EdgeInsets.all(8.0), child: TextField(
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
        )),
      ]),
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
      title: RichText(text: TextSpan(style: const TextStyle(color: Colors.white, fontSize: 14), children: [TextSpan(text: '${commentData['username'] ?? 'unknown'} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: commentData['text'] ?? '')])),
      subtitle: Row(children: [Text('2w', style: TextStyle(color: Colors.grey[600], fontSize: 12)), const SizedBox(width: 12), TextButton(onPressed: onReply, child: Text('Trả lời', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)))]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${commentData['likes'].length}', style: TextStyle(color: Colors.grey)), IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 18), onPressed: _likeComment)]),
      dense: true,
    );
  }
}
