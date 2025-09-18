import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsKey = 'app_notifications';
  List<NotificationModel> _notifications = [];

  // Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    if (_notifications.isEmpty) {
      await _loadNotifications();
    }
    // Sort by timestamp, newest first
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.from(_notifications);
  }

  // Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification); // Add to beginning
    await _saveNotifications();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveNotifications();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
  }

  // Remove specific notification
  Future<void> removeNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
  }

  // Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Check if there are unread notifications
  bool hasUnreadNotifications() {
    return _notifications.any((n) => !n.isRead);
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      
      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        _notifications = decoded
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  // Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_notificationsKey, notificationsJson);
      print('Notifications saved successfully');
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Emergency notification methods for safety service
  Future<void> showEmergencyNotification() async {
    final notification = NotificationModel(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Emergency SOS Activated',
      message: 'Emergency alert has been sent to your contacts',
      type: NotificationType.emergency,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  Future<void> cancelEmergencyNotification() async {
    final notification = NotificationModel(
      id: 'emergency_cancel_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Emergency SOS Deactivated',
      message: 'Emergency alert has been cancelled',
      type: NotificationType.info,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  Future<void> showLocationSharingNotification() async {
    final notification = NotificationModel(
      id: 'location_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Location Sharing Active',
      message: 'Your location is being shared with emergency contacts',
      type: NotificationType.info,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  Future<void> cancelLocationSharingNotification() async {
    final notification = NotificationModel(
      id: 'location_cancel_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Location Sharing Stopped',
      message: 'Location sharing has been deactivated',
      type: NotificationType.info,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  Future<void> showWomenSafetyNotification(String message) async {
    final notification = NotificationModel(
      id: 'women_safety_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Women Safety Alert',
      message: message,
      type: NotificationType.warning,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  Future<void> sendEmergencyAlert(String contactName, String message) async {
    final notification = NotificationModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Emergency Alert Sent',
      message: 'Alert sent to $contactName: $message',
      type: NotificationType.emergency,
      timestamp: DateTime.now(),
      isRead: false,
    );
    await addNotification(notification);
  }

  // Create demo notifications for testing
  Future<void> createDemoNotifications() async {
    final demoNotifications = [
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Welcome to Smart Ticket MTC',
        message: 'Thank you for downloading our app! Book your bus tickets with ease.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        type: NotificationType.welcome,
      ),
      NotificationModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Payment Successful',
        message: 'Your ticket booking payment has been processed successfully.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: NotificationType.payment,
      ),
      NotificationModel(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Journey Reminder',
        message: 'Don\'t forget your upcoming journey from Central to Airport.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        type: NotificationType.reminder,
      ),
    ];

    for (final notification in demoNotifications) {
      await addNotification(notification);
    }
  }

  // Add payment notification
  Future<void> addPaymentNotification({
    required String paymentId,
    required String amount,
    required String route,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Payment Successful',
      message: 'Your payment of ₹$amount for $route has been processed. Payment ID: $paymentId',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.payment,
    );
    
    await addNotification(notification);
  }

  // Add journey reminder notification
  Future<void> addJourneyReminder({
    required String route,
    required DateTime journeyTime,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Journey Reminder',
      message: 'Your journey from $route is scheduled for ${_formatTime(journeyTime)}',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.reminder,
    );
    
    await addNotification(notification);
  }

  // Add general notification
  Future<void> addGeneralNotification({
    required String title,
    required String message,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.general,
    );
    
    await addNotification(notification);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}
