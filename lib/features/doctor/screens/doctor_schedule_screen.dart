import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  int _slotDuration = 15; // 15, 20, 30 mins
  final Map<String, bool> _activeDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };

  String _startTime = '09:00 AM';
  String _endTime = '05:00 PM';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My OPD Schedule & Slots'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/doctor'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shift Hours Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consultation Hours', style: AppTextStyles.titleMedium),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _timeTile('Morning Start', _startTime, (newTime) {
                        setState(() => _startTime = newTime);
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeTile('Evening End', _endTime, (newTime) {
                        setState(() => _endTime = newTime);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Slot Duration Selector
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Slot Duration Interval', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Determines time allocated per patient token',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [15, 20, 30].map((mins) {
                    final isSel = _slotDuration == mins;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _slotDuration = mins),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              '$mins Mins',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Days of Week
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available OPD Days', style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                ..._activeDays.keys.map((day) {
                  final active = _activeDays[day]!;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(day, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    value: active,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _activeDays[day] = val);
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          AppButton(
            label: 'Save Schedule Preferences',
            isLoading: _isSaving,
            onPressed: () async {
              setState(() => _isSaving = true);
              await Future.delayed(const Duration(milliseconds: 600));
              if (mounted) {
                setState(() => _isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doctor schedule updated successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String value, Function(String) onSelect) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
        );
        if (time != null && mounted) {
          onSelect(time.format(context));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
