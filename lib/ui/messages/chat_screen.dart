import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/messages/add_members_screen.dart';
import 'package:lan2tesst/ui/messages/chat_details_screen.dart';
import 'package:lan2tesst/ui/messages/group_chat_options_screen.dart';
import 'package:lan2tesst/ui/home/widgets/post_detail_screen.dart';

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
    if (_messageController.text.isEmpty || currentUser == null) return;

    final messageData = {
      'text': _messageController.text,
      'senderId': currentUser!.uid,
      'timestamp': Timestamp.now(),
      'isSystemMessage': false,
      'type': 'text', // *** THÊM: Type cho tin nhắn thường
    };

    await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages').add(messageData);
    await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
      'lastMessage': _messageController.text,
      'lastMessageTimestamp': Timestamp.now(),
      'lastMessageSenderId': currentUser!.uid,
    });

    _messageController.clear();
  }

  Widget _buildAppBarTitle(BuildContext context, Map<String, dynamic> nicknames) {
    Widget titleContent;
    if (widget.isGroup) {
      titleContent = Text(widget.groupName ?? 'Trò chuyện nhóm', style: const TextStyle(color: Colors.white));
    } else if (widget.recipientId != null && widget.recipientId!.isNotEmpty) {
      final nickname = nicknames[widget.recipientId!];
      if (nickname != null) {
        titleContent = Text(nickname, style: const TextStyle(color: Colors.white));
      } else {
        titleContent = FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.recipientId).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Text('Đang tải...', style: TextStyle(color: Colors.white));
            }
            final recipientData = userSnapshot.data!.data() as Map<String, dynamic>;
            final name = recipientData['displayName']?.isNotEmpty == true ? recipientData['displayName'] : recipientData['username'];
            return Text(name, style: const TextStyle(color: Colors.white));
          },
        );
      }
    } else {
      titleContent = const Text('Trò chuyện', style: TextStyle(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatDetailsScreen(
            conversationId: widget.conversationId,
            isGroup: widget.isGroup,
          ),
        ));
      },
      child: titleContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).snapshots(),
      builder: (context, convoSnapshot) {
        if (!convoSnapshot.hasData) {
          return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, title: const Text('Đang tải...')), body: const Center(child: CircularProgressIndicator()));
        }
        final convoData = convoSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final nicknames = convoData['nicknames'] as Map<String, dynamic>? ?? {};

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: _buildAppBarTitle(context, nicknames),
            actions: widget.isGroup
                ? [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () async {
                  final participants = List<String>.from(convoData['participants'] ?? []);
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
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = msgSnapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData = messages[index].data() as Map<String, dynamic>;

                        // System message
                        if (messageData['isSystemMessage'] == true) {
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
                        final messageType = messageData['type'] ?? 'text';

                        // *** THÊM: Render dựa trên type ***
                        if (messageType == 'post_share') {
                          return _SharedPostBubble(
                            messageData: messageData,
                            isMe: isMe,
                            isGroup: widget.isGroup,
                            senderId: messageData['senderId'],
                            timestamp: messageData['timestamp'],
                            nickname: nicknames[messageData['senderId']] as String?,
                          );
                        }

                        // Text message
                        return _MessageBubble(
                          message: messageData['text'],
                          isMe: isMe,
                          isGroup: widget.isGroup,
                          senderId: messageData['senderId'],
                          timestamp: messageData['timestamp'],
                          nickname: nicknames[messageData['senderId']] as String?,
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
                          hintText: 'Nhắn tin...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: Colors.grey.shade800,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// *** THÊM: Widget cho Shared Post Bubble ***
class _SharedPostBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final bool isMe;
  final bool isGroup;
  final String senderId;
  final Timestamp? timestamp;
  final String? nickname;

  const _SharedPostBubble({
    required this.messageData,
    required this.isMe,
    required this.isGroup,
    required this.senderId,
    this.timestamp,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp?.toDate();
    final formattedTime = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    final sharedPost = messageData['sharedPost'] as Map<String, dynamic>?;
    if (sharedPost == null) {
      return const SizedBox.shrink();
    }

    final postImageUrl = sharedPost['imageUrl'] as String?;
    final postCaption = sharedPost['caption'] as String?;
    final postId = sharedPost['postId'] as String?;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name (for group chats)
          if (isGroup && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 18.0, bottom: 2.0),
              child: (nickname != null)
                  ? Text(nickname!, style: const TextStyle(color: Colors.grey, fontSize: 12))
                  : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final senderData = snapshot.data!.data() as Map<String, dynamic>;
                  final name = senderData['displayName']?.isNotEmpty == true
                      ? senderData['displayName']
                      : senderData['username'];
                  return Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12));
                },
              ),
            ),
          // Post preview card
          GestureDetector(
            onTap: () {
              print('Tapped on post: $postId'); // DEBUG
              if (postId != null) {
                print('Navigating to PostDetailScreen'); // DEBUG
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(postId: postId),
                  ),
                );
              } else {
                print('postId is null!'); // DEBUG
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade700 : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post image
                  if (postImageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        postImageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey.shade700,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade700,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                  // Post caption
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Bài viết',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (postCaption != null && postCaption.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            postCaption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn để xem',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.blue.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Timestamp
          if (formattedTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

// Original MessageBubble (unchanged)
class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isGroup;
  final String senderId;
  final Timestamp? timestamp;
  final String? nickname;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.senderId,
    this.timestamp,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final time = timestamp?.toDate();
    final formattedTime = time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isGroup && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 18.0, bottom: 2.0),
              child: (nickname != null)
                  ? Text(nickname!, style: const TextStyle(color: Colors.grey, fontSize: 12))
                  : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final senderData = snapshot.data!.data() as Map<String, dynamic>;
                  final name = senderData['displayName']?.isNotEmpty == true ? senderData['displayName'] : senderData['username'];
                  return Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12));
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
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
          if (formattedTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}