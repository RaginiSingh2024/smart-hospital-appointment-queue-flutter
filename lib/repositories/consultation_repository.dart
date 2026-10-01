import '../../models/consultation.dart';

abstract class ConsultationRepository {
  Future<List<Consultation>> getConsultationsByPatient(String patientId);
  Future<List<Consultation>> getConsultationsByDoctor(String doctorId);
  Future<Consultation?> getConsultationById(String id);
  Future<Consultation> createConsultation(Consultation consultation);
  Future<Consultation> updateConsultation(Consultation consultation);
  Future<List<Consultation>> getAllConsultations();
}
