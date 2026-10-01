import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/queue.dart';
import '../../repositories/queue_repository.dart';

class FirestoreQueueRepository implements QueueRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreQueueRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String _queueDocId(String doctorId, String date) => '${doctorId}_$date';

  @override
  Future<QueueModel?> getPatientQueue(String patientId, String date) async {
    print('[FIRESTORE QUEUE] Getting queue for patient: $patientId, date: $date');
    try {
      // Get all queue documents for the date
      final snapshot = await _firestore
          .collection('queues')
          .where('date', isEqualTo: date)
          .get();

      for (final doc in snapshot.docs) {
        final queueItems = doc.data()['queueItems'] as List<dynamic>? ?? [];
        for (final item in queueItems) {
          if (item['patientId'] == patientId) {
            return _queueItemFromMap(item);
          }
        }
      }

      print('[FIRESTORE QUEUE] No queue found for patient');
      return null;
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error getting patient queue: ${e.code} - ${e.message}');
      throw Exception('Failed to load queue: ${e.message}');
    }
  }

  @override
  Future<DoctorQueue> getDoctorQueue(String doctorId, String date) async {
    print('[FIRESTORE QUEUE] Getting queue for doctor: $doctorId, date: $date');
    try {
      final docId = _queueDocId(doctorId, date);
      final doc = await _firestore.collection('queues').doc(docId).get();

      if (!doc.exists) {
        print('[FIRESTORE QUEUE] Queue document not found, creating empty queue');
        return _createEmptyDoctorQueue(doctorId, date);
      }

      return _doctorQueueFromFirestore(doc, doctorId, date);
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error getting doctor queue: ${e.code} - ${e.message}');
      throw Exception('Failed to load queue: ${e.message}');
    }
  }

  @override
  Future<void> callNextPatient(String doctorId, String date) async {
    print('[FIRESTORE QUEUE] Calling next patient for doctor: $doctorId, date: $date');
    try {
      final docId = _queueDocId(doctorId, date);
      final docRef = _firestore.collection('queues').doc(docId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Queue not found');
        }

        final data = snapshot.data()!;
        final queueItems = List<Map<String, dynamic>>.from(
          (data['queueItems'] as List).map((e) => e as Map<String, dynamic>)
        );

        // Mark current in-progress as completed
        final currentIdx = queueItems.indexWhere((q) => q['status'] == 'inProgress');
        if (currentIdx >= 0) {
          queueItems[currentIdx]['status'] = 'completed';
          queueItems[currentIdx]['completedAt'] = FieldValue.serverTimestamp();
        }

        // Find next waiting patient
        final waitingIdx = queueItems.indexWhere((q) => q['status'] == 'waiting');
        if (waitingIdx >= 0) {
          queueItems[waitingIdx]['status'] = 'inProgress';
          queueItems[waitingIdx]['calledAt'] = FieldValue.serverTimestamp();
        }

        // Update waiting times
        _updateWaitingTimes(queueItems);

        transaction.update(docRef, {
          'queueItems': queueItems,
          'currentTokenSequence': _calculateCurrentTokenSequence(queueItems),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('[FIRESTORE QUEUE] Next patient called successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error calling next patient: ${e.code} - ${e.message}');
      throw Exception('Failed to call next patient: ${e.message}');
    }
  }

  @override
  Future<void> skipToken(String doctorId, String queueId) async {
    print('[FIRESTORE QUEUE] Skipping token: $queueId for doctor: $doctorId');
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docId = _queueDocId(doctorId, date);
      final docRef = _firestore.collection('queues').doc(docId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final queueItems = List<Map<String, dynamic>>.from(
          (data['queueItems'] as List).map((e) => e as Map<String, dynamic>)
        );

        final idx = queueItems.indexWhere((q) => q['id'] == queueId);
        if (idx >= 0) {
          queueItems[idx]['status'] = 'skipped';
          _updateWaitingTimes(queueItems);
          transaction.update(docRef, {
            'queueItems': queueItems,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('[FIRESTORE QUEUE] Token skipped successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error skipping token: ${e.code} - ${e.message}');
      throw Exception('Failed to skip token: ${e.message}');
    }
  }

  @override
  Future<void> markComplete(String doctorId, String queueId) async {
    print('[FIRESTORE QUEUE] Marking complete: $queueId for doctor: $doctorId');
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final docId = _queueDocId(doctorId, date);
      final docRef = _firestore.collection('queues').doc(docId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final queueItems = List<Map<String, dynamic>>.from(
          (data['queueItems'] as List).map((e) => e as Map<String, dynamic>)
        );

        final idx = queueItems.indexWhere((q) => q['id'] == queueId);
        if (idx >= 0) {
          queueItems[idx]['status'] = 'completed';
          queueItems[idx]['completedAt'] = FieldValue.serverTimestamp();
          _updateWaitingTimes(queueItems);
          transaction.update(docRef, {
            'queueItems': queueItems,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('[FIRESTORE QUEUE] Marked complete successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error marking complete: ${e.code} - ${e.message}');
      throw Exception('Failed to mark complete: ${e.message}');
    }
  }

  @override
  Future<void> checkInPatient(String appointmentId) async {
    print('[FIRESTORE QUEUE] Checking in patient for appointment: $appointmentId');
    try {
      // Find the queue item by appointmentId and update status to waiting
      final snapshot = await _firestore
          .collection('queues')
          .where('queueItems', arrayContains: {'appointmentId': appointmentId})
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final queueItems = List<Map<String, dynamic>>.from(
          (data['queueItems'] as List).map((e) => e as Map<String, dynamic>)
        );

        final idx = queueItems.indexWhere((q) => q['appointmentId'] == appointmentId);
        if (idx >= 0) {
          queueItems[idx]['status'] = 'waiting';
          queueItems[idx]['checkedInAt'] = FieldValue.serverTimestamp();
          _updateWaitingTimes(queueItems);

          await _firestore.collection('queues').doc(doc.id).update({
            'queueItems': queueItems,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;
        }
      }

      print('[FIRESTORE QUEUE] Patient checked in successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error checking in patient: ${e.code} - ${e.message}');
      throw Exception('Failed to check in patient: ${e.message}');
    }
  }

  @override
  Stream<DoctorQueue> watchDoctorQueue(String doctorId, String date) {
    print('[FIRESTORE QUEUE] Watching queue for doctor: $doctorId, date: $date');
    final docId = _queueDocId(doctorId, date);
    return _firestore
        .collection('queues')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return _createEmptyDoctorQueue(doctorId, date);
      }
      return _doctorQueueFromFirestore(snapshot, doctorId, date);
    });
  }

  @override
  Stream<QueueModel?> watchPatientQueue(String patientId, String date) {
    print('[FIRESTORE QUEUE] Watching queue for patient: $patientId, date: $date');
    return _firestore
        .collection('queues')
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      for (final doc in snapshot.docs) {
        final queueItems = doc.data()['queueItems'] as List<dynamic>? ?? [];
        for (final item in queueItems) {
          if (item['patientId'] == patientId) {
            return _queueItemFromMap(item);
          }
        }
      }
      return null;
    });
  }

  // Helper to add patient to queue when appointment is created
  Future<void> addToQueue({
    required String doctorId,
    required String date,
    required QueueModel queueModel,
  }) async {
    print('[FIRESTORE QUEUE] Adding to queue: doctorId=$doctorId, date=$date');
    try {
      final docId = _queueDocId(doctorId, date);
      final docRef = _firestore.collection('queues').doc(docId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        List<Map<String, dynamic>> queueItems = [];

        if (snapshot.exists) {
          final data = snapshot.data()!;
          queueItems = List<Map<String, dynamic>>.from(
            (data['queueItems'] as List).map((e) => e as Map<String, dynamic>)
          );
        }

        // Add new queue item
        queueItems.add(_queueItemToMap(queueModel));
        _updateWaitingTimes(queueItems);

        final doctorData = await _firestore.collection('doctors').doc(doctorId).get();
        final doctorName = doctorData.data()?['name'] ?? 'Doctor';

        if (snapshot.exists) {
          transaction.update(docRef, {
            'queueItems': queueItems,
            'totalPatients': queueItems.length,
            'currentTokenSequence': _calculateCurrentTokenSequence(queueItems),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'doctorId': doctorId,
            'doctorName': doctorName,
            'date': date,
            'queueItems': queueItems,
            'totalPatients': queueItems.length,
            'currentTokenSequence': _calculateCurrentTokenSequence(queueItems),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('[FIRESTORE QUEUE] Added to queue successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE QUEUE] Error adding to queue: ${e.code} - ${e.message}');
      throw Exception('Failed to add to queue: ${e.message}');
    }
  }

  DoctorQueue _createEmptyDoctorQueue(String doctorId, String date) {
    return DoctorQueue(
      doctorId: doctorId,
      doctorName: 'Doctor',
      date: date,
      currentTokenNumber: '-',
      currentTokenSequence: 0,
      queue: [],
      totalPatients: 0,
      completedPatients: 0,
      waitingPatients: 0,
    );
  }

  DoctorQueue _doctorQueueFromFirestore(
    DocumentSnapshot doc,
    String doctorId,
    String date,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final queueItemsData = data['queueItems'] as List<dynamic>? ?? [];
    final queueItems = queueItemsData
        .map((item) => _queueItemFromMap(item as Map<String, dynamic>))
        .toList();

    final current = queueItems.where((q) => q.status == QueueStatus.inProgress).firstOrNull;
    final waiting = queueItems.where((q) => q.status == QueueStatus.waiting).toList()
      ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));
    final completed = queueItems.where((q) => q.status == QueueStatus.completed).length;

    return DoctorQueue(
      doctorId: doctorId,
      doctorName: _stringValue(data['doctorName']) ?? 'Doctor',
      date: date,
      currentTokenNumber: current?.tokenNumber ?? '-',
      currentTokenSequence: current?.tokenSequence ?? 0,
      queue: queueItems,
      totalPatients: queueItems.length,
      completedPatients: completed,
      waitingPatients: waiting.length,
    );
  }

  QueueModel _queueItemFromMap(Map<String, dynamic> map) {
    return QueueModel(
      id: _stringValue(map['id']) ?? '',
      appointmentId: _stringValue(map['appointmentId']) ?? '',
      doctorId: _stringValue(map['doctorId']) ?? '',
      patientId: _stringValue(map['patientId']) ?? '',
      patientName: _stringValue(map['patientName']) ?? '',
      tokenNumber: _stringValue(map['tokenNumber']) ?? '',
      tokenSequence: _intValue(map['tokenSequence']) ?? 0,
      status: _parseQueueStatus(map['status']),
      patientsAhead: _intValue(map['patientsAhead']) ?? 0,
      estimatedWaitMinutes: _intValue(map['estimatedWaitMinutes']) ?? 0,
      calledAt: _timestampValue(map['calledAt']),
      completedAt: _timestampValue(map['completedAt']),
      avgConsultationMinutes: _intValue(map['avgConsultationMinutes']) ?? 15,
      date: _stringValue(map['date']) ?? '',
      isEmergency: map['isEmergency'] as bool? ?? false,
      checkedInAt: _timestampValue(map['checkedInAt']),
      queuePosition: _intValue(map['queuePosition']),
      notes: _stringValue(map['notes']),
    );
  }

  Map<String, dynamic> _queueItemToMap(QueueModel model) {
    return {
      'id': model.id,
      'appointmentId': model.appointmentId,
      'doctorId': model.doctorId,
      'patientId': model.patientId,
      'patientName': model.patientName,
      'tokenNumber': model.tokenNumber,
      'tokenSequence': model.tokenSequence,
      'status': model.status.name,
      'patientsAhead': model.patientsAhead,
      'estimatedWaitMinutes': model.estimatedWaitMinutes,
      'calledAt': model.calledAt != null ? Timestamp.fromDate(model.calledAt!) : null,
      'completedAt': model.completedAt != null ? Timestamp.fromDate(model.completedAt!) : null,
      'avgConsultationMinutes': model.avgConsultationMinutes,
      'date': model.date,
      'isEmergency': model.isEmergency,
      'checkedInAt': model.checkedInAt != null ? Timestamp.fromDate(model.checkedInAt!) : null,
      'queuePosition': model.queuePosition,
      'notes': model.notes,
    };
  }

  void _updateWaitingTimes(List<Map<String, dynamic>> queueItems) {
    final waiting = queueItems
        .where((q) => q['status'] == 'waiting')
        .toList()
      ..sort((a, b) => (a['tokenSequence'] as int).compareTo(b['tokenSequence'] as int));

    for (int i = 0; i < waiting.length; i++) {
      waiting[i]['patientsAhead'] = i;
      waiting[i]['estimatedWaitMinutes'] = i * 15;
      waiting[i]['queuePosition'] = i + 1;
    }
  }

  int _calculateCurrentTokenSequence(List<Map<String, dynamic>> queueItems) {
    final current = queueItems.where((q) => q['status'] == 'inProgress').firstOrNull;
    return current != null ? (current['tokenSequence'] as int) : 0;
  }

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _timestampValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  QueueStatus _parseQueueStatus(dynamic value) {
    final status = value?.toString().toLowerCase();
    switch (status) {
      case 'waiting':
        return QueueStatus.waiting;
      case 'called':
        return QueueStatus.called;
      case 'inprogress':
        return QueueStatus.inProgress;
      case 'completed':
        return QueueStatus.completed;
      case 'skipped':
        return QueueStatus.skipped;
      case 'noshow':
        return QueueStatus.noShow;
      default:
        return QueueStatus.waiting;
    }
  }
}
