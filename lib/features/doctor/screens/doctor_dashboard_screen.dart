import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  String _doctorStatus = 'ON DUTY'; // ON DUTY, ON BREAK, OFF DUTY
  final String _doctorId = 'doc_002'; // Dr. Priya Mehta

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
    final user = ref.watch(currentUserProvider);
    final queueAsync = ref.watch(doctorQueueStreamProvider(_doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor Portal', style: AppTextStyles.titleMedium),
            Text('OPD Room 204 • Dermatology', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Delay Broadcast',
            icon: const Icon(Icons.timer_outlined, color: AppColors.warning),
            onPressed: () => _showDelayDialog(context),
          ),
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
      body: queueAsync.when(
        data: (queue) {
          final currentPatient = queue.currentToken;
          final waitingPatients = queue.waitingTokens;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Doctor Status & Shift Toggle Bar
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
                            user?.name ?? 'Dr. Priya Mehta',
                            style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Head of Dermatology • Room 204',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _doctorStatus,
                      onSelected: (val) => setState(() => _doctorStatus = val),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'ON DUTY', child: Text('🟢 On Duty')),
                        const PopupMenuItem(value: 'ON BREAK', child: Text('🟡 On Break')),
                        const PopupMenuItem(value: 'OFF DUTY', child: Text('🔴 Off Duty')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: _doctorStatus == 'ON DUTY'
                                  ? AppColors.success
                                  : _doctorStatus == 'ON BREAK'
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _doctorStatus,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metric Counters Row
              Row(
                children: [
                  _statCard('In Queue', '${queue.waitingCount}', Icons.people_alt_rounded, AppColors.primary),
                  const SizedBox(width: 10),
                  _statCard('Completed', '${queue.completedCount}', Icons.check_circle_rounded, AppColors.success),
                  const SizedBox(width: 10),
                  _statCard('Total Today', '${queue.totalTodayCount}', Icons.assignment_rounded, AppColors.secondary),
                  const SizedBox(width: 10),
                  _statCard('Avg Time', '12m', Icons.timer_rounded, AppColors.accent),
                ],
              ),
              const SizedBox(height: 20),

              // Active Patient in Consultation Card
              Text('Current Consultation', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: currentPatient != null ? AppColors.primary : AppColors.border,
                    width: currentPatient != null ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: currentPatient != null
                    ? Column(
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
                                  'TOKEN ${currentPatient.tokenNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.record_voice_over_rounded, size: 14, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('IN ROOM', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(currentPatient.patientName, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Chief Complaint: ${currentPatient.notes ?? "Acne consultation & rash check"}',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                                  label: const Text('Prescribe & Complete', style: TextStyle(fontWeight: FontWeight.w700)),
                                  onPressed: () {
                                    context.go('/doctor/consultation/${currentPatient.appointmentId}');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                ),
                                onPressed: () async {
                                  await ref.read(queueRepositoryProvider).markComplete(_doctorId, currentPatient.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Consultation completed')),
                                    );
                                  }
                                },
                                child: const Text('Quick Complete'),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline_rounded, size: 40, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 12),
                          const Text('Consultation Room is Currently Empty', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${waitingPatients.length} patient(s) waiting in the OPD queue',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.campaign_rounded),
                            label: const Text('Call Next Patient Now', style: TextStyle(fontWeight: FontWeight.w800)),
                            onPressed: waitingPatients.isNotEmpty
                                ? () async {
                                    final repo = ref.read(queueRepositoryProvider);
                                    final today = DateTime.now();
                                    final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                    await repo.callNextPatient(_doctorId, date);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🔔 Next patient called into room!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Upcoming Queue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waiting Queue (${waitingPatients.length})', style: AppTextStyles.headlineSmall),
                  TextButton(
                    onPressed: () => context.go('/doctor/queue'),
                    child: const Text('Manage All Queue →', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (waitingPatients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('Queue is clear! No patients waiting.')),
                )
              else
                ...waitingPatients.take(4).map((patient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              patient.tokenNumber,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient.patientName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                'Scheduled: ${patient.estimatedConsultationTime ?? "OPD Slot"}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () async {
                            final repo = ref.read(queueRepositoryProvider);
                            final today = DateTime.now();
                                    final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                    await repo.callNextPatient(_doctorId, date);
                          },
                          child: const Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // Quick Actions Grid
              Text('Doctor Workspace', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  _actionTile(
                    'Full Queue Control',
                    Icons.format_list_numbered_rounded,
                    AppColors.primary,
                    () => context.go('/doctor/queue'),
                  ),
                  const SizedBox(width: 12),
                  _actionTile(
                    'My OPD Schedule',
                    Icons.calendar_month_rounded,
                    AppColors.secondary,
                    () => context.go('/doctor/schedule'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          );
        },
        loading: () => const Scaffold(body: LoadingWidget(message: 'Loading doctor dashboard...')),
        error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
