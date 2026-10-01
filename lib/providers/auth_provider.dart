import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/patient.dart';
import 'repository_providers.dart';

class AuthState {
  final UserModel? user;
  final PatientModel? patient;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.patient,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  UserRole? get role => user?.role;

  AuthState copyWith({
    UserModel? user,
    PatientModel? patient,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      patient: clearUser ? null : (patient ?? this.patient),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<UserModel?>? _authStateSubscription;

  AuthNotifier(this._ref) : super(const AuthState(isLoading: true)) {
    final repository = _ref.read(authRepositoryProvider);
    _authStateSubscription = repository.authStateChanges.listen(
      (user) {
        state = AuthState(
          user: user,
          patient: repository.currentPatient,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AuthState(error: _errorMessage(error));
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signIn(email, password);
      if (user != null) {
        final patient = _ref.read(authRepositoryProvider).currentPatient;
        state = AuthState(user: user, patient: patient, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Sign in failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  Future<bool> registerPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _ref.read(authRepositoryProvider).registerPatient(
        firstName: firstName,
        lastName: lastName,
            email: email,
            password: password,
            phone: phone,
          );
      if (user != null) {
        await _ref.read(authRepositoryProvider).signOut();
        state = const AuthState();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create your patient account.',
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _errorMessage(error),
      );
      return false;
    }
  }

  Future<bool> signInForRole(
    String email,
    String password,
    UserRole expectedRole,
  ) async {
    final success = await signIn(email, password);
    if (!success) return false;

    final actualRole = state.role;
    if (actualRole == expectedRole) return true;

    await signOut();
    state = AuthState(
      error: expectedRole == UserRole.patient
          ? 'Unauthorized. This account is not registered as a patient.'
          : expectedRole == UserRole.doctor
              ? 'Access denied. This account is not registered as a doctor.'
              : 'Access denied. This account is not registered as an administrator.',
    );
    return false;
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = state.user?.id;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'No user logged in');
        return false;
      }

      final updatedUser = await _ref.read(authRepositoryProvider).updateProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      if (updatedUser != null) {
        state = state.copyWith(user: updatedUser, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to update profile');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  Future<bool> login(String email, String password) => signIn(email, password);

  Future<void> logout() => signOut();

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  static String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final authNotifierProvider = authProvider;

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final currentPatientProvider = Provider<PatientModel?>((ref) {
  return ref.watch(authProvider).patient;
});
