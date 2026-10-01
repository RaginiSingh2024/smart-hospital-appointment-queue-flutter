enum QueueStatus { waiting, called, inProgress, completed, skipped, noShow }

class QueueModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String tokenNumber;
  final int tokenSequence;
  final QueueStatus status;
  final int patientsAhead;
  final int estimatedWaitMinutes;
  final DateTime? calledAt;
  final DateTime? completedAt;
  final int avgConsultationMinutes;
  final String date; // 'yyyy-MM-dd'
  final bool isEmergency;
  final DateTime? checkedInAt;
  final int? queuePosition;
  final String? notes;

  const QueueModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.tokenNumber,
    required this.tokenSequence,
    required this.status,
    required this.patientsAhead,
    required this.estimatedWaitMinutes,
    this.calledAt,
    this.completedAt,
    this.avgConsultationMinutes = 15,
    required this.date,
    this.isEmergency = false,
    this.checkedInAt,
    this.queuePosition,
    this.notes,
  });

  /// Human-readable estimated consultation time slot.
  String? get estimatedConsultationTime {
    if (checkedInAt != null) {
      final estTime = checkedInAt!.add(Duration(minutes: estimatedWaitMinutes));
      final h = estTime.hour.toString().padLeft(2, '0');
      final m = estTime.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return null;
  }

  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      id: map['id'] as String,
      appointmentId: map['appointmentId'] as String,
      doctorId: map['doctorId'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      tokenNumber: map['tokenNumber'] as String,
      tokenSequence: map['tokenSequence'] as int,
      status: QueueStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => QueueStatus.waiting,
      ),
      patientsAhead: map['patientsAhead'] as int,
      estimatedWaitMinutes: map['estimatedWaitMinutes'] as int,
      calledAt: map['calledAt'] != null
          ? DateTime.parse(map['calledAt'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      avgConsultationMinutes: map['avgConsultationMinutes'] as int? ?? 15,
      date: map['date'] as String,
      isEmergency: map['isEmergency'] as bool? ?? false,
      checkedInAt: map['checkedInAt'] != null
          ? DateTime.parse(map['checkedInAt'] as String)
          : null,
      queuePosition: map['queuePosition'] as int?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'tokenNumber': tokenNumber,
      'tokenSequence': tokenSequence,
      'status': status.name,
      'patientsAhead': patientsAhead,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'calledAt': calledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'avgConsultationMinutes': avgConsultationMinutes,
      'date': date,
      'isEmergency': isEmergency,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'queuePosition': queuePosition,
      'notes': notes,
    };
  }

  QueueModel copyWith({
    String? id,
    String? appointmentId,
    String? doctorId,
    String? patientId,
    String? patientName,
    String? tokenNumber,
    int? tokenSequence,
    QueueStatus? status,
    int? patientsAhead,
    int? estimatedWaitMinutes,
    DateTime? calledAt,
    DateTime? completedAt,
    int? avgConsultationMinutes,
    String? date,
    bool? isEmergency,
    DateTime? checkedInAt,
    int? queuePosition,
    String? notes,
  }) {
    return QueueModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      tokenSequence: tokenSequence ?? this.tokenSequence,
      status: status ?? this.status,
      patientsAhead: patientsAhead ?? this.patientsAhead,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      calledAt: calledAt ?? this.calledAt,
      completedAt: completedAt ?? this.completedAt,
      avgConsultationMinutes:
          avgConsultationMinutes ?? this.avgConsultationMinutes,
      date: date ?? this.date,
      isEmergency: isEmergency ?? this.isEmergency,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      queuePosition: queuePosition ?? this.queuePosition,
      notes: notes ?? this.notes,
    );
  }
}

class DoctorQueue {
  final String doctorId;
  final String doctorName;
  final String date;
  final String currentTokenNumber;
  final int currentTokenSequence;
  final List<QueueModel> queue;
  final int totalPatients;
  final int completedPatients;
  final int waitingPatients;

  const DoctorQueue({
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.currentTokenNumber,
    required this.currentTokenSequence,
    required this.queue,
    required this.totalPatients,
    required this.completedPatients,
    required this.waitingPatients,
  });

  // ─── Computed getters ──────────────────────────────────────────────────

  /// All queue items (alias for backward compatibility).
  List<QueueModel> get items => queue;

  /// The patient currently in consultation (inProgress status).
  QueueModel? get currentToken =>
      queue.where((q) => q.status == QueueStatus.inProgress).firstOrNull;

  /// All patients still waiting sorted by sequence.
  List<QueueModel> get waitingQueue =>
      queue.where((q) => q.status == QueueStatus.waiting).toList()
        ..sort((a, b) => a.tokenSequence.compareTo(b.tokenSequence));

  /// Alias for waitingQueue used in doctor dashboard.
  List<QueueModel> get waitingTokens => waitingQueue;

  /// Count of waiting patients.
  int get waitingCount => waitingPatients;

  /// Count of completed patients.
  int get completedCount => completedPatients;

  /// Count of no-show patients.
  int get noShowCount =>
      queue.where((q) => q.status == QueueStatus.noShow).length;

  /// Total patients booked today including completed.
  int get totalTodayCount => totalPatients;

  /// Average wait time in minutes (based on avg consultation).
  int get avgWaitTimeMinutes =>
      queue.isNotEmpty ? queue.first.avgConsultationMinutes : 15;
}
