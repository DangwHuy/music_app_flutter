import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/user/edit_profile_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // PRESERVED: This function is unchanged.
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
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

  // PRESERVED: This function is unchanged.
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
              onTap: _logout,
            ),
          ],
        );
      },
    );
  }

  // ADDED: New function to show the create menu.
  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Wrap(
            runSpacing: 10,
            children: <Widget>[
              const Center(
                child: Text('Tạo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(color: Colors.grey, height: 20),
              ListTile(
                leading: const Icon(Icons.video_library_outlined, color: Colors.white),
                title: const Text('Thước phim', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_outlined, color: Colors.white),
                title: const Text('Bài viết', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                title: const Text('Tin', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.white),
                title: const Text('Tin nổi bật', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Material(
        color: Colors.black,
        child: Center(
          child: Text('Vui lòng đăng nhập để xem hồ sơ của bạn.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Material(color: Colors.black, child: Center(child: CircularProgressIndicator()));
        }
        if (userSnapshot.hasError) {
            return const Material(color: Colors.black, child: Center(child: Text('Đã xảy ra lỗi với dữ liệu người dùng', style: TextStyle(color: Colors.white))));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: currentUser.uid).orderBy('timestamp', descending: true).snapshots(),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data?.docs ?? [];
            final postCount = posts.length;

            return Material(
              color: Colors.black,
              child: DefaultTabController(
                length: 3,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        title: Text(userData['username'] ?? 'tên người dùng', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        pinned: true,
                        actions: [
                          // UPGRADED: The onPressed callback now calls the new function.
                          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: _showCreateMenu),
                          IconButton(icon: const Icon(Icons.menu), onPressed: _showSettingsMenu),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.grey.shade800,
                                    backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                                    child: userData['avatarUrl'] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                                  ),
                                  _buildStatColumn('Bài viết', postCount.toString()),
                                  _buildStatColumn('Người theo dõi', (userData['followers']?.length ?? 0).toString()),
                                  _buildStatColumn('Đang theo dõi', (userData['following']?.length ?? 0).toString()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(userData['displayName'] ?? 'Tên của bạn', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(userData['bio'] ?? 'Tiểu sử ở đây', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(userData: userData),
                                        ));
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                                      child: const Text('Chỉnh sửa hồ sơ'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                                      child: const Text('Chia sẻ hồ sơ'),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(icon: Icon(Icons.grid_on)),
                          Tab(icon: Icon(Icons.video_library_outlined)),
                          Tab(icon: Icon(Icons.person_pin_outlined)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            posts.isEmpty ? _buildEmptyState('Chưa có bài viết nào') : _buildPostsGrid(posts),
                            _buildEmptyState('Chưa có thước phim nào'),
                            _buildEmptyState('Chưa có ảnh nào được gắn thẻ'),
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

  // PRESERVED: All helper widgets are unchanged.
  Widget _buildPostsGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postData = posts[index].data() as Map<String, dynamic>;
        return Image.network(postData['imageUrl'], fit: BoxFit.cover);
      },
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white70),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
