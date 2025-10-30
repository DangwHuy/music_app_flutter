import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class ReelsTab extends StatelessWidget {
  const ReelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reels').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có thước phim nào.', style: TextStyle(color: Colors.white)));
          }

          final reels = snapshot.data!.docs;

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              return _ReelVideoPlayer(reelDocument: reels[index]);
            },
          );
        },
      ),
    );
  }
}

class _ReelVideoPlayer extends StatefulWidget {
  final DocumentSnapshot reelDocument;

  const _ReelVideoPlayer({required this.reelDocument});

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    final reelData = widget.reelDocument.data() as Map<String, dynamic>;
    final videoUrl = reelData['videoUrl'] as String?;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    _isLiked = (reelData['likes'] as List? ?? []).contains(currentUserId);
    _likeCount = (reelData['likes'] as List? ?? []).length;

    if (videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          }
        }).catchError((error) {
          // *** THÊM: Error handling ***
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải video: $error')),
          );
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // *** THÊM: Keep alive để preload ***
  @override
  bool get wantKeepAlive => true;

  Future<void> _likeReel() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reelRef = widget.reelDocument.reference;

    setState(() {
      if (_isLiked) {
        _likeCount -= 1;
        _isLiked = false;
      } else {
        _likeCount += 1;
        _isLiked = true;
      }
    });

    if (_isLiked) {
      await reelRef.update({'likes': FieldValue.arrayUnion([currentUser.uid])});
    } else {
      await reelRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final reelData = widget.reelDocument.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(reelData['userId']).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'Unknown';

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  _isPlaying = !_isPlaying;
                });
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            _buildUiOverlay(reelData, username),
          ],
        );
      },
    );
  }

  Widget _buildUiOverlay(Map<String, dynamic> reelData, String username) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(reelData['caption'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: _likeCount.toString(),
                    onTap: _likeReel,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                  _buildActionButton(icon: Icons.comment_bank, label: '0', onTap: () {}),
                  _buildActionButton(icon: Icons.send, label: 'Chia sẻ', onTap: () {}),
                  _buildActionButton(icon: Icons.more_horiz, label: '', onTap: () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 32),
            if (label.isNotEmpty) const SizedBox(height: 4),
            if (label.isNotEmpty) Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}