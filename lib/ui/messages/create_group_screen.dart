import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
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
      'groupAdminId': currentUser.uid, // ADDED: Set the creator as admin
      'groupName': _groupNameController.text.isNotEmpty ? _groupNameController.text : 'New Group',
      'lastMessage': '${currentUser.displayName ?? 'Someone'} created the group.',
      'lastMessageTimestamp': Timestamp.now(),
    });

    if (mounted) {
      Navigator.pop(context); // Pop the create group screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: newConvo.id, isGroup: true, groupName: _groupNameController.text.isNotEmpty ? _groupNameController.text : 'New Group'),
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
        title: const Text('Nhóm chat mới'),
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
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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

                if (following.isEmpty) return const Center(child: Text('Follow users to add them to a group.', style: TextStyle(color: Colors.white)));

                return ListView.builder(
                  itemCount: following.length,
                  itemBuilder: (context, index) {
                    final userId = following[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox.shrink();
                        
                        final followedUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final name = followedUserData['displayName']?.isNotEmpty == true ? followedUserData['displayName'] : followedUserData['username'];
                        final isSelected = _selectedUserIds.contains(userId);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: followedUserData['avatarUrl'] != null ? NetworkImage(followedUserData['avatarUrl']) : null,
                            child: followedUserData['avatarUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('@${followedUserData['username']}', style: const TextStyle(color: Colors.grey)),
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
                child: Text('Tạo (${_selectedUserIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)
                ),
              ),
            )
        ],
      ),
    );
  }
}
