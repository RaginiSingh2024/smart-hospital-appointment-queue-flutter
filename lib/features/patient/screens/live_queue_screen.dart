import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../models/queue.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/repository_providers.dart';

class LiveQueueScreen extends ConsumerStatefulWidget {
  final String? initialDoctorId;

  const LiveQueueScreen({super.key, this.initialDoctorId});

  @override
  ConsumerState<LiveQueueScreen> createState() => _LiveQueueScreenState();
}

class _LiveQueueScreenState extends ConsumerState<LiveQueueScreen> {
  String? _selectedDoctorId;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.initialDoctorId ?? 'doc_001';
  }

  void _triggerBuzzerSimulation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.volume_up_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('🔔 Chime: "Token A-001, please proceed to Room 204"')),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsProvider);
    final patient = ref.watch(currentPatientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live OPD Queue Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
        actions: [
          IconButton(
            tooltip: 'Simulate Token Call Announcement',
            icon: const Icon(Icons.campaign_rounded),
            onPressed: _triggerBuzzerSimulation,
          ),
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (_selectedDoctorId != null) {
                ref.invalidate(doctorQueueStreamProvider(_selectedDoctorId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Queue synchronized with hospital server'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: doctorsAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return const ErrorWidget2(message: 'No active doctor queues found');
          }

          final currentDoctor = doctors.firstWhere(
            (d) => d.id == _selectedDoctorId,
            orElse: () => doctors.first,
          );

          final queueAsync = ref.watch(doctorQueueStreamProvider(currentDoctor.id));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Doctor Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text('Doctor:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentDoctor.id,
                          isExpanded: true,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          items: doctors.map((d) {
                            return DropdownMenuItem<String>(
                              value: d.id,
                              child: Text('${d.name} (${d.specialty})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              setState(() => _selectedDoctorId = newId);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Doctor Room & Status Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    DoctorAvatar(doctor: currentDoctor, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentDoctor.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Room ${currentDoctor.roomNumber} • ${currentDoctor.departmentName}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: AppColors.success, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'ON DUTY',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Queue Stream Content
              queueAsync.when(
                data: (queue) {
                  final activeToken = queue.currentToken?.tokenNumber ?? '--';
                  final waitingCount = queue.waitingCount;
                  final avgTime = queue.avgWaitTimeMinutes;

                  // Find patient's token if exists in this queue
                  QueueModel? patientQueueItem;
                  if (patient != null) {
                    try {
                      patientQueueItem = queue.items.firstWhere(
                        (item) => item.patientId == patient.id,
                      );
                    } catch (_) {
                      patientQueueItem = null;
                    }
                  }

                  final isPatientCalled = patientQueueItem != null &&
                      (patientQueueItem.status == QueueStatus.inProgress ||
                          patientQueueItem.status == QueueStatus.called);

                  final yourToken = patientQueueItem?.tokenNumber ?? 'A-008';
                  final tokensAhead = patientQueueItem != null
                      ? queue.items
                          .where((item) =>
                              item.status == QueueStatus.waiting &&
                              item.tokenNumber.compareTo(patientQueueItem!.tokenNumber) < 0)
                          .length
                      : 4;

                  final estimatedWait = tokensAhead * 10;

                  return Column(
                    children: [
                      // Called Alert Banner
                      if (isPatientCalled)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 36),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'IT\'S YOUR TURN NOW!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Please proceed to Room ${currentDoctor.roomNumber} immediately.',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Now Serving & Your Token Grid
                      Row(
                        children: [
                          // Now Serving
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'NOW SERVING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    activeToken,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Room ${currentDoctor.roomNumber}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Your Token
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'YOUR TOKEN',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    yourToken,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accent,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$tokensAhead patients ahead',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Wait Time & Queue Status Metric Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Est. Wait Time', style: AppTextStyles.labelMedium),
                                  ],
                                ),
                                Text(
                                  '~$estimatedWait Mins',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: tokensAhead > 0 ? (1.0 - (tokensAhead / (tokensAhead + 5))).clamp(0.1, 0.95) : 1.0,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Waiting: $waitingCount',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                                Text(
                                  'Avg Consultation: ${avgTime > 0 ? avgTime : 10}m',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Interactive Examiner Demo Control Bar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.science_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Interactive Simulation Controls',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: () async {
                                      final repo = ref.read(queueRepositoryProvider);
                                      final today = DateTime.now();
                                    final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                    await repo.callNextPatient(currentDoctor.id, date);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('⚡ Next patient called! Queue advanced.'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.skip_next_rounded, size: 16),
                                    label: const Text('Call Next Token', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    onPressed: _triggerBuzzerSimulation,
                                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                                    label: const Text('Test Announcement', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Live Token Sequence List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Queue Tokens', style: AppTextStyles.headlineSmall),
                          Text(
                            'Updated Live',
                            style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (queue.items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('No active patients in this queue currently.'),
                          ),
                        )
                      else
                        ...queue.items.map((item) {
                          final isCurrent = item.status == QueueStatus.inProgress || item.status == QueueStatus.called;
                          final isMine = patient != null && item.patientId == patient.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? AppColors.primarySurface
                                  : isCurrent
                                      ? Colors.white
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMine
                                    ? AppColors.primary
                                    : isCurrent
                                        ? AppColors.success
                                        : AppColors.border,
                                width: isMine || isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.tokenNumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: isCurrent ? AppColors.success : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.patientName,
                                            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          if (isMine) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'YOU',
                                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Estimated: ${item.estimatedConsultationTime ?? "Pending"}',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : item.status == QueueStatus.waiting
                                            ? AppColors.warning.withValues(alpha: 0.15)
                                            : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent
                                          ? AppColors.success
                                          : item.status == QueueStatus.waiting
                                              ? AppColors.warning
                                              : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 40),
                    ],
                  );
                },
                loading: () => const LoadingWidget(message: 'Connecting to hospital queue server...'),
                error: (e, _) => ErrorWidget2(message: e.toString()),
              ),
            ],
          );
        },
        loading: () => const Scaffold(body: LoadingWidget()),
        error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
      ),
    );
  }
}
