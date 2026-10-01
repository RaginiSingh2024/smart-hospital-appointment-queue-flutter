import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/patient.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserModel? _currentUser;
  PatientModel? _currentPatient;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  PatientModel? get currentPatient => _currentPatient;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap(_loadUserProfile);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      print('🔥 PATIENT LOGIN START');
      print('🔥 Email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('🔥 AUTH SUCCESS: Firebase Auth succeeded for UID: ${credential.user?.uid}');
      print('🔥 FIRESTORE READ START: Reading user profile for UID: ${credential.user?.uid}');
      final user = await _loadUserProfile(credential.user);
      print('🔥 ROLE VALUE: ${user?.role}');
      print('🔥 PATIENT LOGIN COMPLETE');
      return user;
    } on FirebaseAuthException catch (error) {
      print('🔥 AUTH ERROR CODE: ${error.code}');
      print('🔥 AUTH ERROR MESSAGE: ${error.message}');
      throw Exception(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      print('🔥 FIRESTORE ERROR CODE: ${error.code}');
      print('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
      throw Exception('Unable to load your account profile: ${error.message ?? error.code}');
    }
  }

  @override
  Future<UserModel?> registerPatient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    UserCredential? credential;
    try {
      print('🔥 Starting patient registration for: $email');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('🔥 AUTH SUCCESS: Firebase Auth user created: ${credential.user?.uid}');

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Unable to create your account. Please try again.');
      }

      print('🔥 FIRESTORE CREATE START: Creating Firestore document for user: ${firebaseUser.uid}');
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'name': '${firstName.trim()} ${lastName.trim()}'.trim(),
        'email': email.trim(),
        'role': 'patient',
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      print('🔥 FIRESTORE CREATE SUCCESS: Firestore document created successfully');

      return await _loadUserProfile(firebaseUser);
    } on FirebaseAuthException catch (error) {
      print('🔥 AUTH ERROR CODE: ${error.code}');
      print('🔥 AUTH ERROR MESSAGE: ${error.message}');
      throw Exception(_authErrorMessage(error, isRegistration: true));
    } on FirebaseException catch (error) {
      print('🔥 FIRESTORE ERROR CODE: ${error.code}');
      print('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
      if (credential?.user != null) {
        await _auth.signOut();
      }
      String errorMsg = error.message ?? error.code;
      if (error.code == 'permission-denied') {
        errorMsg = 'Firestore permission denied. Please update Firestore security rules in Firebase Console to allow authenticated users to create their user document.';
      }
      throw Exception('Your account could not be completed: $errorMsg');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _currentPatient = null;
  }

  @override
  Future<UserModel?> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      print('🔥 Updating profile for user: $userId');
      final updates = <String, dynamic>{};
      
      if (firstName != null) updates['firstName'] = firstName.trim();
      if (lastName != null) updates['lastName'] = lastName.trim();
      if (firstName != null && lastName != null) {
        updates['name'] = '${firstName.trim()} ${lastName.trim()}'.trim();
      }
      if (phone != null) updates['phone'] = phone.trim();
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updates);
      print('🔥 Profile updated successfully');

      // Reload user profile
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        return await _loadUserProfile(firebaseUser);
      }
      return _currentUser;
    } on FirebaseException catch (error) {
      print('🔥 FIRESTORE ERROR CODE: ${error.code}');
      print('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
      throw Exception('Unable to update your profile: ${error.message ?? error.code}');
    }
  }

  Future<UserModel?> _loadUserProfile(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _currentPatient = null;
      return null;
    }

    try {
      print('🔥 FIRESTORE READ START: Reading user document: ${firebaseUser.uid}');
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        print('🔥 FIRESTORE READ ERROR: User document not found in Firestore');
        throw Exception(
          'Your account is authenticated, but no user profile was found. '
          'Please contact an administrator.',
        );
      }

      final data = snapshot.data()!;
      print('🔥 FIRESTORE READ SUCCESS: Data retrieved, role field: ${data['role']}');
      final role = _parseRole(data['role']);
      print('🔥 PARSED ROLE: $role');
      final user = UserModel(
        id: firebaseUser.uid,
        name: _stringValue(data['name']) ?? firebaseUser.displayName ?? '',
        email: _stringValue(data['email']) ?? firebaseUser.email ?? '',
        phone: _stringValue(data['phone']) ?? '',
        role: role,
        profileImageUrl: _stringValue(data['profileImageUrl']),
        createdAt: _dateTimeValue(data['createdAt']) ??
            firebaseUser.metadata.creationTime ??
            DateTime.now(),
        isActive: data['isActive'] as bool? ?? true,
      );

      if (!user.isActive) {
        throw Exception('This user account is inactive. Please contact an administrator.');
      }

      _currentUser = user;
      _currentPatient = null;
      return user;
    } on FirebaseException catch (error) {
      print('🔥 FIRESTORE ERROR CODE: ${error.code}');
      print('🔥 FIRESTORE ERROR MESSAGE: ${error.message}');
      throw Exception('Unable to load your account profile: ${error.message ?? error.code}');
    }
  }

  UserRole _parseRole(Object? value) {
    final role = value?.toString().toLowerCase();
    switch (role) {
      case 'patient':
        return UserRole.patient;
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        throw Exception(
          'Your user profile has no valid role. Please contact an administrator.',
        );
    }
  }

  String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  DateTime? _dateTimeValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _authErrorMessage(
    FirebaseAuthException error, {
    bool isRegistration = false,
  }) {
    print('🔥 Firebase Auth Error: ${error.code} - ${error.message}');
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password. Please check your credentials.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact an administrator.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return '${error.message ?? error.code} (Code: ${error.code})';
    }
  }
}
