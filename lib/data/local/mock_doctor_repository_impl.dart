import 'dart:async';
import 'package:intl/intl.dart';
import '../../models/doctor.dart';
import '../../models/time_slot.dart';
import '../../repositories/doctor_repository.dart';
import '../mock/mock_data.dart';

class MockDoctorRepository implements DoctorRepository {
  final List<Doctor> _doctors = List.from(MockData.doctors);
  final Map<String, Map<String, Set<String>>> _bookedSlots = {};
  // key: doctorId -> date -> Set<time>

  @override
  Future<List<Doctor>> getDoctors() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _doctors.where((d) => d.isActive).toList();
  }

  @override
  Future<Doctor?> getDoctorById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _doctors.where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<List<Doctor>> getDoctorsByDepartment(String departmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _doctors.where((d) => d.departmentId == departmentId && d.isActive).toList();
  }

  @override
  Future<List<Doctor>> searchDoctors(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _doctors.where((d) {
      return d.isActive &&
          (d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.departmentName.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Future<List<TimeSlot>> getAvailableSlots(String doctorId, String date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final doctor = _doctors.where((d) => d.id == doctorId).firstOrNull;
    if (doctor == null) return [];

    // Get day of week from date
    final dateObj = DateFormat('yyyy-MM-dd').parse(date);
    final dayName = DateFormat('EEEE').format(dateObj);

    final slotTimes = doctor.weeklySlots[dayName] ?? [];
    final booked = _bookedSlots[doctorId]?[date] ?? {};

    return MockData.generateSlotsForDoctor(doctorId, date, slotTimes, booked);
  }

  @override
  Future<void> updateDoctorAvailability(
      String doctorId, Map<String, List<String>> weeklySlots) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _doctors.indexWhere((d) => d.id == doctorId);
    if (idx >= 0) {
      _doctors[idx] = _doctors[idx].copyWith(weeklySlots: weeklySlots);
    }
  }

  @override
  Future<void> bookSlot(
      String doctorId, String date, String time, String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bookedSlots[doctorId] ??= {};
    _bookedSlots[doctorId]![date] ??= {};
    _bookedSlots[doctorId]![date]!.add(time);
  }

  @override
  Future<void> releaseSlot(String doctorId, String date, String time) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bookedSlots[doctorId]?[date]?.remove(time);
  }

  @override
  Future<Doctor?> getDoctorByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('🔥 MOCK DOCTOR REPO: Looking for doctor with userId: $userId');
    print('🔥 MOCK DOCTOR REPO: Available doctor userIds: ${_doctors.map((d) => d.userId).toList()}');
    final doctor = _doctors.where((d) => d.userId == userId).firstOrNull;
    print('🔥 MOCK DOCTOR REPO: Found doctor: ${doctor?.id} - ${doctor?.name}');
    return doctor;
  }

  @override
  Future<void> updateDoctor(Doctor doctor) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _doctors.indexWhere((d) => d.id == doctor.id);
    if (idx >= 0) {
      _doctors[idx] = doctor;
    }
  }

  @override
  Future<void> addDoctor(Doctor doctor) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _doctors.add(doctor);
  }

  @override
  Future<void> toggleDoctorStatus(String doctorId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _doctors.indexWhere((d) => d.id == doctorId);
    if (idx >= 0) {
      _doctors[idx] = _doctors[idx].copyWith(isActive: isActive);
    }
  }
}
