import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// iOS-compatible Firebase Messaging Service
class iOSNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Initialize Firebase Messaging for iOS
  static Future<void> initialize() async {
    try {
      // Request permission (crucial for iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('iOS Notification Permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ iOS push notifications authorized');
        
        // Get FCM token for iOS
        String? token = await _firebaseMessaging.getToken();
        print('iOS FCM Token: $token');
        
        // Configure message handlers
        _setupMessageHandlers();
      } else {
        print('⚠️ iOS push notifications not authorized');
      }
    } catch (e) {
      print('❌ iOS notification setup error: $e');
    }
  }
  
  /// Setup message handlers for iOS
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 iOS Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 iOS Background message opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });
  }
  
  /// Show local notification on iOS
  static void _showLocalNotification(RemoteMessage message) {
    // Implementation for local notifications
    // Could use flutter_local_notifications for advanced features
    print('🔔 iOS Local notification: ${message.notification?.title}');
  }
  
  /// Handle notification tap navigation
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification data
    Map<String, dynamic> data = message.data;
    
    if (data.containsKey('screen')) {
      String screen = data['screen'];
      print('📍 iOS Navigation to: $screen');
      // Add navigation logic here
    }
  }
  
  /// Subscribe to iOS-specific topics
  static Future<void> subscribeToTopics() async {
    await _firebaseMessaging.subscribeToTopic('ios_users');
    await _firebaseMessaging.subscribeToTopic('smart_ticket_updates');
    print('✅ iOS subscribed to notification topics');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 iOS Background message: ${message.notification?.title}');
  // Handle background messages
}
