import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/consultation.dart';
import '../../repositories/consultation_repository.dart';

class FirestoreConsultationRepository implements ConsultationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  FirestoreConsultationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<Consultation>> getConsultationsByPatient(String patientId) async {
    print('[FIRESTORE CONSULTATION] Getting consultations for patient: $patientId');
    try {
      final snapshot = await _firestore
          .collection('consultations')
          .where('patientId', isEqualTo: patientId)
          .orderBy('consultationDate', descending: true)
          .get();

      final consultations = snapshot.docs.map((doc) => _consultationFromFirestore(doc)).toList();
      print('[FIRESTORE CONSULTATION] Retrieved ${consultations.length} consultations for patient');
      return consultations;
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error getting patient consultations: ${e.code} - ${e.message}');
      throw Exception('Failed to load consultations: ${e.message}');
    }
  }

  @override
  Future<List<Consultation>> getConsultationsByDoctor(String doctorId) async {
    print('[FIRESTORE CONSULTATION] Getting consultations for doctor: $doctorId');
    try {
      final snapshot = await _firestore
          .collection('consultations')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('consultationDate', descending: true)
          .get();

      final consultations = snapshot.docs.map((doc) => _consultationFromFirestore(doc)).toList();
      print('[FIRESTORE CONSULTATION] Retrieved ${consultations.length} consultations for doctor');
      return consultations;
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error getting doctor consultations: ${e.code} - ${e.message}');
      throw Exception('Failed to load consultations: ${e.message}');
    }
  }

  @override
  Future<Consultation?> getConsultationById(String id) async {
    print('[FIRESTORE CONSULTATION] Getting consultation by ID: $id');
    try {
      final doc = await _firestore.collection('consultations').doc(id).get();
      if (!doc.exists) {
        print('[FIRESTORE CONSULTATION] Consultation not found: $id');
        return null;
      }
      return _consultationFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error getting consultation: ${e.code} - ${e.message}');
      throw Exception('Failed to load consultation: ${e.message}');
    }
  }

  @override
  Future<Consultation> createConsultation(Consultation consultation) async {
    print('[FIRESTORE CONSULTATION] Creating consultation for appointment: ${consultation.appointmentId}');
    try {
      final consultationId = consultation.id.isEmpty ? _uuid.v4() : consultation.id;
      await _firestore.collection('consultations').doc(consultationId).set({
        'id': consultationId,
        'appointmentId': consultation.appointmentId,
        'patientId': consultation.patientId,
        'patientName': consultation.patientName,
        'doctorId': consultation.doctorId,
        'doctorName': consultation.doctorName,
        'doctorSpecialty': consultation.doctorSpecialty,
        'departmentName': consultation.departmentName,
        'consultationDate': Timestamp.fromDate(consultation.consultationDate),
        'diagnosis': consultation.diagnosis,
        'prescription': consultation.prescription,
        'notes': consultation.notes,
        'medicines': consultation.medicines,
        'followUpDate': consultation.followUpDate,
        'isPaid': consultation.isPaid,
        'amountPaid': consultation.amountPaid,
        'paymentMethod': consultation.paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[FIRESTORE CONSULTATION] Consultation created successfully: $consultationId');
      return consultation.copyWith(id: consultationId);
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error creating consultation: ${e.code} - ${e.message}');
      throw Exception('Failed to create consultation: ${e.message}');
    }
  }

  @override
  Future<Consultation> updateConsultation(Consultation consultation) async {
    print('[FIRESTORE CONSULTATION] Updating consultation: ${consultation.id}');
    try {
      await _firestore.collection('consultations').doc(consultation.id).update({
        'diagnosis': consultation.diagnosis,
        'prescription': consultation.prescription,
        'notes': consultation.notes,
        'medicines': consultation.medicines,
        'followUpDate': consultation.followUpDate,
        'isPaid': consultation.isPaid,
        'amountPaid': consultation.amountPaid,
        'paymentMethod': consultation.paymentMethod,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE CONSULTATION] Consultation updated successfully');
      return consultation;
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error updating consultation: ${e.code} - ${e.message}');
      throw Exception('Failed to update consultation: ${e.message}');
    }
  }

  @override
  Future<List<Consultation>> getAllConsultations() async {
    print('[FIRESTORE CONSULTATION] Getting all consultations');
    try {
      final snapshot = await _firestore
          .collection('consultations')
          .orderBy('consultationDate', descending: true)
          .get();

      final consultations = snapshot.docs.map((doc) => _consultationFromFirestore(doc)).toList();
      print('[FIRESTORE CONSULTATION] Retrieved ${consultations.length} total consultations');
      return consultations;
    } on FirebaseException catch (e) {
      print('[FIRESTORE CONSULTATION] Error getting all consultations: ${e.code} - ${e.message}');
      throw Exception('Failed to load consultations: ${e.message}');
    }
  }

  Consultation _consultationFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Consultation(
      id: doc.id,
      appointmentId: _stringValue(data['appointmentId']) ?? '',
      patientId: _stringValue(data['patientId']) ?? '',
      patientName: _stringValue(data['patientName']) ?? '',
      doctorId: _stringValue(data['doctorId']) ?? '',
      doctorName: _stringValue(data['doctorName']) ?? '',
      doctorSpecialty: _stringValue(data['doctorSpecialty']) ?? '',
      departmentName: _stringValue(data['departmentName']) ?? '',
      consultationDate: _timestampValue(data['consultationDate']) ?? DateTime.now(),
      diagnosis: _stringValue(data['diagnosis']) ?? '',
      prescription: _stringValue(data['prescription']) ?? '',
      notes: _stringValue(data['notes']) ?? '',
      medicines: _stringList(data['medicines']),
      followUpDate: _stringValue(data['followUpDate']),
      isPaid: data['isPaid'] as bool? ?? false,
      amountPaid: _numValue(data['amountPaid'])?.toDouble() ?? 0.0,
      paymentMethod: _stringValue(data['paymentMethod']) ?? '',
    );
  }

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  num? _numValue(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  DateTime? _timestampValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
