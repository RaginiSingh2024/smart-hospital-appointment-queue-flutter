import '../../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotificationsForUser(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> addNotification(NotificationModel notification);
  Future<void> deleteNotification(String notificationId);
  Stream<List<NotificationModel>> watchNotifications(String userId);
  Future<int> getUnreadCount(String userId);
}
