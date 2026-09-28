enum PaymentMethod { upi, card, netBanking, cash }
enum PaymentStatus { pending, success, failed, refunded }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.upi:
        return '📱';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.netBanking:
        return '🏦';
      case PaymentMethod.cash:
        return '💵';
    }
  }
}

class Payment {
  final String id;
  final String appointmentId;
  final String patientId;
  final double consultationFee;
  final double convenienceFee;
  final double priorityFee;
  final double totalAmount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String transactionId;
  final DateTime paidAt;
  final String? upiId;
  final String? cardLast4;
  final String? bankName;

  const Payment({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.consultationFee,
    required this.convenienceFee,
    required this.priorityFee,
    required this.totalAmount,
    required this.method,
    required this.status,
    required this.transactionId,
    required this.paidAt,
    this.upiId,
    this.cardLast4,
    this.bankName,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      appointmentId: map['appointmentId'] as String,
      patientId: map['patientId'] as String,
      consultationFee: (map['consultationFee'] as num).toDouble(),
      convenienceFee: (map['convenienceFee'] as num).toDouble(),
      priorityFee: (map['priorityFee'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == map['method'],
        orElse: () => PaymentMethod.upi,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: map['transactionId'] as String,
      paidAt: DateTime.parse(map['paidAt'] as String),
      upiId: map['upiId'] as String?,
      cardLast4: map['cardLast4'] as String?,
      bankName: map['bankName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'consultationFee': consultationFee,
      'convenienceFee': convenienceFee,
      'priorityFee': priorityFee,
      'totalAmount': totalAmount,
      'method': method.name,
      'status': status.name,
      'transactionId': transactionId,
      'paidAt': paidAt.toIso8601String(),
      'upiId': upiId,
      'cardLast4': cardLast4,
      'bankName': bankName,
    };
  }
}
