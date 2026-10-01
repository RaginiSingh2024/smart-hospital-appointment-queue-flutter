import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/appointment.dart';
import '../../../models/doctor.dart';
import '../../../models/queue.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _doctorStatus = 'ON DUTY'; // ON DUTY, ON BREAK, OFF DUTY

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDelayDialog(BuildContext context, String doctorId) {
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
                'Running behind schedule? Notify all waiting patients and adjust estimated wait times.',
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
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delay of $delayMinutes mins broadcast to all waiting OPD patients!'),
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

  void _showAddWalkinDialog(BuildContext context, String doctorId) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Add Emergency / Walk-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Patient Full Name',
                hintText: 'e.g. Ramesh Patel',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Symptoms / Emergency Note',
                hintText: 'e.g. Severe chest pain / acute reaction',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final today = DateTime.now();
              final date = DateFormat('yyyy-MM-dd').format(today);
              final queueRepo = ref.read(mockQueueRepositoryProvider);

              queueRepo.addToQueue(
                QueueModel(
                  id: 'emg_${DateTime.now().millisecondsSinceEpoch}',
                  doctorId: doctorId,
                  patientId: 'patient_walkin',
                  appointmentId: 'appt_walkin',
                  patientName: nameCtrl.text.trim(),
                  tokenNumber: 'EMG-${DateTime.now().millisecond % 90 + 10}',
                  tokenSequence: 0,
                  status: QueueStatus.waiting,
                  patientsAhead: 0,
                  estimatedWaitMinutes: 0,
                  date: date,
                  isEmergency: true,
                  checkedInAt: DateTime.now(),
                  notes: notesCtrl.text.trim(),
                ),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🚨 Emergency walk-in patient placed at head of queue!'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Insert Priority', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final doctorAsync = ref.watch(currentDoctorProvider);

    // Dynamic greeting based on time and actual authenticated doctor's first name
    final rawName = user?.name ?? 'Doctor';
    final cleanName = rawName.startsWith('Dr. ') ? rawName.substring(4) : rawName;
    final doctorFirstName = cleanName.trim().split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return doctorAsync.when(
      data: (doctor) {
        final doc = doctor ??
            Doctor(
              id: 'doc_002',
              userId: user?.id ?? 'user_doc_002',
              name: user?.name ?? 'Dr. Priya Mehta',
              specialty: 'Dermatologist',
              departmentId: 'dept_002',
              departmentName: 'Dermatology',
              experienceYears: 10,
              rating: 4.9,
              reviewCount: 210,
              consultationFee: 700,
              qualification: 'MBBS, MD',
              about: 'Specialist in clinical dermatology.',
              availableDays: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
              weeklySlots: const {},
              registrationNumber: 'KMC-2014-98765',
              email: user?.email ?? 'dr@gmail.com',
              phone: user?.phone ?? '+91 9876543221',
              roomNumber: 'OPD Room 204',
            );

        final doctorId = doc.id;
        final queueAsync = ref.watch(doctorQueueStreamProvider(doctorId));
        final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $doctorFirstName',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  '${doc.departmentName} • ${doc.roomNumber ?? "Room 204"}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Emergency Walk-in',
                icon: const Icon(Icons.bolt_rounded, color: AppColors.error),
                onPressed: () => _showAddWalkinDialog(context, doctorId),
              ),
              IconButton(
                tooltip: 'Broadcast Queue Delay',
                icon: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
                onPressed: () => _showDelayDialog(context, doctorId),
              ),
              IconButton(
                tooltip: 'Doctor Profile',
                icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                onPressed: () => context.go('/doctor/profile'),
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
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Queue & Consult'),
                Tab(icon: Icon(Icons.calendar_today_rounded, size: 18), text: "Today's Appointments"),
                Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Patients List'),
                Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Consultation History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Queue & Active Consultation
              _buildQueueAndConsultTab(context, doc, queueAsync),

              // TAB 2: Today's Appointments (Real Appointments matching doctorId)
              _buildAppointmentsTab(context, doc, appointmentsAsync),

              // TAB 3: Patients List
              _buildPatientsListTab(context, doc, appointmentsAsync),

              // TAB 4: Consultation History
              _buildConsultationHistoryTab(context, doc, appointmentsAsync),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingWidget(message: 'Loading doctor portal...')),
      error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
    );
  }

  // ─── TAB 1: Queue & Active Consultation ──────────────────────────────────────
  Widget _buildQueueAndConsultTab(BuildContext context, Doctor doc, AsyncValue<DoctorQueue> queueAsync) {
    final user = ref.watch(currentUserProvider);

    return queueAsync.when(
      data: (queue) {
        final currentPatient = queue.currentToken;
        final waitingPatients = queue.waitingTokens;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorQueueStreamProvider(doc.id));
            ref.invalidate(doctorAppointmentsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Doctor Shift & Status Bar
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
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        doc.initials,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${doc.specialty} • ${doc.qualification}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  _statCard('Total OPD', '${queue.totalTodayCount}', Icons.assignment_rounded, AppColors.secondary),
                  const SizedBox(width: 10),
                  _statCard('Avg Time', '12m', Icons.timer_rounded, AppColors.accent),
                ],
              ),
              const SizedBox(height: 20),

              // Active Patient in Consultation Card
              Text('Active Consultation Room', style: AppTextStyles.headlineSmall),
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
                                    Text('IN CONSULTATION', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(currentPatient.patientName, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Chief Complaint: ${currentPatient.notes ?? "Clinical consultation & examination"}',
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
                                  await ref.read(queueRepositoryProvider).markComplete(doc.id, currentPatient.id);
                                  ref.invalidate(doctorQueueStreamProvider(doc.id));
                                  ref.invalidate(doctorAppointmentsProvider);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Consultation completed successfully! ✅')),
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
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.meeting_room_outlined, size: 40, color: AppColors.textLight),
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
                                    final today = DateTime.now();
                                    final date = DateFormat('yyyy-MM-dd').format(today);
                                    await ref.read(queueRepositoryProvider).callNextPatient(doc.id, date);
                                    ref.invalidate(doctorQueueStreamProvider(doc.id));
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

              // Waiting Queue List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waiting Queue (${waitingPatients.length})', style: AppTextStyles.headlineSmall),
                  TextButton(
                    onPressed: () => context.go('/doctor/queue'),
                    child: const Text('Full Queue Control →', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (waitingPatients.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('Queue is clear! No waiting patients in OPD line.'),
                  ),
                )
              else
                ...waitingPatients.map((patient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: patient.isEmergency ? AppColors.error : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: patient.isEmergency ? AppColors.error.withValues(alpha: 0.15) : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              patient.tokenNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: patient.isEmergency ? AppColors.error : AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(patient.patientName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                                  if (patient.isEmergency) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('PRIORITY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Scheduled: ${patient.estimatedConsultationTime ?? "OPD Slot"} • Wait ~${patient.estimatedWaitMinutes}m',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () async {
                            final today = DateTime.now();
                            final date = DateFormat('yyyy-MM-dd').format(today);
                            await ref.read(queueRepositoryProvider).callNextPatient(doc.id, date);
                            ref.invalidate(doctorQueueStreamProvider(doc.id));
                          },
                          child: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),

              // Quick Actions
              Text('Doctor Quick Actions', style: AppTextStyles.headlineSmall),
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
                    'OPD Schedule & Slots',
                    Icons.calendar_month_rounded,
                    AppColors.secondary,
                    () => context.go('/doctor/schedule'),
                  ),
                  const SizedBox(width: 12),
                  _actionTile(
                    'My Doctor Profile',
                    Icons.person_rounded,
                    AppColors.accent,
                    () => context.go('/doctor/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Connecting to OPD Queue...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── TAB 2: Today's Appointments (Real Data) ──────────────────────────────────
  Widget _buildAppointmentsTab(BuildContext context, Doctor doc, AsyncValue<List<Appointment>> appointmentsAsync) {
    return appointmentsAsync.when(
      data: (appointments) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(doctorAppointmentsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Doctor's Appointments (${appointments.length})", style: AppTextStyles.headlineSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Doctor: ${doc.name}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (appointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      const Text('No Appointments Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'When patients book appointments with ${doc.name}, they will appear here.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...appointments.map((appt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TOKEN: ${appt.tokenNumber}',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12),
                              ),
                            ),
                            _buildStatusChip(appt.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(appt.patientName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          'Date: ${DateFormat("dd MMM yyyy").format(appt.appointmentDate)} • Slot: ${appt.timeSlot}',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        if (appt.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text('Notes: ${appt.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (appt.status == AppointmentStatus.confirmed)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 16),
                                  label: const Text('Check In Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    await ref.read(appointmentNotifierProvider.notifier).checkIn(appt.id, appt.patientId);
                                    ref.invalidate(doctorAppointmentsProvider);
                                  },
                                ),
                              ),
                            if (appt.status == AppointmentStatus.checkedIn || appt.status == AppointmentStatus.confirmed) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.medical_services_rounded, size: 16),
                                  label: const Text('Start Consultation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    context.go('/doctor/consultation/${appt.id}');
                                  },
                                ),
                              ),
                            ],
                            if (appt.status == AppointmentStatus.inConsultation)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                                  label: const Text('Prescribe & Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    context.go('/doctor/consultation/${appt.id}');
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading doctor appointments...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── TAB 3: Patients List ───────────────────────────────────────────────────
  Widget _buildPatientsListTab(BuildContext context, Doctor doc, AsyncValue<List<Appointment>> appointmentsAsync) {
    return appointmentsAsync.when(
      data: (appointments) {
        // Group unique patients
        final patientMap = <String, Appointment>{};
        for (var a in appointments) {
          patientMap[a.patientId] = a;
        }
        final patients = patientMap.values.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Registered Patients for ${doc.name} (${patients.length})', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            if (patients.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(child: Text('No patient records for this doctor yet.')),
              )
            else
              ...patients.map((p) {
                final patientAppts = appointments.where((a) => a.patientId == p.patientId).toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          p.patientName.isNotEmpty ? p.patientName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.patientName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                            Text('Patient ID: ${p.patientId}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                            Text('${patientAppts.length} total visit(s)', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
                        onPressed: () {
                          // Quick appointment review
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Viewing patient profile for ${p.patientName}')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading patient records...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── TAB 4: Consultation History ───────────────────────────────────────────
  Widget _buildConsultationHistoryTab(BuildContext context, Doctor doc, AsyncValue<List<Appointment>> appointmentsAsync) {
    return appointmentsAsync.when(
      data: (appointments) {
        final completed = appointments.where((a) => a.status == AppointmentStatus.completed).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Completed Consultations (${completed.length})', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            if (completed.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 48, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('No Completed Consultations Yet', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Completed visits and written prescriptions will be archived here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ...completed.map((appt) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(appt.patientName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('COMPLETED', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat("dd MMM yyyy").format(appt.appointmentDate)} • Token: ${appt.tokenNumber}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text('Department: ${appt.departmentName} • Fee Paid: ₹${appt.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading consultation history...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        bg = AppColors.primarySurface;
        fg = AppColors.primary;
        label = 'CONFIRMED';
        break;
      case AppointmentStatus.checkedIn:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'CHECKED IN';
        break;
      case AppointmentStatus.inConsultation:
        bg = AppColors.secondary.withValues(alpha: 0.15);
        fg = AppColors.secondary;
        label = 'IN CONSULT';
        break;
      case AppointmentStatus.completed:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'COMPLETED';
        break;
      case AppointmentStatus.cancelled:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        label = 'CANCELLED';
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = status.name.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 10)),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
