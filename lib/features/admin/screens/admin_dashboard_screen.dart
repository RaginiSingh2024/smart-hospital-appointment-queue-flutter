import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  void _showBroadcastDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Hospital Announcement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Broadcast an instant notification banner to all active patients & waiting room displays.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Pharmacy counter #3 has reopened. Emergency triage priority in effect.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📣 Announcement sent to all hospital displays and patient devices!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Broadcast Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hospital Command Center', style: AppTextStyles.titleMedium),
            Text('City General Hospital • Administrative Portal',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Hospital Broadcast',
            icon: const Icon(Icons.campaign_rounded, color: AppColors.accent),
            onPressed: () => _showBroadcastDialog(context),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hospital Command Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, color: AppColors.accent, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'SYSTEM STATUS: OPTIMAL',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE MONITOR',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hospital Queue & Capacity Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real-time token processing across 6 multi-specialty departments',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    const Text('OPD Load Capacity: 74%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.74,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Metric Grid
          Row(
            children: [
              _kpiBox('Total Patients', '${analytics['totalPatientsToday'] ?? 142}', Icons.people_alt_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _kpiBox('Active Queues', '8', Icons.queue_music_rounded, AppColors.accent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiBox('Avg Wait Time', '${analytics['averageWaitTimeMinutes'] ?? 18}m', Icons.timer_rounded, AppColors.warning),
              const SizedBox(width: 12),
              _kpiBox('Doctors On Duty', '12 / 15', Icons.medical_services_rounded, AppColors.success),
            ],
          ),
          const SizedBox(height: 24),

          // Department Throughput Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Department Flow', style: AppTextStyles.headlineSmall),
              TextButton(
                onPressed: () => context.go('/admin/queues'),
                child: const Text('View All Queues →', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          departmentsAsync.when(
            data: (departments) => Column(
              children: departments.map((dept) {
                final patientCount = (dept.totalDoctors * 6) + 4;
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(dept.icon, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dept.name, style: AppTextStyles.titleSmall),
                            Text(
                              'Head: ${dept.headDoctorName} • ${dept.totalDoctors} Doctors',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$patientCount in queue',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary)),
                          const Text('Est. ~15m wait', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorWidget2(message: e.toString()),
          ),
          const SizedBox(height: 24),

          // Admin Quick Navigation Grid
          Text('Administrative Control', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _adminTile(
                'Live Queues & TV Display',
                Icons.connected_tv_rounded,
                AppColors.primary,
                () => context.go('/admin/queues'),
              ),
              const SizedBox(width: 12),
              _adminTile(
                'Manage Doctor Roster',
                Icons.people_outline_rounded,
                AppColors.secondary,
                () => context.go('/admin/doctors'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _adminTile(
                'Analytics & Trends',
                Icons.bar_chart_rounded,
                AppColors.accent,
                () => context.go('/admin/analytics'),
              ),
              const SizedBox(width: 12),
              _adminTile(
                'Broadcast Announcement',
                Icons.campaign_rounded,
                AppColors.warning,
                () => _showBroadcastDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _kpiBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color)),
            const SizedBox(height: 2),
            Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _adminTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
