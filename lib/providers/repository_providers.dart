import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/mock_auth_repository_impl.dart';
import '../data/local/mock_doctor_repository_impl.dart';
import '../data/local/mock_appointment_repository_impl.dart';
import '../data/local/mock_queue_repository_impl.dart';
import '../data/local/mock_notification_repository_impl.dart';
import '../repositories/auth_repository.dart';
import '../repositories/doctor_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/notification_repository.dart';

// ─── Repository Providers ─────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = MockAuthRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return MockDoctorRepository();
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return MockAppointmentRepository();
});

final queueRepositoryProvider = Provider<QueueRepository>((ref) {
  final repo = MockQueueRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repo = MockNotificationRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Convenience cast providers for implementation-specific methods
final mockQueueRepositoryProvider = Provider<MockQueueRepository>((ref) {
  return ref.watch(queueRepositoryProvider) as MockQueueRepository;
});

final mockNotificationRepositoryProvider = Provider<MockNotificationRepository>((ref) {
  return ref.watch(notificationRepositoryProvider) as MockNotificationRepository;
});

final mockAppointmentRepositoryProvider = Provider<MockAppointmentRepository>((ref) {
  return ref.watch(appointmentRepositoryProvider) as MockAppointmentRepository;
});
