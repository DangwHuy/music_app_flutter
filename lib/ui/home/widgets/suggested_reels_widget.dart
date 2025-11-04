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
  final ScrollController _scrollController = ScrollController();
  String? _currentPlayingReelId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setCurrentPlaying(String? reelId) {
    if (_currentPlayingReelId != reelId) {
      setState(() {
        _currentPlayingReelId = reelId;
      });
    }
  }

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
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    final reelId = reels[index].id;
                    final isCurrentPlaying = _currentPlayingReelId == reelId;

                    return _ReelPreviewCard(
                      key: ValueKey(reelId), // 🔥 FIX: Thêm key
                      reelDocument: reels[index],
                      shouldPlay: isCurrentPlaying,
                      onTap: () => _setCurrentPlaying(reelId),
                      onStop: () => _setCurrentPlaying(null),
                    );
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
  final bool shouldPlay;
  final VoidCallback onTap;
  final VoidCallback onStop;

  const _ReelPreviewCard({
    super.key,
    required this.reelDocument,
    required this.shouldPlay,
    required this.onTap,
    required this.onStop,
  });

  @override
  State<_ReelPreviewCard> createState() => _ReelPreviewCardState();
}

class _ReelPreviewCardState extends State<_ReelPreviewCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isInitializing = false;

  @override
  void didUpdateWidget(_ReelPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldPlay != oldWidget.shouldPlay) {
      if (widget.shouldPlay) {
        _initializeAndPlay();
      } else {
        _stopAndDispose();
      }
    }
  }

  @override
  void dispose() {
    _stopAndDispose();
    super.dispose();
  }

  // 🔥 FIX: Sửa thứ tự và thêm setPlaybackSpeed
  Future<void> _initializeAndPlay() async {
    if (_isInitializing || _controller != null) return;

    final reelData = widget.reelDocument.data() as Map<String, dynamic>;
    final videoUrl = reelData['videoUrl'] as String?;

    if (videoUrl == null || videoUrl.isEmpty) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      print('🎬 Initializing preview video...');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // 🔥 BƯỚC 1: Initialize TRƯỚC
      await _controller!.initialize();

      if (!mounted || !widget.shouldPlay) {
        _controller?.dispose();
        _controller = null;
        return;
      }

      // 🔥 BƯỚC 2: Set options SAU KHI đã initialize
      await _controller!.setVolume(0.0); // Mute
      await _controller!.setLooping(true); // Loop
      await _controller!.setPlaybackSpeed(1.0); // 🔥 QUAN TRỌNG: Speed = 1.0x

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      // 🔥 BƯỚC 3: Thêm listener để kiểm soát
      _controller!.addListener(_videoListener);

      // 🔥 BƯỚC 4: Play
      await _controller!.play();

      print('✅ Preview video initialized and playing at 1.0x speed');
    } catch (error) {
      print('❌ Error initializing reel video: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
        });
      }
      _controller?.dispose();
      _controller = null;
    }
  }

  // 🔥 FIX: Thêm listener để kiểm soát playback
  void _videoListener() {
    if (_controller == null || !mounted) return;

    // Tự động reset về 1.0x nếu bị thay đổi
    if (_controller!.value.playbackSpeed != 1.0) {
      print('⚠️ Preview speed changed to ${_controller!.value.playbackSpeed}, resetting...');
      _controller!.setPlaybackSpeed(1.0);
    }

    // Check errors
    if (_controller!.value.hasError) {
      print('❌ Preview video error: ${_controller!.value.errorDescription}');
      if (mounted && !_hasError) {
        setState(() => _hasError = true);
      }
    }
  }

  void _stopAndDispose() {
    _controller?.removeListener(_videoListener); // 🔥 FIX: Remove listener
    _controller?.pause();
    _controller?.dispose();
    _controller = null;

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _isInitializing = false;
      });
    }
  }

  void _navigateToFullReel() {
    widget.onStop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReelsTab(),
      ),
    );
  }

  void _handleTap() {
    if (!widget.shouldPlay) {
      widget.onTap();
    } else {
      _navigateToFullReel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reelData = widget.reelDocument.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: _handleTap,
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
              // Video hoặc placeholder
              if (_isInitialized && _controller != null && !_hasError)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_hasError)
                Container(
                  color: Colors.grey[900],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Video không tải được',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_isInitializing)
                  Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.video_library, color: Colors.white54, size: 50),
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
                      if (reelData['caption'] != null &&
                          (reelData['caption'] as String).isNotEmpty)
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

              // Play icon - chỉ hiện khi chưa play
              if (!widget.shouldPlay && !_isInitializing)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

              // Mute icon - hiện khi đang play
              if (widget.shouldPlay && _isInitialized)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_off,
                      color: Colors.white,
                      size: 16,
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

// ============================================
//  ĐÃ FIX:
// ============================================
// 1.Thêm key: ValueKey(reelId)
// 2.Sửa thứ tự: initialize() → set options
// 3.Thêm setPlaybackSpeed(1.0) - QUAN TRỌNG NHẤT
// 4.Thêm _videoListener() để kiểm soát speed
// 5.Remove listener trong _stopAndDispose()
// 6.Thêm print statements để debug
// ============================================