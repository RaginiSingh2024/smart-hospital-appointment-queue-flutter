import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  bool _soundAlerts = true;
  bool _smsReminders = true;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final nameParts = user.name.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() => _isEditing = false);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final patient = ref.watch(currentPatientProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient Profile & Health ID'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
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
                    user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 26,
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
                      if (_isEditing) ...[
                        TextField(
                          controller: _firstNameController,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            hintText: 'First Name',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                        TextField(
                          controller: _lastNameController,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            hintText: 'Last Name',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ] else
                        Text(
                          user?.name ?? 'Patient',
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
                      if (_isEditing)
                        TextField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Phone',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        )
                      else
                        Text(
                          user?.phone ?? user?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Health Summary Stats Row
          Row(
            children: [
              _metricTile('Blood Group', patient?.bloodGroup ?? 'O+', Icons.bloodtype_rounded, AppColors.error),
              const SizedBox(width: 12),
              _metricTile(
                'Age',
                '${patient?.dateOfBirth != null ? (DateTime.now().year - patient!.dateOfBirth!.year) : 32} Yrs',
                Icons.cake_rounded,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _metricTile('Gender', 'Male', Icons.wc_rounded, AppColors.secondary),
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
                _infoRow('Known Allergies', (patient?.allergies ?? ['Penicillin']).join(', ')),
                const Divider(height: 20),
                _infoRow('Emergency Contact', '${patient?.emergencyContactName ?? "Pooja Sharma"} (${patient?.emergencyContactPhone ?? "+91 98765 43211"})'),
                const Divider(height: 20),
                _infoRow('Address', patient?.address ?? '42, MG Road, Indiranagar, Bangalore'),
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
