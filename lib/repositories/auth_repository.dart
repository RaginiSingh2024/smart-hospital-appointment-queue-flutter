import '../../models/user.dart';
import '../../models/patient.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel> updateUser(UserModel user);
  Future<PatientModel> updatePatient(PatientModel patient);
  UserModel? get currentUser;
  PatientModel? get currentPatient;
  Stream<UserModel?> get authStateChanges;
}
