import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/patient.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  bool _soundAlerts = true;
  bool _smsReminders = true;

  void _openEditProfileModal(BuildContext context, UserModel user, PatientModel? patient) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final bloodGroupCtrl = TextEditingController(text: patient?.bloodGroup ?? 'O+');
    final emergencyNameCtrl = TextEditingController(text: patient?.emergencyContactName ?? '');
    final emergencyPhoneCtrl = TextEditingController(text: patient?.emergencyContactPhone ?? '');
    final addressCtrl = TextEditingController(text: patient?.address ?? '');
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
                      Text('Edit Patient Profile', style: AppTextStyles.titleLarge),
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: bloodGroupCtrl,
                    label: 'Blood Group',
                    prefixIcon: Icons.bloodtype_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: emergencyNameCtrl,
                    label: 'Emergency Contact Name',
                    prefixIcon: Icons.contact_phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: emergencyPhoneCtrl,
                    label: 'Emergency Contact Phone',
                    prefixIcon: Icons.phone_in_talk_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: addressCtrl,
                    label: 'Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Save Changes',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSaving = true);

                      try {
                        final updatedUser = user.copyWith(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          role: UserRole.patient,
                        );

                        final updatedPatient = (patient ??
                                PatientModel(
                                  id: 'pat_${user.id}',
                                  userId: user.id,
                                  name: nameCtrl.text.trim(),
                                  email: user.email,
                                  phone: phoneCtrl.text.trim(),
                                  dateOfBirth: DateTime(1995, 1, 1),
                                  bloodGroup: bloodGroupCtrl.text.trim(),
                                ))
                            .copyWith(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          bloodGroup: bloodGroupCtrl.text.trim(),
                          emergencyContactName: emergencyNameCtrl.text.trim(),
                          emergencyContactPhone: emergencyPhoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                        );

                        await ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
                        await ref.read(authNotifierProvider.notifier).updatePatient(updatedPatient);

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Patient profile updated successfully! ✅'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Update failed: $e'),
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
    final patient = ref.watch(currentPatientProvider);

    final currentUser = user ??
        UserModel(
          id: 'user_patient_ragini',
          name: 'Ragini Singh',
          email: 'patient@gmail.com',
          phone: '+91 9876543299',
          role: UserRole.patient,
          createdAt: DateTime(2024, 1, 1),
        );

    final initials = currentUser.name.trim().isNotEmpty
        ? currentUser.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'PT';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Patient Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name,
                        style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UHID: ${patient != null ? "UHID-${patient.id.toUpperCase()}" : "UHID-2024-001"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Edit Profile CTA
          AppButton(
            label: 'Edit Profile Details',
            icon: Icons.edit_note_rounded,
            onPressed: () => _openEditProfileModal(context, currentUser, patient),
          ),
          const SizedBox(height: 20),

          // Health Summary Stats Row
          Row(
            children: [
              _metricTile('Blood Group', patient?.bloodGroup ?? 'B+', Icons.bloodtype_rounded, AppColors.error),
              const SizedBox(width: 12),
              _metricTile(
                'Age',
                '${patient?.dateOfBirth != null ? (DateTime.now().year - patient!.dateOfBirth!.year) : 28} Yrs',
                Icons.cake_rounded,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _metricTile('Role', 'Patient', Icons.person_rounded, AppColors.secondary),
            ],
          ),
          const SizedBox(height: 20),

          // Medical Information Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Medical Records', style: AppTextStyles.titleSmall),
                    InkWell(
                      onTap: () => context.go('/patient/history'),
                      child: Text(
                        'View History →',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _infoRow('Known Allergies', (patient != null && patient.allergies.isNotEmpty ? patient.allergies.join(', ') : 'None Reported')),
                const Divider(height: 20),
                _infoRow('Emergency Contact', '${patient?.emergencyContactName ?? "Vikram Singh"} (${patient?.emergencyContactPhone ?? "+91 98765 43290"})'),
                const Divider(height: 20),
                _infoRow('Address', patient?.address ?? '742 Evergreen Terrace, Sector 4, Bangalore'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preferences & Notifications Card
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
                Text('Preferences & Alerts', style: AppTextStyles.titleSmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live Queue Audio & Push Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Get notified when 2 patients are ahead of your token', style: TextStyle(fontSize: 12)),
                  value: _soundAlerts,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _soundAlerts = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SMS Consultation Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive booking confirmations on mobile', style: TextStyle(fontSize: 12)),
                  value: _smsReminders,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _smsReminders = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
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
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
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
          width: 120,
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
