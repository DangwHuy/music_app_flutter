import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/user/user_profile_screen.dart';

class SuggestedFriendsWidget extends StatefulWidget {
  const SuggestedFriendsWidget({super.key});

  @override
  State<SuggestedFriendsWidget> createState() => _SuggestedFriendsWidgetState();
}

class _SuggestedFriendsWidgetState extends State<SuggestedFriendsWidget> {
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _isLoading = true;
  final Set<String> _followingInProgress = {};

  @override
  void initState() {
    super.initState();
    _loadSuggestedFriends();
  }

  Future<void> _loadSuggestedFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final followingList = List<String>.from(currentUserData['following'] ?? []);

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(20)
          .get();

      final List<Map<String, dynamic>> suggestions = [];

      for (var doc in usersSnapshot.docs) {
        if (doc.id != currentUser.uid && !followingList.contains(doc.id)) {
          final userData = doc.data();
          userData['uid'] = doc.id;

          int score = 0;
          final userFollowing = List<String>.from(userData['following'] ?? []);
          final mutualFriends = followingList.where((id) => userFollowing.contains(id)).length;
          score += mutualFriends * 10;

          final followersList = List<String>.from(userData['followers'] ?? []);
          score += followersList.length;

          userData['score'] = score;
          suggestions.add(userData);
        }
      }

      suggestions.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      setState(() {
        _suggestedUsers = suggestions.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading suggested friends: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _followUser(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _followingInProgress.contains(userId)) return;

    setState(() => _followingInProgress.add(userId));

    try {
      final batch = FirebaseFirestore.instance.batch();

      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([userId])
      });

      final targetUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUser.uid])
      });

      await batch.commit();

      final currentUserDoc = await currentUserRef.get();
      final username = currentUserDoc.data()!['username'] ?? 'someone';

      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': userId,
        'actorId': currentUser.uid,
        'actorUsername': username,
        'type': 'follow',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      setState(() {
        _suggestedUsers.removeWhere((user) => user['uid'] == userId);
        _followingInProgress.remove(userId);
      });
    } catch (e) {
      print('Error following user: $e');
      setState(() => _followingInProgress.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_suggestedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đề xuất cho bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_suggestedUsers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final userId = userData['uid'] as String;
    final isFollowing = _followingInProgress.contains(userId);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: userId),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: userData['avatarUrl'] != null
                      ? NetworkImage(userData['avatarUrl'])
                      : null,
                  child: userData['avatarUrl'] == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                if (userData['score'] > 20)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Username
            Text(
              userData['displayName']?.isNotEmpty == true
                  ? userData['displayName']
                  : userData['username'] ?? 'User',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // Followers count
            Text(
              '${(userData['followers'] as List?)?.length ?? 0} người theo dõi',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            // Follow button
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: isFollowing ? null : () => _followUser(userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                child: isFollowing
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Theo dõi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}