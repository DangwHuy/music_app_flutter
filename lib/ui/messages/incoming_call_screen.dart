// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'call_service.dart';
// import 'call_screen.dart';
//
// class IncomingCallScreen extends StatefulWidget {
//   final String callId;
//   final String callerName;
//   final String callerId;
//   final bool isVideoCall;
//
//   const IncomingCallScreen({
//     Key? key,
//     required this.callId,
//     required this.callerName,
//     required this.callerId,
//     required this.isVideoCall,
//   }) : super(key: key);
//
//   @override
//   State<IncomingCallScreen> createState() => _IncomingCallScreenState();
// }
//
// class _IncomingCallScreenState extends State<IncomingCallScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   final CallService _callService = CallService();
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat();
//
//     // Listen for call status changes
//     _listenToCallStatus();
//   }
//
//   void _listenToCallStatus() {
//     FirebaseFirestore.instance
//         .collection('calls')
//         .doc(widget.callId)
//         .snapshots()
//         .listen((snapshot) {
//       if (!mounted) return;
//
//       if (snapshot.exists) {
//         final data = snapshot.data() as Map<String, dynamic>;
//         final status = data['status'] as String;
//
//         // If caller ended the call while ringing
//         if (status == 'ended') {
//           Navigator.of(context).pop();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Cuộc gọi đã kết thúc'),
//               backgroundColor: Colors.grey,
//             ),
//           );
//         }
//       }
//     });
//   }
//
//   Future<void> _acceptCall() async {
//     // Request permissions
//     final hasPermissions = await _requestPermissions();
//     if (!hasPermissions) {
//       _showError('Cần cấp quyền camera và microphone');
//       return;
//     }
//
//     try {
//       // Initialize call service
//       await _callService.initialize();
//       await _callService.openUserMedia(isVideoCall: widget.isVideoCall);
//
//       // Navigate to call screen
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => CallScreen(
//               callId: widget.callId,
//               isVideoCall: widget.isVideoCall,
//               isCaller: false,
//               peerName: widget.callerName,
//               peerId: widget.callerId,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error accepting call: $e');
//       _showError('Không thể chấp nhận cuộc gọi');
//     }
//   }
//
//   Future<void> _rejectCall() async {
//     await _callService.rejectCall(widget.callId);
//     if (mounted) {
//       Navigator.of(context).pop();
//     }
//   }
//
//   Future<bool> _requestPermissions() async {
//     final micPermission = await Permission.microphone.request();
//
//     if (widget.isVideoCall) {
//       final cameraPermission = await Permission.camera.request();
//       return micPermission.isGranted && cameraPermission.isGranted;
//     }
//
//     return micPermission.isGranted;
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Top section
//             const SizedBox(height: 60),
//
//             // Caller info
//             Column(
//               children: [
//                 // Animated avatar
//                 AnimatedBuilder(
//                   animation: _animationController,
//                   builder: (context, child) {
//                     return Container(
//                       width: 150,
//                       height: 150,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(
//                           color: Colors.blue.withOpacity(
//                             0.3 + (_animationController.value * 0.4),
//                           ),
//                           width: 4,
//                         ),
//                       ),
//                       child: child,
//                     );
//                   },
//                   child: CircleAvatar(
//                     radius: 70,
//                     backgroundColor: Colors.grey.shade800,
//                     child: Text(
//                       widget.callerName[0].toUpperCase(),
//                       style: const TextStyle(
//                         fontSize: 56,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 // Caller name
//                 Text(
//                   widget.callerName,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//
//                 const SizedBox(height: 10),
//
//                 // Call type
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       widget.isVideoCall ? Icons.videocam : Icons.call,
//                       color: Colors.blue,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       widget.isVideoCall ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 // Ringing text
//                 const Text(
//                   'Đang gọi đến...',
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 14,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ),
//
//             // Bottom buttons
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   // Reject button
//                   _buildCallActionButton(
//                     icon: Icons.call_end,
//                     label: 'Từ chối',
//                     color: Colors.red,
//                     onTap: _rejectCall,
//                   ),
//
//                   const SizedBox(width: 40),
//
//                   // Accept button
//                   _buildCallActionButton(
//                     icon: widget.isVideoCall ? Icons.videocam : Icons.call,
//                     label: 'Chấp nhận',
//                     color: Colors.green,
//                     onTap: _acceptCall,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCallActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: 70,
//             height: 70,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.4),
//                   blurRadius: 20,
//                   spreadRadius: 5,
//                 ),
//               ],
//             ),
//             child: Icon(
//               icon,
//               color: Colors.white,
//               size: 32,
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }