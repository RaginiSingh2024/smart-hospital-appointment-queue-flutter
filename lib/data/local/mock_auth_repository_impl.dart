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
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.toLowerCase().trim();

    final account = MockData.demoAccounts.where(
      (a) => a['email']!.toLowerCase() == cleanEmail && a['password'] == password,
    ).firstOrNull;

    UserModel? user;
    if (account != null) {
      user = MockData.users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;
    } else {
      // Check existing users
      user = MockData.users.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;
    }

    // Dynamic role fallback if not pre-seeded
    if (user == null) {
      if (cleanEmail.contains('dr@') || cleanEmail.contains('doctor')) {
        user = UserModel(
          id: 'user_doc_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Doctor',
          email: cleanEmail,
          phone: '+91 9876543221',
          role: UserRole.doctor,
          createdAt: DateTime.now(),
        );
        MockData.users.add(user);
      } else if (cleanEmail.contains('admin')) {
        user = UserModel(
          id: 'user_admin_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Admin',
          email: cleanEmail,
          phone: '+91 9876543230',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );
        MockData.users.add(user);
      } else {
        user = UserModel(
          id: 'user_pat_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Patient',
          email: cleanEmail,
          phone: '+91 9876543210',
          role: UserRole.patient,
          createdAt: DateTime.now(),
        );
        MockData.users.add(user);
      }
    }

    _currentUser = user;

    if (user.role == UserRole.patient) {
      _currentPatient = MockData.patients.where((p) => p.userId == user!.id || p.email.toLowerCase() == cleanEmail).firstOrNull;
      if (_currentPatient == null) {
        _currentPatient = PatientModel(
          id: 'pat_${user.id}',
          userId: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          dateOfBirth: DateTime(1995, 1, 1),
          bloodGroup: 'O+',
          address: 'Hospital Patient Address',
        );
        MockData.patients.add(_currentPatient!);
      }
    }

    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = MockData.users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      MockData.users[idx] = user;
    } else {
      MockData.users.add(user);
    }
    _currentUser = user;
    _authController.add(_currentUser);
    return user;
  }

  @override
  Future<PatientModel> updatePatient(PatientModel patient) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = MockData.patients.indexWhere((p) => p.id == patient.id);
    if (idx >= 0) {
      MockData.patients[idx] = patient;
    } else {
      MockData.patients.add(patient);
    }
    _currentPatient = patient;
    return patient;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _currentPatient = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
