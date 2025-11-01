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
import 'package:lan2tesst/ui/home/story/create_story_screen.dart';
import 'package:lan2tesst/ui/home/story/story_view_screen.dart';
// *** THÊM: Cho shimmer loading (tùy chọn) ***
// import 'package:shimmer/shimmer.dart'; // Uncomment nếu dùng shimmer

// --- PRESERVED: MusicHomePage is unchanged ---
class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomeTab(),
    const SearchTab(),
    const ReelsTab(),
    const AccountTab()
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreatePostScreen()));
    } else {
      setState(() {
        _currentIndex = index > 2 ? index - 1 : index;
      });
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
        selectedItemColor: Colors.transparent,
        // *** THAY ĐỔI: Transparent để dùng custom color ***
        unselectedItemColor: Colors.transparent,
        // *** THAY ĐỔI: Transparent ***
        backgroundColor: Colors.white,
        // *** THÊM: Background trắng ***
        elevation: 8,
        // *** THÊM: Shadow nhẹ ***
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home, 0), // *** THAY ĐỔI: Cơ bản nhưng cute với gradient ***
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.search, 1), // Giữ nguyên, hoặc thay Icons.find_in_page nếu muốn ngầu
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.add, 2), // *** THAY ĐỔI: Đơn giản, ngầu ***
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.video_camera_back, 3), // *** THAY ĐỔI: Ngầu như camera ***
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.face, 4), // *** THAY ĐỔI: Cute như mặt cười ***
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // *** SỬA: Logic isSelected để tránh highlight sai ***
  Widget _buildNavIcon(IconData icon, int index) {
    // Create (index=2) không bao giờ selected
    final isSelected = index == 2
        ? false
        : (index < 2 ? index == _currentIndex : index - 1 == _currentIndex);

    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.pinkAccent, Colors.orangeAccent, Colors.yellowAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )
            : null,
        child: Icon(
          icon,
          size: 30,
          color: isSelected ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}



