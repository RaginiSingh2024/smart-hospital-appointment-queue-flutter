import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  FirestoreNotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    print('[FIRESTORE NOTIFICATION] Getting notifications for user: $userId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final notifications = snapshot.docs.map((doc) => _notificationFromFirestore(doc)).toList();
      print('[FIRESTORE NOTIFICATION] Retrieved ${notifications.length} notifications');
      return notifications;
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error getting notifications: ${e.code} - ${e.message}');
      throw Exception('Failed to load notifications: ${e.message}');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    print('[FIRESTORE NOTIFICATION] Marking as read: $notificationId');
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE NOTIFICATION] Marked as read successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error marking as read: ${e.code} - ${e.message}');
      throw Exception('Failed to mark as read: ${e.message}');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    print('[FIRESTORE NOTIFICATION] Marking all as read for user: $userId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('[FIRESTORE NOTIFICATION] Marked all as read successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error marking all as read: ${e.code} - ${e.message}');
      throw Exception('Failed to mark all as read: ${e.message}');
    }
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    print('[FIRESTORE NOTIFICATION] Adding notification for user: ${notification.userId}');
    try {
      final notificationId = notification.id.isEmpty ? _uuid.v4() : notification.id;
      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'userId': notification.userId,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type.name,
        'isRead': notification.isRead,
        'createdAt': FieldValue.serverTimestamp(),
        'appointmentId': notification.appointmentId,
        'metadata': notification.metadata,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE NOTIFICATION] Notification added successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error adding notification: ${e.code} - ${e.message}');
      throw Exception('Failed to add notification: ${e.message}');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    print('[FIRESTORE NOTIFICATION] Deleting notification: $notificationId');
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('[FIRESTORE NOTIFICATION] Notification deleted successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error deleting notification: ${e.code} - ${e.message}');
      throw Exception('Failed to delete notification: ${e.message}');
    }
  }

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    print('[FIRESTORE NOTIFICATION] Watching notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _notificationFromFirestore(doc)).toList();
    });
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    print('[FIRESTORE NOTIFICATION] Getting unread count for user: $userId');
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      print('[FIRESTORE NOTIFICATION] Unread count: ${snapshot.docs.length}');
      return snapshot.docs.length;
    } on FirebaseException catch (e) {
      print('[FIRESTORE NOTIFICATION] Error getting unread count: ${e.code} - ${e.message}');
      throw Exception('Failed to get unread count: ${e.message}');
    }
  }

  // Helper to create and add a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? appointmentId,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = NotificationModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      appointmentId: appointmentId,
      metadata: metadata,
    );
    await addNotification(notification);
  }

  NotificationModel _notificationFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: _stringValue(data['userId']) ?? '',
      title: _stringValue(data['title']) ?? '',
      body: _stringValue(data['body']) ?? '',
      type: _parseNotificationType(data['type']),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _timestampValue(data['createdAt']) ?? DateTime.now(),
      appointmentId: _stringValue(data['appointmentId']),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  DateTime? _timestampValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  NotificationType _parseNotificationType(dynamic value) {
    final type = value?.toString().toLowerCase();
    switch (type) {
      case 'appointmentconfirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointmentreminder':
        return NotificationType.appointmentReminder;
      case 'queueupdate':
        return NotificationType.queueUpdate;
      case 'checkedin':
        return NotificationType.checkedIn;
      case 'appointmentrescheduled':
        return NotificationType.appointmentRescheduled;
      case 'appointmentcancelled':
        return NotificationType.appointmentCancelled;
      case 'consultationcompleted':
        return NotificationType.consultationCompleted;
      case 'doctoravailable':
        return NotificationType.doctorAvailable;
      case 'paymentsuccess':
        return NotificationType.paymentSuccess;
      default:
        return NotificationType.appointmentReminder;
    }
  }
}
