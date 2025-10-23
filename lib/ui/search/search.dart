import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart'; // Import the new screen

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Stream<QuerySnapshot>? _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _usersStream = FirebaseFirestore.instance
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: _searchController.text)
            .where('username', isLessThanOrEqualTo: '${_searchController.text}\uf8ff')
            .snapshots();
      });
    } else {
      setState(() {
        _usersStream = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for users...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (_searchController.text.isEmpty) {
            return const Center(child: Text('Search for other users.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
                  // Navigate to the UserProfileScreen instead of starting a conversation
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: user.id),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
