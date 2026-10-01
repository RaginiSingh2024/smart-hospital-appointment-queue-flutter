import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/queue.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// ─── Appointment Providers ────────────────────────────────────────────────

final patientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  print('[APPOINTMENT PROVIDER] Getting appointments for patient: ${user.id}');
  final appointments = await ref.watch(appointmentRepositoryProvider).getAppointmentsByPatient(user.id);
  print('[APPOINTMENT PROVIDER] Retrieved ${appointments.length} appointments for patient');
  return appointments;
});

final doctorAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final doctor = await ref.watch(doctorByUserIdFutureProvider.future);
  if (doctor == null) return [];
  print('[APPOINTMENT PROVIDER] Getting appointments for doctor: ${doctor.id}');
  final appointments = await ref.watch(appointmentRepositoryProvider).getAppointmentsByDoctor(doctor.id);
  print('[APPOINTMENT PROVIDER] Retrieved ${appointments.length} appointments for doctor');
  return appointments;
});

final doctorByUserIdFutureProvider = FutureProvider<dynamic>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(doctorRepositoryProvider).getDoctorByUserId(user.id);
});

final allAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return ref.watch(appointmentRepositoryProvider).getAllAppointments();
});

final appointmentByIdProvider =
    FutureProvider.family<Appointment?, String>((ref, id) async {
  return ref.watch(appointmentRepositoryProvider).getAppointmentById(id);
});

// ─── Appointment Notifier ─────────────────────────────────────────────────

class AppointmentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AppointmentNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Appointment?> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String departmentId,
    required String departmentName,
    required DateTime appointmentDate,
    required String timeSlot,
    required ConsultationType consultationType,
    required double consultationFee,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Booking appointment for patient: $patientId, doctor: $doctorId');
      final dateStr = DateFormat('yyyy-MM-dd').format(appointmentDate);

      // Check if slot is already booked
      final isBooked = await _ref
          .read(appointmentRepositoryProvider)
          .isSlotBooked(doctorId, dateStr, timeSlot);
      if (isBooked) {
        print('[APPOINTMENT NOTIFIER] Slot already booked');
        state = AsyncValue.error('This slot is already booked. Please select another.', StackTrace.current);
        return null;
      }

      // Get existing appointments count for token generation
      final existingAppointments = await _ref
          .read(appointmentRepositoryProvider)
          .getAppointmentsByDate(dateStr);
      final sequence = existingAppointments.length + 1;
      final tokenNumber = 'A-${sequence.toString().padLeft(3, '0')}';
      final convenienceFee = 30.0;
      final priorityFee = consultationType.additionalFee;
      final totalAmount = consultationFee + convenienceFee + priorityFee;
      final appointmentId = _uuid.v4();
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      final appointment = Appointment(
        id: appointmentId,
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        departmentId: departmentId,
        departmentName: departmentName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        tokenNumber: tokenNumber,
        tokenSequence: sequence,
        status: AppointmentStatus.confirmed,
        consultationType: consultationType,
        consultationFee: consultationFee,
        convenienceFee: convenienceFee,
        priorityFee: priorityFee,
        totalAmount: totalAmount,
        paymentId: transactionId,
        paymentMethod: paymentMethod,
        isPaid: true,
        qrData:
            'HOSP:$appointmentId:$patientId:$doctorId:$tokenNumber:${appointmentDate.toIso8601String()}',
        createdAt: DateTime.now(),
        queuePosition: sequence,
        estimatedWaitMinutes: sequence * 15,
      );

      print('[APPOINTMENT NOTIFIER] Creating appointment in Firestore');
      final created = await _ref
          .read(appointmentRepositoryProvider)
          .createAppointment(appointment);

      // Book the slot in Firestore
      await _ref.read(doctorRepositoryProvider).bookSlot(doctorId, dateStr, timeSlot, appointmentId);

      // Add patient to queue
      final queueRepo = _ref.read(queueRepositoryProvider);
      await queueRepo.addToQueue(
        doctorId: doctorId,
        date: dateStr,
        queueModel: QueueModel(
          id: 'queue_${appointmentId}',
          appointmentId: appointmentId,
          doctorId: doctorId,
          patientId: patientId,
          patientName: patientName,
          tokenNumber: tokenNumber,
          tokenSequence: sequence,
          status: QueueStatus.waiting,
          patientsAhead: 0,
          estimatedWaitMinutes: sequence * 15,
          avgConsultationMinutes: 15,
          date: dateStr,
          isEmergency: consultationType == ConsultationType.emergency,
          queuePosition: sequence,
        ),
      );

      print('[APPOINTMENT NOTIFIER] Appointment created successfully: $appointmentId');

      // Refresh providers
      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);

      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error booking appointment: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Cancelling appointment: $appointmentId');
      await _ref.read(appointmentRepositoryProvider).cancelAppointment(appointmentId);
      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error cancelling appointment: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<Appointment?> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTimeSlot, String patientId) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Rescheduling appointment: $appointmentId');
      final appointment = await _ref
          .read(appointmentRepositoryProvider)
          .rescheduleAppointment(appointmentId, newDate, newTimeSlot);
      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return appointment;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error rescheduling appointment: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> checkIn(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Checking in appointment: $appointmentId');
      await _ref.read(appointmentRepositoryProvider).checkIn(appointmentId);
      _ref.invalidate(patientAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error checking in appointment: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> startConsultation(String appointmentId) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Starting consultation: $appointmentId');
      await _ref.read(appointmentRepositoryProvider).startConsultation(appointmentId);
      _ref.invalidate(doctorAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error starting consultation: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> completeConsultation(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      print('[APPOINTMENT NOTIFIER] Completing consultation: $appointmentId');
      await _ref.read(appointmentRepositoryProvider).completeConsultation(appointmentId);
      _ref.invalidate(doctorAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      _ref.invalidate(patientAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('[APPOINTMENT NOTIFIER] Error completing consultation: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final appointmentNotifierProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<void>>((ref) {
  return AppointmentNotifier(ref);
});

// ─── Booking Service ──────────────────────────────────────────────────────
// A convenience service that screens can use for simple booking flows.

class BookingService {
  final Ref _ref;

  BookingService(this._ref);

  Future<Appointment> bookAppointment({
    required String doctorId,
    required String patientId,
    required String date,
    required String timeSlot,
    required String reason,
    String notes = '',
    String type = 'regular',
    String paymentMethod = 'hospital',
  }) async {
    // Resolve doctor info
    final doctor = await _ref.read(doctorRepositoryProvider).getDoctorById(doctorId);
    if (doctor == null) throw Exception('Doctor not found');

    final patient = _ref.read(currentPatientProvider);
    if (patient == null) throw Exception('Patient not found. Please log in again.');

    final consultationType = _mapType(type);
    final appointmentDate = DateTime.parse(date);

    final result = await _ref.read(appointmentNotifierProvider.notifier).bookAppointment(
      patientId: patient.id,
      patientName: patient.name,
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorSpecialty: doctor.specialty,
      departmentId: doctor.departmentId,
      departmentName: doctor.departmentName,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      consultationType: consultationType,
      consultationFee: doctor.consultationFee,
      paymentMethod: paymentMethod,
    );

    if (result == null) throw Exception('Booking failed. Please try again.');
    return result;
  }

  ConsultationType _mapType(String type) {
    switch (type) {
      case 'follow_up':
        return ConsultationType.followUp;
      case 'emergency':
        return ConsultationType.emergency;
      case 'premium':
        return ConsultationType.premium;
      default:
        return ConsultationType.regular;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String patientId) {
    return _ref.read(appointmentNotifierProvider.notifier).cancelAppointment(appointmentId, patientId);
  }

  Future<bool> checkIn(String appointmentId, String patientId) {
    return _ref.read(appointmentNotifierProvider.notifier).checkIn(appointmentId, patientId);
  }
}

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref);
});
