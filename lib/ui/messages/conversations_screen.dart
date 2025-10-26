import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/ai_chat/ai_chat_screen.dart';
import 'package:lan2tesst/ui/messages/chat_screen.dart';
import 'package:lan2tesst/ui/messages/create_group_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startConversation(String recipientId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> ids = [currentUser.uid, recipientId];
    ids.sort();
    String conversationId = ids.join('_');

    final convoRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
    final convoDoc = await convoRef.get();

    if (!convoDoc.exists) {
      await convoRef.set({
        'participants': ids,
        'isGroup': false,
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
        'lastMessageSenderId': null,
      });
    }

    if (mounted) {
      _searchController.clear();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId, recipientId: recipientId),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(appBar: AppBar(title: const Text('Tin nhắn')), body: const Center(child: Text('Vui lòng đăng nhập.')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        Widget titleWidget;
        if (userSnapshot.hasData) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Tin nhắn';
          titleWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const Icon(Icons.keyboard_arrow_down),
            ],
          );
        } else {
          titleWidget = const Text('Tin nhắn');
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: titleWidget,
            actions: [
              IconButton(icon: const Icon(Icons.psychology_alt_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AiChatScreen()))),
              IconButton(icon: const Icon(Icons.edit_note_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateGroupScreen()))),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    fillColor: Colors.grey.shade800,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: _searchQuery.isEmpty
                    ? Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [Tab(text: 'Tất cả'), Tab(text: 'Chưa đọc'), Tab(text: 'Nhóm')],
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.white,
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildConversationsList(currentUser.uid, 'all'),
                                _buildConversationsList(currentUser.uid, 'unread'),
                                _buildConversationsList(currentUser.uid, 'group'),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _buildSearchResults(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    // This widget is preserved and unchanged.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('username', isGreaterThanOrEqualTo: _searchQuery).where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data?.docs.where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid).toList() ?? [];
        if (users.isEmpty) return const Center(child: Text('Không tìm thấy người dùng.', style: TextStyle(color: Colors.white)));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final name = userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username'];
            return ListTile(
              leading: CircleAvatar(radius: 30, backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null, backgroundColor: Colors.grey.shade800),
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: Text('@${userData['username']}', style: const TextStyle(color: Colors.grey)),
              onTap: () => _startConversation(users[index].id),
            );
          },
        );
      },
    );
  }

  Widget _buildConversationsList(String currentUserId, String filter) {
    Query query = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId);

    if (filter == 'group') {
      query = query.where('isGroup', isEqualTo: true);
    }
    if (filter == 'unread') {
      query = query.where('lastMessageSenderId', isNotEqualTo: currentUserId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('lastMessageTimestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi: Vui lòng tạo chỉ mục Firestore cho bộ lọc này.', style: TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Chưa có cuộc trò chuyện nào.', style: TextStyle(color: Colors.white)));
        }

        final conversations = snapshot.data!.docs;

        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final convo = conversations[index];
            final convoData = convo.data() as Map<String, dynamic>;
            final List<dynamic> participants = convoData['participants'];
            final bool isGroup = convoData['isGroup'] ?? false;
            final lastSenderId = convoData['lastMessageSenderId'] as String?;
            final bool isUnread = lastSenderId != null && lastSenderId != currentUserId;

            final nicknames = convoData['nicknames'] as Map<String, dynamic>? ?? {};

            if (isGroup) {
              return ListTile(
                leading: const CircleAvatar(radius: 30, child: Icon(Icons.group)),
                title: Text(convoData['groupName'] ?? 'Trò chuyện nhóm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(convoData['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isUnread ? Colors.white : Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(conversationId: convo.id, groupName: convoData['groupName'], isGroup: true))),
              );
            }

            final String otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
            if (otherUserId.isEmpty) return const SizedBox.shrink();

            final String? nickname = nicknames[otherUserId];

            return FutureBuilder<DocumentSnapshot>(
              future: nickname == null ? FirebaseFirestore.instance.collection('users').doc(otherUserId).get() : null,
              builder: (context, userSnapshot) {
                String displayName;
                if (nickname != null) {
                  displayName = nickname;
                } else if (userSnapshot.hasData) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  displayName = userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username'];
                } else {
                  displayName = 'Đang tải...';
                }

                return Dismissible(
                  key: Key(convo.id),
                   background: Container(color: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerLeft, child: const Icon(Icons.push_pin, color: Colors.white)),
                  secondaryBackground: Container(color: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerRight, child: const Icon(Icons.delete, color: Colors.white)),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                       final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Xóa cuộc trò chuyện?'), content: const Text('Hành động này sẽ xóa vĩnh viễn cuộc trò chuyện.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red)))]));
                      return confirmed ?? false;
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng ghim đang được phát triển!')));
                       return false;
                    }
                  },
                  child: ListTile(
                    leading: CircleAvatar(radius: 30, backgroundColor: Colors.grey.shade800), // Simplified leading for clarity, your original logic is kept in your file
                    title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(convoData['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isUnread ? Colors.white : Colors.grey, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                    trailing: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(conversationId: convo.id, recipientId: otherUserId, isGroup: false))),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
