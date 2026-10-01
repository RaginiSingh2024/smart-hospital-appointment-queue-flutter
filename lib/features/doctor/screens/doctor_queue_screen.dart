import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/queue.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorQueueScreen extends ConsumerStatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  ConsumerState<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends ConsumerState<DoctorQueueScreen> {
  final String _doctorId = 'doc_002'; // Dr. Priya Mehta
  String _selectedFilter = 'all'; // all, waiting, completed, noshow

  void _showAddEmergencyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Add Emergency Walk-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Patient Name', hintText: 'e.g. Ramesh Kumar'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Emergency Reason', hintText: 'Severe acute reaction'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final repo = ref.read(queueRepositoryProvider);
              final today = DateTime.now();
              final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              await repo.addToQueue(
                doctorId: _doctorId,
                date: date,
                queueModel: QueueModel(
                  id: 'emg_${DateTime.now().millisecondsSinceEpoch}',
                  doctorId: _doctorId,
                  patientId: 'patient_walkin',
                  appointmentId: 'appt_walkin',
                  patientName: nameController.text.trim(),
                  tokenNumber: 'EMG-${DateTime.now().millisecond % 100}',
                  tokenSequence: 0,
                  status: QueueStatus.waiting,
                  patientsAhead: 0,
                  estimatedWaitMinutes: 0,
                  date: date,
                  isEmergency: true,
                  checkedInAt: DateTime.now(),
                  notes: reasonController.text.trim(),
                ),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 Emergency patient added to top of queue!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Insert as Priority', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(doctorQueueStreamProvider(_doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OPD Queue Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/doctor'),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Emergency Walk-in',
            icon: const Icon(Icons.bolt_rounded, color: AppColors.error),
            onPressed: () => _showAddEmergencyDialog(context),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (queue) {
          final items = queue.items;

          final filteredItems = items.where((item) {
            if (_selectedFilter == 'waiting') {
              return item.status == QueueStatus.waiting ||
                  item.status == QueueStatus.inProgress ||
                  item.status == QueueStatus.called;
            }
            if (_selectedFilter == 'completed') return item.status == QueueStatus.completed;
            if (_selectedFilter == 'noshow') return item.status == QueueStatus.noShow;
            return true;
          }).toList();

          return Column(
            children: [
              // Top Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.campaign_rounded),
                        label: const Text('Call Next Patient', style: TextStyle(fontWeight: FontWeight.w800)),
                        onPressed: queue.waitingCount > 0
                            ? () async {
                                final repo = ref.read(queueRepositoryProvider);
                                final today = DateTime.now();
                                final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                await repo.callNextPatient(_doctorId, date);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Next patient called! Display & notifications triggered.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 18),
                      label: const Text('Priority Walk-in', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () => _showAddEmergencyDialog(context),
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    _filterChip('all', 'All (${items.length})'),
                    const SizedBox(width: 8),
                    _filterChip('waiting', 'Waiting (${queue.waitingCount})'),
                    const SizedBox(width: 8),
                    _filterChip('completed', 'Done (${queue.completedCount})'),
                    const SizedBox(width: 8),
                    _filterChip('noshow', 'No-Show (${queue.noShowCount})'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // List of Queue Items
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('No queue records for this filter.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        itemBuilder: (ctx, i) {
                          final item = filteredItems[i];
                          return _buildQueueCard(item);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Loading queue items...'),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(QueueModel item) {
    final isCurrent = item.status == QueueStatus.inProgress || item.status == QueueStatus.called;
    final isCompleted = item.status == QueueStatus.completed;
    final isNoShow = item.status == QueueStatus.noShow;
    final isEmergency = item.isEmergency;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency
              ? AppColors.error
              : isCurrent
                  ? AppColors.primary
                  : AppColors.border,
          width: isEmergency || isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? AppColors.error
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tokenNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: (isEmergency || isCurrent) ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isEmergency) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'EMERGENCY',
                    style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.patientName,
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.12)
                      : isNoShow
                          ? AppColors.error.withValues(alpha: 0.12)
                          : isCurrent
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? AppColors.success
                        : isNoShow
                            ? AppColors.error
                            : isCurrent
                                ? AppColors.primary
                                : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check-in: ${item.checkedInAt != null ? "${item.checkedInAt!.hour}:${item.checkedInAt!.minute.toString().padLeft(2, '0')}" : "Pending"} • Pos: #${item.queuePosition ?? item.tokenSequence}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Complaint: ${item.notes}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),

          // Action Buttons
          if (!isCompleted && !isNoShow)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.status == QueueStatus.waiting) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () async {
                      final repo = ref.read(queueRepositoryProvider);
                      await repo.skipToken(_doctorId, item.id);
                    },
                    child: const Text('No-Show', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () async {
                      final repo = ref.read(queueRepositoryProvider);
                      final today = DateTime.now();
                      final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                      await repo.callNextPatient(_doctorId, date);
                    },
                    child: const Text('Call Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
                if (isCurrent) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 14),
                    label: const Text('Write Rx / Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      context.go('/doctor/consultation/${item.appointmentId}');
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
