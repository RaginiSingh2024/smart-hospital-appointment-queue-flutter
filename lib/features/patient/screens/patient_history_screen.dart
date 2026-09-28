import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/mock/mock_data.dart';
import '../../../models/consultation.dart';

class PatientHistoryScreen extends ConsumerWidget {
  const PatientHistoryScreen({super.key});

  void _showPrescriptionModal(BuildContext context, Consultation consultation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Digital Rx Prescription', style: AppTextStyles.titleLarge),
                    Text('Record ID: ${consultation.id.toUpperCase()}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prescription PDF exported to downloads')),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),

            // Doctor details
            Text(consultation.doctorName, style: AppTextStyles.titleMedium),
            Text(
              '${consultation.doctorSpecialty} • ${consultation.departmentName}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Diagnosis
            Text('Clinical Diagnosis', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(consultation.diagnosis, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),

            // Vitals
            Text('Vitals Recorded at Triage', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _vitalItem('BP', '120/80 mmHg'),
                  _vitalItem('Pulse', '74 bpm'),
                  _vitalItem('Temp', '98.6 °F'),
                  _vitalItem('SpO2', '99%'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Medications
            Text('Prescribed Medications', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            ...consultation.medicines.map((med) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(med, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      Text('Take as prescribed',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),

            if (consultation.notes.isNotEmpty) ...[
              Text('Doctor Advice', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(consultation.notes, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _vitalItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultations = MockData.consultations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Consultation History & Rx'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        itemBuilder: (ctx, i) {
          final c = consultations[i];
          final dateStr = DateFormat('MMM d, yyyy').format(c.consultationDate);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.doctorName, style: AppTextStyles.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.doctorSpecialty} • $dateStr',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text('Diagnosis: ${c.diagnosis}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Prescription: ${c.medicines.join(", ")}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('View Digital Rx', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () => _showPrescriptionModal(context, c),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
