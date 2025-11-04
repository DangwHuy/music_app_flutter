import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/user/edit_profile_screen.dart';

// Import các widget mới
import 'package:lan2tesst/ui/user/widgets/account_stats_widget.dart';
import 'package:lan2tesst/ui/user/widgets/profile_action_buttons.dart';
import 'package:lan2tesst/ui/user/widgets/story_highlights_widget.dart';
import 'package:lan2tesst/ui/user/followers_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  bool get wantKeepAlive => true; // Giữ state khi chuyển tab

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Thanh kéo
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black),
                title: const Text('Cài đặt và quyền riêng tư'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.black),
                title: const Text('Hoạt động của bạn'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to activity
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: Colors.black),
                title: const Text('Đã lưu'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to saved posts
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.black),
                title: const Text('Mã QR'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show QR code
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Tạo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(color: Colors.grey, height: 24),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined, color: Colors.white),
                  title: const Text('Thước phim', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to create reels
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_on_outlined, color: Colors.white),
                  title: const Text('Bài viết', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                  title: const Text('Tin', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to create story
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border, color: Colors.white),
                  title: const Text('Tin nổi bật', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to create highlight
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Material(
        color: Colors.white,
        child: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Material(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data?.docs ?? [];
            final postCount = posts.length;
            final followerCount = (userData['followers']?.length ?? 0);
            final followingCount = (userData['following']?.length ?? 0);

            return Material(
              color: Colors.white,
              child: DefaultTabController(
                length: 3,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        title: Row(
                          children: [
                            Text(
                              userData['username'] ?? 'username',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          ],
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        pinned: true,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.add_box_outlined),
                            onPressed: _showCreateMenu,
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: _showSettingsMenu,
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar và Stats
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 42,
                                        backgroundColor: Colors.grey.shade300,
                                        backgroundImage: userData['avatarUrl'] != null
                                            ? NetworkImage(userData['avatarUrl'])
                                            : null,
                                        child: userData['avatarUrl'] == null
                                            ? const Icon(Icons.person, size: 42, color: Colors.grey)
                                            : null,
                                      ),
                                      Expanded(
                                        child: AccountStatsWidget(
                                          postCount: postCount,
                                          followerCount: followerCount,
                                          followingCount: followingCount,
                                          onFollowersTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => FollowersScreen(
                                                  userId: currentUser.uid,
                                                  initialTab: 0,
                                                ),
                                              ),
                                            );
                                          },
                                          onFollowingTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => FollowersScreen(
                                                  userId: currentUser.uid,
                                                  initialTab: 1,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Tên và Bio
                                  if (userData['displayName'] != null && userData['displayName'].toString().isNotEmpty)
                                    Text(
                                      userData['displayName'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  if (userData['bio'] != null && userData['bio'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      userData['bio'],
                                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Nút hành động
                                  ProfileActionButtons(
                                    username: userData['username'] ?? 'user',
                                    onEditProfile: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(userData: userData),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Story Highlights
                            StoryHighlightsWidget(userId: currentUser.uid),
                            const SizedBox(height: 8),

                            // Divider trước TabBar
                            Divider(height: 1, color: Colors.grey.shade300),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: Column(
                    children: [
                      Material(
                        color: Colors.white,
                        child: TabBar(
                          indicatorColor: Colors.black,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorWeight: 1,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on, size: 24)),
                            Tab(icon: Icon(Icons.video_library_outlined, size: 24)),
                            Tab(icon: Icon(Icons.person_pin_outlined, size: 24)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            posts.isEmpty
                                ? _buildEmptyState('Chia sẻ ảnh và video đầu tiên', Icons.camera_alt_outlined)
                                : _buildPostsGrid(posts),
                            _buildEmptyState('Thước phim của bạn sẽ xuất hiện ở đây', Icons.video_library_outlined),
                            _buildEmptyState('Ảnh và video có mặt bạn', Icons.person_pin_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostsGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(1.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postData = posts[index].data() as Map<String, dynamic>? ?? {};
        final imageUrl = postData['imageUrl'];

        if (imageUrl == null) {
          return Container(color: Colors.grey[300]);
        }

        return GestureDetector(
          onTap: () {
            // TODO: Navigate to post detail
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              // Icon cho multiple images
              if (postData['images'] != null && (postData['images'] as List).length > 1)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.copy_all, color: Colors.white, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}