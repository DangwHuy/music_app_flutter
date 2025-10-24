import 'package:flutter/material.dart';
import 'package:lan2tesst/ui/messages/nickname_screen.dart'; // Import the new screen

class ChatDetailsScreen extends StatelessWidget {
  final String conversationId;
  final bool isGroup;

  const ChatDetailsScreen({super.key, required this.conversationId, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tùy chọn'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: Colors.white),
            title: const Text('Chủ đề', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white),
            title: const Text('Cảm xúc nhanh', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline, color: Colors.white),
            title: const Text('Biệt danh', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => NicknameScreen(conversationId: conversationId),
              ));
            },
          ),
          if (isGroup)
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.white),
              title: const Text('Xem thành viên', style: TextStyle(color: Colors.white)),
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
