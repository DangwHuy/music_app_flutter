import 'package:flutter/material.dart';

// Placeholder data model for a Reel. Later, this can be a class that maps to your Firestore documents.
class _Reel {
  final String imageUrl;
  final String username;
  final String songTitle;
  final String likes;
  final String comments;

  _Reel({
    required this.imageUrl,
    required this.username,
    required this.songTitle,
    required this.likes,
    required this.comments,
  });
}

class ReelsTab extends StatefulWidget {
  const ReelsTab({super.key});

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  // Placeholder data. Later, you can fetch this from a `reels` collection in Firestore.
  final List<_Reel> _reels = [
    _Reel(imageUrl: 'https://picsum.photos/seed/reel1/800/1600', username: 'phan.dang.huy', songTitle: 'Ocean Drive - Duke Dumont', likes: '1.2M', comments: '4,532'),
    _Reel(imageUrl: 'https://picsum.photos/seed/reel2/800/1600', username: 'giang.cute', songTitle: 'Blinding Lights - The Weeknd', likes: '987K', comments: '2,109'),
    _Reel(imageUrl: 'https://picsum.photos/seed/reel3/800/1600', username: 'duc.thuan', songTitle: 'Levitating - Dua Lipa', likes: '2.5M', comments: '11.2K'),
    _Reel(imageUrl: 'https://picsum.photos/seed/reel4/800/1600', username: 'meta.ai', songTitle: 'Future Nostalgia - Dua Lipa', likes: '876K', comments: '1,987'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          return _ReelPage(reel: _reels[index]);
        },
      ),
    );
  }
}

// This widget represents a single page (a single Reel) in the PageView.
class _ReelPage extends StatelessWidget {
  final _Reel reel;

  const _ReelPage({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image (simulating the video)
        Image.network(reel.imageUrl, fit: BoxFit.cover),
        
        // Gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.center,
            ),
          ),
        ),

        // UI Elements (Username, Song, Buttons)
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side: User and song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                            const SizedBox(width: 8),
                            Text(reel.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(reel.songTitle, style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side: Action buttons
                  Column(
                    children: [
                      _buildActionButton(icon: Icons.favorite, label: reel.likes, onTap: () {}),
                      _buildActionButton(icon: Icons.comment_bank, label: reel.comments, onTap: () {}),
                      _buildActionButton(icon: Icons.send, label: 'Chia sẻ', onTap: () {}),
                      _buildActionButton(icon: Icons.more_horiz, label: '', onTap: () {}),
                    ],
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            if (label.isNotEmpty)
              const SizedBox(height: 4),
            if (label.isNotEmpty)
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
