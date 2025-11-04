import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Widget chứa các nút hành động trên profile
/// Đặt trong: lib/ui/user/widgets/profile_action_buttons.dart
class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onEditProfile;
  final String username;

  const ProfileActionButtons({
    super.key,
    required this.onEditProfile,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nút Chỉnh sửa
        Expanded(
          child: _buildOutlinedButton(
            onPressed: onEditProfile,
            label: 'Chỉnh sửa trang cá nhân',
          ),
        ),
        const SizedBox(width: 8),
        // Nút Chia sẻ
        Expanded(
          child: _buildOutlinedButton(
            onPressed: () => _shareProfile(context),
            label: 'Chia sẻ trang cá nhân',
          ),
        ),
        const SizedBox(width: 8),
        // Nút Khám phá người
        _buildIconButton(
          onPressed: () => _showDiscoverPeople(context),
          icon: Icons.person_add_outlined,
        ),
      ],
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(44, 44),
      ),
      child: Icon(icon, size: 20),
    );
  }

  void _shareProfile(BuildContext context) {
    // TODO: Thay bằng link thực tế của app
    final profileLink = 'https://yourapp.com/@$username';
    Share.share(
      'Xem trang cá nhân của tôi: $profileLink',
      subject: 'Trang cá nhân $username',
    );
  }

  void _showDiscoverPeople(BuildContext context) {
    // TODO: Navigate to discover people screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }
}