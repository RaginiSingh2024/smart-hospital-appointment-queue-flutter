import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/appointment_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/appointment.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';

class MyAppointmentsScreen extends ConsumerStatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  ConsumerState<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends ConsumerState<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQrDialog(BuildContext context, Appointment appt) {
    final qrData = 'HOSPITAL_APPT:${appt.id}|TOKEN:${appt.tokenNumber}|DOC:${appt.doctorId}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Column(
            children: [
              Text('Token ${appt.tokenNumber}', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w900)),
              Text(appt.doctorName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show this at the OPD reception or scan at kiosk',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?'),
        content: Text(
          'Are you sure you want to cancel your appointment with ${appt.doctorName} on ${appt.appointmentDate} at ${appt.timeSlot}?\n\nYour token will be released back to the hospital queue.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final patient = ref.read(currentPatientProvider);
              if (patient != null) {
                await ref.read(bookingServiceProvider).cancelAppointment(appt.id, patient.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment cancelled successfully'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              }
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        data: (allAppointments) {
          final upcoming = allAppointments.where((a) => a.isUpcoming).toList();
          final completed = allAppointments.where((a) => a.isCompleted).toList();
          final cancelled = allAppointments
              .where((a) => a.isCancelled || a.status == AppointmentStatus.noShow)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(upcoming, 'No upcoming appointments', true),
              _buildAppointmentList(completed, 'No completed appointments yet', false),
              _buildAppointmentList(cancelled, 'No cancelled appointments', false),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Loading appointments...'),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/patient/find-doctors'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Book New'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAppointmentList(
      List<Appointment> list, String emptyMessage, bool isUpcoming) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(emptyMessage, style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Schedule doctor appointments easily with real-time queue tokens.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              if (isUpcoming)
                ElevatedButton(
                  onPressed: () => context.go('/patient/find-doctors'),
                  child: const Text('Find Doctors'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final appt = list[i];
        return AppointmentCard(
          appointment: appt,
          onTap: () => context.go('/patient/appointment/${appt.id}'),
          onCheckIn: appt.canCheckIn
              ? () => context.go('/patient/qr-checkin/${appt.id}')
              : null,
          onCancel: appt.canCancel
              ? () => _showCancelDialog(context, appt)
              : null,
          onViewQr: () => _showQrDialog(context, appt),
          onTrackQueue: (appt.status == AppointmentStatus.checkedIn || appt.status == AppointmentStatus.inConsultation)
              ? () => context.go('/patient/live-queue')
              : null,
        );
      },
    );
  }
}
