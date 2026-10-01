class Consultation {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String departmentName;
  final DateTime consultationDate;
  final String diagnosis;
  final String prescription;
  final String notes;
  final List<String> medicines;
  final String? followUpDate;
  final bool isPaid;
  final double amountPaid;
  final String paymentMethod;

  const Consultation({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.departmentName,
    required this.consultationDate,
    required this.diagnosis,
    required this.prescription,
    required this.notes,
    required this.medicines,
    this.followUpDate,
    required this.isPaid,
    required this.amountPaid,
    required this.paymentMethod,
  });

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'] as String,
      appointmentId: map['appointmentId'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      doctorId: map['doctorId'] as String,
      doctorName: map['doctorName'] as String,
      doctorSpecialty: map['doctorSpecialty'] as String,
      departmentName: map['departmentName'] as String,
      consultationDate: DateTime.parse(map['consultationDate'] as String),
      diagnosis: map['diagnosis'] as String,
      prescription: map['prescription'] as String,
      notes: map['notes'] as String,
      medicines: List<String>.from(map['medicines'] as List),
      followUpDate: map['followUpDate'] as String?,
      isPaid: map['isPaid'] as bool,
      amountPaid: (map['amountPaid'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'departmentName': departmentName,
      'consultationDate': consultationDate.toIso8601String(),
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'medicines': medicines,
      'followUpDate': followUpDate,
      'isPaid': isPaid,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
    };
  }
}
