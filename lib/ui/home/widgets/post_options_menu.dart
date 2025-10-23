import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showPostOptionsMenu(BuildContext context, DocumentSnapshot postDocument) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final postAuthorId = postDocument['userId'];
  final isMyPost = currentUserId == postAuthorId;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    builder: (context) {
      return Wrap(
        children: <Widget>[
          if (isMyPost)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close the bottom sheet
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Post?'),
                    content: const Text('Are you sure you want to delete this post?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await postDocument.reference.delete();
                }
              },
            )
          else ...[
            const ListTile(
              leading: Icon(Icons.bookmark_outline, color: Colors.white),
              title: Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
            const ListTile(
              leading: Icon(Icons.person_add_disabled_outlined, color: Colors.white),
              title: Text('Bỏ theo dõi', style: TextStyle(color: Colors.white)),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white),
              title: Text('Tại sao bạn nhìn thấy bài viết này', style: TextStyle(color: Colors.white)),
            ),
             ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Báo cáo', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ]
        ],
      );
    },
  );
}
