import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================================
// BACKGROUND MESSAGE HANDLER - PHẢI Ở NGOÀI CLASS
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📲 Background message: ${message.messageId}');
}

// ============================================================================
// NOTIFICATION SERVICE - Xử lý tất cả logic notification
// ============================================================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // NavigatorKey để navigate từ notification
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  // ============================================================================
  // KHỞI TẠO SERVICE
  // ============================================================================
  Future<void> initialize() async {
    print('🔔 Initializing NotificationService...');

    // 1. Cấu hình Local Notifications
    await _initializeLocalNotifications();

    // 2. Request permission
    await _requestPermission();

    // 3. Setup message handlers
    _setupMessageHandlers();

    print('✅ NotificationService initialized');
  }

  // ============================================================================
  // CẤU HÌNH LOCAL NOTIFICATIONS
  // ============================================================================
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Tạo notification channel cho Android
    const channel = AndroidNotificationChannel(
      'viewly_channel',
      'Viewly Notifications',
      description: 'Thông báo từ Viewly',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ============================================================================
  // REQUEST PERMISSION
  // ============================================================================
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User declined notification permission');
    }
  }

  // ============================================================================
  // SETUP MESSAGE HANDLERS
  // ============================================================================
  void _setupMessageHandlers() {
    // Xử lý foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Xử lý khi tap notification (app ở background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    // Xử lý khi app mở từ terminated state
    _checkInitialMessage();
  }

  // ============================================================================
  // XỬ LÝ FOREGROUND MESSAGE
  // ============================================================================
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Hiển thị notification local
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'viewly_channel',
          'Viewly Notifications',
          channelDescription: 'Thông báo từ Viewly',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  // ============================================================================
  // XỬ LÝ KHI TAP NOTIFICATION
  // ============================================================================
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    final data = _decodePayload(response.payload!);
    _navigateToScreen(data);
  }

  Future<void> _handleBackgroundTap(RemoteMessage message) async {
    _navigateToScreen(message.data);
  }

  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _navigateToScreen(message.data);
    }
  }

  // ============================================================================
  // NAVIGATE ĐẾN SCREEN TƯƠNG ỨNG
  // ============================================================================
  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'];
    final postId = data['postId'];
    final actorId = data['actorId'];

    print('🔗 Navigate to: $type, postId: $postId, actorId: $actorId');

    // TODO: Implement navigation logic tương tự NotificationsScreen
    // Ví dụ:
    // if (type == 'like' || type == 'comment') {
    //   navigatorKey.currentState?.push(...);
    // }
  }

  // ============================================================================
  // LƯU FCM TOKEN
  // ============================================================================
  Future<void> saveToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('❌ Could not get FCM token');
        return;
      }

      print('💾 Saving FCM token: ${token.substring(0, 20)}...');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      print('✅ FCM token saved');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // ============================================================================
  // TẠO NOTIFICATION TRONG FIRESTORE + GỬI PUSH
  // ============================================================================

  /// Gửi notification khi có like
  static Future<void> sendLikeNotification({
    required String postId,
    required String postOwnerId,
    required String actorId,
    required String actorUsername,
    String? postImageUrl,
  }) async {
    if (postOwnerId == actorId) return; // Không tự gửi cho chính mình

    try {
      // 1. Tạo notification trong Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'like',
        'recipientId': postOwnerId,
        'actorId': actorId,
        'actorUsername': actorUsername,
        'postId': postId,
        'postImageUrl': postImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // 2. Gửi push notification
      await _sendPushToUser(
        userId: postOwnerId,
        title: 'Lượt thích mới',
        body: '$actorUsername đã thích bài viết của bạn',
        data: {
          'type': 'like',
          'postId': postId,
          'actorId': actorId,
        },
      );

      print('✅ Like notification sent');
    } catch (e) {
      print('❌ Error sending like notification: $e');
    }
  }

  /// Gửi notification khi có comment
  static Future<void> sendCommentNotification({
    required String postId,
    required String postOwnerId,
    required String actorId,
    required String actorUsername,
    String? postImageUrl,
  }) async {
    if (postOwnerId == actorId) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'comment',
        'recipientId': postOwnerId,
        'actorId': actorId,
        'actorUsername': actorUsername,
        'postId': postId,
        'postImageUrl': postImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _sendPushToUser(
        userId: postOwnerId,
        title: 'Bình luận mới',
        body: '$actorUsername đã bình luận về bài viết của bạn',
        data: {
          'type': 'comment',
          'postId': postId,
          'actorId': actorId,
        },
      );

      print('✅ Comment notification sent');
    } catch (e) {
      print('❌ Error sending comment notification: $e');
    }
  }

  /// Gửi notification khi có follow
  static Future<void> sendFollowNotification({
    required String followedUserId,
    required String actorId,
    required String actorUsername,
  }) async {
    if (followedUserId == actorId) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'follow',
        'recipientId': followedUserId,
        'actorId': actorId,
        'actorUsername': actorUsername,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _sendPushToUser(
        userId: followedUserId,
        title: 'Người theo dõi mới',
        body: '$actorUsername đã bắt đầu theo dõi bạn',
        data: {
          'type': 'follow',
          'actorId': actorId,
        },
      );

      print('✅ Follow notification sent');
    } catch (e) {
      print('❌ Error sending follow notification: $e');
    }
  }

  // ============================================================================
  // GỬI PUSH NOTIFICATION QUA FCM (CẦN CLOUD FUNCTION)
  // ============================================================================
  static Future<void> _sendPushToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // Lấy FCM tokens của user
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) return;

    final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);
    if (tokens.isEmpty) return;

    // Lưu thông tin push vào collection để Cloud Function xử lý
    await FirebaseFirestore.instance.collection('pushQueue').add({
      'tokens': tokens,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // HELPER FUNCTIONS
  // ============================================================================
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (var pair in payload.split('&')) {
      final kv = pair.split('=');
      if (kv.length == 2) map[kv[0]] = kv[1];
    }
    return map;
  }
}