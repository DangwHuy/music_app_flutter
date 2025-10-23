import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/chat_screen.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final List<String> _selectedUserIds = [];
  final TextEditingController _groupNameController = TextEditingController();

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createGroupConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _selectedUserIds.isEmpty) return;

    final participants = [currentUser.uid, ..._selectedUserIds];
    participants.sort();

    final newConvo = await FirebaseFirestore.instance.collection('conversations').add({
      'participants': participants,
      'isGroup': true,
      'groupName': _groupNameController.text.isNotEmpty ? _groupNameController.text : 'New Group',
      'lastMessage': 'Group created',
      'lastMessageTimestamp': Timestamp.now(),
    });

    if (mounted) {
      Navigator.pop(context); // Pop the create group screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: newConvo.id, recipientId: ''), // recipientId is not needed for group
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nhóm chat mới', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tên nhóm (không bắt buộc)',
                hintStyle: const TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Gợi ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final following = List<String>.from(userData['following'] ?? []);

                if (following.isEmpty) return const Center(child: Text('You are not following anyone.', style: TextStyle(color: Colors.white)));

                return ListView.builder(
                  itemCount: following.length,
                  itemBuilder: (context, index) {
                    final userId = following[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const ListTile(title: Text('Loading...', style: TextStyle(color: Colors.grey)));
                        
                        final followedUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final name = followedUserData['displayName']?.isNotEmpty == true ? followedUserData['displayName'] : followedUserData['username'];
                        final isSelected = _selectedUserIds.contains(userId);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: followedUserData['avatarUrl'] != null ? NetworkImage(followedUserData['avatarUrl']) : null,
                            child: followedUserData['avatarUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          onTap: () => _toggleUserSelection(userId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _createGroupConversation,
                child: const Text('Tạo nhóm chat'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            )
        ],
      ),
    );
  }
}
