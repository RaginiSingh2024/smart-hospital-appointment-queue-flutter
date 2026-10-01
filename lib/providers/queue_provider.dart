import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/queue.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';
import '../models/notification_model.dart';

// ─── Queue Providers ──────────────────────────────────────────────────────

final todayDateProvider = Provider<String>((ref) {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
});

final doctorQueueProvider = FutureProvider<DoctorQueue?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final doctorFuture = ref.watch(doctorByUserIdForQueueProvider.future);
  final doctor = await doctorFuture;
  if (doctor == null) return null;

  final today = ref.watch(todayDateProvider);
  return ref.watch(queueRepositoryProvider).getDoctorQueue(doctor.id, today);
});

final doctorByUserIdForQueueProvider = FutureProvider<dynamic>((ref) async {
  final user = ref.watch(currentUserProvider);
  print('🔥 DOCTOR DASHBOARD: Doctor lookup start for user ID: ${user?.id}');
  if (user == null) {
    print('🔥 DOCTOR DASHBOARD: User is null');
    return null;
  }
  final doctor = await ref.watch(doctorRepositoryProvider).getDoctorByUserId(user.id);
  print('🔥 DOCTOR DASHBOARD: Doctor lookup result: ${doctor?.id} - ${doctor?.name}');
  return doctor;
});

// Stream-based provider — accepts a doctorId String directly.
// Resolves today's date internally so callers only need to pass the doctorId.
final doctorQueueStreamProvider = StreamProvider.family<DoctorQueue, String>(
    (ref, doctorId) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  print('[DOCTOR] QUEUE PROVIDER: doctorId=$doctorId, date=$today');
  final stream = ref.watch(queueRepositoryProvider).watchDoctorQueue(doctorId, today);
  print('[DOCTOR] QUEUE PROVIDER: Stream obtained, starting to listen');
  int emitCount = 0;
  return stream.map((queue) {
    emitCount++;
    print('[DOCTOR] QUEUE PROVIDER: Data emitted #$emitCount - waitingCount=${queue.waitingPatients}');
    return queue;
  }).handleError((error) {
    print('[DOCTOR] QUEUE PROVIDER ERROR: $error');
  });
});

final patientQueueStreamProvider = StreamProvider<QueueModel?>((ref) {
  final patient = ref.watch(currentPatientProvider);
  if (patient == null) return const Stream.empty();
  final today = ref.watch(todayDateProvider);
  return ref.watch(queueRepositoryProvider).watchPatientQueue(patient.id, today);
});

// ─── Queue Notifier ───────────────────────────────────────────────────────

class QueueNotifier extends StateNotifier<AsyncValue<DoctorQueue?>> {
  final Ref _ref;
  String? _doctorId;

  QueueNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> loadQueue(String doctorId, String date) async {
    _doctorId = doctorId;
    state = const AsyncValue.loading();
    try {
      final queue = await _ref.read(queueRepositoryProvider).getDoctorQueue(doctorId, date);
      state = AsyncValue.data(queue);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> callNextPatient(String date) async {
    if (_doctorId == null) return;
    try {
      await _ref.read(queueRepositoryProvider).callNextPatient(_doctorId!, date);
      // Reload queue
      final queue = await _ref.read(queueRepositoryProvider).getDoctorQueue(_doctorId!, date);
      state = AsyncValue.data(queue);

      // Notify waiting patients
      final queueData = queue;
      // Notifications are created via repository when needed
      print('[QUEUE] Notified ${queueData.waitingQueue.length} waiting patients');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> skipToken(String queueId, String date) async {
    if (_doctorId == null) return;
    try {
      await _ref.read(queueRepositoryProvider).skipToken(_doctorId!, queueId);
      final queue = await _ref.read(queueRepositoryProvider).getDoctorQueue(_doctorId!, date);
      state = AsyncValue.data(queue);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final queueNotifierProvider =
    StateNotifierProvider<QueueNotifier, AsyncValue<DoctorQueue?>>((ref) {
  return QueueNotifier(ref);
});

// Patient's own queue position
final patientQueuePositionProvider = FutureProvider.family<QueueModel?, String>(
    (ref, appointmentId) async {
  final patient = ref.watch(currentPatientProvider);
  if (patient == null) return null;
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.watch(queueRepositoryProvider).getPatientQueue(patient.id, today);
});
