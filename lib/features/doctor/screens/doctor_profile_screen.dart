import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/doctor.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  void _openEditProfileModal(BuildContext context, Doctor doctor, UserModel user) {
    final nameCtrl = TextEditingController(text: doctor.name);
    final phoneCtrl = TextEditingController(text: doctor.phone);
    final specialtyCtrl = TextEditingController(text: doctor.specialty);
    final deptCtrl = TextEditingController(text: doctor.departmentName);
    final qualCtrl = TextEditingController(text: doctor.qualification);
    final expCtrl = TextEditingController(text: doctor.experienceYears.toString());
    final feeCtrl = TextEditingController(text: doctor.consultationFee.toStringAsFixed(0));
    final aboutCtrl = TextEditingController(text: doctor.about);
    bool isAvailable = doctor.isAvailable;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Doctor Profile', style: AppTextStyles.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: specialtyCtrl,
                    label: 'Specialty',
                    prefixIcon: Icons.medical_services_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Specialty required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: deptCtrl,
                    label: 'Department',
                    prefixIcon: Icons.local_hospital_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Department required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: qualCtrl,
                    label: 'Qualification',
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: expCtrl,
                          label: 'Experience (Yrs)',
                          prefixIcon: Icons.work_outline_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: feeCtrl,
                          label: 'Fee (₹)',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: aboutCtrl,
                    label: 'About / Bio',
                    prefixIcon: Icons.info_outline_rounded,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for OPD Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(isAvailable ? 'Status: Active & Visible' : 'Status: Unavailable', style: const TextStyle(fontSize: 12)),
                    value: isAvailable,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setModalState(() => isAvailable = v),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Save Changes',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);

                      try {
                        final updatedDoc = doctor.copyWith(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          specialty: specialtyCtrl.text.trim(),
                          departmentName: deptCtrl.text.trim(),
                          qualification: qualCtrl.text.trim(),
                          experienceYears: int.tryParse(expCtrl.text.trim()) ?? doctor.experienceYears,
                          consultationFee: double.tryParse(feeCtrl.text.trim()) ?? doctor.consultationFee,
                          about: aboutCtrl.text.trim(),
                          isAvailable: isAvailable,
                        );

                        final updatedUser = user.copyWith(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          role: UserRole.doctor,
                        );

                        // Update in repository
                        await ref.read(doctorRepositoryProvider).updateDoctor(updatedDoc);
                        await ref.read(authNotifierProvider.notifier).updateUser(updatedUser);

                        // Invalidate providers
                        ref.invalidate(currentDoctorProvider);
                        ref.invalidate(doctorsProvider);

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Doctor Profile updated successfully! ✅'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final doctorAsync = ref.watch(currentDoctorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/doctor'),
        ),
      ),
      body: doctorAsync.when(
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
                qualification: 'MBBS, MD (Dermatology)',
                about: 'Senior Dermatologist specializing in clinical dermatology and cosmetology.',
                availableDays: const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                weeklySlots: const {
                  'Monday': ['09:00', '09:30', '10:00', '10:30'],
                },
                registrationNumber: 'KMC-2014-98765',
                email: user?.email ?? 'doctor@hospital.com',
                phone: user?.phone ?? '+91 9876543221',
                roomNumber: 'OPD Room 204',
              );

          final currentUser = user ??
              UserModel(
                id: doc.userId,
                name: doc.name,
                email: doc.email,
                phone: doc.phone,
                role: UserRole.doctor,
                createdAt: DateTime(2023, 1, 1),
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Text(
                        doc.initials,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${doc.specialty} • ${doc.departmentName}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg No: ${doc.registrationNumber}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Edit Profile CTA Button
              AppButton(
                label: 'Edit Profile Details',
                icon: Icons.edit_note_rounded,
                onPressed: () => _openEditProfileModal(context, doc, currentUser),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  _statCard('Experience', '${doc.experienceYears} Years', Icons.history_edu_rounded, AppColors.primary),
                  const SizedBox(width: 10),
                  _statCard('Fee', '₹${doc.consultationFee.toStringAsFixed(0)}', Icons.currency_rupee_rounded, AppColors.success),
                  const SizedBox(width: 10),
                  _statCard('Status', doc.isAvailable ? 'Available' : 'On Leave', Icons.health_and_safety_rounded, doc.isAvailable ? AppColors.success : AppColors.error),
                ],
              ),
              const SizedBox(height: 20),

              // Professional Information Card
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
                    Text('Professional Details', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 14),
                    _infoRow('Department', doc.departmentName),
                    const Divider(height: 20),
                    _infoRow('Specialty', doc.specialty),
                    const Divider(height: 20),
                    _infoRow('Qualification', doc.qualification),
                    const Divider(height: 20),
                    _infoRow('Registration No.', doc.registrationNumber),
                    const Divider(height: 20),
                    _infoRow('OPD Room', doc.roomNumber ?? 'Room 204'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information Card
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
                    Text('Contact Information', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 14),
                    _infoRow('Email', doc.email),
                    const Divider(height: 20),
                    _infoRow('Phone', doc.phone),
                    const Divider(height: 20),
                    _infoRow('Role', 'Medical Specialist (Doctor)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // About & Bio Card
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
                    Text('About Doctor', style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      doc.about.isNotEmpty ? doc.about : 'Senior hospital practitioner.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
