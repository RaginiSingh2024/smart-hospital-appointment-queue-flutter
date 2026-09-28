import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationActionsProvider).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
            child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Queue alerts and appointment updates will appear here.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (ctx, i) {
              final notif = notifications[i];
              return _buildNotificationCard(context, ref, notif);
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading notifications...'),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, NotificationModel notif) {
    IconData icon;
    Color color;

    switch (notif.type) {
      case NotificationType.queueUpdate:
        icon = Icons.campaign_rounded;
        color = AppColors.success;
        break;
      case NotificationType.appointmentReminder:
        icon = Icons.alarm_rounded;
        color = AppColors.primary;
        break;
      case NotificationType.appointmentConfirmed:
        icon = Icons.event_available_rounded;
        color = AppColors.secondary;
        break;
      case NotificationType.consultationCompleted:
        icon = Icons.medication_rounded;
        color = AppColors.accent;
        break;
      case NotificationType.checkedIn:
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.primary;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationActionsProvider).deleteNotification(notif.id);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(notificationActionsProvider).markAsRead(notif.id);
          if (notif.type == NotificationType.queueUpdate) {
            context.go('/patient/live-queue');
          } else if (notif.type == NotificationType.appointmentConfirmed || notif.type == NotificationType.appointmentReminder) {
            context.go('/patient/appointments');
          } else if (notif.type == NotificationType.consultationCompleted) {
            context.go('/patient/history');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : AppColors.primarySurface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, h:mm a').format(notif.createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
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
}
