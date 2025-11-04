import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Màn hình hiển thị danh sách người theo dõi / đang theo dõi
/// Đặt trong: lib/ui/user/followers_screen.dart
class FollowersScreen extends StatefulWidget {
  final String userId;
  final int initialTab; // 0: Followers, 1: Following

  const FollowersScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Kết nối', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Người theo dõi'),
                  Tab(text: 'Đang theo dõi'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersList(isFollowers: true),
          _buildFollowersList(isFollowers: false),
        ],
      ),
    );
  }

  Widget _buildFollowersList({required bool isFollowers}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> userIds = isFollowers
            ? (userData['followers'] ?? [])
            : (userData['following'] ?? []);

        if (userIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFollowers ? Icons.people_outline : Icons.person_add_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isFollowers ? 'Chưa có người theo dõi' : 'Chưa theo dõi ai',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: userIds.isNotEmpty ? userIds : [''])
              .snapshots(),
          builder: (context, usersSnapshot) {
            if (!usersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var users = usersSnapshot.data!.docs;

            // Lọc theo search query
            if (_searchQuery.isNotEmpty) {
              users = users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final username = (data['username'] ?? '').toLowerCase();
                final displayName = (data['displayName'] ?? '').toLowerCase();
                return username.contains(_searchQuery) || displayName.contains(_searchQuery);
              }).toList();
            }

            if (users.isEmpty) {
              return const Center(child: Text('Không tìm thấy kết quả'));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final userId = users[index].id;
                return _buildUserTile(userId, user);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserTile(String userId, Map<String, dynamic> userData) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        backgroundImage: userData['avatarUrl'] != null
            ? NetworkImage(userData['avatarUrl'])
            : null,
        child: userData['avatarUrl'] == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        userData['username'] ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        userData['displayName'] ?? '',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: _buildFollowButton(userId),
      onTap: () {
        // TODO: Navigate to user profile
      },
    );
  }

  Widget _buildFollowButton(String userId) {
    // TODO: Implement follow/unfollow logic
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      ),
      child: const Text('Theo dõi', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}