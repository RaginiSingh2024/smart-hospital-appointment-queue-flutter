import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

class DoctorLoginScreen extends StatelessWidget {
  const DoctorLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffLoginScreen(
      role: UserRole.doctor,
      title: 'Doctor Login',
      emailLabel: 'Doctor Email',
      icon: Icons.medical_services_outlined,
    );
  }
}

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffLoginScreen(
      role: UserRole.admin,
      title: 'Admin Login',
      emailLabel: 'Admin Email',
      icon: Icons.admin_panel_settings_outlined,
    );
  }
}

class StaffLoginScreen extends ConsumerStatefulWidget {
  final UserRole role;
  final String title;
  final String emailLabel;
  final IconData icon;

  const StaffLoginScreen({
    required this.role,
    required this.title,
    required this.emailLabel,
    required this.icon,
    super.key,
  });

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔥 ${widget.role.toString().toUpperCase()} LOGIN START');
    print('🔥 Email: ${_emailController.text.trim()}');
    print('🔥 Expected role: ${widget.role}');

    final success = await ref.read(authProvider.notifier).signInForRole(
          _emailController.text.trim(),
          _passwordController.text,
          widget.role,
        );
    if (!mounted || !success) return;

    print('🔥 ${widget.role.toString().toUpperCase()} LOGIN SUCCESS - Navigating to dashboard');
    context.go(widget.role == UserRole.doctor ? '/doctor' : '/admin');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final roleName = widget.role == UserRole.doctor ? 'doctor' : 'administrator';

    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.34,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 58),
                    const SizedBox(height: 12),
                    Text(
                      'MediQueue',
                      style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: AppTextStyles.displaySmall),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in with your provisioned $roleName account',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 28),
                          AppTextField(
                            controller: _emailController,
                            label: widget.emailLabel,
                            hint: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _signIn(),
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          AppButton(
                            label: 'Sign In',
                            onPressed: authState.isLoading ? null : _signIn,
                            isLoading: authState.isLoading,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => context.go('/login'),
                              child: const Text('Back to Patient Login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
