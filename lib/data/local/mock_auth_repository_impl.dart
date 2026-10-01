import 'dart:async';
import '../../models/user.dart';
import '../../models/patient.dart';
import '../../repositories/auth_repository.dart';
import '../mock/mock_data.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  PatientModel? _currentPatient;
  final _authController = StreamController<UserModel?>.broadcast();

  @override
  UserModel? get currentUser => _currentUser;

  @override
  PatientModel? get currentPatient => _currentPatient;

  @override
  Stream<UserModel?> get authStateChanges => _authController.stream;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final account = MockData.demoAccounts.where(
      (a) => a['email'] == email.toLowerCase().trim() && a['password'] == password,
    ).firstOrNull;

    if (account == null) {
      throw Exception('Invalid email or password. Please check your credentials.');
    }

    final user = MockData.users.where((u) => u.email == email.toLowerCase().trim()).firstOrNull;

    if (user == null) {
      throw Exception('User account not found.');
    }

    _currentUser = user;

    if (user.role == UserRole.patient) {
      _currentPatient = MockData.patients.where((p) => p.userId == user.id).firstOrNull;
    }

    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel?> registerPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    throw UnsupportedError('Mock registration is not available.');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _currentPatient = null;
    _authController.add(null);
  }

  @override
  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser?.id == userId) {
      final updatedUser = _currentUser!.copyWith(
        name: firstName != null && lastName != null
            ? '$firstName $lastName'
            : _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      );
      _currentUser = updatedUser;
      _authController.add(_currentUser);
      return _currentUser;
    }
    return _currentUser;
  }

  void dispose() {
    _authController.close();
  }
}
