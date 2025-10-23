import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMembersScreen extends StatefulWidget {
  final String conversationId;
  final List<String> currentParticipantIds;

  const AddMembersScreen({super.key, required this.conversationId, required this.currentParticipantIds});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final List<String> _selectedUserIds = [];

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _addMembers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _selectedUserIds.isEmpty) return;

    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);

    // Add new participants to the group
    await convoRef.update({
      'participants': FieldValue.arrayUnion(_selectedUserIds),
    });

    // Create system messages for each added member
    final currentUserData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final actorName = currentUserData.data()?['username'] ?? 'Someone';

    for (String userId in _selectedUserIds) {
      final newMemberData = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final newMemberName = newMemberData.data()?['username'] ?? 'a new member';
      
      await convoRef.collection('messages').add({
        'text': '$actorName added $newMemberName to the group.',
        'senderId': currentUser.uid,
        'timestamp': Timestamp.now(),
        'isSystemMessage': true, // Mark as a system message
      });
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Add Members'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(currentUserId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final following = List<String>.from(userData['following'] ?? []);

                // Filter out users who are already in the group
                final usersToShow = following.where((id) => !widget.currentParticipantIds.contains(id)).toList();

                if (usersToShow.isEmpty) {
                  return const Center(child: Text('No one new to add.', style: TextStyle(color: Colors.white)));
                }

                return ListView.builder(
                  itemCount: usersToShow.length,
                  itemBuilder: (context, index) {
                    final userId = usersToShow[index];
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
                onPressed: _addMembers,
                child: Text('Add (${_selectedUserIds.length})'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            )
        ],
      ),
    );
  }
}
