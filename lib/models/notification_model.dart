enum NotificationType {
  appointmentConfirmed,
  appointmentReminder,
  queueUpdate,
  checkedIn,
  appointmentRescheduled,
  appointmentCancelled,
  consultationCompleted,
  doctorAvailable,
  paymentSuccess,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return 'Appointment Confirmed';
      case NotificationType.appointmentReminder:
        return 'Appointment Reminder';
      case NotificationType.queueUpdate:
        return 'Queue Update';
      case NotificationType.checkedIn:
        return 'Checked In';
      case NotificationType.appointmentRescheduled:
        return 'Appointment Rescheduled';
      case NotificationType.appointmentCancelled:
        return 'Appointment Cancelled';
      case NotificationType.consultationCompleted:
        return 'Consultation Completed';
      case NotificationType.doctorAvailable:
        return 'Doctor Available';
      case NotificationType.paymentSuccess:
        return 'Payment Successful';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.appointmentConfirmed:
        return '✅';
      case NotificationType.appointmentReminder:
        return '🔔';
      case NotificationType.queueUpdate:
        return '📋';
      case NotificationType.checkedIn:
        return '✔️';
      case NotificationType.appointmentRescheduled:
        return '📅';
      case NotificationType.appointmentCancelled:
        return '❌';
      case NotificationType.consultationCompleted:
        return '🏥';
      case NotificationType.doctorAvailable:
        return '👨‍⚕️';
      case NotificationType.paymentSuccess:
        return '💳';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? appointmentId;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.appointmentId,
    this.metadata,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.appointmentReminder,
      ),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      appointmentId: map['appointmentId'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'appointmentId': appointmentId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? appointmentId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      appointmentId: appointmentId ?? this.appointmentId,
      metadata: metadata ?? this.metadata,
    );
  }
}
