import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<void> _createFollowNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final username = userData.data()!['username'] ?? 'someone';

    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientId': widget.userId,
      'actorId': currentUser.uid,
      'actorUsername': username,
      'type': 'follow',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    final userDoc = await userRef.get();
    final followers = List<String>.from(userDoc.data()?['followers'] ?? []);

    final isFollowing = followers.contains(currentUser.uid);

    if (isFollowing) {
      await userRef.update({'followers': FieldValue.arrayRemove([currentUser.uid])});
      await currentUserRef.update({'following': FieldValue.arrayRemove([widget.userId])});
    } else {
      await userRef.update({'followers': FieldValue.arrayUnion([currentUser.uid])});
      await currentUserRef.update({'following': FieldValue.arrayUnion([widget.userId])});
      _createFollowNotification();
    }
  }

  Future<void> _startConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, widget.userId];
    ids.sort();
    String conversationId = ids.join('_');

    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
    final convoDoc = await convoRef.get();

    if (!convoDoc.exists) {
      await convoRef.set({
        'participants': [currentUser.uid, widget.userId],
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId, recipientId: widget.userId),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = widget.userId == currentUserId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final followers = List<String>.from(userData['followers'] ?? []);
        final isFollowing = followers.contains(currentUserId);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              userData['username'] ?? 'Profile',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: widget.userId).orderBy('timestamp', descending: true).snapshots(),
            builder: (context, postSnapshot) {
              final postCount = postSnapshot.hasData ? postSnapshot.data!.docs.length : 0;
              final List<DocumentSnapshot> posts = postSnapshot.hasData ? postSnapshot.data!.docs : <DocumentSnapshot>[];

              return DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Header
                              Row(
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundColor: Colors.grey.shade800,
                                      backgroundImage: userData['avatarUrl'] != null
                                          ? NetworkImage(userData['avatarUrl'])
                                          : null,
                                      child: userData['avatarUrl'] == null
                                          ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.white54,
                                      )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatColumn('Posts', postCount.toString()),
                                        _buildStatColumn('Followers', followers.length.toString()),
                                        _buildStatColumn('Following', (userData['following']?.length ?? 0).toString()),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // User Info
                              Text(
                                userData['displayName'] ?? 'Your Name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData['bio'] ?? 'Bio goes here',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: isFollowing
                                            ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            Colors.grey.shade900,
                                          ],
                                        )
                                            : LinearGradient(
                                          colors: [
                                            Colors.blue.shade500,
                                            Colors.purple.shade500,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _toggleFollow,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _startConversation,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.message, size: 18, color: Colors.white),
                                            SizedBox(width: 6),
                                            Text(
                                              'Message',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Column(
                    children: [
                      // Custom Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.grid_on, size: 24),
                              text: 'POSTS',
                            ),
                            Tab(
                              icon: Icon(Icons.video_library_outlined, size: 24),
                              text: 'REELS',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            posts.isEmpty
                                ? _buildEmptyState(
                              Icons.photo_library_outlined,
                              'No Posts Yet',
                              'When you share photos, they will appear here',
                            )
                                : _buildPostsGrid(posts),
                            _buildEmptyState(
                              Icons.video_library_outlined,
                              'No Reels Yet',
                              'When you create reels, they will appear here',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postData = posts[index].data() as Map<String, dynamic>;
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Image.network(
              postData['imageUrl'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade800,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade900,
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}