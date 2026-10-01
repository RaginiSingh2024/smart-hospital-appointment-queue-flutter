import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/doctor.dart';
import '../../models/time_slot.dart';
import '../../repositories/doctor_repository.dart';

class FirestoreDoctorRepository implements DoctorRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreDoctorRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<Doctor>> getDoctors() async {
    print('[FIRESTORE DOCTOR] Getting all doctors');
    try {
      final snapshot = await _firestore.collection('doctors').get();
      final doctors = snapshot.docs.map((doc) => _doctorFromFirestore(doc)).toList();
      print('[FIRESTORE DOCTOR] Retrieved ${doctors.length} doctors');
      return doctors;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error getting doctors: ${e.code} - ${e.message}');
      throw Exception('Failed to load doctors: ${e.message}');
    }
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    print('[FIRESTORE DOCTOR] Getting doctor by ID: $id');
    try {
      final doc = await _firestore.collection('doctors').doc(id).get();
      if (!doc.exists) {
        print('[FIRESTORE DOCTOR] Doctor not found: $id');
        return null;
      }
      return _doctorFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error getting doctor: ${e.code} - ${e.message}');
      throw Exception('Failed to load doctor: ${e.message}');
    }
  }

  @override
  Future<List<Doctor>> getDoctorsByDepartment(String departmentId) async {
    print('[FIRESTORE DOCTOR] Getting doctors by department: $departmentId');
    try {
      final snapshot = await _firestore
          .collection('doctors')
          .where('departmentId', isEqualTo: departmentId)
          .get();
      final doctors = snapshot.docs.map((doc) => _doctorFromFirestore(doc)).toList();
      print('[FIRESTORE DOCTOR] Retrieved ${doctors.length} doctors for department');
      return doctors;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error getting doctors by department: ${e.code} - ${e.message}');
      throw Exception('Failed to load doctors: ${e.message}');
    }
  }

  @override
  Future<List<Doctor>> searchDoctors(String query) async {
    print('[FIRESTORE DOCTOR] Searching doctors: $query');
    try {
      final snapshot = await _firestore.collection('doctors').get();
      final q = query.toLowerCase();
      final doctors = snapshot.docs
          .map((doc) => _doctorFromFirestore(doc))
          .where((d) {
        return d.isActive &&
            (d.name.toLowerCase().contains(q) ||
                d.specialty.toLowerCase().contains(q) ||
                d.departmentName.toLowerCase().contains(q));
      }).toList();
      print('[FIRESTORE DOCTOR] Found ${doctors.length} matching doctors');
      return doctors;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error searching doctors: ${e.code} - ${e.message}');
      throw Exception('Failed to search doctors: ${e.message}');
    }
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots(String doctorId, String date) async {
    print('[FIRESTORE DOCTOR] Getting available slots for doctor: $doctorId, date: $date');
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) {
        print('[FIRESTORE DOCTOR] Doctor not found: $doctorId');
        return [];
      }

      final data = doc.data()!;
      final weeklySlots = data['weeklySlots'] as Map<String, dynamic>? ?? {};
      final bookedSlots = data['bookedSlots'] as Map<String, dynamic>? ?? {};

      // Get day of week from date
      final dateObj = DateTime.parse(date);
      final dayName = _getDayName(dateObj);

      final slotTimes = weeklySlots[dayName] as List<dynamic>? ?? [];
      final booked = bookedSlots[date] as Set<dynamic>? ?? {};

      final slots = slotTimes.map((time) {
        final timeStr = time.toString();
        return TimeSlot(
          id: '$doctorId-$date-$timeStr',
          doctorId: doctorId,
          date: date,
          time: timeStr,
          status: booked.contains(timeStr) ? SlotStatus.booked : SlotStatus.available,
        );
      }).toList();

      print('[FIRESTORE DOCTOR] Retrieved ${slots.length} slots for $dayName');
      return slots;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error getting slots: ${e.code} - ${e.message}');
      throw Exception('Failed to load available slots: ${e.message}');
    }
  }

  @override
  Future<void> updateDoctorAvailability(
      String doctorId, Map<String, List<String>> weeklySlots) async {
    print('[FIRESTORE DOCTOR] Updating availability for doctor: $doctorId');
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'weeklySlots': weeklySlots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DOCTOR] Availability updated successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error updating availability: ${e.code} - ${e.message}');
      throw Exception('Failed to update availability: ${e.message}');
    }
  }

  @override
  Future<void> bookSlot(
      String doctorId, String date, String time, String appointmentId) async {
    print('[FIRESTORE DOCTOR] Booking slot: doctorId=$doctorId, date=$date, time=$time');
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'bookedSlots.$date': FieldValue.arrayUnion([time]),
      });
      print('[FIRESTORE DOCTOR] Slot booked successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error booking slot: ${e.code} - ${e.message}');
      throw Exception('Failed to book slot: ${e.message}');
    }
  }

  @override
  Future<void> releaseSlot(String doctorId, String date, String time) async {
    print('[FIRESTORE DOCTOR] Releasing slot: doctorId=$doctorId, date=$date, time=$time');
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'bookedSlots.$date': FieldValue.arrayRemove([time]),
      });
      print('[FIRESTORE DOCTOR] Slot released successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error releasing slot: ${e.code} - ${e.message}');
      throw Exception('Failed to release slot: ${e.message}');
    }
  }

  @override
  Future<Doctor?> getDoctorByUserId(String userId) async {
    print('[FIRESTORE DOCTOR] Getting doctor by userId: $userId');
    try {
      final snapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('[FIRESTORE DOCTOR] Doctor not found for userId: $userId');
        return null;
      }

      return _doctorFromFirestore(snapshot.docs.first);
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error getting doctor by userId: ${e.code} - ${e.message}');
      throw Exception('Failed to load doctor: ${e.message}');
    }
  }

  @override
  Future<void> updateDoctor(Doctor doctor) async {
    print('[FIRESTORE DOCTOR] Updating doctor: ${doctor.id}');
    try {
      await _firestore.collection('doctors').doc(doctor.id).update({
        'name': doctor.name,
        'specialty': doctor.specialty,
        'consultationFee': doctor.consultationFee,
        'isAvailable': doctor.isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DOCTOR] Doctor updated successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error updating doctor: ${e.code} - ${e.message}');
      throw Exception('Failed to update doctor: ${e.message}');
    }
  }

  @override
  Future<void> addDoctor(Doctor doctor) async {
    print('[FIRESTORE DOCTOR] Adding doctor: ${doctor.id}');
    try {
      await _firestore.collection('doctors').doc(doctor.id).set({
        'userId': doctor.userId,
        'name': doctor.name,
        'specialty': doctor.specialty,
        'departmentId': doctor.departmentId,
        'departmentName': doctor.departmentName,
        'experienceYears': doctor.experienceYears,
        'rating': doctor.rating,
        'reviewCount': doctor.reviewCount,
        'consultationFee': doctor.consultationFee,
        'qualification': doctor.qualification,
        'about': doctor.about,
        'isAvailable': doctor.isAvailable,
        'registrationNumber': doctor.registrationNumber,
        'email': doctor.email,
        'phone': doctor.phone,
        'availableDays': doctor.availableDays,
        'weeklySlots': doctor.weeklySlots,
        'bookedSlots': {},
        'profileImageUrl': doctor.profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DOCTOR] Doctor added successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error adding doctor: ${e.code} - ${e.message}');
      throw Exception('Failed to add doctor: ${e.message}');
    }
  }

  @override
  Future<void> toggleDoctorStatus(String doctorId, bool isActive) async {
    print('[FIRESTORE DOCTOR] Toggling doctor status: $doctorId, active=$isActive');
    try {
      await _firestore.collection('doctors').doc(doctorId).update({
        'isAvailable': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DOCTOR] Doctor status toggled successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DOCTOR] Error toggling status: ${e.code} - ${e.message}');
      throw Exception('Failed to toggle doctor status: ${e.message}');
    }
  }

  Doctor _doctorFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      userId: _stringValue(data['userId']) ?? '',
      name: _stringValue(data['name']) ?? '',
      specialty: _stringValue(data['specialty']) ?? '',
      departmentId: _stringValue(data['departmentId']) ?? '',
      departmentName: _stringValue(data['departmentName']) ?? '',
      experienceYears: _intValue(data['experienceYears']) ?? 0,
      rating: _numValue(data['rating'])?.toDouble() ?? 0.0,
      reviewCount: _intValue(data['reviewCount']) ?? 0,
      consultationFee: _numValue(data['consultationFee'])?.toDouble() ?? 0.0,
      qualification: _stringValue(data['qualification']) ?? '',
      about: _stringValue(data['about']) ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      registrationNumber: _stringValue(data['registrationNumber']) ?? '',
      email: _stringValue(data['email']) ?? '',
      phone: _stringValue(data['phone']) ?? '',
      availableDays: _stringList(data['availableDays']),
      weeklySlots: _mapStringList(data['weeklySlots']),
      profileImageUrl: _stringValue(data['profileImageUrl']),
      createdAt: _dateTimeValue(data['createdAt']),
      updatedAt: _dateTimeValue(data['updatedAt']),
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

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [];
  }

  Map<String, List<String>> _mapStringList(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(
        k.toString(),
        v is List ? v.whereType<String>().toList() : [],
      ));
    }
    return {};
  }

  DateTime? _dateTimeValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }
}
