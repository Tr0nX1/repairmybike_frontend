
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'api_config.dart';

import 'router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
  } catch (e) {
    debugPrint("Failed to handle background message (Firebase uninitialized): $e");
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;
    
    // 2. Request Permissions (iOS/Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Setup Local Notifications for Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) {
           _handleNotificationTap(RemoteMessage(data: {'payload': details.payload}));
        });

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 5. Handle Tap when App is in Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 6. Handle Tap when App is Terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> registerTokenWithBackend(String? sessionToken) async {
    if (sessionToken == null) return;
    
    String? fcmToken = await getToken();
    if (fcmToken == null) return;

    try {
      final dio = Dio(BaseOptions(
        baseUrl: backendBase,
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
      ));

      await dio.post('/api/auth/fcm-token/', data: {
        'token': fcmToken,
      });
      debugPrint('FCM Token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['booking_id'] ?? message.data['type'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final bookingId = data['booking_id'] as String?;

    if (type == 'new_booking') {
       router.push('/staff'); // Manager/Staff will see in list
    } else if (type == 'booking_status' || type == 'payment' || type == 'parts_approval') {
       if (bookingId != null) {
         router.push('/bookings/$bookingId');
       } else {
         router.push('/bookings');
       }
    } else if (type == 'cash_variance') {
       router.push('/staff/reconciliation');
    } else if (type == 'promotion') {
       router.push('/home');
    }
  }
}


// Export the background handler so main.dart can see it
Future<void> fcmBackgroundHandler(RemoteMessage message) => _firebaseMessagingBackgroundHandler(message);
