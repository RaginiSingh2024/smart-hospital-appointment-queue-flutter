enum SlotStatus { available, booked, unavailable }

class TimeSlot {
  final String id;
  final String doctorId;
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm'
  final SlotStatus status;
  final String? appointmentId;

  const TimeSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    this.appointmentId,
  });

  bool get isAvailable => status == SlotStatus.available;

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      status: SlotStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SlotStatus.available,
      ),
      appointmentId: map['appointmentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'status': status.name,
      'appointmentId': appointmentId,
    };
  }

  TimeSlot copyWith({
    String? id,
    String? doctorId,
    String? date,
    String? time,
    SlotStatus? status,
    String? appointmentId,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      appointmentId: appointmentId ?? this.appointmentId,
    );
  }
}
