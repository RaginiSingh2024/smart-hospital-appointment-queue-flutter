import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_doctors_screen.dart';
import '../../features/admin/screens/admin_profile_screen.dart';
import '../../features/admin/screens/admin_queue_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/doctor/screens/doctor_consultation_screen.dart';
import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import '../../features/doctor/screens/doctor_profile_screen.dart';
import '../../features/doctor/screens/doctor_queue_screen.dart';
import '../../features/doctor/screens/doctor_schedule_screen.dart';
import '../../features/patient/screens/appointment_detail_screen.dart';
import '../../features/patient/screens/booking_screen.dart';
import '../../features/patient/screens/booking_success_screen.dart';
import '../../features/patient/screens/digital_checkin_screen.dart';
import '../../features/patient/screens/doctor_detail_screen.dart';
import '../../features/patient/screens/find_doctors_screen.dart';
import '../../features/patient/screens/live_queue_screen.dart';
import '../../features/patient/screens/my_appointments_screen.dart';
import '../../features/patient/screens/notifications_screen.dart';
import '../../features/patient/screens/patient_history_screen.dart';
import '../../features/patient/screens/patient_home_screen.dart';
import '../../features/patient/screens/patient_profile_screen.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = authState.user;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      final role = user.role;

      if (isLoggingIn || location == '/') {
        if (role == UserRole.doctor) return '/doctor';
        if (role == UserRole.admin) return '/admin';
        return '/patient';
      }

      // Role isolation guards
      if (role == UserRole.patient) {
        if (location.startsWith('/doctor') || location.startsWith('/admin')) {
          return '/patient';
        }
      } else if (role == UserRole.doctor) {
        if (location.startsWith('/patient') || location.startsWith('/admin')) {
          return '/doctor';
        }
      } else if (role == UserRole.admin) {
        if (location.startsWith('/patient') || location.startsWith('/doctor')) {
          return '/admin';
        }
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Patient Routes
      GoRoute(
        path: '/patient',
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: '/patient/find-doctors',
        builder: (context, state) {
          final dept = state.uri.queryParameters['dept'];
          return FindDoctorsScreen(initialDepartmentId: dept);
        },
      ),
      GoRoute(
        path: '/patient/doctor/:doctorId',
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId'] ?? '';
          return DoctorDetailScreen(doctorId: doctorId);
        },
      ),
      GoRoute(
        path: '/patient/book-appointment/:doctorId',
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId'] ?? '';
          final date = state.uri.queryParameters['date'];
          final slot = state.uri.queryParameters['slot'];
          return BookingScreen(
            doctorId: doctorId,
            initialDate: date,
            initialSlot: slot,
          );
        },
      ),
      GoRoute(
        path: '/patient/booking-success/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'] ?? '';
          return BookingSuccessScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/patient/appointments',
        builder: (context, state) => const MyAppointmentsScreen(),
      ),
      GoRoute(
        path: '/patient/appointment/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'] ?? '';
          return AppointmentDetailScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/patient/live-queue',
        builder: (context, state) {
          final doctorId = state.uri.queryParameters['doctor'];
          return LiveQueueScreen(initialDoctorId: doctorId);
        },
      ),
      GoRoute(
        path: '/patient/live-queue/:doctorId',
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId'];
          return LiveQueueScreen(initialDoctorId: doctorId);
        },
      ),
      GoRoute(
        path: '/patient/qr-checkin',
        builder: (context, state) => const DigitalCheckinScreen(),
      ),
      GoRoute(
        path: '/patient/qr-checkin/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'];
          return DigitalCheckinScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/patient/profile',
        builder: (context, state) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: '/patient/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/patient/history',
        builder: (context, state) => const PatientHistoryScreen(),
      ),

      // Doctor Routes
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor/profile',
        builder: (context, state) => const DoctorProfileScreen(),
      ),
      GoRoute(
        path: '/doctor/queue',
        builder: (context, state) => const DoctorQueueScreen(),
      ),
      GoRoute(
        path: '/doctor/consultation/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'] ?? '';
          return DoctorConsultationScreen(appointmentId: appointmentId);
        },
      ),
      GoRoute(
        path: '/doctor/schedule',
        builder: (context, state) => const DoctorScheduleScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/admin/queues',
        builder: (context, state) => const AdminQueueScreen(),
      ),
      GoRoute(
        path: '/admin/doctors',
        builder: (context, state) => const AdminDoctorsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('No route defined for ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final role = authState.user?.role;
                if (role == UserRole.doctor) {
                  context.go('/doctor');
                } else if (role == UserRole.admin) {
                  context.go('/admin');
                } else {
                  context.go('/patient');
                }
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
