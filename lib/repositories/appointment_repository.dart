import '../../models/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointmentsByPatient(String patientId);
  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId);
  Future<List<Appointment>> getAllAppointments();
  Future<Appointment?> getAppointmentById(String id);
  Future<Appointment> createAppointment(Appointment appointment);
  Future<Appointment> updateAppointment(Appointment appointment);
  Future<void> cancelAppointment(String appointmentId);
  Future<Appointment> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTimeSlot);
  Future<Appointment> checkIn(String appointmentId);
  Future<Appointment> startConsultation(String appointmentId);
  Future<Appointment> completeConsultation(String appointmentId);
  Future<List<Appointment>> getAppointmentsByDate(String date);
  Future<bool> isSlotBooked(String doctorId, String date, String timeSlot);
}
