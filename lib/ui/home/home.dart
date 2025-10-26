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
import 'package:lan2tesst/ui/home/story/create_story_screen.dart'; // Thêm Story
import 'package:lan2tesst/ui/home/story/story_view_screen.dart'; // <-- xem Story
// TODO: Import CreateStoryScreen and StoryViewScreen later

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
                            // Mark notifications as read optimistically before navigating
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background color
          ),
          // --- STORY BAR IS NOW HERE ---
          const SliverToBoxAdapter(child: _StoryBar()),
          // --- END STORY BAR ---
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

// --- BẮT ĐẦU NÂNG CẤP STORY BAR ---

class _StoryBar extends StatefulWidget {
  const _StoryBar();
  @override
  State<_StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<_StoryBar> {
  // Hàm điều hướng đến màn hình xem Story (sẽ tạo sau)
  void _navigateToStoryView(String userId, List<QueryDocumentSnapshot> userStories) {
    // Xóa dòng print cũ
    if (userStories.isNotEmpty) { // Chỉ mở nếu có story để xem
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => StoryViewScreen(userId: userId, stories: userStories), // <-- Mở màn hình mới và truyền dữ liệu
      ));
      // TODO: Đánh dấu các story này là đã xem (cập nhật trạng thái 'viewers' trong Firestore)
    }
  }

  // Hàm điều hướng đến màn hình tạo Story (sẽ tạo sau)
  void _navigateToCreateStory() {
    // Xóa dòng print cũ
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CreateStoryScreen(), // <-- Mở màn hình mới
      fullscreenDialog: true, // Mở dạng modal từ dưới lên (giống Instagram)
    ));
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    // Lắng nghe thông tin user hiện tại (để lấy danh sách following)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          // Hiển thị placeholder loading cho toàn bộ story bar
          return Container(height: 100, alignment: Alignment.centerLeft, child: const Padding(padding: EdgeInsets.all(8.0), child: _StoryCircle(isPlaceholder: true)));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final followingList = List<String>.from(userData['following'] ?? []);
        // Thêm cả ID của user hiện tại vào danh sách để lấy story của mình
        final relevantUserIds = [currentUser.uid, ...followingList];

        // Lắng nghe collection 'stories'
        return StreamBuilder<QuerySnapshot>(
          // Query các story chưa hết hạn VÀ thuộc về user hiện tại HOẶC người đang follow
          stream: FirebaseFirestore.instance
              .collection('stories')
              .where('userId', whereIn: relevantUserIds.isNotEmpty ? relevantUserIds : ['dummy_id']) // Use dummy if list is empty to avoid error
              .where('expiresAt', isGreaterThan: Timestamp.now()) // Chỉ lấy story còn hạn
              .orderBy('expiresAt', descending: true) // Sắp xếp (tùy chọn)
              .snapshots(),
          builder: (context, storySnapshot) {
            if (!storySnapshot.hasData) {
              // Vẫn hiển thị story của user hiện tại khi đang load story khác
              return Container(
                height: 100,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Consistent padding
                  child: _StoryCircle(
                    userId: currentUser.uid, // <-- Thêm userId
                    username: 'Tin của bạn', // Use 'Tin của bạn'
                    imageUrl: userData['avatarUrl'],
                    isCurrentUser: true, // <-- Đánh dấu đây là user hiện tại
                    onTap: _navigateToCreateStory, // <-- Nhấn để tạo story
                    hasUnseen: false, // Initially false until we fetch own stories
                  ),
                ),
              );
            }

            final allStories = storySnapshot.data!.docs;

            // Nhóm các story theo userId
            final Map<String, List<QueryDocumentSnapshot>> storiesByUser = {};
            for (var storyDoc in allStories) {
              final storyData = storyDoc.data() as Map<String, dynamic>;
              final userId = storyData['userId'] as String?; // Handle potential null
              if (userId != null) {
                if (storiesByUser.containsKey(userId)) {
                  storiesByUser[userId]!.add(storyDoc);
                } else {
                  storiesByUser[userId] = [storyDoc];
                }
              }
            }

            // Lấy danh sách các userId có story (ngoại trừ user hiện tại)
            final usersWithStories = storiesByUser.keys.where((id) => id != currentUser.uid).toList();
            // TODO: Sort usersWithStories by latest story timestamp if desired

            return Container(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                scrollDirection: Axis.horizontal,
                // Item count = 1 (current user) + number of others with stories
                itemCount: 1 + usersWithStories.length,
                itemBuilder: (context, index) {
                  // --- First Circle: Always the Current User ---
                  if (index == 0) {
                    final bool hasOwnStory = storiesByUser.containsKey(currentUser.uid);
                    // TODO: Implement logic to check if current user has viewed all their own stories
                    final bool hasViewedAllOwn = false; // Placeholder

                    return _StoryCircle(
                      userId: currentUser.uid,
                      username: 'Tin của bạn', // Always 'Tin của bạn'
                      imageUrl: userData['avatarUrl'],
                      isCurrentUser: true,
                      hasUnseen: hasOwnStory && !hasViewedAllOwn, // Show border if has story and hasn't viewed all
                      onTap: hasOwnStory
                          ? () => _navigateToStoryView(currentUser.uid, storiesByUser[currentUser.uid]!)
                          : _navigateToCreateStory, // Tap to view (if has story) or create (if not)
                    );
                  }

                  // --- Subsequent Circles: Others with stories ---
                  final otherUserId = usersWithStories[index - 1]; // Get corresponding userId
                  final userStories = storiesByUser[otherUserId]!;
                  // Get user info from the first story (or query 'users' collection for accuracy)
                  final firstStoryData = userStories.first.data() as Map<String, dynamic>? ?? {};


                  // TODO: Implement logic to check if current user has viewed all stories from this user
                  final bool hasViewedAllOther = false; // Placeholder

                  return _StoryCircle(
                    userId: otherUserId,
                    username: firstStoryData['username'] ?? 'User', // Get username from story
                    imageUrl: firstStoryData['userAvatarUrl'],   // Get avatar from story
                    isCurrentUser: false,
                    hasUnseen: !hasViewedAllOther, // Show border if hasn't viewed all
                    onTap: () => _navigateToStoryView(otherUserId, userStories), // Tap to view
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

// --- NÂNG CẤP STORY CIRCLE ---
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
              CircleAvatar(radius: 30, backgroundColor: Colors.grey[200]),
              const SizedBox(height: 5),
              Container(height: 10, width: 50, color: Colors.grey[200]),
            ],
          ),
        ),
      );
    }

    final BoxDecoration? unseenBorder = hasUnseen
        ? BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [Colors.yellow.shade600, Colors.orange, Colors.red, Colors.purple], // Instagram-like gradient
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    )
        : null;

    return GestureDetector(
      onTap: onTap,
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
                      width: 64, height: 64,
                      decoration: unseenBorder,
                    ),
                  CircleAvatar(
                      radius: unseenBorder != null ? 30 : 31,
                      backgroundColor: Colors.white
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
                    child: (imageUrl == null || imageUrl!.isEmpty) ? Icon(Icons.person, color: Colors.grey[600], size: 28) : null,
                  ),
                  // Show '+' only for current user AND if they have NO unseen stories (meaning no stories or all viewed)
                  if (isCurrentUser && !hasUnseen)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.add, color: Colors.white, size: 16)),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                username ?? 'User',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  // Use grey text if it's the current user and they have no unseen stories
                  color: (isCurrentUser && !hasUnseen) ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --- KẾT THÚC NÂNG CẤP STORY BAR ---


