import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../models/doctor.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/doctor_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String? initialDate;
  final String? initialSlot;

  const BookingScreen({
    super.key,
    required this.doctorId,
    this.initialDate,
    this.initialSlot,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  String? _selectedSlot;
  String _selectedType = 'regular'; // regular, follow_up, emergency
  String _paymentMethod = 'hospital'; // hospital, upi, card
  bool _isSubmitting = false;

  final List<String> _commonSymptoms = [
    'General Checkup',
    'Fever / Cold',
    'Headache',
    'Skin Rash',
    'Chest Discomfort',
    'Follow-up Visit',
    'Lab Report Review',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.initialDate!);
      } catch (_) {
        _selectedDate = DateTime.now().add(const Duration(days: 1));
      }
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }
    _selectedSlot = widget.initialSlot?.isNotEmpty == true ? widget.initialSlot : null;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleBookAppointment(Doctor doctor) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preferred time slot'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final patient = ref.read(currentPatientProvider);

    if (user == null || patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final bookingService = ref.read(bookingServiceProvider);

      final appointment = await bookingService.bookAppointment(
        doctorId: doctor.id,
        patientId: patient.id,
        date: dateStr,
        timeSlot: _selectedSlot!,
        reason: _reasonController.text.trim().isEmpty ? 'General Consultation' : _reasonController.text.trim(),
        notes: _notesController.text.trim(),
        type: _selectedType,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        context.go('/patient/booking-success/${appointment.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorByIdProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient/doctor/${widget.doctorId}');
            }
          },
        ),
      ),
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return const ErrorWidget2(message: 'Doctor details not found');
          }

          final slotQuery = SlotQuery(
            doctorId: doctor.id,
            date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          );
          final slotsAsync = ref.watch(timeSlotsProvider(slotQuery));
          final convenienceFee = 30.0;
          final totalFee = doctor.consultationFee + convenienceFee;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Doctor Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      DoctorAvatar(doctor: doctor, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${doctor.specialty} • ${doctor.departmentName}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.roomNumber ?? 'Room 204',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appointment Type Selector
                Text('Consultation Type', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _typeOption('regular', 'OPD Visit', Icons.local_hospital_rounded),
                    const SizedBox(width: 10),
                    _typeOption('follow_up', 'Follow-up', Icons.replay_rounded),
                    const SizedBox(width: 10),
                    _typeOption('emergency', 'Priority', Icons.bolt_rounded),
                  ],
                ),
                const SizedBox(height: 24),

                // Date Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Date', style: AppTextStyles.headlineSmall),
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 76,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (ctx, i) {
                      final date = DateTime.now().add(Duration(days: i + 1));
                      final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                          DateFormat('yyyy-MM-dd').format(_selectedDate);
                      final dayName = DateFormat('EEE').format(date);
                      final isAvailable = doctor.availableDays.contains(DateFormat('EEEE').format(date));

                      return GestureDetector(
                        onTap: isAvailable
                            ? () {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedSlot = null;
                                });
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isAvailable
                                    ? Colors.white
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isAvailable
                                          ? AppColors.textSecondary
                                          : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d').format(date),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : isAvailable
                                          ? AppColors.textPrimary
                                          : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Slot Selection
                Text('Preferred Slot', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                slotsAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No slots available for this date. Please pick another day.'),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((slot) {
                        final isSelected = _selectedSlot == slot.time;
                        final isAvailable = slot.isAvailable;

                        return GestureDetector(
                          onTap: isAvailable ? () => setState(() => _selectedSlot = slot.time) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isAvailable
                                      ? Colors.white
                                      : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : isAvailable
                                        ? AppColors.border
                                        : AppColors.border,
                              ),
                            ),
                            child: Text(
                              slot.time,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                        ? AppColors.textPrimary
                                        : AppColors.textLight,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LoadingWidget(message: 'Checking slots...'),
                  error: (e, _) => ErrorWidget2(message: e.toString()),
                ),
                const SizedBox(height: 24),

                // Reason / Symptoms Quick Chips
                Text('Reason for Visit', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonSymptoms.map((symptom) {
                    final isChosen = _reasonController.text == symptom;
                    return ChoiceChip(
                      label: Text(symptom),
                      selected: isChosen,
                      selectedColor: AppColors.primarySurface,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isChosen ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _reasonController.text = selected ? symptom : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Or describe your symptoms in detail...',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  maxLines: 2,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please mention a reason for visit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes for doctor (allergies, ongoing meds, etc.)',
                    prefixIcon: Icon(Icons.info_outline_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Payment Options
                Text('Payment Mode', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'hospital',
                        groupValue: _paymentMethod,
                        title: const Text('Pay at Hospital Desk', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Pay via Cash, Card or UPI during digital check-in'),
                        secondary: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'upi',
                        groupValue: _paymentMethod,
                        title: const Text('Pay Online via UPI', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Google Pay, PhonePe, Paytm, BHIM'),
                        secondary: const Icon(Icons.qr_code_2_rounded, color: AppColors.accent),
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'card',
                        groupValue: _paymentMethod,
                        title: const Text('Debit / Credit Card', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Visa, MasterCard, RuPay'),
                        secondary: const Icon(Icons.credit_card_rounded, color: AppColors.secondary),
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Price Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Doctor Consultation Fee', style: AppTextStyles.bodyMedium),
                          Text('₹${doctor.consultationFee.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hospital Convenience Fee', style: AppTextStyles.bodyMedium),
                          Text('₹${convenienceFee.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.divider),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Payable', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            '₹${totalFee.toStringAsFixed(0)}',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  label: _paymentMethod == 'hospital' ? 'Confirm Booking & Get Token' : 'Pay & Confirm Appointment',
                  isLoading: _isSubmitting,
                  onPressed: () => _handleBookAppointment(doctor),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading doctor details...'),
        error: (e, _) => ErrorWidget2(message: e.toString()),
      ),
    );
  }

  Widget _typeOption(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
