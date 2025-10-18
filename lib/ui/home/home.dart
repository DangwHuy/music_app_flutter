import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lan2tesst/ui/search/search.dart';
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
    const SearchTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        // The HomeTab will manage its own scrolling and app bar, so we don't provide one here.
        return CupertinoPageScaffold(
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
      body: CustomScrollView(
        slivers: [
          // SliverAppBar that appears and disappears on scroll
          SliverAppBar(
            title: const Text(
              'Viewly',
              style: TextStyle(
                fontFamily: 'Billabong',
                fontSize: 35,
                color: Colors.black,
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () {}),
            ],
            floating: true, // Appears as soon as you scroll up
            snap: true,     // Snaps into view
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),

          // The Story bar
          const SliverToBoxAdapter(
            child: _StoryBar(),
          ),

          // The list of posts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PostCard(index: index), // Pass the index to the PostCard
              childCount: 10, // Let's create 10 mock posts
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBar extends StatelessWidget {
  const _StoryBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          // Pass the index to each story circle
          return _StoryCircle(index: index);
        },
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final int index;
  const _StoryCircle({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    // Generate a deterministic but different image for each story avatar
    final imageUrl = 'https://picsum.photos/seed/story$index/100/100';

    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.orange, // Story border color
              ),
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                backgroundImage: NetworkImage(imageUrl), // Load the avatar image
              ),
              if (isFirst)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(isFirst ? 'Your Story' : 'username', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}


class PostCard extends StatelessWidget {
  final int index;
  const PostCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // Use the index to generate a deterministic but different image for each card.
    // The first post (index 0) will have a static image, the rest will be seeded.
    final imageUrl = index == 0
        ? 'https://picsum.photos/id/1025/600/400' // A static image for the user's post (a dog)
        : 'https://picsum.photos/seed/${index + 1}/600/400';

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
            imageUrl, // Use the generated image URL
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 300,
              child: Center(child: Icon(Icons.error, color: Colors.grey)),
            ),
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
