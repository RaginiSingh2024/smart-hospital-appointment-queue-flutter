import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/queue.dart';
import '../models/notification_model.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// ─── Appointment Providers ────────────────────────────────────────────────

final patientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  // Get patient id from mock data
  final patient = ref.watch(currentPatientProvider);
  if (patient == null) return [];
  return ref.watch(appointmentRepositoryProvider).getAppointmentsByPatient(patient.id);
});

final doctorAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final doctor = await ref.watch(doctorByUserIdFutureProvider.future);
  if (doctor == null) return [];
  return ref.watch(appointmentRepositoryProvider).getAppointmentsByDoctor(doctor.id);
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
      final repo = _ref.read(mockAppointmentRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(appointmentDate);

      // Check if slot is already booked
      final isBooked = await _ref
          .read(appointmentRepositoryProvider)
          .isSlotBooked(doctorId, dateStr, timeSlot);
      if (isBooked) {
        state = AsyncValue.error('This slot is already booked. Please select another.', StackTrace.current);
        return null;
      }

      final sequence = repo.getNextTokenSequence(doctorId, dateStr);
      final tokenNumber = repo.generateTokenNumber(doctorId, sequence);
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

      final created = await _ref
          .read(appointmentRepositoryProvider)
          .createAppointment(appointment);

      // Book the slot
      await _ref.read(doctorRepositoryProvider).bookSlot(doctorId, dateStr, timeSlot, appointmentId);

      // Add to queue
      final queueRepo = _ref.read(mockQueueRepositoryProvider);
      queueRepo.addToQueue(QueueModel(
        id: _uuid.v4(),
        appointmentId: appointmentId,
        doctorId: doctorId,
        patientId: patientId,
        patientName: patientName,
        tokenNumber: tokenNumber,
        tokenSequence: sequence,
        status: QueueStatus.waiting,
        patientsAhead: sequence - 1,
        estimatedWaitMinutes: (sequence - 1) * 15,
        date: dateStr,
      ));

      // Send notifications
      final notifRepo = _ref.read(mockNotificationRepositoryProvider);
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Appointment Confirmed ✅',
        body: 'Your appointment with $doctorName is confirmed for ${DateFormat('dd MMM yyyy').format(appointmentDate)} at $timeSlot. Token: $tokenNumber',
        type: NotificationType.appointmentConfirmed,
        appointmentId: appointmentId,
      );
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Payment Successful 💳',
        body: 'Payment of ₹${totalAmount.toStringAsFixed(0)} received. Transaction ID: $transactionId',
        type: NotificationType.paymentSuccess,
        appointmentId: appointmentId,
      );

      // Refresh providers
      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);

      state = const AsyncValue.data(null);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(appointmentRepositoryProvider).cancelAppointment(appointmentId);

      final notifRepo = _ref.read(mockNotificationRepositoryProvider);
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Appointment Cancelled',
        body: 'Your appointment has been cancelled successfully.',
        type: NotificationType.appointmentCancelled,
        appointmentId: appointmentId,
      );

      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<Appointment?> rescheduleAppointment(
      String appointmentId, DateTime newDate, String newTimeSlot, String patientId) async {
    state = const AsyncValue.loading();
    try {
      final appointment = await _ref
          .read(appointmentRepositoryProvider)
          .rescheduleAppointment(appointmentId, newDate, newTimeSlot);

      final notifRepo = _ref.read(mockNotificationRepositoryProvider);
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Appointment Rescheduled 📅',
        body: 'Your appointment has been rescheduled to ${DateFormat('dd MMM yyyy').format(newDate)} at $newTimeSlot.',
        type: NotificationType.appointmentRescheduled,
        appointmentId: appointmentId,
      );

      _ref.invalidate(patientAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return appointment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> checkIn(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(appointmentRepositoryProvider).checkIn(appointmentId);
      await _ref.read(queueRepositoryProvider).checkInPatient(appointmentId);

      final notifRepo = _ref.read(mockNotificationRepositoryProvider);
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Check-in Successful ✔️',
        body: 'You have checked in successfully. Please wait for your token to be called.',
        type: NotificationType.checkedIn,
        appointmentId: appointmentId,
      );

      _ref.invalidate(patientAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> startConsultation(String appointmentId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(appointmentRepositoryProvider).startConsultation(appointmentId);
      _ref.invalidate(doctorAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> completeConsultation(String appointmentId, String patientId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(appointmentRepositoryProvider).completeConsultation(appointmentId);

      final notifRepo = _ref.read(mockNotificationRepositoryProvider);
      await notifRepo.createNotification(
        userId: patientId,
        title: 'Consultation Completed 🏥',
        body: 'Your consultation is complete. View your prescription in Consultation History.',
        type: NotificationType.consultationCompleted,
        appointmentId: appointmentId,
      );

      _ref.invalidate(doctorAppointmentsProvider);
      _ref.invalidate(allAppointmentsProvider);
      _ref.invalidate(patientAppointmentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
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
