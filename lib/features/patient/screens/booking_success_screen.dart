import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/appointment.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/appointment_provider.dart';

class BookingSuccessScreen extends ConsumerWidget {
  final String appointmentId;

  const BookingSuccessScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentAsync = ref.watch(appointmentByIdProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/patient'),
          ),
        ],
      ),
      body: appointmentAsync.when(
        data: (appointment) {
          if (appointment == null) {
            return const ErrorWidget2(message: 'Appointment record not found');
          }

          final qrData = 'HOSPITAL_APPT:${appointment.id}|TOKEN:${appointment.tokenNumber}|DOC:${appointment.doctorId}|DATE:${appointment.appointmentDate}';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Celebration Icon
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Appointment Confirmed!',
                  style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'A confirmation SMS & notification have been sent',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // Digital Pass Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with Token
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OPD QUEUE TOKEN',
                                style: AppTextStyles.caption.copyWith(color: Colors.white70, letterSpacing: 1.1),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appointment.tokenNumber,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              appointment.status.displayName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Appointment Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(Icons.person_rounded, 'Doctor', appointment.doctorName),
                          const SizedBox(height: 12),
                          _detailRow(Icons.calendar_today_rounded, 'Date & Time', '${appointment.appointmentDate} at ${appointment.timeSlot}'),
                          const SizedBox(height: 12),
                          _detailRow(Icons.location_on_rounded, 'Room Number', appointment.roomNumber),
                          const SizedBox(height: 12),
                          _detailRow(Icons.medical_services_outlined, 'Department', appointment.departmentName),
                          const SizedBox(height: 12),
                          _detailRow(Icons.badge_outlined, 'Booking ID', appointment.id.toUpperCase()),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Divider(color: AppColors.divider, thickness: 1),
                          ),

                          // QR Code
                          Center(
                            child: Column(
                              children: [
                                QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 160.0,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.primary,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan this at Hospital Kiosk for Check-In',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              AppButton(
                label: 'Track Live Queue Status',
                icon: Icons.access_time_filled_rounded,
                onPressed: () => context.go('/patient/live-queue'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/patient/appointments'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View All My Appointments', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Scaffold(body: LoadingWidget()),
        error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
