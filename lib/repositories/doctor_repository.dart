import '../../models/doctor.dart';
import '../../models/time_slot.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
  Future<Doctor?> getDoctorById(String id);
  Future<List<Doctor>> getDoctorsByDepartment(String departmentId);
  Future<List<Doctor>> searchDoctors(String query);
  Future<List<TimeSlot>> getAvailableSlots(String doctorId, String date);
  Future<void> updateDoctorAvailability(String doctorId, Map<String, List<String>> weeklySlots);
  Future<void> bookSlot(String doctorId, String date, String time, String appointmentId);
  Future<void> releaseSlot(String doctorId, String date, String time);
  Future<Doctor?> getDoctorByUserId(String userId);
  Future<void> updateDoctor(Doctor doctor);
  Future<void> addDoctor(Doctor doctor);
  Future<void> toggleDoctorStatus(String doctorId, bool isActive);
}
