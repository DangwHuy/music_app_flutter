import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _usersStream;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _usersStream = FirebaseFirestore.instance
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: _searchController.text)
            .where('username', isLessThanOrEqualTo: '${_searchController.text}\uf8ff')
            .snapshots();
      } else {
        _usersStream = null;
      }
    });
  }

  // Hàm lấy danh sách người dùng đang theo dõi
  Future<List<DocumentSnapshot>> _getFollowingUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final following = List<String>.from(doc.data()?['following'] ?? []);
    if (following.isEmpty) return [];

    // Sử dụng FieldPath.documentId để query theo document ID
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: following)
        .get();
    return query.docs;
  }

  // Hàm follow/unfollow user
  Future<void> _toggleFollow(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(targetUserId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    final userDoc = await userRef.get();
    final followers = List<String>.from(userDoc.data()?['followers'] ?? []);

    final isFollowing = followers.contains(currentUser.uid);

    if (isFollowing) {
      await userRef.update({'followers': FieldValue.arrayRemove([currentUser.uid])});
      await currentUserRef.update({'following': FieldValue.arrayRemove([targetUserId])});
    } else {
      await userRef.update({'followers': FieldValue.arrayUnion([currentUser.uid])});
      await currentUserRef.update({'following': FieldValue.arrayUnion([targetUserId])});
    }
    setState(() {}); // Refresh UI sau khi follow/unfollow
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildFollowingUsers()  // Hiển thị danh bạ khi không tìm kiếm
                  : _buildSearchResults(),  // Ẩn danh bạ và chỉ hiện kết quả tìm kiếm
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowingUsers() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFF533483)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đang theo dõi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Following Users List
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _getFollowingUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSuggestions();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptySuggestions();
                }

                final users = snapshot.data!;
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;
                    final followers = List<String>.from(userData['followers'] ?? []);
                    final isFollowing = followers.contains(currentUserId);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE94560), Color(0xFF533483)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: userData['avatarUrl'] != null
                                  ? NetworkImage(userData['avatarUrl'])
                                  : null,
                              child: userData['avatarUrl'] == null
                                  ? const Icon(Icons.person, size: 28, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        title: Text(
                          userData['displayName']?.isNotEmpty == true
                              ? userData['displayName']
                              : userData['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${userData['username']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${followers.length} người theo dõi',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          width: 100,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: isFollowing
                                ? null
                                : const LinearGradient(
                              colors: [Color(0xFFE94560), Color(0xFF533483)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: isFollowing
                                ? Border.all(color: Colors.grey[400]!)
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: () => _toggleFollow(user.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.transparent : Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isFollowing ? Colors.grey[600] : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(userId: user.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
            ),
            title: Container(
              width: 100,
              height: 12,
              color: Colors.grey[300],
            ),
            subtitle: Container(
              width: 60,
              height: 10,
              color: Colors.grey[300],
            ),
            trailing: Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa theo dõi ai',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm bạn bè để bắt đầu kết nối',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy người dùng',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!.docs;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;
            final followers = List<String>.from(userData['followers'] ?? []);
            final isFollowing = followers.contains(currentUserId);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFF533483)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: userData['avatarUrl'] != null
                          ? NetworkImage(userData['avatarUrl'])
                          : null,
                      child: userData['avatarUrl'] == null
                          ? const Icon(Icons.person, size: 28, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                title: Text(
                  userData['displayName']?.isNotEmpty == true
                      ? userData['displayName']
                      : userData['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${userData['username']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${followers.length} người theo dõi',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  width: 100,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isFollowing
                        ? null
                        : const LinearGradient(
                      colors: [Color(0xFFE94560), Color(0xFF533483)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: isFollowing
                        ? Border.all(color: Colors.grey[400]!)
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _toggleFollow(user.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.transparent : Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFollowing ? Colors.grey[600] : Colors.white,
                      ),
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: user.id),
                    ),
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