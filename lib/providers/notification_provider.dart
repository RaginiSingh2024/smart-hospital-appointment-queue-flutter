import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(notificationRepositoryProvider).getNotificationsForUser(user.id);
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.watch(notificationRepositoryProvider).getUnreadCount(user.id);
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    await _ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _ref.read(notificationRepositoryProvider).deleteNotification(notificationId);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref);
});

final notificationActionsProvider = Provider<NotificationNotifier>((ref) {
  return ref.watch(notificationNotifierProvider.notifier);
});
