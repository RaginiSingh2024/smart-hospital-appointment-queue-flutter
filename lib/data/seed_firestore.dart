import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/mock/mock_data.dart';
import 'firebase_options.dart';

Future<void> seedFirestoreData() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    print('🌱 Seeding Firestore data...');

    // Seed departments
    for (final dept in MockData.departments) {
      try {
        await firestore.collection('departments').doc(dept.id).set({
          'name': dept.name,
          'description': dept.description,
          'icon': dept.icon,
          'color': dept.color,
          'totalDoctors': dept.totalDoctors,
          'headDoctorName': dept.headDoctorName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Seeded department: ${dept.name}');
      } catch (e) {
        print('❌ Failed to seed department ${dept.name}: $e');
      }
    }

    // Seed doctors
    for (final doctor in MockData.doctors) {
      try {
        await firestore.collection('doctors').doc(doctor.id).set({
          'userId': doctor.userId,
          'name': doctor.name,
          'specialty': doctor.specialty,
          'departmentId': doctor.departmentId,
          'departmentName': doctor.departmentName,
          'experienceYears': doctor.experienceYears,
          'rating': doctor.rating,
          'reviewCount': doctor.reviewCount,
          'consultationFee': doctor.consultationFee,
          'qualification': doctor.qualification,
          'about': doctor.about,
          'isAvailable': doctor.isAvailable,
          'registrationNumber': doctor.registrationNumber,
          'email': doctor.email,
          'phone': doctor.phone,
          'availableDays': doctor.availableDays,
          'weeklySlots': doctor.weeklySlots,
          'bookedSlots': {},
          'profileImageUrl': doctor.profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Seeded doctor: ${doctor.name} (${doctor.id})');
      } catch (e) {
        print('❌ Failed to seed doctor ${doctor.name}: $e');
      }
    }

    print('🌱 Firestore seeding complete!');
  } catch (e) {
    print('❌ Firestore seeding failed: $e');
    rethrow;
  }
}
