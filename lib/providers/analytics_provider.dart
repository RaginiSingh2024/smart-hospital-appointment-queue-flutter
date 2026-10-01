import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock/mock_data.dart';
import '../models/consultation.dart';
import 'auth_provider.dart';

final analyticsProvider = Provider<Map<String, dynamic>>((ref) {
  return MockData.getAnalyticsSummary();
});

final consultationHistoryProvider = FutureProvider<List<Consultation>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final patient = ref.watch(currentPatientProvider);
  if (patient == null) return [];
  return MockData.consultations.where((c) => c.patientId == patient.id).toList()
    ..sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
});

final allConsultationsProvider = FutureProvider<List<Consultation>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockData.consultations;
});
