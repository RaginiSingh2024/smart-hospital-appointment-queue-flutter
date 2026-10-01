import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/time_slot.dart';
import '../../../providers/doctor_provider.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorByIdProvider(widget.doctorId));

    return doctorAsync.when(
      data: (doctor) {
        if (doctor == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorWidget2(message: 'Doctor not found'),
          );
        }

        final slotQuery = SlotQuery(
          doctorId: doctor.id,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
        final slotsAsync = ref.watch(timeSlotsProvider(slotQuery));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/patient/find-doctors');
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                        child: Row(
                          children: [
                            DoctorAvatar(doctor: doctor, size: 80),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(doctor.name,
                                      style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(doctor.specialty,
                                      style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 14,
                                          color: Colors.white70)),
                                  Text(doctor.departmentName,
                                      style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 13,
                                          color: Colors.white54)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFF59E0B), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${doctor.rating} (${doctor.reviewCount} reviews)',
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 12,
                                              color: Colors.white70)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              icon: Icons.work_outline_rounded,
                              label: 'Experience',
                              value: '${doctor.experienceYears} Years',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: Icons.currency_rupee_rounded,
                              label: 'Consultation',
                              value: '₹${doctor.consultationFee.toStringAsFixed(0)}',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              icon: Icons.verified_outlined,
                              label: 'Reg No',
                              value: doctor.registrationNumber.split('-').last,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Qualification
                      _InfoSection(
                        title: 'Qualification',
                        content: doctor.qualification,
                      ),
                      const SizedBox(height: 16),

                      // About
                      _InfoSection(title: 'About', content: doctor.about),
                      const SizedBox(height: 16),

                      // Available Days
                      Text('Available Days', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doctor.availableDays
                            .map((day) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    day,
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // Date Selection
                      Text('Select Date', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 14,
                          itemBuilder: (ctx, i) {
                            final date = DateTime.now().add(Duration(days: i + 1));
                            final isSelected =
                                DateFormat('yyyy-MM-dd').format(date) ==
                                    DateFormat('yyyy-MM-dd').format(_selectedDate);
                            final dayName =
                                DateFormat('EEE').format(date);
                            final isAvailable =
                                doctor.availableDays.contains(
                                    DateFormat('EEEE').format(date));

                            return GestureDetector(
                              onTap: isAvailable
                                  ? () => setState(() => _selectedDate = date)
                                  : null,
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isAvailable
                                          ? Colors.white
                                          : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
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
                                        fontFamily: 'Nunito',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : isAvailable
                                                ? AppColors.textPrimary
                                                : AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM').format(date),
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white70
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
                      const SizedBox(height: 20),

                      // Time Slots
                      Text('Available Time Slots',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 12),
                      slotsAsync.when(
                        data: (slots) {
                          if (slots.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('No slots available for this date'),
                              ),
                            );
                          }
                          return _SlotsGrid(
                            slots: slots,
                            onSlotSelected: (slot) {
                              context.go(
                                  '/patient/book-appointment/${doctor.id}?date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}&slot=${slot.time}');
                            },
                          );
                        },
                        loading: () =>
                            const LoadingWidget(message: 'Loading slots...'),
                        error: (e, _) =>
                            ErrorWidget2(message: e.toString()),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consultation Fee',
                        style: AppTextStyles.caption),
                    Text('₹${doctor.consultationFee.toStringAsFixed(0)} + ₹30 convenience',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: doctor.isAvailable
                      ? () => context.go(
                          '/patient/book-appointment/${doctor.id}?date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}&slot=')
                      : null,
                  child: const Text('Book Appointment'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(body: ErrorWidget2(message: e.toString())),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Text(content,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final Function(TimeSlot) onSlotSelected;

  const _SlotsGrid({required this.slots, required this.onSlotSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isAvailable = slot.isAvailable;
        return GestureDetector(
          onTap: isAvailable ? () => onSlotSelected(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.primarySurface
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAvailable
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Text(
              slot.time,
              style: AppTextStyles.labelMedium.copyWith(
                color: isAvailable ? AppColors.primary : AppColors.textLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
