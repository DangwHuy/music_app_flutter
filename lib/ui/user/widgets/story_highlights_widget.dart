import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget hiển thị Story Highlights
/// Đặt trong: lib/ui/user/widgets/story_highlights_widget.dart
class StoryHighlightsWidget extends StatelessWidget {
  final String userId;

  const StoryHighlightsWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('highlights')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Không hiển thị gì nếu chưa có highlights
          return const SizedBox.shrink();
        }

        final highlights = snapshot.data!.docs;

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length + 1, // +1 cho nút "Thêm mới"
            itemBuilder: (context, index) {
              // Nút thêm mới ở cuối
              if (index == highlights.length) {
                return _buildAddHighlight(context);
              }

              final highlight = highlights[index].data() as Map<String, dynamic>;
              return _buildHighlightItem(
                context: context,
                title: highlight['title'] ?? 'Highlight',
                coverUrl: highlight['coverUrl'],
                onTap: () => _viewHighlight(context, highlights[index].id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHighlightItem({
    required BuildContext context,
    required String title,
    String? coverUrl,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipOval(
                child: coverUrl != null
                    ? Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _defaultHighlightIcon(),
                )
                    : _defaultHighlightIcon(),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHighlight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _createHighlight(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const Icon(Icons.add, size: 32, color: Colors.black),
            ),
            const SizedBox(height: 4),
            const SizedBox(
              width: 70,
              child: Text(
                'Mới',
                style: TextStyle(fontSize: 12, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultHighlightIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.photo_library, size: 32, color: Colors.grey),
    );
  }

  void _viewHighlight(BuildContext context, String highlightId) {
    // TODO: Implement view highlight screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xem highlight')),
    );
  }

  void _createHighlight(BuildContext context) {
    // TODO: Implement create highlight screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo highlight mới')),
    );
  }
}