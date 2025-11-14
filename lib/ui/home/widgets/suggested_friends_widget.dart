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
  final Set<String> _followingInProgress = {};
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .snapshots(),
      builder: (context, currentUserSnapshot) {
        if (!currentUserSnapshot.hasData) {
          return _buildLoadingState();
        }

        final currentUserData = currentUserSnapshot.data!.data() as Map<String, dynamic>;
        final followingList = List<String>.from(currentUserData['following'] ?? []);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, isNotEqualTo: _currentUserId)
              .limit(20)
              .snapshots(),
          builder: (context, allUsersSnapshot) {
            if (!allUsersSnapshot.hasData) {
              return _buildLoadingState();
            }

            final allUsers = allUsersSnapshot.data!.docs;

            // Lọc và tính điểm đề xuất
            final List<Map<String, dynamic>> suggestions = [];

            for (var doc in allUsers) {
              final userData = doc.data() as Map<String, dynamic>;
              final userId = doc.id;

              // Bỏ qua nếu đã follow
              if (followingList.contains(userId)) continue;

              // Tính điểm đề xuất
              int score = 0;
              final userFollowing = List<String>.from(userData['following'] ?? []);
              final mutualFriends = followingList.where((id) => userFollowing.contains(id)).length;
              score += mutualFriends * 10;

              final followersList = List<String>.from(userData['followers'] ?? []);
              score += followersList.length;

              suggestions.add({
                ...userData,
                'uid': userId,
                'score': score,
                'mutualFriends': mutualFriends,
              });
            }

            // Sắp xếp theo điểm
            suggestions.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
            final topSuggestions = suggestions.take(5).toList();

            if (topSuggestions.isEmpty) {
              return const SizedBox.shrink();
            }

            return _buildSuggestionsList(topSuggestions, followingList);
          },
        );
      },
    );
  }

  Widget _buildSuggestionsList(List<Map<String, dynamic>> suggestions, List<String> followingList) {
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
                  'Đề xuất kết nối',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Có thể mở trang discover ở đây
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Xem thêm',
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
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return _buildUserCard(suggestions[index], followingList);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, List<String> followingList) {
    final userId = userData['uid'] as String;
    final isFollowing = followingList.contains(userId);
    final isProcessing = _followingInProgress.contains(userId);
    final mutualFriends = userData['mutualFriends'] as int;

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Avatar với badge mutual friends
            Stack(
              children: [
                Container(
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
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: userData['avatarUrl'] != null
                          ? NetworkImage(userData['avatarUrl'])
                          : null,
                      child: userData['avatarUrl'] == null
                          ? const Icon(Icons.person, size: 24, color: Colors.grey)
                          : null,
                    ),
                  ),
                ),
                if (mutualFriends > 0)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$mutualFriends',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
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
            // Bio hoặc mutual friends text
            Text(
              mutualFriends > 0
                  ? '$mutualFriends bạn chung'
                  : 'Đề xuất mới',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Follow button
            SizedBox(
              width: double.infinity,
              height: 32,
              child: _buildFollowButton(userId, isFollowing, isProcessing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(String userId, bool isFollowing, bool isProcessing) {
    if (isFollowing) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Đã theo dõi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isProcessing ? null : () => _followUser(userId),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE94560),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
      child: isProcessing
          ? const SizedBox(
        width: 16,
        height: 16,
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
    );
  }

  Future<void> _followUser(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _followingInProgress.contains(userId)) return;

    setState(() => _followingInProgress.add(userId));

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update current user's following
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([userId])
      });

      // Update target user's followers
      final targetUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUser.uid])
      });

      await batch.commit();

      // Create notification
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

    } catch (e) {
      print('Error following user: $e');
      // Có thể thêm snackbar thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi theo dõi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _followingInProgress.remove(userId));
      }
    }
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
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
                      const SizedBox(height: 8),
                      Container(
                        height: 32,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
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