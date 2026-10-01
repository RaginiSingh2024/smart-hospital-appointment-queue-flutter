import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../models/appointment.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentAsync = ref.watch(appointmentByIdProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient/appointments');
            }
          },
        ),
      ),
      body: appointmentAsync.when(
        data: (appointment) {
          if (appointment == null) {
            return const ErrorWidget2(message: 'Appointment not found');
          }

          final doctorAsync = ref.watch(doctorByIdProvider(appointment.doctorId));
          final qrData = 'HOSPITAL_APPT:${appointment.id}|TOKEN:${appointment.tokenNumber}|DOC:${appointment.doctorId}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOKEN NUMBER',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment.tokenNumber,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estimated Time: ${appointment.timeSlot}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.status.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Timeline Flow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Journey Progress', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 16),
                    _timelineStep(
                      title: 'Appointment Booked',
                      subtitle: 'Confirmed on system',
                      isDone: true,
                      isCurrent: appointment.status == AppointmentStatus.confirmed,
                    ),
                    _timelineDivider(appointment.status != AppointmentStatus.confirmed),
                    _timelineStep(
                      title: 'Digital Check-In',
                      subtitle: appointment.checkedInAt != null
                          ? 'Checked-in at ${appointment.checkedInAt}'
                          : 'Pending kiosk / QR check-in',
                      isDone: appointment.status == AppointmentStatus.checkedIn ||
                          appointment.status == AppointmentStatus.inConsultation ||
                          appointment.status == AppointmentStatus.completed,
                      isCurrent: appointment.status == AppointmentStatus.checkedIn,
                    ),
                    _timelineDivider(appointment.status == AppointmentStatus.inConsultation || appointment.status == AppointmentStatus.completed),
                    _timelineStep(
                      title: 'Live Queue & Calling',
                      subtitle: 'Wait for token call on display',
                      isDone: appointment.status == AppointmentStatus.inConsultation || appointment.status == AppointmentStatus.completed,
                      isCurrent: appointment.status == AppointmentStatus.inConsultation,
                    ),
                    _timelineDivider(appointment.status == AppointmentStatus.completed),
                    _timelineStep(
                      title: 'Consultation Completed',
                      subtitle: 'Diagnosis and prescription generated',
                      isDone: appointment.status == AppointmentStatus.completed,
                      isCurrent: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Doctor Info Card
              doctorAsync.when(
                data: (doctor) => doctor != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            DoctorAvatar(doctor: doctor, size: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doctor.name, style: AppTextStyles.titleMedium),
                                  Text('${doctor.specialty} • ${doctor.departmentName}',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Room: ${doctor.roomNumber ?? 'Room 204'}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                              onPressed: () => context.go('/patient/doctor/${doctor.id}'),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Visit Reason & Notes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason for Visit', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 6),
                    Text(appointment.reason, style: AppTextStyles.bodyMedium),
                    if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Patient Notes', style: AppTextStyles.titleSmall),
                      const SizedBox(height: 4),
                      Text(appointment.notes!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Ticket Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Center(
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 160.0,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Present QR code at hospital kiosk for self check-in',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (appointment.canCheckIn) ...[
                AppButton(
                  label: 'Proceed to Digital Check-in',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () => context.go('/patient/qr-checkin/${appointment.id}'),
                ),
                const SizedBox(height: 12),
              ],

              if (appointment.status == AppointmentStatus.checkedIn || appointment.status == AppointmentStatus.inConsultation) ...[
                AppButton(
                  label: 'Track Live Queue Status',
                  icon: Icons.speed_rounded,
                  onPressed: () => context.go('/patient/live-queue'),
                ),
                const SizedBox(height: 12),
              ],

              if (appointment.canCancel) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Appointment?'),
                        content: const Text('Are you sure you want to cancel this booking?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final patient = ref.read(currentPatientProvider);
                      if (patient != null) {
                        await ref.read(bookingServiceProvider).cancelAppointment(appointment.id, patient.id);
                        if (context.mounted) {
                          context.pop();
                        }
                      }
                    }
                  },
                  child: const Text('Cancel This Appointment', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
              const SizedBox(height: 30),
            ],
          );
        },
        loading: () => const Scaffold(body: LoadingWidget()),
        error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : Icons.circle_rounded,
            size: 14,
            color: (isDone || isCurrent) ? Colors.white : AppColors.textLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: (isDone || isCurrent) ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineDivider(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      width: 2,
      height: 22,
      color: active ? AppColors.success : AppColors.border,
    );
  }
}
