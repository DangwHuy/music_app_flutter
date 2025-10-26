import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/user/edit_profile_screen.dart'; // Giữ lại để dùng

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- CÁC HÀM LOGIC CỦA BẠN VẪN GIỮ NGUYÊN ---
  Future<void> _logout() async {
    // ... (code cũ)
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

  void _showSettingsMenu() {
    // ... (code cũ)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Màu nền tối
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context); // Đóng bottom sheet
                // TODO: Điều hướng đến màn hình cài đặt (nếu có)
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white), // Thêm icon Lịch sử (ví dụ)
              title: const Text('Lịch sử hoạt động', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Điều hướng đến màn hình lịch sử
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border, color: Colors.white), // Thêm icon Đã lưu
              title: const Text('Đã lưu', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Điều hướng đến màn hình đã lưu
              },
            ),
            const Divider(color: Colors.grey, height: 1), // Thêm đường kẻ
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red), // Đổi màu icon logout
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)), // Đổi màu chữ logout
              onTap: _logout,
            ),
          ],
        );
      },
    );
  }

  void _showCreateMenu() {
    // ... (code cũ)
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
                onTap: () => Navigator.pop(context), // TODO: Điều hướng đến tạo Reels
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
                onTap: () => Navigator.pop(context), // TODO: Điều hướng đến tạo Story
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.white),
                title: const Text('Tin nổi bật', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () => Navigator.pop(context), // TODO: Điều hướng đến tạo Highlight
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BẮT ĐẦU NÂNG CẤP GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Phần này giữ nguyên
      return const Material( /* ... */ );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        // Phần xử lý loading/error giữ nguyên
        if (!userSnapshot.hasData) { /* ... */ }
        if (userSnapshot.hasError) { /* ... */ }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: currentUser.uid).orderBy('timestamp', descending: true).snapshots(),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data?.docs ?? [];
            final postCount = posts.length;
            final followerCount = (userData['followers']?.length ?? 0);
            final followingCount = (userData['following']?.length ?? 0);

            // Sử dụng màu nền trắng cho toàn bộ màn hình hồ sơ
            return Material(
              color: Colors.white, // <-- Đổi màu nền chính
              child: DefaultTabController(
                length: 3, // Giữ nguyên 3 tab
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        // AppBar màu trắng, chữ đen
                        title: Text(userData['username'] ?? 'username', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        backgroundColor: Colors.white, // <-- AppBar màu trắng
                        foregroundColor: Colors.black, // <-- Icon màu đen
                        elevation: 0, // Bỏ bóng đổ
                        pinned: true,
                        actions: [
                          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: _showCreateMenu),
                          IconButton(icon: const Icon(Icons.menu), onPressed: _showSettingsMenu),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Giảm padding dọc
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Bố cục Header mới ---
                              Row(
                                children: [
                                  // Avatar lớn hơn một chút
                                  CircleAvatar(
                                    radius: 40, // <-- Kích thước avatar
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                                    child: userData['avatarUrl'] == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                                  ),
                                  // Dùng Expanded để đẩy các chỉ số ra xa
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Căn đều các chỉ số
                                      children: [
                                        _buildStatColumn('Bài viết', postCount.toString()),
                                        _buildStatColumn('Người theo dõi', followerCount.toString()),
                                        _buildStatColumn('Đang theo dõi', followingCount.toString()),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Giảm khoảng cách

                              // Tên và Bio (chữ đen)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(userData['displayName'] ?? '', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                              Text(userData['bio'] ?? '', style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 12), // Giảm khoảng cách

                              // --- Nút bấm kiểu mới ---
                              Row(
                                children: [
                                  // Nút Chỉnh sửa (viền xám)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(userData: userData),
                                        ));
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black, // Chữ đen
                                        side: BorderSide(color: Colors.grey.shade400), // Viền xám nhạt
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Chỉnh sửa trang cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Nút Chia sẻ (viền xám)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () { /* TODO: Implement Share Profile */ },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: BorderSide(color: Colors.grey.shade400),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Chia sẻ trang cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              // TODO: Có thể thêm phần Story Highlights ở đây nếu muốn
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  // --- Phần TabBar và TabBarView giữ nguyên cấu trúc ---
                  body: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.black, // Màu thanh trượt đen
                        labelColor: Colors.black,     // Màu icon tab được chọn đen
                        unselectedLabelColor: Colors.grey, // Màu icon không được chọn xám
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_on)),
                          Tab(icon: Icon(Icons.video_library_outlined)),
                          Tab(icon: Icon(Icons.person_pin_outlined)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            posts.isEmpty ? _buildEmptyState('Chưa có bài viết', Icons.camera_alt_outlined) : _buildPostsGrid(posts),
                            _buildEmptyState('Chưa có thước phim', Icons.video_library_outlined),
                            _buildEmptyState('Ảnh có mặt bạn', Icons.person_pin_outlined), // Đổi chữ cho rõ
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

  // --- Các Widget phụ trợ (Helper Widgets) ---

  // Sửa lại GridView để phù hợp nền trắng
  Widget _buildPostsGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      // Thêm padding nhẹ
      padding: const EdgeInsets.all(1.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 cột
          crossAxisSpacing: 1, // Khoảng cách ngang rất nhỏ
          mainAxisSpacing: 1   // Khoảng cách dọc rất nhỏ
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postData = posts[index].data() as Map<String, dynamic>;
        // Thêm widget loading cho từng ảnh
        return Image.network(
          postData['imageUrl'],
          fit: BoxFit.cover, // Grid vẫn nên dùng cover
          loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: Colors.grey[200]),
          errorBuilder: (context, error, stack) => Container(color: Colors.grey[300]),
        );
      },
    );
  }

  // Sửa lại cột chỉ số cho phù hợp nền trắng
  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)), // Chữ đen
        const SizedBox(height: 2), // Giảm khoảng cách
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)), // Chữ đen nhạt
      ],
    );
  }

  // Sửa lại Empty State cho phù hợp nền trắng và thêm Icon tùy chọn
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]), // Icon xám nhạt
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Chữ đen nhạt
          // Có thể thêm 1 Text nhỏ hơn giải thích ở đây nếu muốn
        ],
      ),
    );
  }
// --- KẾT THÚC NÂNG CẤP GIAO DIỆN ---
}