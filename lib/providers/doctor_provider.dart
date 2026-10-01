import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor.dart';
import '../models/time_slot.dart';
import '../models/department.dart';
import '../models/user.dart';
import '../data/mock/mock_data.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// ─── Departments ──────────────────────────────────────────────────────────

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return MockData.departments;
});

// ─── Doctors ──────────────────────────────────────────────────────────────

final doctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  return ref.watch(doctorRepositoryProvider).getDoctors();
});

final doctorByIdProvider = FutureProvider.family<Doctor?, String>((ref, id) async {
  return ref.watch(doctorRepositoryProvider).getDoctorById(id);
});

final doctorsByDepartmentProvider =
    FutureProvider.family<List<Doctor>, String>((ref, departmentId) async {
  return ref.watch(doctorRepositoryProvider).getDoctorsByDepartment(departmentId);
});

// ─── Doctor Search ────────────────────────────────────────────────────────

final doctorSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedDepartmentFilterProvider = StateProvider<String?>((ref) => null);
final selectedSpecialtyFilterProvider = StateProvider<String?>((ref) => null);
final availabilityFilterProvider = StateProvider<bool>((ref) => false);
final sortByFeeProvider = StateProvider<bool>((ref) => false);

final filteredDoctorsProvider = Provider<AsyncValue<List<Doctor>>>((ref) {
  final query = ref.watch(doctorSearchQueryProvider);
  final departmentFilter = ref.watch(selectedDepartmentFilterProvider);
  final availabilityFilter = ref.watch(availabilityFilterProvider);
  final sortByFee = ref.watch(sortByFeeProvider);
  final doctorsAsync = ref.watch(doctorsProvider);

  return doctorsAsync.whenData((doctors) {
    var filtered = doctors;

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.specialty.toLowerCase().contains(q) ||
            d.departmentName.toLowerCase().contains(q);
      }).toList();
    }

    if (departmentFilter != null) {
      filtered = filtered.where((d) => d.departmentId == departmentFilter).toList();
    }

    if (availabilityFilter) {
      filtered = filtered.where((d) => d.isAvailable).toList();
    }

    if (sortByFee) {
      filtered = List.from(filtered)
        ..sort((a, b) => a.consultationFee.compareTo(b.consultationFee));
    }

    return filtered;
  });
});

// ─── Time Slots ───────────────────────────────────────────────────────────

class SlotQuery {
  final String doctorId;
  final String date;

  const SlotQuery({required this.doctorId, required this.date});

  @override
  bool operator ==(Object other) =>
      other is SlotQuery && other.doctorId == doctorId && other.date == date;

  @override
  int get hashCode => Object.hash(doctorId, date);
}

final timeSlotsProvider = FutureProvider.family<List<TimeSlot>, SlotQuery>((ref, query) async {
  return ref.watch(doctorRepositoryProvider).getAvailableSlots(query.doctorId, query.date);
});

final selectedDateProvider = StateProvider.family<DateTime, String>((ref, doctorId) {
  return DateTime.now().add(const Duration(days: 1));
});

final selectedSlotProvider = StateProvider<TimeSlot?>((ref) => null);

// ─── Doctor by userId ─────────────────────────────────────────────────────

final doctorByUserIdProvider = FutureProvider.family<Doctor?, String>((ref, userId) async {
  return ref.watch(doctorRepositoryProvider).getDoctorByUserId(userId);
});

final currentDoctorProvider = FutureProvider<Doctor?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.role != UserRole.doctor) return null;
  final docRepo = ref.watch(doctorRepositoryProvider);
  final docByUid = await docRepo.getDoctorByUserId(user.id);
  if (docByUid != null) return docByUid;

  final allDocs = await docRepo.getDoctors();
  final cleanEmail = user.email.toLowerCase();
  final matched = allDocs.where((d) => d.email.toLowerCase() == cleanEmail || d.userId == user.id).firstOrNull;
  if (matched != null) return matched;

  // If newly signed in doctor without matching id, fallback to Dr. Priya Mehta (doc_002)
  return allDocs.where((d) => d.id == 'doc_002').firstOrNull ?? allDocs.firstOrNull;
});
