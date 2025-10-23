import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/add_members_screen.dart';
import 'package:lan2tesst/ui/messages/group_chat_options_screen.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Temporarily commented out

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? recipientId;
  final String? groupName;
  final bool isGroup;

  const ChatScreen({
    super.key, 
    required this.conversationId, 
    this.recipientId,
    this.groupName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageData = {
      'text': _messageController.text,
      'senderId': currentUser!.uid,
      'timestamp': Timestamp.now(),
      'isSystemMessage': false,
    };

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add(messageData);

    await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
      'lastMessage': _messageController.text,
      'lastMessageTimestamp': Timestamp.now(),
    });

    _messageController.clear();
  }

  Widget _buildAppBarTitle(BuildContext context) {
    if (widget.isGroup) {
      // Temporarily use hardcoded string
      return Text(widget.groupName ?? 'Messages', style: const TextStyle(color: Colors.white));
    }

    if (widget.recipientId == null || widget.recipientId!.isEmpty) {
      // Temporarily use hardcoded string
      return const Text('Messages', style: TextStyle(color: Colors.white));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.recipientId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          // Temporarily use hardcoded string
          return const Text('Loading...', style: TextStyle(color: Colors.white));
        }
        final recipientData = userSnapshot.data!.data() as Map<String, dynamic>;
        final name = recipientData['displayName']?.isNotEmpty == true ? recipientData['displayName'] : recipientData['username'];
        return Text(name, style: const TextStyle(color: Colors.white));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _buildAppBarTitle(context),
        actions: widget.isGroup
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  onPressed: () async {
                    final convoDoc = await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).get();
                    final participants = List<String>.from(convoDoc.data()?['participants'] ?? []);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddMembersScreen(conversationId: widget.conversationId, currentParticipantIds: participants),
                    ));
                  },
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => GroupChatOptionsScreen(conversationId: widget.conversationId),
                    ));
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final bool isSystemMessage = messageData['isSystemMessage'] ?? false;

                    if (isSystemMessage) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            messageData['text'],
                            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    final isMe = messageData['senderId'] == currentUser!.uid;
                    return _MessageBubble(
                      message: messageData['text'],
                      isMe: isMe,
                      isGroup: widget.isGroup,
                      senderId: messageData['senderId'],
                      timestamp: messageData['timestamp'],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      // Temporarily use hardcoded string
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.grey.shade800,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isGroup;
  final String senderId;
  final Timestamp? timestamp;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.senderId,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp?.toDate();
    final formattedTime = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isGroup && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 18.0, bottom: 2.0),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final senderData = snapshot.data!.data() as Map<String, dynamic>;
                  final name = senderData['displayName']?.isNotEmpty == true ? senderData['displayName'] : senderData['username'];
                  return Text(
                    name,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (formattedTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                formattedTime,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
