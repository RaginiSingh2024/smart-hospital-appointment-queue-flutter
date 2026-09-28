import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../mock/mock_data.dart';

class MockAppointmentRepository implements AppointmentRepository {
  final List<Appointment> _appointments = MockData.appointments;

  @override
  Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _appointments.where((a) => a.patientId == patientId).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  @override
  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _appointments.where((a) => a.doctorId == doctorId).toList()
      ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));
  }

  @override
  Future<List<Appointment>> getAllAppointments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_appointments)
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _appointments.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _appointments.add(appointment);
    return appointment;
  }

  @override
  Future<Appointment> updateAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _appointments.indexWhere((a) => a.id == appointment.id);
    if (idx >= 0) {
      _appointments[idx] = appointment;
    }
    return appointment;
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      _appointments[idx] = _appointments[idx].copyWith(
        status: AppointmentStatus.cancelled,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<Appointment> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTimeSlot) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx < 0) throw Exception('Appointment not found');

    final updated = _appointments[idx].copyWith(
      appointmentDate: newDate,
      timeSlot: newTimeSlot,
      status: AppointmentStatus.confirmed,
      updatedAt: DateTime.now(),
    );
    _appointments[idx] = updated;
    return updated;
  }

  @override
  Future<Appointment> checkIn(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx < 0) throw Exception('Appointment not found');

    final updated = _appointments[idx].copyWith(
      status: AppointmentStatus.checkedIn,
      checkedInAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _appointments[idx] = updated;
    return updated;
  }

  @override
  Future<Appointment> startConsultation(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx < 0) throw Exception('Appointment not found');

    final updated = _appointments[idx].copyWith(
      status: AppointmentStatus.inConsultation,
      updatedAt: DateTime.now(),
    );
    _appointments[idx] = updated;
    return updated;
  }

  @override
  Future<Appointment> completeConsultation(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx < 0) throw Exception('Appointment not found');

    final updated = _appointments[idx].copyWith(
      status: AppointmentStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _appointments[idx] = updated;
    return updated;
  }

  @override
  Future<List<Appointment>> getAppointmentsByDate(String date) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _appointments.where((a) {
      final apptDate = DateFormat('yyyy-MM-dd').format(a.appointmentDate);
      return apptDate == date;
    }).toList();
  }

  @override
  Future<bool> isSlotBooked(String doctorId, String date, String timeSlot) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _appointments.any((a) {
      final apptDate = DateFormat('yyyy-MM-dd').format(a.appointmentDate);
      return a.doctorId == doctorId &&
          apptDate == date &&
          a.timeSlot == timeSlot &&
          a.status != AppointmentStatus.cancelled;
    });
  }

  // Generate token number for a doctor's appointments on a date
  int getNextTokenSequence(String doctorId, String date) {
    final count = _appointments.where((a) {
      final apptDate = DateFormat('yyyy-MM-dd').format(a.appointmentDate);
      return a.doctorId == doctorId &&
          apptDate == date &&
          a.status != AppointmentStatus.cancelled;
    }).length;
    return count + 1;
  }

  String generateTokenNumber(String doctorId, int sequence) {
    // Use first letter of doctor's department
    final doctor = MockData.doctors.where((d) => d.id == doctorId).firstOrNull;
    final prefix = doctor?.departmentName.substring(0, 1).toUpperCase() ?? 'A';
    return '$prefix-${sequence.toString().padLeft(2, '0')}';
  }
}
