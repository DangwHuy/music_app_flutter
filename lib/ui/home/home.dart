import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lan2tesst/ui/create_post/create_post.dart';
import 'package:lan2tesst/ui/reels/reels_screen.dart';
import 'package:lan2tesst/ui/search/search.dart';
import 'package:lan2tesst/ui/user/user.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const HomeTab(),
    const SearchTab(),
    const ReelsTab(),
    const AccountTab(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // The "Create" button
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
    } else {
      // Adjust index for the tabs list, as "Create" is not a real tab
      setState(() {
        _currentIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < 2 ? _currentIndex : _currentIndex + 1,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              'Viewly',
              style: TextStyle(fontFamily: 'Billabong', fontSize: 35, color: Colors.black),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
            ],
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          const SliverToBoxAdapter(
            child: _StoryBar(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PostCard(index: index),
              childCount: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBar extends StatefulWidget {
  const _StoryBar();

  @override
  State<_StoryBar> createState() => _StoryBarState();
}

class _StoryBarState extends State<_StoryBar> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      height: 100,
      child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
          builder: (context, snapshot) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                if (index == 0) {
                  if (!snapshot.hasData) {
                    return const _StoryCircle(index: 0, isPlaceholder: true);
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return _StoryCircle(
                    index: 0,
                    username: userData['username'] ?? '',
                    imageUrl: userData['avatarUrl'],
                  );
                }
                return _StoryCircle(index: index);
              },
            );
          }),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final int index;
  final String? username;
  final String? imageUrl;
  final bool isPlaceholder;

  const _StoryCircle({
    super.key,
    required this.index,
    this.username,
    this.imageUrl,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final mockImageUrl = 'https://picsum.photos/seed/story$index/100/100';

    return SizedBox(
      width: 80,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.orange),
                const CircleAvatar(radius: 28, backgroundColor: Colors.white),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: isPlaceholder
                      ? null
                      : NetworkImage(isFirst ? (imageUrl ?? mockImageUrl) : mockImageUrl),
                ),
                if (isFirst && !isPlaceholder)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              isPlaceholder
                  ? ''
                  : (isFirst ? username ?? 'You' : 'user_$index'),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final int index;
  const PostCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final imageUrl = index == 0
        ? 'https://picsum.photos/id/1025/600/400'
        : 'https://picsum.photos/seed/${index + 1}/600/400';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey),
            title: Text('username', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Location'),
            trailing: Icon(Icons.more_horiz),
          ),
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 300,
              child: Center(child: Icon(Icons.error, color: Colors.grey)),
            ),
          ),
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
