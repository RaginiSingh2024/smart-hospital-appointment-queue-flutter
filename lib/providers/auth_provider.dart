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

  AuthNotifier(this._ref) : super(const AuthState());

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
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> login(String email, String password) => signIn(email, password);

  Future<void> logout() => signOut();

  void clearError() {
    state = state.copyWith(clearError: true);
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
