import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/appointment.dart';

class AppointmentStatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const AppointmentStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.statusConfirmed;
      case AppointmentStatus.pending:
        return AppColors.statusPending;
      case AppointmentStatus.cancelled:
        return AppColors.statusCancelled;
      case AppointmentStatus.completed:
        return AppColors.statusCompleted;
      case AppointmentStatus.checkedIn:
        return AppColors.statusCheckedIn;
      case AppointmentStatus.inQueue:
        return AppColors.accent;
      case AppointmentStatus.inConsultation:
        return AppColors.primary;
      case AppointmentStatus.rescheduled:
        return AppColors.warning;
      case AppointmentStatus.noShow:
        return AppColors.error;
    }
  }

  Color get _bgColor {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.successSurface;
      case AppointmentStatus.pending:
        return AppColors.warningSurface;
      case AppointmentStatus.cancelled:
        return AppColors.errorSurface;
      case AppointmentStatus.completed:
        return AppColors.secondarySurface;
      case AppointmentStatus.checkedIn:
        return AppColors.accentSurface;
      case AppointmentStatus.inQueue:
        return AppColors.primarySurface;
      case AppointmentStatus.inConsultation:
        return AppColors.primarySurface;
      case AppointmentStatus.rescheduled:
        return AppColors.warningSurface;
      case AppointmentStatus.noShow:
        return AppColors.errorSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: AppTextStyles.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onQRCheckIn;
  final VoidCallback? onCheckIn;
  final VoidCallback? onViewQr;
  final VoidCallback? onTrackQueue;
  final VoidCallback? onViewDetails;
  final bool showActions;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onReschedule,
    this.onCancel,
    this.onQRCheckIn,
    this.onCheckIn,
    this.onViewQr,
    this.onTrackQueue,
    this.onViewDetails,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appointment.doctorName,
                            style: AppTextStyles.titleSmall
                                .copyWith(color: Colors.white)),
                        Text(appointment.doctorSpecialty,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  AppointmentStatusBadge(status: appointment.status),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy')
                            .format(appointment.appointmentDate),
                      ),
                      const SizedBox(width: 16),
                      _DetailItem(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: appointment.timeSlot,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DetailItem(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Token',
                        value: appointment.tokenNumber,
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      _DetailItem(
                        icon: Icons.local_hospital_outlined,
                        label: 'Department',
                        value: appointment.departmentName,
                      ),
                    ],
                  ),
                  if (appointment.isUpcoming &&
                      appointment.estimatedWaitMinutes != null &&
                      appointment.queuePosition != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _QueueInfo(
                            label: 'Queue Position',
                            value: '#${appointment.queuePosition}',
                          ),
                          Container(
                              width: 1,
                              height: 30,
                              color: AppColors.divider),
                          _QueueInfo(
                            label: 'Est. Wait',
                            value: '${appointment.estimatedWaitMinutes} min',
                          ),
                          Container(
                              width: 1,
                              height: 30,
                              color: AppColors.divider),
                          _QueueInfo(
                            label: 'Fee',
                            value:
                                '₹${appointment.totalAmount.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showActions && _shouldShowActions()) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildActions(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowActions() {
    return appointment.status == AppointmentStatus.confirmed ||
        appointment.status == AppointmentStatus.pending ||
        appointment.status == AppointmentStatus.checkedIn;
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onViewDetails != null)
          _ActionButton(
            icon: Icons.visibility_outlined,
            label: 'View',
            onTap: onViewDetails!,
            color: AppColors.info,
          ),
        if (onQRCheckIn != null &&
            appointment.status == AppointmentStatus.confirmed)
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Check In',
            onTap: onQRCheckIn!,
            color: AppColors.success,
          ),
        if (onReschedule != null &&
            appointment.status != AppointmentStatus.checkedIn)
          _ActionButton(
            icon: Icons.edit_calendar_outlined,
            label: 'Reschedule',
            onTap: onReschedule!,
            color: AppColors.warning,
          ),
        if (onCancel != null &&
            appointment.status != AppointmentStatus.checkedIn)
          _ActionButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel',
            onTap: onCancel!,
            color: AppColors.error,
          ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(
                value,
                style: AppTextStyles.labelMedium.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueInfo extends StatelessWidget {
  final String label;
  final String value;

  const _QueueInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
