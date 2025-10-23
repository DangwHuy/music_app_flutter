import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupMembersScreen extends StatelessWidget {
  final String conversationId;
  final List<String> participantIds;
  final String? adminId;

  const GroupMembersScreen({super.key, required this.participantIds, this.adminId, required this.conversationId});

  Future<void> _removeMember(BuildContext context, String memberId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('Are you sure you want to remove this member from the group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
        'participants': FieldValue.arrayRemove([memberId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUserAdmin = currentUserId == adminId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Members (${participantIds.length})'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: participantIds.length,
        itemBuilder: (context, index) {
          final userId = participantIds[index];
          final bool isMemberAdmin = userId == adminId;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(title: Text('Loading...', style: TextStyle(color: Colors.grey)));
              }
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final name = userData['displayName']?.isNotEmpty == true ? userData['displayName'] : userData['username'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                  child: userData['avatarUrl'] == null ? const Icon(Icons.person) : null,
                ),
                title: Row(
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white)),
                    if (isMemberAdmin)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text('Admin', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Text('@${userData['username']}', style: const TextStyle(color: Colors.grey)),
                // Show remove button if the current user is admin AND the member is not the admin themselves
                trailing: (isCurrentUserAdmin && !isMemberAdmin)
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeMember(context, userId),
                    )
                  : null,
              );
            },
          );
        },
      ),
    );
  }
}
