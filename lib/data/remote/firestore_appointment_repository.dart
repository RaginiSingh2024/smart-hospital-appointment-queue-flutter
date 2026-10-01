import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';

class FirestoreAppointmentRepository implements AppointmentRepository {
  final FirebaseFirestore _firestore;

  FirestoreAppointmentRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    print('[FIRESTORE APPOINTMENT] Getting appointments for patient: $patientId');
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true)
          .get();

      final appointments = snapshot.docs.map((doc) => _appointmentFromFirestore(doc)).toList();
      print('[FIRESTORE APPOINTMENT] Retrieved ${appointments.length} appointments for patient');
      return appointments;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error getting patient appointments: ${e.code} - ${e.message}');
      throw Exception('Failed to load appointments: ${e.message}');
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    print('[FIRESTORE APPOINTMENT] Getting appointments for doctor: $doctorId');
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: true)
          .get();

      final appointments = snapshot.docs.map((doc) => _appointmentFromFirestore(doc)).toList();
      print('[FIRESTORE APPOINTMENT] Retrieved ${appointments.length} appointments for doctor');
      return appointments;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error getting doctor appointments: ${e.code} - ${e.message}');
      throw Exception('Failed to load appointments: ${e.message}');
    }
  }

  @override
  Future<List<Appointment>> getAllAppointments() async {
    print('[FIRESTORE APPOINTMENT] Getting all appointments');
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .orderBy('appointmentDate', descending: true)
          .get();

      final appointments = snapshot.docs.map((doc) => _appointmentFromFirestore(doc)).toList();
      print('[FIRESTORE APPOINTMENT] Retrieved ${appointments.length} total appointments');
      return appointments;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error getting all appointments: ${e.code} - ${e.message}');
      throw Exception('Failed to load appointments: ${e.message}');
    }
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    print('[FIRESTORE APPOINTMENT] Getting appointment by ID: $id');
    try {
      final doc = await _firestore.collection('appointments').doc(id).get();
      if (!doc.exists) {
        print('[FIRESTORE APPOINTMENT] Appointment not found: $id');
        return null;
      }
      return _appointmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error getting appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to load appointment: ${e.message}');
    }
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    print('[FIRESTORE APPOINTMENT] Creating appointment for patient: ${appointment.patientId}, doctor: ${appointment.doctorId}');
    try {
      final appointmentId = appointment.id.isEmpty ? const Uuid().v4() : appointment.id;
      final docRef = _firestore.collection('appointments').doc(appointmentId);

      await docRef.set({
        'id': appointmentId,
        'patientId': appointment.patientId,
        'patientName': appointment.patientName,
        'doctorId': appointment.doctorId,
        'doctorName': appointment.doctorName,
        'doctorSpecialty': appointment.doctorSpecialty,
        'departmentId': appointment.departmentId,
        'departmentName': appointment.departmentName,
        'appointmentDate': Timestamp.fromDate(appointment.appointmentDate),
        'timeSlot': appointment.timeSlot,
        'tokenNumber': appointment.tokenNumber,
        'tokenSequence': appointment.tokenSequence,
        'status': appointment.status.name,
        'consultationType': appointment.consultationType.name,
        'consultationFee': appointment.consultationFee,
        'convenienceFee': appointment.convenienceFee,
        'priorityFee': appointment.priorityFee,
        'totalAmount': appointment.totalAmount,
        'paymentId': appointment.paymentId,
        'paymentMethod': appointment.paymentMethod,
        'isPaid': appointment.isPaid,
        'qrData': appointment.qrData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'queuePosition': appointment.queuePosition,
        'estimatedWaitMinutes': appointment.estimatedWaitMinutes,
      });

      print('[FIRESTORE APPOINTMENT] Appointment created successfully: $appointmentId');
      return appointment.copyWith(id: appointmentId);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error creating appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to create appointment: ${e.message}');
    }
  }

  @override
  Future<Appointment> updateAppointment(Appointment appointment) async {
    print('[FIRESTORE APPOINTMENT] Updating appointment: ${appointment.id}');
    try {
      await _firestore.collection('appointments').doc(appointment.id).update({
        'status': appointment.status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (appointment.checkedInAt != null) 'checkedInAt': Timestamp.fromDate(appointment.checkedInAt!),
        if (appointment.completedAt != null) 'completedAt': Timestamp.fromDate(appointment.completedAt!),
      });
      print('[FIRESTORE APPOINTMENT] Appointment updated successfully');
      return appointment;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error updating appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to update appointment: ${e.message}');
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    print('[FIRESTORE APPOINTMENT] Cancelling appointment: $appointmentId');
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE APPOINTMENT] Appointment cancelled successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error cancelling appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to cancel appointment: ${e.message}');
    }
  }

  @override
  Future<Appointment> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTimeSlot) async {
    print('[FIRESTORE APPOINTMENT] Rescheduling appointment: $appointmentId to $newDate at $newTimeSlot');
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'appointmentDate': Timestamp.fromDate(newDate),
        'timeSlot': newTimeSlot,
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE APPOINTMENT] Appointment rescheduled successfully');
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      return _appointmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error rescheduling appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to reschedule appointment: ${e.message}');
    }
  }

  @override
  Future<Appointment> checkIn(String appointmentId) async {
    print('[FIRESTORE APPOINTMENT] Checking in appointment: $appointmentId');
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'checkedIn',
        'checkedInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE APPOINTMENT] Appointment checked in successfully');
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      return _appointmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error checking in appointment: ${e.code} - ${e.message}');
      throw Exception('Failed to check in appointment: ${e.message}');
    }
  }

  @override
  Future<Appointment> startConsultation(String appointmentId) async {
    print('[FIRESTORE APPOINTMENT] Starting consultation: $appointmentId');
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'inProgress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE APPOINTMENT] Consultation started successfully');
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      return _appointmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error starting consultation: ${e.code} - ${e.message}');
      throw Exception('Failed to start consultation: ${e.message}');
    }
  }

  @override
  Future<Appointment> completeConsultation(String appointmentId) async {
    print('[FIRESTORE APPOINTMENT] Completing consultation: $appointmentId');
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE APPOINTMENT] Consultation completed successfully');
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      return _appointmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error completing consultation: ${e.code} - ${e.message}');
      throw Exception('Failed to complete consultation: ${e.message}');
    }
  }

  @override
  Future<List<Appointment>> getAppointmentsByDate(String date) async {
    print('[FIRESTORE APPOINTMENT] Getting appointments for date: $date');
    try {
      final startOfDay = DateTime.parse(date);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final appointments = snapshot.docs.map((doc) => _appointmentFromFirestore(doc)).toList();
      print('[FIRESTORE APPOINTMENT] Retrieved ${appointments.length} appointments for date');
      return appointments;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error getting appointments by date: ${e.code} - ${e.message}');
      throw Exception('Failed to load appointments: ${e.message}');
    }
  }

  @override
  Future<bool> isSlotBooked(String doctorId, String date, String timeSlot) async {
    print('[FIRESTORE APPOINTMENT] Checking if slot is booked: doctorId=$doctorId, date=$date, time=$timeSlot');
    try {
      final startOfDay = DateTime.parse(date);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['confirmed', 'checkedIn', 'inProgress'])
          .get();

      final isBooked = snapshot.docs.isNotEmpty;
      print('[FIRESTORE APPOINTMENT] Slot booked: $isBooked');
      return isBooked;
    } on FirebaseException catch (e) {
      print('[FIRESTORE APPOINTMENT] Error checking slot: ${e.code} - ${e.message}');
      throw Exception('Failed to check slot availability: ${e.message}');
    }
  }

  Appointment _appointmentFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: _stringValue(data['patientId']) ?? '',
      patientName: _stringValue(data['patientName']) ?? '',
      doctorId: _stringValue(data['doctorId']) ?? '',
      doctorName: _stringValue(data['doctorName']) ?? '',
      doctorSpecialty: _stringValue(data['doctorSpecialty']) ?? '',
      departmentId: _stringValue(data['departmentId']) ?? '',
      departmentName: _stringValue(data['departmentName']) ?? '',
      appointmentDate: _timestampValue(data['appointmentDate']) ?? DateTime.now(),
      timeSlot: _stringValue(data['timeSlot']) ?? '',
      tokenNumber: _stringValue(data['tokenNumber']) ?? '',
      tokenSequence: _intValue(data['tokenSequence']) ?? 0,
      status: _parseStatus(data['status']),
      consultationType: _parseConsultationType(data['consultationType']),
      consultationFee: _numValue(data['consultationFee'])?.toDouble() ?? 0.0,
      convenienceFee: _numValue(data['convenienceFee'])?.toDouble() ?? 0.0,
      priorityFee: _numValue(data['priorityFee'])?.toDouble() ?? 0.0,
      totalAmount: _numValue(data['totalAmount'])?.toDouble() ?? 0.0,
      paymentId: _stringValue(data['paymentId']) ?? '',
      paymentMethod: _stringValue(data['paymentMethod']) ?? '',
      isPaid: data['isPaid'] as bool? ?? false,
      qrData: _stringValue(data['qrData']) ?? '',
      createdAt: _timestampValue(data['createdAt']) ?? DateTime.now(),
      checkedInAt: _timestampValue(data['checkedInAt']),
      completedAt: _timestampValue(data['completedAt']),
      queuePosition: _intValue(data['queuePosition']) ?? 0,
      estimatedWaitMinutes: _intValue(data['estimatedWaitMinutes']) ?? 0,
    );
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

  num? _numValue(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  DateTime? _timestampValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  AppointmentStatus _parseStatus(dynamic value) {
    final status = value?.toString().toLowerCase();
    switch (status) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'checkedin':
        return AppointmentStatus.checkedIn;
      case 'inqueue':
        return AppointmentStatus.inQueue;
      case 'inprogress':
        return AppointmentStatus.inConsultation;
      case 'completed':
        return AppointmentStatus.completed;
      case 'noshow':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.confirmed;
    }
  }

  ConsultationType _parseConsultationType(dynamic value) {
    final type = value?.toString().toLowerCase();
    switch (type) {
      case 'follow_up':
        return ConsultationType.followUp;
      case 'emergency':
        return ConsultationType.emergency;
      case 'premium':
        return ConsultationType.premium;
      default:
        return ConsultationType.regular;
    }
  }
}
