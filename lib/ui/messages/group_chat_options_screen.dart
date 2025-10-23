import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/group_members_screen.dart';

class GroupChatOptionsScreen extends StatelessWidget {
  final String conversationId;

  const GroupChatOptionsScreen({super.key, required this.conversationId});

  Future<void> _leaveGroup(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời nhóm?'),
        content: const Text('Bạn sẽ không nhận được tin nhắn từ nhóm này nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rời', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final convoRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
      final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final username = userData.data()?['username'] ?? 'Someone';

      // Create system message before leaving
      await convoRef.collection('messages').add({
        'text': '$username has left the group.',
        'senderId': currentUser.uid,
        'timestamp': Timestamp.now(),
        'isSystemMessage': true,
      });

      // Remove user from participants
      await convoRef.update({
        'participants': FieldValue.arrayRemove([currentUser.uid])
      });

      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tùy chọn'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('conversations').doc(conversationId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final convoData = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(convoData['participants'] ?? []);
          final adminId = convoData['groupAdminId'] as String?;

          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.people_outline, color: Colors.white),
                title: Text('Xem thành viên (${participants.length})', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => GroupMembersScreen(participantIds: participants, adminId: adminId, conversationId: conversationId),
                  ));
                },
              ),
              // Other options...
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                onTap: () => _leaveGroup(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
