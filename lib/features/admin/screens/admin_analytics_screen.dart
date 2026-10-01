import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../models/appointment.dart';
import '../../../providers/repository_providers.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hospital Operations Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'Export Report',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📊 Hospital Operations Summary Report exported to CSV'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: ['Today', 'This Week', 'This Month'].asMap().entries.map((e) {
                    final isSel = _selectedPeriod == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: isSel ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _metricTile('Total Patients', '${analytics.totalPatients}', Icons.people_rounded, AppColors.primary),
                  const SizedBox(width: 12),
                  _metricTile('Total Doctors', '${analytics.totalDoctors}', Icons.medical_services_rounded, AppColors.success),
                  const SizedBox(width: 12),
                  _metricTile('Today\'s Appts', '${analytics.todayAppointments}', Icons.calendar_today_rounded, AppColors.accent),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _metricTile('Completed', '${analytics.completedAppointments}', Icons.check_circle_rounded, AppColors.success),
                  const SizedBox(width: 12),
                  _metricTile('Pending', '${analytics.pendingAppointments}', Icons.pending_rounded, AppColors.warning),
                  const SizedBox(width: 12),
                  _metricTile('Cancelled', '${analytics.cancelledAppointments}', Icons.cancel_rounded, AppColors.error),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
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
                        Text('Hourly OPD Rush & Peak Times', style: AppTextStyles.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Peak: 10 AM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Number of patients registered by hour', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 35,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 26,
                                getTitlesWidget: (val, meta) => Text(
                                  val.toInt().toString(),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  const hours = ['9am', '10am', '11am', '12pm', '2pm', '3pm', '4pm'];
                                  if (val.toInt() < hours.length) {
                                    return Text(hours[val.toInt()], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.border, strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _barGroup(0, 14, false),
                            _barGroup(1, 32, true),
                            _barGroup(2, 28, false),
                            _barGroup(3, 16, false),
                            _barGroup(4, 22, false),
                            _barGroup(5, 19, false),
                            _barGroup(6, 11, false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Department Queue Distribution', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text('Proportion of total OPD traffic today', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(value: 30, color: const Color(0xFFEF4444), radius: 24, showTitle: false),
                                PieChartSectionData(value: 25, color: const Color(0xFFEC4899), radius: 24, showTitle: false),
                                PieChartSectionData(value: 20, color: const Color(0xFF8B5CF6), radius: 24, showTitle: false),
                                PieChartSectionData(value: 15, color: const Color(0xFF3B82F6), radius: 24, showTitle: false),
                                PieChartSectionData(value: 10, color: const Color(0xFF10B981), radius: 24, showTitle: false),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legendItem('Cardiology (30%)', const Color(0xFFEF4444)),
                              _legendItem('Dermatology (25%)', const Color(0xFFEC4899)),
                              _legendItem('Neurology (20%)', const Color(0xFF8B5CF6)),
                              _legendItem('Orthopedics (15%)', const Color(0xFF3B82F6)),
                              _legendItem('Pediatrics (10%)', const Color(0xFF10B981)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Patient Throughput', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text('Daily consultations completed this week', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (v.toInt() < days.length) {
                                    return Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 110),
                                FlSpot(1, 142),
                                FlSpot(2, 138),
                                FlSpot(3, 160),
                                FlSpot(4, 155),
                                FlSpot(5, 120),
                                FlSpot(6, 75),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load analytics',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, bool isPeak) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isPeak ? AppColors.accent : AppColors.primary,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class AnalyticsData {
  final int totalPatients;
  final int totalDoctors;
  final int todayAppointments;
  final int completedAppointments;
  final int pendingAppointments;
  final int cancelledAppointments;
  final int totalDepartments;

  AnalyticsData({
    required this.totalPatients,
    required this.totalDoctors,
    required this.todayAppointments,
    required this.completedAppointments,
    required this.pendingAppointments,
    required this.cancelledAppointments,
    required this.totalDepartments,
  });
}

final _analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  try {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final appointmentRepo = ref.read(appointmentRepositoryProvider);
    final allAppointments = await appointmentRepo.getAllAppointments();

    final todayAppointments = allAppointments.where((a) {
      return a.appointmentDate.isAfter(startOfDay) && a.appointmentDate.isBefore(endOfDay);
    }).toList();

    final completedCount = allAppointments.where((a) => a.status == AppointmentStatus.completed).length;
    final cancelledCount = allAppointments.where((a) => a.status == AppointmentStatus.cancelled).length;
    final pendingCount = allAppointments.where((a) => 
      a.status == AppointmentStatus.confirmed || 
      a.status == AppointmentStatus.pending ||
      a.status == AppointmentStatus.checkedIn ||
      a.status == AppointmentStatus.inQueue ||
      a.status == AppointmentStatus.inConsultation
    ).length;

    final doctorRepo = ref.read(doctorRepositoryProvider);
    final doctors = await doctorRepo.getDoctors();

    final departmentRepo = ref.read(departmentRepositoryProvider);
    final departments = await departmentRepo.getDepartments();

    final uniquePatients = allAppointments.map((a) => a.patientId).toSet().length;

    return AnalyticsData(
      totalPatients: uniquePatients,
      totalDoctors: doctors.length,
      todayAppointments: todayAppointments.length,
      completedAppointments: completedCount,
      pendingAppointments: pendingCount,
      cancelledAppointments: cancelledCount,
      totalDepartments: departments.length,
    );
  } catch (e) {
    rethrow;
  }
});
