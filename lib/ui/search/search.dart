import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  // UPGRADED: Changed _usersStream to be nullable and managed by setState
  Stream<QuerySnapshot>? _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  // PRESERVED: This function's logic is unchanged.
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm người dùng...',
            border: InputBorder.none,
          ),
        ),
      ),
      // UPGRADED: The body now conditionally shows the grid or the search results.
      body: _searchController.text.isEmpty
          ? _buildExplorerGrid() // Show grid when search bar is empty
          : _buildSearchResults(), // Show search results when typing
    );
  }

  // ADDED: New widget to build the explorer grid.
  Widget _buildExplorerGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 images per row
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 30, // Show 30 random images
      itemBuilder: (context, index) {
        return Image.network(
          'https://picsum.photos/seed/${index + 10}/300/300', // Use a seed to get different random images
          fit: BoxFit.cover,
        );
      },
    );
  }

  // ADDED: New widget for search results, containing the old logic.
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không tìm thấy người dùng.'));
        }
        
        final users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userData = user.data() as Map<String, dynamic>;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                child: userData['avatarUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username']),
              subtitle: Text('@${userData['username']}'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: user.id),
                ));
              },
            );
          },
        );
      },
    );
  }
}
