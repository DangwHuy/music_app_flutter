import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/auth/auth_screen.dart';
import 'package:lan2tesst/ui/user/edit_profile_screen.dart'; // Import the new screen

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _logout() async {
    Navigator.of(context).pop(); 
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Log Out', style: TextStyle(color: Colors.white)),
              onTap: _logout,
            ),
          ],
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
          child: Text('Please log in to see your profile.', style: TextStyle(color: Colors.white)),
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
            return const Material(color: Colors.black, child: Center(child: Text('Something went wrong with user data', style: TextStyle(color: Colors.white))));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: currentUser.uid).orderBy('timestamp', descending: true).snapshots(),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting && !postSnapshot.hasData) {
                 return const Material(color: Colors.black, child: Center(child: CircularProgressIndicator()));
            }
            if (postSnapshot.hasError) {
                return const Material(color: Colors.black, child: Center(child: Text('Something went wrong with posts', style: TextStyle(color: Colors.white))));
            }
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
                        title: Text(userData['username'] ?? 'username', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        pinned: true,
                        actions: [
                          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: () {}),
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
                                  _buildStatColumn('Posts', postCount.toString()),
                                  _buildStatColumn('Followers', (userData['followers']?.length ?? 0).toString()),
                                  _buildStatColumn('Following', (userData['following']?.length ?? 0).toString()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(userData['displayName'] ?? 'Your Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text(userData['bio'] ?? 'Bio goes here', style: const TextStyle(color: Colors.white70)),
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
                                      child: const Text('Edit Profile'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white),
                                      child: const Text('Share Profile'),
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
                            posts.isEmpty ? _buildEmptyState('No Posts Yet') : _buildPostsGrid(posts),
                            _buildEmptyState('No Reels Yet'),
                            _buildEmptyState('No Tagged Photos'),
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
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
