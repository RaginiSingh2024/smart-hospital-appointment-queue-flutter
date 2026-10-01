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
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
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
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Consultation copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? departmentName,
    DateTime? consultationDate,
    String? diagnosis,
    String? prescription,
    String? notes,
    List<String>? medicines,
    String? followUpDate,
    bool? isPaid,
    double? amountPaid,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consultation(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      departmentName: departmentName ?? this.departmentName,
      consultationDate: consultationDate ?? this.consultationDate,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      medicines: medicines ?? this.medicines,
      followUpDate: followUpDate ?? this.followUpDate,
      isPaid: isPaid ?? this.isPaid,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
