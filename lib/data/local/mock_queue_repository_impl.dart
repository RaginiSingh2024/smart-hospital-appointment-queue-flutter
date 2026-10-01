import 'dart:async';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/queue.dart';
import '../../repositories/queue_repository.dart';
import '../mock/mock_data.dart';

class MockQueueRepository implements QueueRepository {
  final Map<String, List<QueueModel>> _queues = {};
  final Map<String, BehaviorSubject<DoctorQueue>> _queueControllers = {};
  final Map<String, StreamController<QueueModel?>> _patientControllers = {};

  MockQueueRepository() {
    _initializeDemoQueue();
  }

  void _initializeDemoQueue() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrow = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().add(const Duration(days: 1)));

    _queues['doc_001_$today'] = MockData.getDoctorQueue('doc_001', today);
    _queues['doc_001_$tomorrow'] = MockData.getDoctorQueue('doc_001', tomorrow);
    // Initialize queue for Firebase doctor
    _queues['doc_firebase_001_$today'] = []; // Empty queue for new doctor
    _queues['doc_firebase_001_$tomorrow'] = [];
  }

  String _key(String doctorId, String date) => '${doctorId}_$date';

  @override
  Future<QueueModel?> getPatientQueue(String patientId, String date) async {
    await Future.delayed(const Duration(milliseconds: 400));

    for (final queue in _queues.values) {
      final entry = queue.where((q) => q.patientId == patientId && q.date == date).firstOrNull;
      if (entry != null) return entry;
    }
    return null;
  }

  @override
  Future<DoctorQueue> getDoctorQueue(String doctorId, String date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _buildDoctorQueue(doctorId, date);
  }

  DoctorQueue _buildDoctorQueue(String doctorId, String date) {
    final key = _key(doctorId, date);
    final queue = _queues[key] ?? [];

    final current = queue.where((q) => q.status == QueueStatus.inProgress).firstOrNull;
    final waiting = queue.where((q) => q.status == QueueStatus.waiting).toList()
      ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));
    final completed = queue.where((q) => q.status == QueueStatus.completed).length;

    final doctor = MockData.doctors.where((d) => d.id == doctorId).firstOrNull;

    return DoctorQueue(
      doctorId: doctorId,
      doctorName: doctor?.name ?? 'Doctor',
      date: date,
      currentTokenNumber: current?.tokenNumber ?? (queue.isEmpty ? '-' : queue.last.tokenNumber),
      currentTokenSequence: current?.tokenSequence ?? 0,
      queue: queue,
      totalPatients: queue.length,
      completedPatients: completed,
      waitingPatients: waiting.length,
    );
  }

  @override
  Future<void> callNextPatient(String doctorId, String date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final key = _key(doctorId, date);
    final queue = _queues[key] ?? [];

    // Mark current patient as complete
    final currentIdx = queue.indexWhere((q) => q.status == QueueStatus.inProgress);
    if (currentIdx >= 0) {
      queue[currentIdx] = queue[currentIdx].copyWith(
        status: QueueStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    // Find next waiting patient
    final waitingQueue = queue
        .where((q) => q.status == QueueStatus.waiting)
        .toList()
      ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));

    if (waitingQueue.isNotEmpty) {
      final nextIdx = queue.indexWhere((q) => q.id == waitingQueue.first.id);
      if (nextIdx >= 0) {
        queue[nextIdx] = queue[nextIdx].copyWith(
          status: QueueStatus.inProgress,
          calledAt: DateTime.now(),
        );
      }
    }

    // Update waiting times
    _updateWaitingTimes(queue);
    _queues[key] = queue;
    _notifyDoctorQueueChange(doctorId, date);
  }

  void _updateWaitingTimes(List<QueueModel> queue) {
    final waiting = queue
        .where((q) => q.status == QueueStatus.waiting)
        .toList()
      ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));

    for (int i = 0; i < waiting.length; i++) {
      final idx = queue.indexWhere((q) => q.id == waiting[i].id);
      if (idx >= 0) {
        queue[idx] = queue[idx].copyWith(
          patientsAhead: i,
          estimatedWaitMinutes: i * 15,
        );
      }
    }
  }

  void _notifyDoctorQueueChange(String doctorId, String date) {
    final key = _key(doctorId, date);
    final controller = _queueControllers[key];
    if (controller != null && !controller.isClosed) {
      controller.add(_buildDoctorQueue(doctorId, date));
    }

    // Also update patient-specific streams
    final queue = _queues[key] ?? [];
    for (final queueItem in queue) {
      final patientController = _patientControllers[queueItem.patientId];
      if (patientController != null && !patientController.isClosed) {
        patientController.add(queueItem);
      }
    }
  }

  @override
  Future<void> skipToken(String doctorId, String queueId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = _key(doctorId, date);
    final queue = _queues[key] ?? [];

    final idx = queue.indexWhere((q) => q.id == queueId);
    if (idx >= 0) {
      queue[idx] = queue[idx].copyWith(status: QueueStatus.skipped);
    }

    _updateWaitingTimes(queue);
    _queues[key] = queue;
    _notifyDoctorQueueChange(doctorId, date);
  }

  @override
  Future<void> markComplete(String doctorId, String queueId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = _key(doctorId, date);
    final queue = _queues[key] ?? [];

    final idx = queue.indexWhere((q) => q.id == queueId);
    if (idx >= 0) {
      queue[idx] = queue[idx].copyWith(
        status: QueueStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    _queues[key] = queue;
    _notifyDoctorQueueChange(doctorId, date);
  }

  @override
  Future<void> checkInPatient(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // In a real app, this would update the queue to mark the patient as arrived
    for (final queue in _queues.values) {
      final idx = queue.indexWhere((q) => q.appointmentId == appointmentId);
      if (idx >= 0) {
        queue[idx] = queue[idx].copyWith(status: QueueStatus.waiting);
      }
    }
  }

  @override
  Future<void> addToQueue({
    required String doctorId,
    required String date,
    required QueueModel queueModel,
  }) async {
    final key = _key(doctorId, date);
    _queues[key] ??= [];
    _queues[key]!.add(queueModel);
    _notifyDoctorQueueChange(doctorId, date);
  }

  @override
  Stream<DoctorQueue> watchDoctorQueue(String doctorId, String date) {
    final key = _key(doctorId, date);
    print('[DOCTOR] QUEUE REPO: watchDoctorQueue called for doctorId=$doctorId, date=$date, key=$key');
    _queueControllers[key] ??= BehaviorSubject<DoctorQueue>();
    // Add initial value to BehaviorSubject
    final initialQueue = _buildDoctorQueue(doctorId, date);
    print('[DOCTOR] QUEUE REPO: Built initial queue with ${initialQueue.waitingPatients} waiting patients');
    _queueControllers[key]!.add(initialQueue);
    print('[DOCTOR] QUEUE REPO: Initial queue data added to BehaviorSubject');
    return _queueControllers[key]!.stream;
  }

  @override
  Stream<QueueModel?> watchPatientQueue(String patientId, String date) {
    _patientControllers[patientId] ??= StreamController<QueueModel?>.broadcast();
    return _patientControllers[patientId]!.stream;
  }

  void dispose() {
    for (final c in _queueControllers.values) {
      c.close();
    }
    for (final c in _patientControllers.values) {
      c.close();
    }
  }
}