// --- POST CARD (Unchanged from previous version with BoxFit.contain) ---
class PostCard extends StatefulWidget {
  final DocumentSnapshot postDocument;
  const PostCard({super.key, required this.postDocument});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {

  Future<void> _createNotification(String type) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; // Add null check
    final postData = widget.postDocument.data() as Map<String, dynamic>?; // Use safe cast
    if (postData == null) return;
    final postOwnerId = postData['userId'];

    if (currentUser.uid == postOwnerId) return;

    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final username = userData.data()?['username'] ?? 'someone'; // Safe access

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': postOwnerId, 'actorId': currentUser.uid, 'actorUsername': username, 'type': type, 'postId': widget.postDocument.id, 'postImageUrl': postData['imageUrl'], 'timestamp': FieldValue.serverTimestamp(), 'read': false,
    });
  }

  Future<void> _likePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final postRef = widget.postDocument.reference;
    final postData = widget.postDocument.data() as Map<String, dynamic>?; // Safe cast
    if (postData == null) return;

    final likes = List<String>.from(postData['likes'] ?? []); // Use ?? [] for safety

    // Use transaction for consistency
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Re-fetch the document inside the transaction
      final freshSnap = await transaction.get(postRef);
      final freshLikes = List<String>.from( (freshSnap.data() as Map<String, dynamic>?)?['likes'] ?? []);

      if (freshLikes.contains(currentUser.uid)) {
        transaction.update(postRef, {'likes': FieldValue.arrayRemove([currentUser.uid])});
      } else {
        transaction.update(postRef, {'likes': FieldValue.arrayUnion([currentUser.uid])});
        // Create notification only when liking
        _createNotification('like');
      }
    });

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
    final postData = widget.postDocument.data() as Map<String, dynamic>?; // Safe cast
    if (postData == null) return const SizedBox.shrink(); // Handle null post data

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = (postData['likes'] as List?)?.contains(currentUserId) ?? false; // Safe check for likes

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(postData['userId']).get(),
      builder: (context, userSnapshot) {
        // Handle loading and error states for user data
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2.0))); // Smaller loading indicator
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Card(margin: EdgeInsets.symmetric(vertical: 8.0), child: ListTile(title: Text("Could not load author info."))); // Indicate error loading author
        }

        final authorData = userSnapshot.data!.data() as Map<String, dynamic>;
        final authorUsername = authorData['username'] ?? 'user'; // Provide default
        final authorDisplayName = authorData['displayName']?.isNotEmpty == true ? authorData['displayName'] : authorUsername;
        final authorAvatarUrl = authorData['avatarUrl'] as String?; // Cast as String?


        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                onTap: () {
                  // Navigate only if userId is valid
                  if (postData['userId'] != null && postData['userId'] is String) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: postData['userId']),
                    ));
                  }
                },
                leading: CircleAvatar(
                    backgroundImage: authorAvatarUrl != null ? NetworkImage(authorAvatarUrl) : null,
                    child: authorAvatarUrl == null ? const Icon(Icons.person, size: 20) : null // Smaller icon
                ),
                title: Text(authorDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => showPostOptionsMenu(context, widget.postDocument)),
              ),

              // Display post image
              if (postData['imageUrl'] != null && postData['imageUrl'] is String)
                Image.network(
                  postData['imageUrl'],
                  fit: BoxFit.contain, // Use contain as requested
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0, // Thinner indicator
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container( // Placeholder for error
                      height: 200, // Give some height
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                    );
                  },
                )
              else // Placeholder if no image URL
                Container(height: 200, color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40))),


              Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: Row(children: [
                IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null), onPressed: _likePost),
                IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _showCommentSheet),
                IconButton(icon: const Icon(Icons.send_outlined), onPressed: () { /* TODO: Implement Share */ }),
                const Spacer(),
                IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () { /* TODO: Implement Bookmark */ }),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Safe access to likes count
                Text('${(postData['likes'] as List?)?.length ?? 0} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // Use authorUsername here
                RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '$authorUsername ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: postData['caption'] ?? '')])),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: widget.postDocument.reference.collection('comments').orderBy('timestamp', descending: true).limit(2).snapshots(), // Limit initial comments
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return GestureDetector(onTap: _showCommentSheet, child: Text('Add a comment...', style: TextStyle(color: Colors.grey[600])));
                    }
                    final commentCount = snapshot.data!.docs.length; // This is now max 2
                    // TODO: Get total comment count separately if needed for "View all X comments"

                    return GestureDetector(onTap: _showCommentSheet, child: Text('View all comments', style: TextStyle(color: Colors.grey[600]))); // Simpler text
                  },
                ),
                // Display post time (optional)
                if (postData['timestamp'] != null && postData['timestamp'] is Timestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatTimestamp(postData['timestamp']), // Helper function needed
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ),
                const SizedBox(height: 16),
              ])),
            ],
          ),
        );
      },
    );
  }

  // Helper function to format timestamp (Add this function to the _PostCardState)
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      // Format as date, e.g., Oct 26
      return '${_getMonthAbbreviation(date.month)} ${date.day}';
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
// --- KẾT THÚC POST CARD ---