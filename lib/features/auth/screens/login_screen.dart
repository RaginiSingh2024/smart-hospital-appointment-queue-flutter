import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialRegistration;

  const LoginScreen({super.key, this.initialRegistration = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late bool _isRegistering;
  bool _registrationComplete = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isRegistering = widget.initialRegistration;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

        final success = await ref.read(authProvider.notifier).signInForRole(
          _emailController.text.trim(),
          _passwordController.text,
          UserRole.patient,
        );

    if (!mounted) return;

    if (success) context.go('/patient');
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔥 RegisterPatient button clicked');
    print('🔥 Email: ${_emailController.text.trim()}');
    print('🔥 First Name: ${_firstNameController.text.trim()}');
    print('🔥 Last Name: ${_lastNameController.text.trim()}');

    final success = await ref.read(authProvider.notifier).registerPatient(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );

    print('🔥 Registration success: $success');
    if (!mounted || !success) return;
    setState(() => _registrationComplete = true);
  }

  void _toggleRegistration() {
    print('🔥 _toggleRegistration called, _isRegistering: $_isRegistering');
    if (_isRegistering) {
      print('🔥 Navigating to /login');
      context.go('/login');
      return;
    }
    print('🔥 Navigating to /patient-register');
    context.go('/patient-register');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(authProvider.notifier).clearError();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              height: size.height * 0.34,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'MediQueue',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart Hospital Queue Management',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart Healthcare. Smarter Queues.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Login Form
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
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
                        const SizedBox(height: 8),
                        Text(
                          _isRegistering ? 'Create Patient Account' : 'Welcome Back',
                          style: AppTextStyles.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRegistering
                              ? 'Create your secure MediQueue patient account'
                              : 'Sign in to access your healthcare portal',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),

                        if (_registrationComplete) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Account created successfully!',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: 'Continue to Patient Login',
                            onPressed: () => context.go('/login'),
                          ),
                        ] else ...[
                        if (_isRegistering) ...[
                          AppTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            hint: 'Enter your first name',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            hint: 'Enter your last name',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Invalid email';
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
                            onSubmitted: (_) =>
                              _isRegistering ? _registerPatient() : _signIn(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm password',
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_reset_outlined,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.next,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _phoneController,
                            label: 'Phone number (optional)',
                            hint: 'Enter your phone number',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                        const SizedBox(height: 28),

                        AppButton(
                          label: _isRegistering ? 'Create Account' : 'Sign In',
                          onPressed: authState.isLoading
                              ? null
                              : (_isRegistering ? _registerPatient : _signIn),
                          isLoading: authState.isLoading,
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: TextButton(
                            onPressed: authState.isLoading
                                ? null
                                : _toggleRegistration,
                            child: Text(
                              _isRegistering
                                  ? 'Already have an account? Sign In'
                                  : 'Create Patient Account',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!_isRegistering) ...[
                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 14),
                          Text('Staff Login', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    print('🔥 Doctor Login button clicked');
                                    context.go('/doctor-login');
                                  },
                                  icon: const Icon(Icons.medical_services_outlined),
                                  label: const Text('Doctor Login'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    print('🔥 Admin Login button clicked');
                                    context.go('/admin-login');
                                  },
                                  icon: const Icon(Icons.admin_panel_settings_outlined),
                                  label: const Text('Admin Login'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        ],
                            ],
                          ),
                        ),
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