// --- UPGRADED: HomeTab with better spacing, colors, and animations ---
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // *** THÊM: Background nhẹ ***
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Viewly', style: TextStyle(fontFamily: 'Billabong', fontSize: 30, color: Colors.black, fontWeight: FontWeight.w600)),
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
                          icon: const Icon(Icons.notifications_none, size: 28), // *** THÊM: Icon lớn hơn ***
                          onPressed: () {
                            if (snapshot.hasData) {
                              final WriteBatch batch = FirebaseFirestore.instance.batch();
                              for (var doc in snapshot.data!.docs) {
                                batch.update(doc.reference, {'read': true});
                              }
                              batch.commit().catchError((error) {
                                print("Error marking notifications read: $error");
                              });
                            }
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                          },
                        ),
                        if (hasUnread)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.message_outlined, size: 28), // *** THÊM: Icon lớn hơn ***
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationsScreen())),
              ),
            ],
            floating: true, snap: true, elevation: 2, // *** THÊM: Elevation nhẹ ***
            backgroundColor: Colors.white, // *** THÊM: Background trắng ***
            shadowColor: Colors.black12,
          ),
          const SliverToBoxAdapter(child: _StoryBar()),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                // *** THÊM: Placeholder đẹp cho loading ***
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildPostPlaceholder(),
                    childCount: 3, // Placeholder cho 3 posts
                  ),
                );
              }
              if (snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    heightFactor: 5,
                    child: Text("No posts yet.", style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ),
                );
              }

              final posts = snapshot.data!.docs;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => AnimatedOpacity( // *** THÊM: Fade-in animation ***
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: PostCard(
                        key: ValueKey(posts[index].id),
                        postDocument: posts[index]
                    ),
                  ),
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // *** THÊM: Placeholder cho loading posts ***
  Widget _buildPostPlaceholder() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade300),
            title: Container(height: 10, color: Colors.grey.shade300),
            subtitle: Container(height: 8, width: 100, color: Colors.grey.shade300),
          ),
          Container(height: 300, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 150, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Container(height: 8, width: 200, color: Colors.grey.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- UPGRADED: _StoryBar with gradient borders and better spacing ---
class _StoryBar extends StatefulWidget {
  const _StoryBar();
  @override
  State<_StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<_StoryBar> {
  void _navigateToStoryView(String userId, List<QueryDocumentSnapshot> userStories) {
    if (userStories.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => StoryViewScreen(userId: userId, stories: userStories),
      ));
    }
  }

  void _navigateToCreateStory() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CreateStoryScreen(),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Container(
            height: 120, // *** THÊM: Chiều cao lớn hơn ***
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: _StoryCircle(isPlaceholder: true),
            ),
          );
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final followingList = List<String>.from(userData['following'] ?? []);
        final relevantUserIds = [currentUser.uid, ...followingList];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stories')
              .where('userId', whereIn: relevantUserIds.isNotEmpty ? relevantUserIds : ['dummy_id'])
              .where('expiresAt', isGreaterThan: Timestamp.now())
              .orderBy('expiresAt', descending: true)
              .snapshots(),
          builder: (context, storySnapshot) {
            if (!storySnapshot.hasData) {
              return Container(
                height: 120,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _StoryCircle(
                    userId: currentUser.uid,
                    username: 'Tin của bạn',
                    imageUrl: userData['avatarUrl'],
                    isCurrentUser: true,
                    onTap: _navigateToCreateStory,
                    hasUnseen: false,
                  ),
                ),
              );
            }

            final allStories = storySnapshot.data!.docs;
            final Map<String, List<QueryDocumentSnapshot>> storiesByUser = {};
            for (var storyDoc in allStories) {
              final storyData = storyDoc.data() as Map<String, dynamic>;
              final userId = storyData['userId'] as String?;
              if (userId != null) {
                if (storiesByUser.containsKey(userId)) {
                  storiesByUser[userId]!.add(storyDoc);
                } else {
                  storiesByUser[userId] = [storyDoc];
                }
              }
            }

            final usersWithStories = storiesByUser.keys.where((id) => id != currentUser.uid).toList();

            return Container(
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 8.0), // *** THÊM: Margin ***
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0), // *** THÊM: Padding lớn hơn ***
                scrollDirection: Axis.horizontal,
                itemCount: 1 + usersWithStories.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final bool hasOwnStory = storiesByUser.containsKey(currentUser.uid);
                    final bool hasViewedAllOwn = false;
                    return _StoryCircle(
                      userId: currentUser.uid,
                      username: 'Tin của bạn',
                      imageUrl: userData['avatarUrl'],
                      isCurrentUser: true,
                      hasUnseen: hasOwnStory && !hasViewedAllOwn,
                      onTap: hasOwnStory
                          ? () => _navigateToStoryView(currentUser.uid, storiesByUser[currentUser.uid]!)
                          : _navigateToCreateStory,
                    );
                  }

                  final otherUserId = usersWithStories[index - 1];
                  final userStories = storiesByUser[otherUserId]!;
                  final firstStoryData = userStories.first.data() as Map<String, dynamic>? ?? {};
                  final bool hasViewedAllOther = false;

                  return _StoryCircle(
                    userId: otherUserId,
                    username: firstStoryData['username'] ?? 'User',
                    imageUrl: firstStoryData['userAvatarUrl'],
                    isCurrentUser: false,
                    hasUnseen: !hasViewedAllOther,
                    onTap: () => _navigateToStoryView(otherUserId, userStories),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- UPGRADED: _StoryCircle with gradient border and animations ---
class _StoryCircle extends StatelessWidget {
  final String? userId;
  final String? username;
  final String? imageUrl;
  final bool isCurrentUser;
  final bool hasUnseen;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const _StoryCircle({
    super.key,
    this.userId,
    this.username,
    this.imageUrl,
    this.isCurrentUser = false,
    this.hasUnseen = false,
    this.isPlaceholder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder) {
      return SizedBox(
        width: 80,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 32, backgroundColor: Colors.grey.shade200), // *** THÊM: Radius lớn hơn ***
              const SizedBox(height: 5),
              Container(height: 12, width: 60, color: Colors.grey.shade200), // *** THÊM: Chiều cao lớn hơn ***
            ],
          ),
        ),
      );
    }

    final BoxDecoration? unseenBorder = hasUnseen
        ? BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient( // *** THÊM: Gradient đẹp hơn ***
        colors: [Colors.pink, Colors.orange, Colors.yellow, Colors.green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    )
        : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale( // *** THÊM: Scale animation khi tap ***
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 80,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (unseenBorder != null)
                      Container(
                        width: 70, // *** THÊM: Kích thước lớn hơn ***
                        height: 70,
                        decoration: unseenBorder,
                      ),
                    CircleAvatar(radius: 33, backgroundColor: Colors.white),
                    CircleAvatar(
                      radius: 31,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                    ),
                    if (isCurrentUser && onTap != null && !hasUnseen)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18), // *** THÊM: Icon lớn hơn ***
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  username ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // *** THÊM: Font weight ***
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- UPGRADED: PostCard with full image display (no cropping) ---
class PostCard extends StatefulWidget {
  final DocumentSnapshot postDocument;
  const PostCard({super.key, required this.postDocument});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  @override
  void initState() {
    super.initState();
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _isLiked = (postData['likes'] as List? ?? []).contains(currentUserId);
    _likeCount = (postData['likes'] as List? ?? []).length;
  }

  Future<void> _createNotification(String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final postData = widget.postDocument.data() as Map<String, dynamic>;
    final postOwnerId = postData['userId'];
    if (currentUser!.uid == postOwnerId) return;
    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final username = userData.data()!['username'] ?? 'someone';
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': postOwnerId,
      'actorId': currentUser.uid,
      'actorUsername': username,
      'type': type,
      'postId': widget.postDocument.id,
      'postImageUrl': postData['imageUrl'],
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _likePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef = widget.postDocument.reference;

    // Update UI immediately (Optimistic Update)
    setState(() {
      if (_isLiked) {
        _likeCount -= 1;
        _isLiked = false;
      } else {
        _likeCount += 1;
        _isLiked = true;
      }
    });

    // Update Firestore in the background
    if (_isLiked) {
      await postRef.update({'likes': FieldValue.arrayUnion([currentUser.uid])});
      _createNotification('like');
    } else {
      await postRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
    }
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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(postData['userId']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 400); // Placeholder while loading author
        final authorData = userSnapshot.data!.data() as Map<String, dynamic>;
        return Card(
          elevation: 4, // *** THÊM: Elevation cao hơn cho shadow ***
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // *** THÊM: Margin ***
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // *** THÊM: Rounded corners ***
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserProfileScreen(userId: postData['userId']))),
              leading: CircleAvatar(backgroundImage: authorData['avatarUrl'] != null ? NetworkImage(authorData['avatarUrl']) : null, child: authorData['avatarUrl'] == null ? const Icon(Icons.person) : null),
              title: Text(authorData['displayName']?.isNotEmpty == true ? authorData['displayName'] : authorData['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // *** THÊM: Font size lớn hơn ***
              trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => showPostOptionsMenu(context, widget.postDocument)),
            ),
            ClipRRect( // *** THÊM: Clip ảnh để rounded ***
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity, // Width full
                constraints: const BoxConstraints(maxHeight: 600), // TÙY CHỌN: Giới hạn max height nếu ảnh quá cao (có thể bỏ nếu muốn full height)
                child: Image.network(
                  postData['imageUrl'],
                  fit: BoxFit.fitWidth, // THAY ĐỔI: Hiển thị full ảnh theo width, height tự động (không crop)
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator()); // Loading indicator cho ảnh
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error, size: 50, color: Colors.grey)); // Error handling
                  },
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Row(children: [
              AnimatedScale( // *** THÊM: Scale animation cho like button ***
                scale: _isLiked ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : null, size: 28), onPressed: _likePost), // *** THÊM: Icon size lớn hơn ***
              ),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 28), onPressed: _showCommentSheet),
              IconButton(icon: const Icon(Icons.send_outlined, size: 28), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border, size: 28), onPressed: () {}),
            ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_likeCount likes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // *** THÊM: Font size ***
              const SizedBox(height: 4),
              RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), children: [TextSpan(text: '${authorData['username']} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: postData['caption'] ?? '')])), // *** THÊM: Font size và color ***
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: widget.postDocument.reference.collection('comments').snapshots(),
                builder: (context, snapshot) {
                  final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return GestureDetector(onTap: _showCommentSheet, child: Text('View all $commentCount comments', style: const TextStyle(color: Colors.grey, fontSize: 14))); // *** THÊM: Font size ***
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