import '../../models/user.dart';
import '../../models/patient.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<UserModel?> registerPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone,
  });
  Future<void> signOut();
  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  });
  UserModel? get currentUser;
  PatientModel? get currentPatient;
  Stream<UserModel?> get authStateChanges;
}
