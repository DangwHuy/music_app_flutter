import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/chat_screen.dart';
import 'package:lan2tesst/ui/messages/create_group_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        Widget titleWidget;
        if (userSnapshot.hasData) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Messages';
          titleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const Icon(Icons.keyboard_arrow_down),
            ],
          );
        } else {
          titleWidget = const Text('Messages');
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: titleWidget,
            actions: [
              // THIS BUTTON NOW NAVIGATES TO THE CORRECT SCREEN
              IconButton(
                icon: const Icon(Icons.edit_note_outlined), 
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ));
                }
              ),
            ],
          ),
          body: Column(
            children: [
              // This search bar section will be removed as per the next step
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    fillColor: Colors.grey.shade800,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // The "Nhóm chat" button is now redundant
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .where('participants', arrayContains: currentUser.uid)
                      .orderBy('lastMessageTimestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('You have no conversations yet.', style: TextStyle(color: Colors.white)));
                    }

                    final conversations = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final convo = conversations[index];
                        final convoData = convo.data() as Map<String, dynamic>;
                        final List<dynamic> participants = convoData['participants'];
                        final bool isGroup = convoData['isGroup'] ?? false;

                        if (isGroup) {
                          return ListTile(
                            leading: const CircleAvatar(radius: 30, child: Icon(Icons.group)),
                            title: Text(convoData['groupName'] ?? 'Group Chat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              convoData['lastMessage'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: convo.id,
                                  groupName: convoData['groupName'] ?? 'Group Chat',
                                  isGroup: true,
                                ),
                              ));
                            },
                          );
                        }
                        
                        final String otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
                        if (otherUserId.isEmpty) return const SizedBox.shrink();

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return ListTile(
                                leading: const CircleAvatar(backgroundColor: Colors.grey, radius: 30),
                                title: Container(height: 10, width: 100, color: Colors.grey.shade800),
                                subtitle: Container(height: 10, width: 200, color: Colors.grey.shade800),
                              );
                            }

                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            final recipientName = userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username'];

                            return Dismissible(
                              key: Key(convo.id),
                              background: Container(
                                color: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.push_pin, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Conversation?'),
                                      content: const Text('This will permanently delete the conversation.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await convo.reference.delete();
                                    return true;
                                  }
                                  return false;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pinning feature coming soon!')),
                                  );
                                  return false;
                                }
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                                  child: userData['avatarUrl'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                                  backgroundColor: Colors.grey.shade800,
                                ),
                                title: Text(recipientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  convoData['lastMessage'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      conversationId: convo.id,
                                      recipientId: otherUserId,
                                      isGroup: false,
                                    ),
                                  ));
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
