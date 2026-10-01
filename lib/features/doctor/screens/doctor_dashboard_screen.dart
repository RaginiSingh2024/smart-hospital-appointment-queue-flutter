import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  String _doctorStatus = 'ON DUTY'; // ON DUTY, ON BREAK, OFF DUTY
  String? _doctorId;

  void _showDelayDialog(BuildContext context) {
    int delayMinutes = 15;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Broadcast Queue Delay'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Running behind schedule? Notify all waiting patients and automatically adjust estimated wait times.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [10, 15, 20, 30].map((m) {
                  final isSel = delayMinutes == m;
                  return ChoiceChip(
                    label: Text('+$m min'),
                    selected: isSel,
                    selectedColor: AppColors.warning.withValues(alpha: 0.2),
                    onSelected: (_) => setDialogState(() => delayMinutes = m),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () async {
                Navigator.pop(ctx);
                // Simulate delay broadcast — in production this would update estimated wait times
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delay of $delayMinutes mins broadcast to all waiting patients!'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              child: const Text('Broadcast Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[DOCTOR] DASHBOARD LOAD START');
    final user = ref.watch(currentUserProvider);
    print('[DOCTOR] AUTH UID: ${user?.id}');
    final doctorAsync = ref.watch(doctorByUserIdForQueueProvider);
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    // If user is null, show loading
    if (user == null) {
      print('[DOCTOR] User is null, showing loading');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('[DOCTOR] User found: ${user.name} (${user.id})');
    print('[DOCTOR] Doctor lookup state: loading=${doctorAsync.isLoading}, hasValue=${doctorAsync.hasValue}, hasError=${doctorAsync.hasError}');

    // Get doctor ID from the doctor lookup
    final doctorId = doctorAsync.value?.id;
    if (doctorId != null && _doctorId != doctorId) {
      _doctorId = doctorId;
      print('[DOCTOR] Doctor ID set to: $_doctorId');
    }

    // If doctor lookup has error, show error
    if (doctorAsync.hasError) {
      print('[DOCTOR] PROFILE FETCH ERROR: ${doctorAsync.error}');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Doctor Portal'),
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Error loading doctor profile'),
              const SizedBox(height: 8),
              Text(
                '${doctorAsync.error}',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // If doctor not found, show error
    if (doctorId == null && !doctorAsync.isLoading) {
      print('[DOCTOR] PROFILE FETCH ERROR: Doctor not found for user ID: ${user.id}');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Doctor Portal'),
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Doctor profile not found'),
              const SizedBox(height: 8),
              Text(
                'User ID: ${user.id}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // If doctor is loading, show loading
    if (doctorAsync.isLoading) {
      print('[DOCTOR] PROFILE FETCH START: Loading doctor profile');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('[DOCTOR] PROFILE FETCH SUCCESS: Doctor found - ${doctorAsync.value?.name} (ID: $doctorId)');

    // Watch appointments from Firestore
    print('[DOCTOR] Watching appointments for doctor: $_doctorId');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor Portal', style: AppTextStyles.titleMedium),
            Text('OPD Room 204 • ${doctorAsync.value?.specialty ?? "Medicine"}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: appointmentsAsync.when(
        loading: () {
          print('[DOCTOR] APPOINTMENTS FETCH START: Loading appointments');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('[DOCTOR] APPOINTMENTS FETCH ERROR: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Error loading appointments'),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/doctor'),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (appointments) {
          print('[DOCTOR] APPOINTMENTS FETCH SUCCESS: ${appointments.length} appointments loaded');
          if (appointments.isEmpty) {
            print('[DOCTOR] No appointments, showing empty state');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('No patients scheduled', style: AppTextStyles.titleMedium),
                  SizedBox(height: 8),
                  Text('Appointments booked by patients will appear here', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Doctor Status Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Doctor',
                            style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${doctorAsync.value?.specialty ?? "Medicine"} • ${appointments.length} appointments today',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Appointments Header
              Text('Today\'s Appointments', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 10),

              // Appointments List
              ...appointments.map((appt) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'TOKEN ${appt.tokenNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                          ),
                        ),
                        Text(
                          appt.timeSlot,
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(appt.patientName, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${appt.status.name.toUpperCase()}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              context.go('/doctor/consultation/${appt.id}');
                            },
                            child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
