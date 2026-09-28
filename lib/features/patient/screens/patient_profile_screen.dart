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

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text('Quick Role Switcher', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Switch account persona instantly for presentation demo',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Patient
            _roleOption(
              ctx,
              name: 'Arjun Sharma',
              role: 'Patient (Self-Service & Live Queue)',
              icon: Icons.person_rounded,
              color: AppColors.primary,
              email: 'patient@hospital.com',
              route: '/patient',
            ),
            const SizedBox(height: 10),

            // Doctor
            _roleOption(
              ctx,
              name: 'Dr. Priya Mehta',
              role: 'Doctor (OPD Queue Control & Rx)',
              icon: Icons.medical_services_rounded,
              color: AppColors.secondary,
              email: 'doctor@hospital.com',
              route: '/doctor',
            ),
            const SizedBox(height: 10),

            // Admin
            _roleOption(
              ctx,
              name: 'Ravi Krishnan',
              role: 'Hospital Admin (Live Command Center)',
              icon: Icons.admin_panel_settings_rounded,
              color: AppColors.accent,
              email: 'admin@hospital.com',
              route: '/admin',
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(
    BuildContext ctx, {
    required String name,
    required String role,
    required IconData icon,
    required Color color,
    required String email,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        Navigator.pop(ctx);
        final success = await ref.read(authNotifierProvider.notifier).login(email, 'password123');
        if (success && mounted) {
          context.go(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  Text(role, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
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
            tooltip: 'Switch Demo Role',
            icon: const Icon(Icons.switch_account_rounded),
            onPressed: () => _showRoleSwitcher(context),
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
                  child: const Text(
                    'AS',
                    style: TextStyle(
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
                      Text(
                        user?.name ?? 'Arjun Sharma',
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
                        user?.email ?? 'patient@hospital.com',
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

          // Demo Mode Persona Switcher Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.swap_calls_rounded, color: AppColors.primary),
            label: const Text('Switch Persona / Test Role', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => _showRoleSwitcher(context),
          ),
          const SizedBox(height: 12),

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
