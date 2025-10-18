import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lan2tesst/ui/discovery/discovery.dart';
import 'package:lan2tesst/ui/settings/settings.dart';
import 'package:lan2tesst/ui/user/user.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const DiscoveryTab(),
    const AccountTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Discovery'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Viewly'),
          ),
          child: _tabs[index],
        );
      },
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 10, // Let's create 10 mock posts
        itemBuilder: (context, index) {
          return const PostCard();
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          const ListTile(
            leading: CircleAvatar(
              // Placeholder for user avatar
              backgroundColor: Colors.grey,
            ),
            title: Text('username', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Location'),
            trailing: Icon(Icons.more_horiz),
          ),

          // Post Image
          Image.network(
            // Placeholder image - using picsum.photos for variety
            'https://picsum.photos/600/400?random=${DateTime.now().millisecondsSinceEpoch}',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
                IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
                const Spacer(),
                IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
              ],
            ),
          ),

          // Likes and Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1,234 likes', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'username ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'This is a caption for the post. #flutter #viewly'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('View all 56 comments', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
