import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remote/firebase_auth_repository.dart';
import '../data/remote/firestore_doctor_repository.dart';
import '../data/remote/firestore_appointment_repository.dart';
import '../data/remote/firestore_queue_repository.dart';
import '../data/remote/firestore_notification_repository.dart';
import '../data/remote/firestore_consultation_repository.dart';
import '../data/remote/firestore_department_repository.dart';
import '../data/remote/api_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/consultation_repository.dart';
import '../repositories/department_repository.dart';

// ─── Repository Providers ─────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return FirestoreDoctorRepository();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return FirestoreAppointmentRepository();
});

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  return FirestoreQueueRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});

final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return FirestoreConsultationRepository();
});

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  return FirestoreDepartmentRepository();
});

final apiServiceProvider = Provider.family<ApiService, String>((ref, baseUrl) {
  return ApiService(baseUrl: baseUrl);
});
