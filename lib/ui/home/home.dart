import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/home/widgets/comment_screen.dart';
import 'package:lan2tesst/ui/home/widgets/post_options_menu.dart';
import 'package:lan2tesst/ui/messages/conversations_screen.dart';
import 'package:lan2tesst/ui/notifications/notifications_screen.dart';
import 'package:lan2tesst/ui/reels/reels_screen.dart';
import 'package:lan2tesst/ui/search/search.dart';
import 'package:lan2tesst/ui/user/user.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Temporarily commented out

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
          // Temporarily use hardcoded strings
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


class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Viewly', style: TextStyle(fontFamily: 'Billabong', fontSize: 33, color: Colors.black)),
            actions: [
              if (currentUserId != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('notifications').where('recipientId', isEqualTo: currentUserId).where('read', isEqualTo: false).snapshots(),
                  builder: (context, snapshot) {
                    final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                doc.reference.update({'read': true});
                              }
                            }
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                          },
                        ),
                        if (hasUnread)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.message_outlined), 
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationsScreen())),
              ),
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

class PostCard extends StatefulWidget {
  final DocumentSnapshot postDocument;
  const PostCard({super.key, required this.postDocument});

  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  Future<void> _createNotification(String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final postOwnerId = postData['userId'];

    if (currentUser!.uid == postOwnerId) return;

    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final username = userData.data()!['username'] ?? 'someone';

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': postOwnerId, 'actorId': currentUser.uid, 'actorUsername': username, 'type': type, 'postId': widget.postDocument.id, 'postImageUrl': postData['imageUrl'], 'timestamp': FieldValue.serverTimestamp(), 'read': false,
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
      _createNotification('like');
    }
    await widget.postDocument.reference.update({'likes': likes});
  }

  void _showCommentSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8, minChildSize: 0.4, maxChildSize: 0.95,
        builder: (_, controller) => CommentScreen(postDocument: widget.postDocument, scrollController: controller, onCommentPosted: () => _createNotification('comment')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: postData['userId']),
                ));
              },
              leading: CircleAvatar(backgroundImage: authorData['avatarUrl'] != null ? NetworkImage(authorData['avatarUrl']) : null, child: authorData['avatarUrl'] == null ? const Icon(Icons.person) : null),
              title: Text(authorData['displayName']?.isNotEmpty == true ? authorData['displayName'] : authorData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => showPostOptionsMenu(context, widget.postDocument)),
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
