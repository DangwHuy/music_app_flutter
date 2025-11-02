import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:lan2tesst/ui/reels/reels_screen.dart';

class SuggestedReelsWidget extends StatefulWidget {
  const SuggestedReelsWidget({super.key});

  @override
  State<SuggestedReelsWidget> createState() => _SuggestedReelsWidgetState();
}

class _SuggestedReelsWidgetState extends State<SuggestedReelsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.video_library, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Thước phim gợi ý',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to ReelsTab
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ReelsTab()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reels')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildLoadingState();
              }

              if (snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              final reels = snapshot.data!.docs;

              return SizedBox(
                height: 240,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    return _ReelPreviewCard(reelDocument: reels[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _ReelPreviewCard extends StatefulWidget {
  final DocumentSnapshot reelDocument;

  const _ReelPreviewCard({required this.reelDocument});

  @override
  State<_ReelPreviewCard> createState() => _ReelPreviewCardState();
}

class _ReelPreviewCardState extends State<_ReelPreviewCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final reelData = widget.reelDocument.data() as Map<String, dynamic>;
    final videoUrl = reelData['videoUrl'] as String?;

    if (videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            // Loop video sau 3 giây
            _controller!.play();
            _controller!.setLooping(true);

            // Giới hạn playback 3 giây
            _controller!.addListener(_loopAfter3Seconds);
          }
        }).catchError((error) {
          if (mounted) {
            setState(() => _hasError = true);
          }
          print('Error loading reel preview: $error');
        });
    }
  }

  void _loopAfter3Seconds() {
    if (_controller != null && _controller!.value.position.inSeconds >= 3) {
      _controller!.seekTo(Duration.zero);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_loopAfter3Seconds);
    _controller?.dispose();
    super.dispose();
  }

  void _navigateToFullReel() {
    // Navigate to ReelsTab với index cụ thể
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReelsTab(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelData = widget.reelDocument.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: _navigateToFullReel,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              if (_isInitialized && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_hasError)
                const Center(
                  child: Icon(Icons.error_outline, color: Colors.white, size: 40),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(reelData['userId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          return Text(
                            userData['username'] ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Caption
                      if (reelData['caption'] != null && (reelData['caption'] as String).isNotEmpty)
                        Text(
                          reelData['caption'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      // Like count
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${(reelData['likes'] as List?)?.length ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Play icon overlay
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              // 3s badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '3s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}