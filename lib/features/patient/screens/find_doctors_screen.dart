import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/doctor_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../providers/doctor_provider.dart';

class FindDoctorsScreen extends ConsumerStatefulWidget {
  final String? initialDepartmentId;

  const FindDoctorsScreen({super.key, this.initialDepartmentId});

  @override
  ConsumerState<FindDoctorsScreen> createState() => _FindDoctorsScreenState();
}

class _FindDoctorsScreenState extends ConsumerState<FindDoctorsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDepartmentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedDepartmentFilterProvider.notifier).state =
            widget.initialDepartmentId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = ref.watch(filteredDoctorsProvider);
    final departments = ref.watch(departmentsProvider);
    final selectedDept = ref.watch(selectedDepartmentFilterProvider);
    final availFilter = ref.watch(availabilityFilterProvider);
    final sortByFee = ref.watch(sortByFeeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Doctors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/patient'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterBottomSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name, specialty...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textLight, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: AppTextStyles.bodyMedium,
                onChanged: (v) {
                  ref.read(doctorSearchQueryProvider.notifier).state = v;
                },
              ),
            ),
          ),

          // Department Filter Chips
          Container(
            height: 50,
            color: Colors.white,
            child: departments.when(
              data: (depts) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedDept == null,
                    onSelected: (_) => ref
                        .read(selectedDepartmentFilterProvider.notifier)
                        .state = null,
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  const SizedBox(width: 8),
                  ...depts.map((dept) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${dept.icon} ${dept.name}'),
                          selected: selectedDept == dept.id,
                          onSelected: (_) => ref
                              .read(selectedDepartmentFilterProvider.notifier)
                              .state = dept.id,
                          selectedColor: AppColors.primarySurface,
                          checkmarkColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      )),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Active Filters Indicator
          if (availFilter || sortByFee)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primarySurface,
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  if (availFilter)
                    const _FilterTag(label: 'Available Only'),
                  const SizedBox(width: 8),
                  if (sortByFee)
                    const _FilterTag(label: 'Sorted by Fee'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(availabilityFilterProvider.notifier).state = false;
                      ref.read(sortByFeeProvider.notifier).state = false;
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Doctor List
          Expanded(
            child: filteredDoctors.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No Doctors Found',
                    subtitle: 'Try adjusting your search filters',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (ctx, i) {
                    final doctor = doctors[i];
                    return DoctorCard(
                      doctor: doctor,
                      onTap: () =>
                          context.go('/patient/doctor/${doctor.id}'),
                      onBook: doctor.isAvailable
                          ? () => context.go('/patient/doctor/${doctor.id}')
                          : null,
                    );
                  },
                );
              },
              loading: () => const LoadingWidget(message: 'Loading doctors...'),
              error: (e, _) => ErrorWidget2(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => _FilterBottomSheet(),
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;

  const _FilterTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availFilter = ref.watch(availabilityFilterProvider);
    final sortByFee = ref.watch(sortByFeeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppTextStyles.headlineSmall),
              TextButton(
                onPressed: () {
                  ref.read(availabilityFilterProvider.notifier).state = false;
                  ref.read(sortByFeeProvider.notifier).state = false;
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Available Doctors Only',
                style: AppTextStyles.titleSmall),
            subtitle: Text('Show only currently available doctors',
                style: AppTextStyles.bodySmall),
            value: availFilter,
            onChanged: (v) =>
                ref.read(availabilityFilterProvider.notifier).state = v,
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title:
                Text('Sort by Consultation Fee', style: AppTextStyles.titleSmall),
            subtitle: Text('Low to high fee ordering',
                style: AppTextStyles.bodySmall),
            value: sortByFee,
            onChanged: (v) =>
                ref.read(sortByFeeProvider.notifier).state = v,
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
