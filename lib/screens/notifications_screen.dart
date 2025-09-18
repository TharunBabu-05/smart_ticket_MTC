import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final loadedNotifications = await NotificationService().getNotifications();
      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Add some demo notifications for now
      _addDemoNotifications();
    }
  }

  void _addDemoNotifications() {
    setState(() {
      notifications = [
        NotificationModel(
          id: '1',
          title: 'Welcome to Smart Ticket MTC',
          message: 'Thank you for downloading our app! Book your bus tickets with ease.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          type: NotificationType.welcome,
        ),
        NotificationModel(
          id: '2',
          title: 'Payment Successful',
          message: 'Your ticket booking payment has been processed successfully.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          type: NotificationType.payment,
        ),
        NotificationModel(
          id: '3',
          title: 'Journey Reminder',
          message: 'Don\'t forget your upcoming journey from Central to Airport.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          isRead: false,
          type: NotificationType.reminder,
        ),
        NotificationModel(
          id: '4',
          title: 'New Routes Available',
          message: 'We\'ve added new bus routes in Chennai. Check them out!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          type: NotificationType.update,
        ),
      ];
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
      }
    });
    NotificationService().markAsRead(notificationId);
  }

  void _clearAll() {
    setState(() {
      notifications.clear();
    });
    NotificationService().clearAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: notifications.isNotEmpty
            ? [
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : notifications.isEmpty
              ? _buildEmptyState(context)
              : _buildNotificationsList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 60,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! No new notifications at the moment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, notification);
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? colorScheme.surface 
            : colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? colorScheme.outline.withOpacity(0.2)
              : colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: notification.isRead 
                                  ? FontWeight.w500 
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return Icons.waving_hand;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.update:
        return Icons.system_update;
      case NotificationType.general:
        return Icons.info_outline;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.warning:
        return Icons.warning;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.welcome:
        return Colors.green;
      case NotificationType.payment:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.update:
        return Colors.purple;
      case NotificationType.general:
        return colorScheme.primary;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue.shade300;
      case NotificationType.warning:
        return Colors.orange.shade600;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
