import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';

class DigitalCheckinScreen extends ConsumerStatefulWidget {
  final String? appointmentId;

  const DigitalCheckinScreen({super.key, this.appointmentId});

  @override
  ConsumerState<DigitalCheckinScreen> createState() => _DigitalCheckinScreenState();
}

class _DigitalCheckinScreenState extends ConsumerState<DigitalCheckinScreen> {
  final _codeController = TextEditingController();
  bool _isProcessing = false;
  bool _geoFenceVerified = true;

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _codeController.text = widget.appointmentId!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn(String apptId) async {
    setState(() => _isProcessing = true);
    try {
      final patient = ref.read(currentPatientProvider);
      if (patient == null) {
        throw Exception('Patient not logged in');
      }

      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.checkIn(apptId, patient.id);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
                ),
                const SizedBox(height: 16),
                Text(
                  'Check-In Successful!',
                  style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your token is now live in the doctor\'s consultation queue. Please proceed to the waiting lounge.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Go to Live Queue Tracker',
                  icon: Icons.speed_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/patient/live-queue');
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Self Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Geofence Hospital Verification Status Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _geoFenceVerified
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _geoFenceVerified
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _geoFenceVerified ? Icons.fmd_good_rounded : Icons.location_searching_rounded,
                  color: _geoFenceVerified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _geoFenceVerified
                            ? 'Hospital Geofence Verified'
                            : 'Hospital Location Pending',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _geoFenceVerified ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        'Location: OPD Block Ground Floor • Main Campus',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kiosk QR Scanner Visual Frame
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated Scanner View Box
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scanner lines & reticle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        child: Text(
                          'Point at Kiosk QR',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Camera Scanner Active',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Simulation Button for Testing/Demo
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, color: AppColors.primary),
                  label: const Text('Simulate Scan Hospital Kiosk QR', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    // Pick the first eligible appointment or use default
                    appointmentsAsync.whenData((list) {
                      final appt = list.firstWhere(
                        (a) => a.canCheckIn,
                        orElse: () => list.first,
                      );
                      _performCheckIn(appt.id);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Or Manual Booking Code Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Or Enter Booking / Appointment ID', style: AppTextStyles.titleSmall),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. APPT_001',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Verify & Check-In',
                  isLoading: _isProcessing,
                  onPressed: () {
                    final id = _codeController.text.trim().toLowerCase();
                    if (id.isNotEmpty) {
                      _performCheckIn(id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an appointment ID')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Eligible Appointments to Check-In Today
          Text('Your Appointments Ready for Check-In', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          appointmentsAsync.when(
            data: (list) {
              final checkinList = list.where((a) => a.canCheckIn).toList();

              if (checkinList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No pending appointments scheduled for check-in today.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: checkinList.map((appt) {
                  final dateFormatted = DateFormat('EEE, d MMM').format(appt.appointmentDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              appt.tokenNumber,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.doctorName, style: AppTextStyles.titleSmall),
                              Text(
                                '$dateFormatted • ${appt.timeSlot}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => _performCheckIn(appt.id),
                          child: const Text('Check In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorWidget2(message: e.toString()),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
