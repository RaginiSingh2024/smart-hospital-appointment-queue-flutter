import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_card.dart';
import '../../../models/appointment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/doctor_provider.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final firstName = user?.name.split(' ').first ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientAppointmentsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar / Hero
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () => context.go('/patient/notifications'),
                    ),
                    unreadCount.when(
                      data: (count) => count > 0
                          ? Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded,
                      color: Colors.white),
                  onPressed: () => context.go('/patient/profile'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$greeting,',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          GestureDetector(
                            onTap: () => context.go('/patient/find-doctors'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded,
                                      color: AppColors.textLight, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Search doctors, specialties...',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    const SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    _QuickActionsGrid(),
                    const SizedBox(height: 24),

                    // Upcoming Appointment
                    const SectionHeader(title: 'Upcoming Appointment'),
                    const SizedBox(height: 12),
                    appointmentsAsync.when(
                      data: (appointments) {
                        final upcoming = appointments
                            .where((a) => a.isUpcoming)
                            .toList()
                          ..sort((a, b) =>
                              a.appointmentDate.compareTo(b.appointmentDate));

                        if (upcoming.isEmpty) {
                          return _NoUpcomingAppointment(
                            onBook: () => context.go('/patient/find-doctors'),
                          );
                        }
                        final next = upcoming.first;
                        return AppointmentCard(
                          appointment: next,
                          onTap: () => context.go('/patient/appointment/${next.id}'),
                          onQRCheckIn: next.status == AppointmentStatus.confirmed
                              ? () => context.go('/patient/qr-checkin/${next.id}')
                              : null,
                          onReschedule: () => context.go(
                              '/patient/reschedule/${next.id}'),
                          onCancel: () => _confirmCancel(context, ref, next),
                          onViewDetails: () => context
                              .go('/patient/appointment/${next.id}'),
                        );
                      },
                      loading: () => const LoadingWidget(message: 'Loading appointments...'),
                      error: (e, _) => ErrorWidget2(message: e.toString()),
                    ),
                    const SizedBox(height: 24),

                    // Specialties
                    const SectionHeader(
                      title: 'Browse by Specialty',
                      actionLabel: 'View All',
                      onAction: null,
                    ),
                    const SizedBox(height: 12),
                    _SpecialtiesGrid(),
                    const SizedBox(height: 24),

                    // Health Tips
                    _HealthTipsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(
      BuildContext context, WidgetRef ref, Appointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Cancel Appointment',
        message:
            'Are you sure you want to cancel your appointment with ${appointment.doctorName}?',
        confirmLabel: 'Cancel Appointment',
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          final patient = ref.read(currentPatientProvider);
          await ref
              .read(appointmentNotifierProvider.notifier)
              .cancelAppointment(appointment.id, patient?.id ?? '');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointment cancelled successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickAction(
          icon: Icons.search_rounded,
          label: 'Find\nDoctor',
          color: AppColors.primary,
          onTap: () => context.go('/patient/find-doctors')),
      _QuickAction(
          icon: Icons.calendar_today_rounded,
          label: 'My\nAppointments',
          color: AppColors.success,
          onTap: () => context.go('/patient/appointments')),
      _QuickAction(
          icon: Icons.queue_rounded,
          label: 'Live\nQueue',
          color: AppColors.accent,
          onTap: () => context.go('/patient/live-queue')),
      _QuickAction(
          icon: Icons.qr_code_scanner_rounded,
          label: 'QR\nCheck-in',
          color: AppColors.secondary,
          onTap: () => context.go('/patient/qr-checkin')),
      _QuickAction(
          icon: Icons.history_rounded,
          label: 'Consultation\nHistory',
          color: AppColors.warning,
          onTap: () => context.go('/patient/history')),
      _QuickAction(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          color: const Color(0xFFE91E63),
          onTap: () => context.go('/patient/notifications')),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: actions
          .map((a) => GestureDetector(
                onTap: a.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon, color: a.color, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _NoUpcomingAppointment extends StatelessWidget {
  final VoidCallback onBook;

  const _NoUpcomingAppointment({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text('No Upcoming Appointments', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Book an appointment with your preferred doctor',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onBook,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}

class _SpecialtiesGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      data: (departments) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: departments
            .map((dept) => GestureDetector(
                  onTap: () => context.go('/patient/find-doctors?dept=${dept.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dept.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          dept.name,
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
      loading: () => const LoadingWidget(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _HealthTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Tip of the Day',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Drink at least 8 glasses of water daily for optimal health and energy.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Learn more →',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 56),
        ],
      ),
    );
  }
}
