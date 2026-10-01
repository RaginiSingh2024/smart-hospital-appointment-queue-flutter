import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../mock/mock_data.dart';

class MockNotificationRepository implements NotificationRepository {
  final Map<String, List<NotificationModel>> _notifications = {};
  final Map<String, StreamController<List<NotificationModel>>> _controllers = {};
  final _uuid = const Uuid();

  void _initForUser(String userId) {
    _notifications[userId] ??= MockData.getNotificationsForUser(userId);
  }

  @override
  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initForUser(userId);
    return List.from(_notifications[userId]!)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final list in _notifications.values) {
      final idx = list.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initForUser(userId);
    _notifications[userId] = _notifications[userId]!
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _notifyChange(userId);
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    _initForUser(notification.userId);
    _notifications[notification.userId]!.insert(0, notification);
    _notifyChange(notification.userId);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final entry in _notifications.entries) {
      final initialLen = entry.value.length;
      entry.value.removeWhere((n) => n.id == notificationId);
      if (entry.value.length != initialLen) {
        _notifyChange(entry.key);
      }
    }
  }

  void _notifyChange(String userId) {
    final controller = _controllers[userId];
    if (controller != null && !controller.isClosed) {
      final sorted = List<NotificationModel>.from(_notifications[userId] ?? [])
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(sorted);
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    _initForUser(userId);
    _controllers[userId] ??= StreamController<List<NotificationModel>>.broadcast();
    return _controllers[userId]!.stream;
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    _initForUser(userId);
    return _notifications[userId]!.where((n) => !n.isRead).length;
  }

  // Helper to create and add a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? appointmentId,
  }) async {
    final notification = NotificationModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      appointmentId: appointmentId,
    );
    await addNotification(notification);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}
