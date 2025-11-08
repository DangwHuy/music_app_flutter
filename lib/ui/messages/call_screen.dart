// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'call_service.dart';
//
// class CallScreen extends StatefulWidget {
//   final String callId;
//   final bool isVideoCall;
//   final bool isCaller;
//   final String peerName;
//   final String peerId;
//
//   const CallScreen({
//     Key? key,
//     required this.callId,
//     required this.isVideoCall,
//     required this.isCaller,
//     required this.peerName,
//     required this.peerId,
//   }) : super(key: key);
//
//   @override
//   State<CallScreen> createState() => _CallScreenState();
// }
//
// class _CallScreenState extends State<CallScreen> {
//   final CallService _callService = CallService();
//   bool _isMuted = false;
//   bool _isVideoEnabled = true;
//   bool _isConnected = false;
//   String _callStatus = 'Đang kết nối...';
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCall();
//     _listenToCallStatus();
//   }
//
//   Future<void> _initializeCall() async {
//     try {
//       await _callService.initialize();
//       await _callService.openUserMedia(isVideoCall: widget.isVideoCall);
//
//       if (widget.isCaller) {
//         // Caller đã tạo call từ trước, chỉ cần setup
//         setState(() {
//           _callStatus = 'Đang gọi ${widget.peerName}...';
//         });
//       } else {
//         // Receiver trả lời cuộc gọi
//         await _callService.answerCall(widget.callId);
//         setState(() {
//           _isConnected = true;
//           _callStatus = 'Đã kết nối';
//         });
//       }
//     } catch (e) {
//       print('Error initializing call: $e');
//       _showError('Không thể khởi tạo cuộc gọi');
//     }
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
//         if (status == 'accepted' && widget.isCaller) {
//           setState(() {
//             _isConnected = true;
//             _callStatus = 'Đã kết nối';
//           });
//         } else if (status == 'rejected') {
//           _showError('${widget.peerName} đã từ chối cuộc gọi');
//           _endCallAndPop();
//         } else if (status == 'ended') {
//           _endCallAndPop();
//         }
//       }
//     });
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
//   Future<void> _endCallAndPop() async {
//     await _callService.endCall(widget.callId);
//     if (mounted) {
//       Navigator.of(context).pop();
//     }
//   }
//
//   @override
//   void dispose() {
//     _callService.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // Remote video (full screen)
//             if (widget.isVideoCall)
//               Positioned.fill(
//                 child: _isConnected
//                     ? RTCVideoView(
//                   _callService.remoteRenderer,
//                   objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                 )
//                     : Container(
//                   color: Colors.grey.shade900,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 60,
//                           backgroundColor: Colors.grey.shade800,
//                           child: Text(
//                             widget.peerName[0].toUpperCase(),
//                             style: const TextStyle(
//                               fontSize: 48,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Text(
//                           widget.peerName,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//             else
//             // Voice call UI
//               Positioned.fill(
//                 child: Container(
//                   color: Colors.grey.shade900,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 80,
//                           backgroundColor: Colors.grey.shade800,
//                           child: Text(
//                             widget.peerName[0].toUpperCase(),
//                             style: const TextStyle(
//                               fontSize: 64,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 30),
//                         Text(
//                           widget.peerName,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           _callStatus,
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//
//             // Local video preview (for video calls)
//             if (widget.isVideoCall)
//               Positioned(
//                 top: 50,
//                 right: 20,
//                 child: Container(
//                   width: 120,
//                   height: 160,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.white, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: RTCVideoView(
//                       _callService.localRenderer,
//                       mirror: true,
//                       objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                     ),
//                   ),
//                 ),
//               ),
//
//             // Top info bar
//             Positioned(
//               top: 20,
//               left: 20,
//               right: widget.isVideoCall ? 160 : 20,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.peerName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _callStatus,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             // Control buttons
//             Positioned(
//               bottom: 50,
//               left: 0,
//               right: 0,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   // Mute button
//                   _buildControlButton(
//                     icon: _isMuted ? Icons.mic_off : Icons.mic,
//                     label: _isMuted ? 'Bật mic' : 'Tắt mic',
//                     onTap: () {
//                       setState(() {
//                         _isMuted = !_isMuted;
//                         _callService.toggleMicrophone();
//                       });
//                     },
//                     backgroundColor: _isMuted ? Colors.red : Colors.white24,
//                   ),
//
//                   // Video toggle (only for video calls)
//                   if (widget.isVideoCall)
//                     _buildControlButton(
//                       icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
//                       label: _isVideoEnabled ? 'Tắt camera' : 'Bật camera',
//                       onTap: () {
//                         setState(() {
//                           _isVideoEnabled = !_isVideoEnabled;
//                           _callService.toggleCamera();
//                         });
//                       },
//                       backgroundColor: _isVideoEnabled ? Colors.white24 : Colors.red,
//                     ),
//
//                   // End call button
//                   _buildControlButton(
//                     icon: Icons.call_end,
//                     label: 'Kết thúc',
//                     onTap: _endCallAndPop,
//                     backgroundColor: Colors.red,
//                     size: 64,
//                   ),
//
//                   // Switch camera (only for video calls)
//                   if (widget.isVideoCall)
//                     _buildControlButton(
//                       icon: Icons.flip_camera_ios,
//                       label: 'Đổi camera',
//                       onTap: () {
//                         _callService.switchCamera();
//                       },
//                       backgroundColor: Colors.white24,
//                     ),
//
//                   // Speaker button
//                   _buildControlButton(
//                     icon: Icons.volume_up,
//                     label: 'Loa',
//                     onTap: () {
//                       // TODO: Implement speaker toggle
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Chức năng đang phát triển'),
//                         ),
//                       );
//                     },
//                     backgroundColor: Colors.white24,
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
//   Widget _buildControlButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     required Color backgroundColor,
//     double size = 56,
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: size,
//             height: size,
//             decoration: BoxDecoration(
//               color: backgroundColor,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: Colors.white,
//               size: size * 0.45,
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white70,
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }
// }