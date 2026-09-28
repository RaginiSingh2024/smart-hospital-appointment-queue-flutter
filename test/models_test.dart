import 'package:flutter_test/flutter_test.dart';
import 'package:smart_hospital_queue_flutter/models/appointment.dart';
import 'package:smart_hospital_queue_flutter/models/doctor.dart';
import 'package:smart_hospital_queue_flutter/models/queue.dart';

void main() {
  group('Model Unit Tests', () {
    test('AppointmentStatusExtension gives correct display names', () {
      expect(AppointmentStatus.confirmed.displayName, equals('Confirmed'));
      expect(AppointmentStatus.checkedIn.displayName, equals('Checked In'));
      expect(AppointmentStatus.completed.displayName, equals('Completed'));
      expect(AppointmentStatus.inConsultation.displayName, equals('In Consultation'));
      expect(AppointmentStatus.cancelled.displayName, equals('Cancelled'));
    });

    test('DoctorQueue getters compute counts accurately', () {
      final List<QueueModel> items = [
        const QueueModel(
          id: 'q1',
          appointmentId: 'apt1',
          patientId: 'p1',
          patientName: 'Patient 1',
          doctorId: 'doc1',
          tokenNumber: 'A-001',
          tokenSequence: 1,
          status: QueueStatus.inProgress,
          estimatedWaitMinutes: 0,
          date: '2026-09-28',
          patientsAhead: 0,
          avgConsultationMinutes: 15,
        ),
        const QueueModel(
          id: 'q2',
          appointmentId: 'apt2',
          patientId: 'p2',
          patientName: 'Patient 2',
          doctorId: 'doc1',
          tokenNumber: 'A-002',
          tokenSequence: 2,
          status: QueueStatus.waiting,
          estimatedWaitMinutes: 15,
          date: '2026-09-28',
          patientsAhead: 1,
          avgConsultationMinutes: 15,
        ),
        const QueueModel(
          id: 'q3',
          appointmentId: 'apt3',
          patientId: 'p3',
          patientName: 'Patient 3',
          doctorId: 'doc1',
          tokenNumber: 'A-003',
          tokenSequence: 3,
          status: QueueStatus.completed,
          estimatedWaitMinutes: 0,
          date: '2026-09-28',
          patientsAhead: 0,
          avgConsultationMinutes: 15,
        ),
      ];

      final doctorQueue = DoctorQueue(
        doctorId: 'doc1',
        doctorName: 'Dr. Test',
        date: '2026-09-28',
        currentTokenNumber: 'A-001',
        currentTokenSequence: 1,
        queue: items,
        totalPatients: items.length,
        completedPatients: 1,
        waitingPatients: 1,
      );

      expect(doctorQueue.currentToken?.tokenNumber, equals('A-001'));
      expect(doctorQueue.waitingQueue.length, equals(1));
      expect(doctorQueue.waitingQueue.first.tokenNumber, equals('A-002'));
      expect(doctorQueue.completedCount, equals(1));
      expect(doctorQueue.waitingCount, equals(1));
      expect(doctorQueue.totalTodayCount, equals(3));
    });

    test('Doctor model instantiation and properties', () {
      const doc = Doctor(
        id: 'doc_test',
        userId: 'user_doc_test',
        name: 'Dr. Anita Roy',
        specialty: 'Cardiology',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        experienceYears: 12,
        rating: 4.9,
        reviewCount: 42,
        consultationFee: 800.0,
        qualification: 'MBBS, MD (Cardio)',
        about: 'Cardiologist with 12 years of clinical excellence.',
        availableDays: ['Monday', 'Wednesday', 'Friday'],
        weeklySlots: {
          'Monday': ['09:00 AM', '10:00 AM'],
        },
        registrationNumber: 'MCI-12345',
        email: 'anita@hospital.org',
        phone: '+91 99887 76655',
        roomNumber: 'OPD-302',
      );

      expect(doc.name, equals('Dr. Anita Roy'));
      expect(doc.consultationFee, equals(800.0));
      expect(doc.isAvailable, isTrue);
      expect(doc.roomNumber, equals('OPD-302'));
    });
  });
}
