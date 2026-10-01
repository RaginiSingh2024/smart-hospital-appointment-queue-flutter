import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/appointment.dart';
import '../../../models/consultation.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/repository_providers.dart';

class DoctorConsultationScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const DoctorConsultationScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _MedicineItem {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String timing;

  const _MedicineItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.timing,
  });
}

class _DoctorConsultationScreenState extends ConsumerState<DoctorConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();

  DateTime _followUpDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  Appointment? _appointment;

  final List<_MedicineItem> _medicines = [
    const _MedicineItem(
      name: 'Levocetirizine 5mg',
      dosage: '1 tablet',
      frequency: '0-0-1',
      duration: '5 days',
      timing: 'After dinner',
    ),
    const _MedicineItem(
      name: 'Hydrocortisone 1% Cream',
      dosage: 'Topical Application',
      frequency: '1-0-1',
      duration: '7 days',
      timing: 'Apply thin layer on rash',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    final appointment = await ref.read(appointmentRepositoryProvider).getAppointmentById(widget.appointmentId);
    if (mounted && appointment != null) {
      setState(() => _appointment = appointment);
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 tablet');
    final freqCtrl = TextEditingController(text: '1-0-1');
    final durCtrl = TextEditingController(text: '5 days');
    final timingCtrl = TextEditingController(text: 'After food');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Medicine Name', hintText: 'e.g. Paracetamol 500mg'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 1 tab / 5ml'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: freqCtrl,
                decoration: const InputDecoration(labelText: 'Frequency', hintText: 'e.g. 1-0-1 (Morn-Aft-Night)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durCtrl,
                decoration: const InputDecoration(labelText: 'Duration', hintText: 'e.g. 5 days'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timingCtrl,
                decoration: const InputDecoration(labelText: 'Instructions', hintText: 'e.g. After meals'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _medicines.add(
                    _MedicineItem(
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      frequency: freqCtrl.text.trim(),
                      duration: durCtrl.text.trim(),
                      timing: timingCtrl.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add to Rx'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      if (_appointment == null) {
        throw Exception('Appointment not found');
      }

      // 1. Mark appointment completed
      final apptRepo = ref.read(appointmentRepositoryProvider);
      await apptRepo.completeConsultation(widget.appointmentId);

      // 2. Add consultation record to Firestore
      final consultationRepo = ref.read(consultationRepositoryProvider);
      final consultation = Consultation(
        id: '',
        appointmentId: widget.appointmentId,
        patientId: _appointment!.patientId,
        patientName: _appointment!.patientName,
        doctorId: _appointment!.doctorId,
        doctorName: _appointment!.doctorName,
        doctorSpecialty: _appointment!.doctorSpecialty,
        departmentName: _appointment!.departmentName,
        consultationDate: DateTime.now(),
        diagnosis: _diagnosisController.text.trim(),
        prescription: _medicines.map((m) => '${m.name} (${m.dosage}, ${m.frequency}) for ${m.duration} - ${m.timing}').join('\n'),
        notes: _notesController.text.trim(),
        medicines: _medicines.map((m) => '${m.name} (${m.dosage}, ${m.frequency})').toList(),
        followUpDate: DateFormat('yyyy-MM-dd').format(_followUpDate),
        isPaid: _appointment!.isPaid,
        amountPaid: _appointment!.totalAmount,
        paymentMethod: _appointment!.paymentMethod ?? 'Hospital Desk',
      );
      await consultationRepo.createConsultation(consultation);

      // 3. Mark queue token completed
      final queueRepo = ref.read(queueRepositoryProvider);
      final today = DateTime.now();
      final date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await queueRepo.markComplete(_appointment!.doctorId, widget.appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Consultation completed! Digital prescription sent to patient.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/doctor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clinical Consultation & Rx'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/doctor'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      _appointment?.patientName.isNotEmpty == true 
                          ? _appointment!.patientName.substring(0, 1).toUpperCase() 
                          : 'P',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_appointment?.patientName ?? 'Patient', style: AppTextStyles.titleMedium),
                        Text('Token: ${_appointment?.tokenNumber ?? "-"} • ${_appointment?.timeSlot ?? "-"}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Department: ${_appointment?.departmentName ?? "-"}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Patient Vitals Section
            Text('Patient Vitals', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bpController,
                    decoration: const InputDecoration(labelText: 'Blood Pressure', prefixIcon: Icon(Icons.favorite_rounded, size: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _pulseController,
                    decoration: const InputDecoration(labelText: 'Pulse (bpm)', prefixIcon: Icon(Icons.monitor_heart_rounded, size: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tempController,
                    decoration: const InputDecoration(labelText: 'Temp (°F)', prefixIcon: Icon(Icons.thermostat_rounded, size: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _spo2Controller,
                    decoration: const InputDecoration(labelText: 'SpO2 (%)', prefixIcon: Icon(Icons.air_rounded, size: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Diagnosis
            Text('Clinical Diagnosis', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                hintText: 'Enter clinical diagnosis & findings',
                prefixIcon: Icon(Icons.health_and_safety_rounded),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter a diagnosis' : null,
            ),
            const SizedBox(height: 20),

            // Prescription Builder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prescribed Medicines (${_medicines.length})', style: AppTextStyles.headlineSmall),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Drug', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _showAddMedicineDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._medicines.asMap().entries.map((entry) {
              final idx = entry.key;
              final med = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_liquid_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
                          Text('${med.dosage} • ${med.frequency} for ${med.duration}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          Text(med.timing, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      onPressed: () {
                        setState(() => _medicines.removeAt(idx));
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Advice & Instructions
            Text('Doctor Advice & Precautions', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Lifestyle advice, diet restrictions, wound care, etc.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Follow-up Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Follow-up', style: AppTextStyles.labelMedium),
                    Text(DateFormat('EEE, d MMM yyyy').format(_followUpDate),
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _followUpDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setState(() => _followUpDate = picked);
                    }
                  },
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            AppButton(
              label: 'Complete Consultation & Issue Rx',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _completeConsultation,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
