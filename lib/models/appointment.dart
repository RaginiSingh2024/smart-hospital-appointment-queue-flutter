enum AppointmentStatus {
  pending,
  confirmed,
  checkedIn,
  inQueue,
  inConsultation,
  completed,
  cancelled,
  rescheduled,
  noShow,
}

enum ConsultationType { regular, premium, emergency, followUp }

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.checkedIn:
        return 'Checked In';
      case AppointmentStatus.inQueue:
        return 'In Queue';
      case AppointmentStatus.inConsultation:
        return 'In Consultation';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

extension ConsultationTypeExtension on ConsultationType {
  String get displayName {
    switch (this) {
      case ConsultationType.regular:
        return 'Regular';
      case ConsultationType.premium:
        return 'Premium Priority';
      case ConsultationType.emergency:
        return 'Emergency';
      case ConsultationType.followUp:
        return 'Follow Up';
    }
  }

  double get additionalFee {
    switch (this) {
      case ConsultationType.regular:
        return 0;
      case ConsultationType.premium:
        return 150;
      case ConsultationType.emergency:
        return 300;
      case ConsultationType.followUp:
        return 0;
    }
  }
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String departmentId;
  final String departmentName;
  final DateTime appointmentDate;
  final String timeSlot;
  final String tokenNumber;
  final int tokenSequence;
  final AppointmentStatus status;
  final ConsultationType consultationType;
  final double consultationFee;
  final double convenienceFee;
  final double priorityFee;
  final double totalAmount;
  final String? paymentId;
  final String? paymentMethod;
  final bool isPaid;
  final String? notes;
  final String? qrData;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? checkedInAt;
  final DateTime? completedAt;
  final int? queuePosition;
  final int? estimatedWaitMinutes;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.departmentId,
    required this.departmentName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.tokenNumber,
    required this.tokenSequence,
    required this.status,
    required this.consultationType,
    required this.consultationFee,
    required this.convenienceFee,
    required this.priorityFee,
    required this.totalAmount,
    this.paymentId,
    this.paymentMethod,
    this.isPaid = false,
    this.notes,
    this.qrData,
    required this.createdAt,
    this.updatedAt,
    this.checkedInAt,
    this.completedAt,
    this.queuePosition,
    this.estimatedWaitMinutes,
  });

  bool get isUpcoming =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.checkedIn ||
      status == AppointmentStatus.inConsultation;

  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get canCheckIn => status == AppointmentStatus.confirmed || status == AppointmentStatus.pending;
  bool get canCancel => status == AppointmentStatus.confirmed || status == AppointmentStatus.pending;
  String get roomNumber => 'Room 204';
  String get reason => notes ?? 'General OPD Consultation';

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      doctorId: map['doctorId'] as String,
      doctorName: map['doctorName'] as String,
      doctorSpecialty: map['doctorSpecialty'] as String,
      departmentId: map['departmentId'] as String,
      departmentName: map['departmentName'] as String,
      appointmentDate: DateTime.parse(map['appointmentDate'] as String),
      timeSlot: map['timeSlot'] as String,
      tokenNumber: map['tokenNumber'] as String,
      tokenSequence: map['tokenSequence'] as int,
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      consultationType: ConsultationType.values.firstWhere(
        (t) => t.name == map['consultationType'],
        orElse: () => ConsultationType.regular,
      ),
      consultationFee: (map['consultationFee'] as num).toDouble(),
      convenienceFee: (map['convenienceFee'] as num).toDouble(),
      priorityFee: (map['priorityFee'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paymentId: map['paymentId'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      notes: map['notes'] as String?,
      qrData: map['qrData'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      checkedInAt: map['checkedInAt'] != null
          ? DateTime.parse(map['checkedInAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      queuePosition: map['queuePosition'] as int?,
      estimatedWaitMinutes: map['estimatedWaitMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'tokenNumber': tokenNumber,
      'tokenSequence': tokenSequence,
      'status': status.name,
      'consultationType': consultationType.name,
      'consultationFee': consultationFee,
      'convenienceFee': convenienceFee,
      'priorityFee': priorityFee,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'notes': notes,
      'qrData': qrData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'queuePosition': queuePosition,
      'estimatedWaitMinutes': estimatedWaitMinutes,
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? departmentId,
    String? departmentName,
    DateTime? appointmentDate,
    String? timeSlot,
    String? tokenNumber,
    int? tokenSequence,
    AppointmentStatus? status,
    ConsultationType? consultationType,
    double? consultationFee,
    double? convenienceFee,
    double? priorityFee,
    double? totalAmount,
    String? paymentId,
    String? paymentMethod,
    bool? isPaid,
    String? notes,
    String? qrData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? checkedInAt,
    DateTime? completedAt,
    int? queuePosition,
    int? estimatedWaitMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      tokenSequence: tokenSequence ?? this.tokenSequence,
      status: status ?? this.status,
      consultationType: consultationType ?? this.consultationType,
      consultationFee: consultationFee ?? this.consultationFee,
      convenienceFee: convenienceFee ?? this.convenienceFee,
      priorityFee: priorityFee ?? this.priorityFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      qrData: qrData ?? this.qrData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      completedAt: completedAt ?? this.completedAt,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
    );
  }
}
