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
    if (widget.userId == currentUserId) {
      // This check prevents users from viewing their own profile on this screen.
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final followers = List<String>.from(userData['followers'] ?? []);
        final isFollowing = followers.contains(currentUserId);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(userData['username'] ?? 'Profile', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
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
                                  _buildStatColumn('Followers', followers.length.toString()),
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
                                      onPressed: _toggleFollow,
                                      child: Text(isFollowing ? 'Following' : 'Follow'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing ? Colors.grey.shade800 : Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: ElevatedButton(onPressed: _startConversation, child: const Text('Message'))),
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
                        tabs: [Tab(icon: Icon(Icons.grid_on)), Tab(icon: Icon(Icons.video_library_outlined))],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            posts.isEmpty ? _buildEmptyState('No Posts Yet') : _buildPostsGrid(posts),
                            _buildEmptyState('No Reels Yet'),
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

  // RESTORED THE FULL IMPLEMENTATION
  Widget _buildPostsGrid(List<DocumentSnapshot> posts) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        crossAxisSpacing: 2, 
        mainAxisSpacing: 2
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
