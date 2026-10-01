import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/remote/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 10485760, // 10 MB
    );
    print('✅ Firestore offline persistence enabled');
  } catch (e) {
    print('⚠️ Firestore persistence setup failed: $e');
  }

  // Seed Firestore data if empty
  await _seedFirestoreIfNeeded();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SmartHospitalApp(),
    ),
  );
}

Future<void> _seedFirestoreIfNeeded() async {
  try {
    final seedService = SeedDataService();
    await seedService.seedAll();
  } catch (e) {
    print('❌ Firestore seeding failed: $e');
  }
}

class SmartHospitalApp extends ConsumerWidget {
  const SmartHospitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Smart Hospital Queue & Appointment',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
