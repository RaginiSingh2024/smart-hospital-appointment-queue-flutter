import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/queue.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/repository_providers.dart';

class AdminQueueScreen extends ConsumerStatefulWidget {
  const AdminQueueScreen({super.key});

  @override
  ConsumerState<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends ConsumerState<AdminQueueScreen> {
  String _selectedDeptId = 'dept_002'; // Dermatology default
  String _selectedDoctorId = 'doc_002'; // Dr. Priya Mehta
  bool _tvDisplayMode = false;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final queueAsync = ref.watch(doctorQueueStreamProvider(_selectedDoctorId));

    return Scaffold(
      backgroundColor: _tvDisplayMode ? const Color(0xFF0F172A) : AppColors.background,
      appBar: AppBar(
        title: Text(_tvDisplayMode ? 'Hospital OPD Waiting Lounge Display' : 'Hospital Queue Monitor'),
        backgroundColor: _tvDisplayMode ? const Color(0xFF1E293B) : null,
        foregroundColor: _tvDisplayMode ? Colors.white : null,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _tvDisplayMode ? Colors.white : null),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: _tvDisplayMode ? 'Exit TV Mode' : 'Toggle TV Display Mode',
            icon: Icon(_tvDisplayMode ? Icons.fullscreen_exit_rounded : Icons.tv_rounded),
            color: _tvDisplayMode ? AppColors.accent : null,
            onPressed: () => setState(() => _tvDisplayMode = !_tvDisplayMode),
          ),
          IconButton(
            tooltip: 'Synchronize All Queues',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              ref.invalidate(doctorQueueStreamProvider(_selectedDoctorId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All department queues synchronized')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Department Filter Chips
          if (!_tvDisplayMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: departmentsAsync.when(
                data: (depts) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: depts.map((d) {
                      final isSel = _selectedDeptId == d.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${d.icon} ${d.name}'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedDeptId = d.id;
                                if (d.id == 'dept_001') _selectedDoctorId = 'doc_001';
                                if (d.id == 'dept_002') _selectedDoctorId = 'doc_002';
                                if (d.id == 'dept_003') _selectedDoctorId = 'doc_003';
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const Divider(height: 1),
          ],

          // TV Screen Mode Banner
          if (_tvDisplayMode)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              color: const Color(0xFF1E293B),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.live_tv_rounded, color: AppColors.accent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'MAIN OPD HALL TOKEN ANNOUNCER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: AppColors.success, size: 10),
                      SizedBox(width: 6),
                      Text('AUDIO CHIME ENABLED', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

          // Main Queue Content
          Expanded(
            child: queueAsync.when(
              data: (queue) {
                final currentToken = queue.currentToken;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Big Display Board
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: _tvDisplayMode
                            ? const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)])
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NOW SERVING IN ROOM 204',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentToken?.tokenNumber ?? '---',
                                  style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currentToken != null ? 'Patient: ${currentToken.patientName}' : 'Waiting for next patient call',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  '${queue.waitingCount}',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const Text('Waiting', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin Quick Queue Overrides
                    if (!_tvDisplayMode) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Queue Sequence Table', style: AppTextStyles.headlineSmall),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.skip_next_rounded, size: 16),
                            label: const Text('Call Next Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final repo = ref.read(queueRepositoryProvider);
                              final today = DateTime.now();
                              final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                              await repo.callNextPatient(_selectedDoctorId, date);
                              ref.invalidate(doctorQueueStreamProvider(_selectedDoctorId));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Next token announced!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Queue Records
                    if (queue.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _tvDisplayMode ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'No tokens in queue for this department',
                            style: TextStyle(color: _tvDisplayMode ? Colors.white70 : AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...queue.items.map((item) {
                        final isNow = item.status == 'in_consultation' || item.status == 'called';
                        final isEmergency = item.isEmergency;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _tvDisplayMode ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEmergency
                                  ? AppColors.error
                                  : isNow
                                      ? AppColors.success
                                      : _tvDisplayMode
                                          ? const Color(0xFF334155)
                                          : AppColors.border,
                              width: isEmergency || isNow ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isNow
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : isEmergency
                                          ? AppColors.error.withValues(alpha: 0.2)
                                          : AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    item.tokenNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: isNow
                                          ? AppColors.success
                                          : isEmergency
                                              ? AppColors.error
                                              : AppColors.primary,
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
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _tvDisplayMode ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (isEmergency) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'EMERGENCY',
                                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Position #${item.queuePosition} • Est: ${item.estimatedConsultationTime ?? "Pending"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _tvDisplayMode ? Colors.white60 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isNow
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : item.status == QueueStatus.completed
                                          ? AppColors.info.withValues(alpha: 0.2)
                                          : AppColors.warning.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  item.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isNow
                                        ? AppColors.success
                                        : item.status == QueueStatus.completed
                                            ? AppColors.info
                                            : AppColors.warning,
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
          ),
        ],
      ),
    );
  }
}
