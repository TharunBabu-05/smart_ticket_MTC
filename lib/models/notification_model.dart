class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.name,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, timestamp: $timestamp, isRead: $isRead, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        message.hashCode ^
        timestamp.hashCode ^
        isRead.hashCode ^
        type.hashCode;
  }
}

enum NotificationType {
  welcome,
  payment,
  reminder,
  update,
  general,
  emergency,
  info,
  warning,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.welcome:
        return 'Welcome';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.update:
        return 'Update';
      case NotificationType.general:
        return 'General';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.info:
        return 'Information';
      case NotificationType.warning:
        return 'Warning';
    }
  }

  String get description {
    switch (this) {
      case NotificationType.welcome:
        return 'Welcome messages and app introduction';
      case NotificationType.payment:
        return 'Payment confirmations and receipts';
      case NotificationType.reminder:
        return 'Journey reminders and alerts';
      case NotificationType.update:
        return 'App updates and new features';
      case NotificationType.general:
        return 'General app notifications';
      case NotificationType.emergency:
        return 'Emergency and safety alerts';
      case NotificationType.info:
        return 'Informational messages';
      case NotificationType.warning:
        return 'Warning and safety messages';
    }
  }
}
