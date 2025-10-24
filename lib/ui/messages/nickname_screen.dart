import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NicknameScreen extends StatefulWidget {
  final String conversationId;

  const NicknameScreen({super.key, required this.conversationId});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {

  Future<void> _editNickname(BuildContext context, String memberId, String currentName) async {
    final TextEditingController nicknameController = TextEditingController();
    nicknameController.text = currentName;

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt biệt danh'),
        content: TextField(
          controller: nicknameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập biệt danh'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, nicknameController.text), child: const Text('Lưu')),
        ],
      ),
    );

    if (newNickname != null && newNickname.isNotEmpty) {
      final convoRef = FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);
      final currentUser = FirebaseAuth.instance.currentUser!;

      // Update the nicknames map in the conversation document
      await convoRef.update({
        'nicknames.$memberId': newNickname,
      });

      // Create a system message to notify about the change
      await convoRef.collection('messages').add({
        'text': '${currentUser.displayName ?? 'Bạn'} đã đặt biệt danh cho $currentName là $newNickname',
        'senderId': currentUser.uid,
        'timestamp': Timestamp.now(),
        'isSystemMessage': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Biệt danh'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final convoData = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(convoData['participants'] ?? []);
          final nicknames = convoData['nicknames'] as Map<String, dynamic>? ?? {};

          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final userId = participants[index];
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Đang tải...', style: TextStyle(color: Colors.grey)));
                  }
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  
                  // Use nickname if available, otherwise use display name, fallback to username
                  final currentName = nicknames[userId] ?? (userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                      child: userData['avatarUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(currentName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Đặt biệt danh', style: const TextStyle(color: Colors.grey)),
                    onTap: () => _editNickname(context, userId, currentName),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
