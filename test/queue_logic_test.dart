import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_hospital_queue_flutter/data/local/mock_queue_repository_impl.dart';
import 'package:smart_hospital_queue_flutter/models/queue.dart';

void main() {
  group('MockQueueRepository & Queue Logic Tests', () {
    late MockQueueRepository queueRepo;
    const testDoctorId = 'doc_001';
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setUp(() {
      queueRepo = MockQueueRepository();
    });

    test('Initial doctor queue loads with items', () async {
      final queue = await queueRepo.getDoctorQueue(testDoctorId, dateStr);
      expect(queue.doctorId, equals(testDoctorId));
      expect(queue.items.isNotEmpty, isTrue);
      expect(queue.totalPatients, greaterThan(0));
    });

    test('Calling next patient advances the active token', () async {
      final queueBefore = await queueRepo.getDoctorQueue(testDoctorId, dateStr);
      final activeBefore = queueBefore.currentToken;

      await queueRepo.callNextPatient(testDoctorId, dateStr);

      final queueAfter = await queueRepo.getDoctorQueue(testDoctorId, dateStr);
      final activeAfter = queueAfter.currentToken;

      if (queueBefore.waitingCount > 0) {
        expect(activeAfter, isNotNull);
        expect(activeAfter?.tokenNumber, isNot(equals(activeBefore?.tokenNumber)));
      }
    });

    test('Marking complete updates item status', () async {
      final queue = await queueRepo.getDoctorQueue(testDoctorId, dateStr);
      if (queue.currentToken != null) {
        final currentTokenId = queue.currentToken!.id;
        await queueRepo.markComplete(testDoctorId, currentTokenId);

        final updatedQueue = await queueRepo.getDoctorQueue(testDoctorId, dateStr);
        final item = updatedQueue.items.firstWhere((q) => q.id == currentTokenId);
        expect(item.status, equals(QueueStatus.completed));
      }
    });
  });
}
