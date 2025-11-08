// import 'dart:async'; // Thêm import này để sử dụng StreamSubscription
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'incoming_call_screen.dart'; // Đảm bảo file này tồn tại và import đúng
//
// /// Service để lắng nghe cuộc gọi đến
// /// Thêm vào main.dart hoặc root widget của app
// class CallListenerService {
//   static StreamSubscription<QuerySnapshot>? _callSubscription;
//
//   /// Bắt đầu lắng nghe cuộc gọi đến
//   static void startListening(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) return;
//
//     _callSubscription = FirebaseFirestore.instance
//         .collection('calls')
//         .where('receiverId', isEqualTo: currentUser.uid)
//         .where('status', isEqualTo: 'ringing')
//         .snapshots()
//         .listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final data = change.doc.data() as Map<String, dynamic>;
//
//           // Show incoming call screen
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => IncomingCallScreen(
//                 callId: change.doc.id,
//                 callerName: data['callerName'] ?? 'Unknown',
//                 callerId: data['callerId'],
//                 isVideoCall: data['isVideoCall'] ?? false,
//               ),
//               fullscreenDialog: true,
//             ),
//           );
//         }
//       }
//     });
//   }
//
//   /// Dừng lắng nghe
//   static void stopListening() {
//     _callSubscription?.cancel();
//     _callSubscription = null;
//   }
// }