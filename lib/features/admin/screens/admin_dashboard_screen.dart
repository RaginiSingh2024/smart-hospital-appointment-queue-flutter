import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/appointment.dart';
import '../../../models/department.dart';
import '../../../models/doctor.dart';
import '../../../models/patient.dart';
import '../../../models/user.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/repository_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              'Broadcast an instant notification banner to all hospital displays & waiting room terminals.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Pharmacy counter #3 open. Emergency priority in effect.',
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
                  content: Text('📣 Announcement broadcast to all hospital terminals! ✅'),
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
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final analytics = ref.watch(analyticsProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final doctorsAsync = ref.watch(doctorsProvider);
    final allApptsAsync = ref.watch(allAppointmentsProvider);

    // Dynamic greeting using actual admin first name
    final rawName = user?.name ?? 'Admin';
    final adminFirstName = rawName.trim().split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $adminFirstName',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Hospital Admin Command Center',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Hospital Broadcast',
            icon: const Icon(Icons.campaign_rounded, color: AppColors.accent),
            onPressed: () => _showBroadcastDialog(context),
          ),
          IconButton(
            tooltip: 'Admin Profile',
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => context.go('/admin/profile'),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.medical_services_rounded, size: 18), text: 'Doctors'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'Patients'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Appointments'),
            Tab(icon: Icon(Icons.domain_rounded, size: 18), text: 'Departments'),
            Tab(icon: Icon(Icons.insights_rounded, size: 18), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Overview
          _buildOverviewTab(context, analytics, departmentsAsync, doctorsAsync, allApptsAsync),

          // 2. Doctors Management
          _buildDoctorsTab(context, doctorsAsync),

          // 3. Patients Management
          _buildPatientsTab(context),

          // 4. Appointments Management
          _buildAppointmentsTab(context, allApptsAsync),

          // 5. Departments Management
          _buildDepartmentsTab(context, departmentsAsync),

          // 6. Analytics
          _buildAnalyticsTab(context, analytics),
        ],
      ),
    );
  }

  // ─── 1. Overview Tab ────────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    BuildContext context,
    Map<String, dynamic> analytics,
    AsyncValue<List<Department>> deptsAsync,
    AsyncValue<List<Doctor>> docsAsync,
    AsyncValue<List<Appointment>> apptsAsync,
  ) {
    final totalPatients = analytics['todayAppointments']?.toString() ?? '8';
    final waiting = analytics['waitingPatients']?.toString() ?? '3';
    final doctors = analytics['totalDoctors']?.toString() ?? '10';
    final avgWait = analytics['averageWaitTime']?.toString() ?? '22';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // System Status Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                  const Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, color: AppColors.accent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'SYSTEM STATUS: ALL OPDs NORMAL',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Hospital Operations Command',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              const Text(
                'Real-time OPD queue flow, doctor duty monitoring & department loads',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Key Metrics Grid
        Row(
          children: [
            _statTile('Today OPD Visits', totalPatients, Icons.people_alt_rounded, AppColors.primary),
            const SizedBox(width: 10),
            _statTile('Active In Queue', waiting, Icons.queue_rounded, AppColors.warning),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile('Doctors Registered', doctors, Icons.medical_services_rounded, AppColors.success),
            const SizedBox(width: 10),
            _statTile('Avg Wait Time', '${avgWait}m', Icons.timer_rounded, AppColors.secondary),
          ],
        ),
        const SizedBox(height: 24),

        // Admin Quick Control
        Text('Quick Administration Actions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 10),
        Row(
          children: [
            _actionCard('Live Queues', Icons.format_list_numbered_rounded, AppColors.primary, () => context.go('/admin/queues')),
            const SizedBox(width: 12),
            _actionCard('Manage Doctors', Icons.medical_information_rounded, AppColors.secondary, () => _tabController.animateTo(1)),
            const SizedBox(width: 12),
            _actionCard('Full Analytics', Icons.bar_chart_rounded, AppColors.accent, () => context.go('/admin/analytics')),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  String _doctorSearch = '';
  String _doctorDeptFilter = 'ALL';

  void _showAddDoctorDialog(BuildContext context, [String? initialDeptId]) {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: 'Room 205');
    final feeCtrl = TextEditingController(text: '700');
    final expCtrl = TextEditingController(text: '8');
    final qualCtrl = TextEditingController(text: 'MBBS, MD');
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 9876543210');
    String selectedDeptId = initialDeptId ?? 'dept_001';

    final deptMap = {
      'dept_001': {'name': 'Cardiology', 'icon': '❤️'},
      'dept_002': {'name': 'Dermatology', 'icon': '🌿'},
      'dept_003': {'name': 'Neurology', 'icon': '🧠'},
      'dept_004': {'name': 'Pediatrics', 'icon': '👶'},
      'dept_005': {'name': 'Orthopedics', 'icon': '🦴'},
      'dept_006': {'name': 'General Medicine', 'icon': '🏥'},
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Register Hospital Doctor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter physician details to add them to OPD rosters & queue systems.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Full Name *',
                      hintText: 'e.g. Dr. Ramesh Gupta',
                      prefixIcon: Icon(Icons.badge_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDeptId,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Department *',
                      prefixIcon: Icon(Icons.domain_rounded, size: 20),
                    ),
                    items: deptMap.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text('${e.value["icon"]} ${e.value["name"]}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedDeptId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Specialty / Sub-specialty',
                      hintText: 'e.g. Senior Interventional Cardiologist',
                      prefixIcon: Icon(Icons.medical_services_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qualCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Qualifications',
                            hintText: 'MBBS, MD, DM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: expCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Experience (Yrs)',
                            hintText: '10',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: feeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Consultation Fee (₹)',
                            prefixText: '₹ ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          decoration: const InputDecoration(
                            labelText: 'OPD Room No.',
                            hintText: 'Room 205',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Email (Optional)',
                      hintText: 'doctor.name@hospital.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter doctor name!'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                final deptName = deptMap[selectedDeptId]?['name'] ?? 'General Medicine';
                final specialty = specCtrl.text.trim().isNotEmpty
                    ? specCtrl.text.trim()
                    : '$deptName Specialist';
                final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

                final newDoc = Doctor(
                  id: docId,
                  userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  name: name.startsWith('Dr.') ? name : 'Dr. $name',
                  specialty: specialty,
                  departmentId: selectedDeptId,
                  departmentName: deptName,
                  experienceYears: int.tryParse(expCtrl.text.trim()) ?? 8,
                  rating: 4.8,
                  reviewCount: 1,
                  consultationFee: double.tryParse(feeCtrl.text.trim()) ?? 600.0,
                  qualification: qualCtrl.text.trim().isNotEmpty ? qualCtrl.text.trim() : 'MBBS, MD',
                  about: 'Experienced specialist dedicated to comprehensive clinical patient care in $deptName.',
                  isAvailable: true,
                  registrationNumber: 'MCI-${DateTime.now().millisecondsSinceEpoch % 90000 + 10000}',
                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : 'doc.${DateTime.now().millisecond}@hospital.com',
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 98765 43210',
                  roomNumber: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'OPD Room 204',
                  availableDays: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                  weeklySlots: const {
                    'Monday': ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00'],
                    'Tuesday': ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00'],
                    'Wednesday': ['09:00', '09:30', '10:00', '10:30', '11:00'],
                    'Thursday': ['09:00', '09:30', '10:00', '10:30', '11:00', '14:00', '14:30', '15:00'],
                    'Friday': ['09:00', '09:30', '10:00', '10:30', '11:00'],
                  },
                );

                await ref.read(doctorRepositoryProvider).addDoctor(newDoc);
                ref.invalidate(doctorsProvider);
                if (ctx.mounted) Navigator.pop(ctx);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ${newDoc.name} registered and added to $deptName successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Add Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Doctors Management Tab ──────────────────────────────────────────────
  Widget _buildDoctorsTab(BuildContext context, AsyncValue<List<Doctor>> doctorsAsync) {
    return doctorsAsync.when(
      data: (doctors) {
        final filtered = doctors.where((d) {
          final matchesDept = _doctorDeptFilter == 'ALL' || d.departmentId == _doctorDeptFilter;
          final matchesQuery = _doctorSearch.isEmpty ||
              d.name.toLowerCase().contains(_doctorSearch.toLowerCase()) ||
              d.specialty.toLowerCase().contains(_doctorSearch.toLowerCase()) ||
              d.departmentName.toLowerCase().contains(_doctorSearch.toLowerCase());
          return matchesDept && matchesQuery;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hospital Doctors (${filtered.length}/${doctors.length})', style: AppTextStyles.headlineSmall),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddDoctorDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search doctor by name or specialty...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _doctorSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _doctorSearch = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _doctorSearch = v.trim()),
            ),
            const SizedBox(height: 10),

            // Department Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  {'id': 'ALL', 'name': 'All Departments'},
                  {'id': 'dept_001', 'name': '❤️ Cardiology'},
                  {'id': 'dept_002', 'name': '🌿 Dermatology'},
                  {'id': 'dept_003', 'name': '🧠 Neurology'},
                  {'id': 'dept_004', 'name': '👶 Pediatrics'},
                  {'id': 'dept_005', 'name': '🦴 Orthopedics'},
                  {'id': 'dept_006', 'name': '🏥 General Medicine'},
                ].map((dept) {
                  final isSel = _doctorDeptFilter == dept['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(dept['name']!),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _doctorDeptFilter = dept['id']!),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('No doctors match your filter criteria.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...filtered.map((doctor) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          doctor.initials,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doctor.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                            Text('${doctor.specialty} • ${doctor.departmentName}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Fee: ₹${doctor.consultationFee.toStringAsFixed(0)} • Exp: ${doctor.experienceYears}y • ${doctor.roomNumber ?? "Room 204"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Switch(
                            value: doctor.isAvailable,
                            activeColor: AppColors.success,
                            onChanged: (val) async {
                              final updated = doctor.copyWith(isAvailable: val);
                              await ref.read(doctorRepositoryProvider).updateDoctor(updated);
                              ref.invalidate(doctorsProvider);
                            },
                          ),
                          Text(
                            doctor.isAvailable ? 'AVAILABLE' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: doctor.isAvailable ? AppColors.success : AppColors.error,
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
        );
      },
      loading: () => const LoadingWidget(message: 'Loading hospital doctors...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── 3. Patients Management Tab ─────────────────────────────────────────────
  Widget _buildPatientsTab(BuildContext context) {
    final patients = [
      PatientModel(
        id: 'pat_ragini',
        userId: 'user_patient_ragini',
        name: 'Ragini Singh',
        email: 'patient@gmail.com',
        phone: '+91 9876543299',
        bloodGroup: 'B+',
        address: '742 Evergreen Terrace, Sector 4, Bangalore',
      ),
      PatientModel(
        id: 'pat_001',
        userId: 'user_patient_001',
        name: 'Arjun Sharma',
        email: 'patient@hospital.com',
        phone: '+91 9876543210',
        bloodGroup: 'O+',
        address: '123, MG Road, Bangalore',
      ),
      PatientModel(
        id: 'pat_002',
        userId: 'user_patient_002',
        name: 'Meena Patel',
        email: 'meena@hospital.com',
        phone: '+91 9876543211',
        bloodGroup: 'A+',
        address: '456, Linking Road, Mumbai',
      ),
      PatientModel(
        id: 'pat_003',
        userId: 'user_patient_003',
        name: 'Rahul Kumar',
        email: 'rahul@hospital.com',
        phone: '+91 9876543212',
        bloodGroup: 'B+',
        address: '789, Park Street, Kolkata',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Patient Registry (${patients.length})', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        ...patients.map((p) {
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
                  radius: 22,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0] : 'P',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                      Text('UHID: UHID-${p.id.toUpperCase()} • Blood: ${p.bloodGroup ?? "O+"}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      Text('Phone: ${p.phone} • ${p.email}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── 4. Appointments Management Tab ─────────────────────────────────────────
  Widget _buildAppointmentsTab(BuildContext context, AsyncValue<List<Appointment>> allApptsAsync) {
    return allApptsAsync.when(
      data: (appts) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Hospital-Wide Appointments (${appts.length})', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...appts.map((a) {
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.tokenNumber,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.patientName, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                          Text('Doctor: ${a.doctorName} • ${a.departmentName}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          Text('Date: ${DateFormat("dd MMM").format(a.appointmentDate)} • Slot: ${a.timeSlot}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(a.status.name.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading appointments...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── 5. Departments Management Tab ──────────────────────────────────────────
  Widget _buildDepartmentsTab(BuildContext context, AsyncValue<List<Department>> deptsAsync) {
    return deptsAsync.when(
      data: (depts) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Clinical Departments (${depts.length})', style: AppTextStyles.headlineSmall),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.format_list_numbered_rounded, size: 16),
                  label: const Text('Live Queue Monitor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => context.go('/admin/queues'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...depts.map((d) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(d.icon, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                              Text(d.description, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('Head: ${d.headDoctorName} • ${d.totalDoctors} Registered Doctors', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.people_alt_rounded, size: 14),
                            label: const Text('View Doctors', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () {
                              setState(() {
                                _doctorDeptFilter = d.id;
                                _tabController.animateTo(1);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.queue_rounded, size: 14),
                            label: const Text('Live Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            onPressed: () => context.go('/admin/queues'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Add Doctor to ${d.name}',
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.secondary, size: 20),
                          onPressed: () => _showAddDoctorDialog(context, d.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 30),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading departments...'),
      error: (e, _) => ErrorWidget2(message: e.toString()),
    );
  }

  // ─── 6. Analytics Tab ───────────────────────────────────────────────────────
  Widget _buildAnalyticsTab(BuildContext context, Map<String, dynamic> analytics) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('OPD Operational Analytics', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
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
              Text('Key Performance Indicators', style: AppTextStyles.titleSmall),
              const SizedBox(height: 14),
              _kpiRow('Total Patients Served Today', '${analytics["todayAppointments"] ?? 8}'),
              const Divider(height: 20),
              _kpiRow('Currently Waiting in Queue', '${analytics["waitingPatients"] ?? 3}'),
              const Divider(height: 20),
              _kpiRow('Average Consultation Wait Time', '${analytics["averageWaitTime"] ?? 22} minutes'),
              const Divider(height: 20),
              _kpiRow('Total Doctors in Hospital', '${analytics["totalDoctors"] ?? 10}'),
              const Divider(height: 20),
              _kpiRow('OPD Queue Clearance Rate', '94.2%'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.analytics_rounded),
          label: const Text('View Full Analytics & Graphs', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => context.go('/admin/analytics'),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _kpiRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    );
  }
}
