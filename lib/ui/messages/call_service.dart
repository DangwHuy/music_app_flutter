// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class CallService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
//
//   final RTCVideoRenderer localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
//
//   bool _isMuted = false;
//   bool _isVideoEnabled = true;
//
//   // Cấu hình ICE servers
//   final Map<String, dynamic> configuration = {
//     'iceServers': [
//       {'urls': 'stun:stun.l.google.com:19302'},
//       {'urls': 'stun:stun1.l.google.com:19302'},
//       {'urls': 'stun:stun2.l.google.com:19302'},
//     ]
//   };
//
//   // Khởi tạo
//   Future<void> initialize() async {
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//   }
//
//   // Dọn dẹp
//   Future<void> dispose() async {
//     await _localStream?.dispose();
//     await _remoteStream?.dispose();
//     await _peerConnection?.close();
//     await localRenderer.dispose();
//     await remoteRenderer.dispose();
//   }
//
//   // Mở camera và microphone
//   Future<void> openUserMedia({required bool isVideoCall}) async {
//     final Map<String, dynamic> mediaConstraints = {
//       'audio': {
//         'echoCancellation': true,
//         'noiseSuppression': true,
//         'autoGainControl': true,
//       },
//       'video': isVideoCall
//           ? {
//         'facingMode': 'user',
//         'width': {'ideal': 1280},
//         'height': {'ideal': 720},
//       }
//           : false,
//     };
//
//     try {
//       _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
//       localRenderer.srcObject = _localStream;
//       _isVideoEnabled = isVideoCall;
//     } catch (e) {
//       print('Error opening media: $e');
//       rethrow;
//     }
//   }
//
//   // Tạo cuộc gọi mới
//   Future<String> createCall({
//     required String receiverId,
//     required String receiverName,
//     required bool isVideoCall,
//   }) async {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) throw Exception('User not logged in');
//
//     // Tạo peer connection
//     _peerConnection = await createPeerConnection(configuration);
//
//     // Add local stream tracks
//     _localStream?.getTracks().forEach((track) {
//       _peerConnection?.addTrack(track, _localStream!);
//     });
//
//     // Listen for remote stream
//     _peerConnection?.onTrack = (RTCTrackEvent event) {
//       if (event.streams.isNotEmpty) {
//         _remoteStream = event.streams[0];
//         remoteRenderer.srcObject = _remoteStream;
//       }
//     };
//
//     // Tạo document cho cuộc gọi
//     final callDoc = _firestore.collection('calls').doc();
//     final callId = callDoc.id;
//
//     // Tạo offer
//     RTCSessionDescription offer = await _peerConnection!.createOffer();
//     await _peerConnection!.setLocalDescription(offer);
//
//     // Lưu thông tin call
//     await callDoc.set({
//       'callerId': currentUser.uid,
//       'callerName': currentUser.displayName ?? 'Unknown',
//       'receiverId': receiverId,
//       'receiverName': receiverName,
//       'isVideoCall': isVideoCall,
//       'status': 'ringing',
//       'offer': {
//         'sdp': offer.sdp,
//         'type': offer.type,
//       },
//       'createdAt': FieldValue.serverTimestamp(),
//     });
//
//     // Listen for ICE candidates
//     _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//       if (candidate.candidate != null) {
//         callDoc.collection('callerCandidates').add({
//           'candidate': candidate.candidate,
//           'sdpMid': candidate.sdpMid,
//           'sdpMLineIndex': candidate.sdpMLineIndex,
//         });
//       }
//     };
//
//     // Listen for answer
//     callDoc.snapshots().listen((snapshot) async {
//       if (snapshot.exists) {
//         final data = snapshot.data() as Map<String, dynamic>;
//
//         // Check if call was rejected or ended
//         if (data['status'] == 'rejected' || data['status'] == 'ended') {
//           return;
//         }
//
//         // Set remote description from answer
//         if (data['answer'] != null && _peerConnection != null) {
//           final answer = RTCSessionDescription(
//             data['answer']['sdp'],
//             data['answer']['type'],
//           );
//           await _peerConnection!.setRemoteDescription(answer);
//         }
//       }
//     });
//
//     // Listen for receiver's ICE candidates
//     callDoc.collection('receiverCandidates').snapshots().listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final data = change.doc.data() as Map<String, dynamic>;
//           _peerConnection?.addCandidate(RTCIceCandidate(
//             data['candidate'],
//             data['sdpMid'],
//             data['sdpMLineIndex'],
//           ));
//         }
//       }
//     });
//
//     return callId;
//   }
//
//   // Trả lời cuộc gọi
//   Future<void> answerCall(String callId) async {
//     final callDoc = _firestore.collection('calls').doc(callId);
//     final callSnapshot = await callDoc.get();
//
//     if (!callSnapshot.exists) {
//       throw Exception('Call not found');
//     }
//
//     final data = callSnapshot.data() as Map<String, dynamic>;
//
//     // Create peer connection
//     _peerConnection = await createPeerConnection(configuration);
//
//     // Add local stream
//     _localStream?.getTracks().forEach((track) {
//       _peerConnection?.addTrack(track, _localStream!);
//     });
//
//     // Listen for remote stream
//     _peerConnection?.onTrack = (RTCTrackEvent event) {
//       if (event.streams.isNotEmpty) {
//         _remoteStream = event.streams[0];
//         remoteRenderer.srcObject = _remoteStream;
//       }
//     };
//
//     // Set remote description (offer)
//     final offer = RTCSessionDescription(
//       data['offer']['sdp'],
//       data['offer']['type'],
//     );
//     await _peerConnection!.setRemoteDescription(offer);
//
//     // Create answer
//     final answer = await _peerConnection!.createAnswer();
//     await _peerConnection!.setLocalDescription(answer);
//
//     // Save answer and update status
//     await callDoc.update({
//       'answer': {
//         'sdp': answer.sdp,
//         'type': answer.type,
//       },
//       'status': 'accepted',
//     });
//
//     // Listen for ICE candidates
//     _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//       if (candidate.candidate != null) {
//         callDoc.collection('receiverCandidates').add({
//           'candidate': candidate.candidate,
//           'sdpMid': candidate.sdpMid,
//           'sdpMLineIndex': candidate.sdpMLineIndex,
//         });
//       }
//     };
//
//     // Listen for caller's ICE candidates
//     callDoc.collection('callerCandidates').snapshots().listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           final data = change.doc.data() as Map<String, dynamic>;
//           _peerConnection?.addCandidate(RTCIceCandidate(
//             data['candidate'],
//             data['sdpMid'],
//             data['sdpMLineIndex'],
//           ));
//         }
//       }
//     });
//   }
//
//   // Từ chối cuộc gọi
//   Future<void> rejectCall(String callId) async {
//     await _firestore.collection('calls').doc(callId).update({
//       'status': 'rejected',
//     });
//   }
//
//   // Kết thúc cuộc gọi
//   Future<void> endCall(String callId) async {
//     await _firestore.collection('calls').doc(callId).update({
//       'status': 'ended',
//       'endedAt': FieldValue.serverTimestamp(),
//     });
//
//     await _localStream?.dispose();
//     await _peerConnection?.close();
//     _localStream = null;
//     _peerConnection = null;
//   }
//
//   // Toggle microphone
//   void toggleMicrophone() {
//     if (_localStream != null) {
//       final audioTracks = _localStream!.getAudioTracks();
//       if (audioTracks.isNotEmpty) {
//         _isMuted = !_isMuted;
//         audioTracks[0].enabled = !_isMuted;
//       }
//     }
//   }
//
//   // Toggle camera
//   void toggleCamera() {
//     if (_localStream != null) {
//       final videoTracks = _localStream!.getVideoTracks();
//       if (videoTracks.isNotEmpty) {
//         _isVideoEnabled = !_isVideoEnabled;
//         videoTracks[0].enabled = _isVideoEnabled;
//       }
//     }
//   }
//
//   // Switch camera
//   Future<void> switchCamera() async {
//     if (_localStream != null) {
//       final videoTracks = _localStream!.getVideoTracks();
//       if (videoTracks.isNotEmpty) {
//         await Helper.switchCamera(videoTracks[0]);
//       }
//     }
//   }
//
//   // Getters
//   bool get isMuted => _isMuted;
//   bool get isVideoEnabled => _isVideoEnabled;
// }