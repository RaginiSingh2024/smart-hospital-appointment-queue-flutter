import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (Deep Blue)
  static const Color primary = Color(0xFF1E3A8A); // Tailwind blue-900
  static const Color primaryDark = Color(0xFF172554); // Tailwind blue-950
  static const Color primaryLight = Color(0xFF2563EB); // Tailwind blue-600
  static const Color primarySurface = Color(0xFFEFF6FF); // Tailwind blue-50

  // Accent / Teal
  static const Color accent = Color(0xFF0D9488); // Tailwind teal-600
  static const Color accentDark = Color(0xFF0F766E); // Tailwind teal-700
  static const Color accentLight = Color(0xFF5EEAD4); // Tailwind teal-300
  static const Color accentSurface = Color(0xFFF0FDFA); // Tailwind teal-50

  // Secondary
  static const Color secondary = Color(0xFF475569); // Tailwind slate-600
  static const Color secondarySurface = Color(0xFFF8FAFC); // Tailwind slate-50

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // Appointment Status Colors
  static const Color statusConfirmed = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFF6366F1);
  static const Color statusCheckedIn = Color(0xFF06B6D4);

  // Specialty Colors
  static const Color cardiology = Color(0xFFEF4444);
  static const Color dermatology = Color(0xFFEC4899);
  static const Color neurology = Color(0xFF8B5CF6);
  static const Color pediatrics = Color(0xFF10B981);
  static const Color orthopedics = Color(0xFFF59E0B);
  static const Color generalMedicine = Color(0xFF3B82F6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Divider
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Shadow
  static const Color shadow = Color(0x0A000000); // 4% black
  static const Color shadowMedium = Color(0x14000000); // 8% black
}
