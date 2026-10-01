import '../../models/queue.dart';

abstract class QueueRepository {
  Future<QueueModel?> getPatientQueue(String patientId, String date);
  Future<DoctorQueue> getDoctorQueue(String doctorId, String date);
  Future<void> callNextPatient(String doctorId, String date);
  Future<void> skipToken(String doctorId, String queueId);
  Future<void> markComplete(String doctorId, String queueId);
  Future<void> checkInPatient(String appointmentId);
  Stream<DoctorQueue> watchDoctorQueue(String doctorId, String date);
  Stream<QueueModel?> watchPatientQueue(String patientId, String date);
  Future<void> addToQueue({required String doctorId, required String date, required QueueModel queueModel});
}
