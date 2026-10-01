import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/doctor.dart';
import '../../../providers/doctor_provider.dart';

class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController(text: 'General Physician');
    final roomCtrl = TextEditingController(text: 'Room 108');
    final feeCtrl = TextEditingController(text: '600');
    final expCtrl = TextEditingController(text: '8');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Hospital Doctor'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Doctor Name', hintText: 'Dr. Rahul Sen'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specCtrl,
                decoration: const InputDecoration(labelText: 'Specialty', hintText: 'e.g. Cardiologist'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'OPD Room', hintText: 'Room 108'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: feeCtrl,
                      decoration: const InputDecoration(labelText: 'Fee (₹)', prefixText: '₹'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      decoration: const InputDecoration(labelText: 'Exp (Years)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newDoc = Doctor(
                  id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
                  userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                  departmentId: 'dept_006',
                  departmentName: 'General Medicine',
                  qualification: 'MBBS, MD',
                  experienceYears: int.tryParse(expCtrl.text.trim()) ?? 5,
                  rating: 4.8,
                  reviewCount: 24,
                  consultationFee: double.tryParse(feeCtrl.text.trim()) ?? 500.0,
                  availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                  weeklySlots: {
                    'Monday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
                    'Tuesday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
                    'Wednesday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
                    'Thursday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
                    'Friday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
                  },
                  email: 'doctor@smarthospital.org',
                  phone: '+91 98765 43210',
                  roomNumber: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : 'OPD-101',
                  registrationNumber: 'MCI-${DateTime.now().millisecond}',
                  about: 'Experienced specialist dedicated to comprehensive patient health.',
                  isAvailable: true,
                );
                MockData.doctors.insert(0, newDoc);
                ref.invalidate(doctorsProvider);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doctor added to hospital roster successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Add Doctor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hospital Doctor Roster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            tooltip: 'Add New Doctor',
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddDoctorDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctor by name or specialty...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),

          // Doctors List
          Expanded(
            child: doctorsAsync.when(
              data: (doctors) {
                final filtered = doctors.where((d) {
                  if (_searchQuery.isEmpty) return true;
                  return d.name.toLowerCase().contains(_searchQuery) ||
                      d.specialty.toLowerCase().contains(_searchQuery) ||
                      d.departmentName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No doctors match your query'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final doc = filtered[i];
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
                          DoctorAvatar(doctor: doc, size: 56),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doc.name,
                                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: doc.isAvailable
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        doc.isAvailable ? 'ACTIVE' : 'OFFLINE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: doc.isAvailable ? AppColors.success : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${doc.specialty} • ${doc.departmentName}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc.roomNumber ?? 'OPD Room',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.currency_rupee_rounded, size: 14, color: AppColors.textSecondary),
                                    Text(
                                      '${doc.consultationFee.toStringAsFixed(0)} fee',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorWidget2(message: e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDoctorDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Doctor'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
