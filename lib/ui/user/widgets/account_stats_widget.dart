import 'package:flutter/material.dart';

/// Widget hiển thị thống kê tài khoản (Bài viết, Người theo dõi, Đang theo dõi)
/// Đặt trong: lib/ui/user/widgets/account_stats_widget.dart
class AccountStatsWidget extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const AccountStatsWidget({
    super.key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Bài viết', postCount.toString(), null),
        _buildStatColumn('Người theo dõi', _formatCount(followerCount), onFollowersTap),
        _buildStatColumn('Đang theo dõi', _formatCount(followingCount), onFollowingTap),
      ],
    );
  }

  Widget _buildStatColumn(String label, String count, VoidCallback? onTap) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: column,
        ),
      );
    }

    return column;
  }

  /// Format số lượng theo kiểu K, M
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}