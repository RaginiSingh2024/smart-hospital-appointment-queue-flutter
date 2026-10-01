import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor.dart';
import '../../models/department.dart';

class SeedDataService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SeedDataService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<bool> isSeeded() async {
    try {
      final departments = await _firestore.collection('departments').limit(1).get();
      return departments.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> seedDepartments() async {
    print('[SEED DATA] Seeding departments...');
    final departments = _getSeedDepartments();

    for (final dept in departments) {
      final docRef = _firestore.collection('departments').doc(dept.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'id': dept.id,
          'name': dept.name,
          'description': dept.description,
          'icon': dept.icon,
          'color': dept.color,
          'isActive': dept.isActive,
          'totalDoctors': dept.totalDoctors,
          'headDoctorName': dept.headDoctorName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[SEED DATA] Created department: ${dept.name}');
      }
    }
    print('[SEED DATA] Departments seeded successfully');
  }

  Future<void> seedDoctors() async {
    print('[SEED DATA] Seeding doctors...');
    final doctors = _getSeedDoctors();

    for (final doctor in doctors) {
      final docRef = _firestore.collection('doctors').doc(doctor.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'id': doctor.id,
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
          'isActive': doctor.isActive,
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
        print('[SEED DATA] Created doctor: ${doctor.name}');
      }
    }
    print('[SEED DATA] Doctors seeded successfully');
  }

  Future<void> seedAll() async {
    if (await isSeeded()) {
      print('[SEED DATA] Data already seeded, skipping...');
      return;
    }

    await seedDepartments();
    await seedDoctors();
    print('[SEED DATA] All seed data created successfully');
  }

  List<Department> _getSeedDepartments() {
    return [
      Department(
        id: 'dept_cardiology',
        name: 'Cardiology',
        description: 'Heart and cardiovascular care',
        icon: '❤️',
        color: '#FF6B6B',
        totalDoctors: 3,
        headDoctorName: 'Dr. Sarah Johnson',
      ),
      Department(
        id: 'dept_neurology',
        name: 'Neurology',
        description: 'Brain and nervous system disorders',
        icon: '🧠',
        color: '#4ECDC4',
        totalDoctors: 2,
        headDoctorName: 'Dr. Michael Chen',
      ),
      Department(
        id: 'dept_orthopedics',
        name: 'Orthopedics',
        description: 'Bone and joint care',
        icon: '🦴',
        color: '#95E1D3',
        totalDoctors: 4,
        headDoctorName: 'Dr. Emily Brown',
      ),
      Department(
        id: 'dept_dermatology',
        name: 'Dermatology',
        description: 'Skin and hair care',
        icon: '🌟',
        color: '#F38181',
        totalDoctors: 2,
        headDoctorName: 'Dr. James Wilson',
      ),
      Department(
        id: 'dept_pediatrics',
        name: 'Pediatrics',
        description: 'Child healthcare',
        icon: '👶',
        color: '#AA96DA',
        totalDoctors: 3,
        headDoctorName: 'Dr. Lisa Anderson',
      ),
      Department(
        id: 'dept_general',
        name: 'General Medicine',
        description: 'Primary healthcare',
        icon: '🏥',
        color: '#FCBAD3',
        totalDoctors: 5,
        headDoctorName: 'Dr. Robert Taylor',
      ),
    ];
  }

  List<Doctor> _getSeedDoctors() {
    return [
      Doctor(
        id: 'doc_cardiology_001',
        userId: 'doctor_cardiology_001',
        name: 'Dr. Sarah Johnson',
        specialty: 'Cardiologist',
        departmentId: 'dept_cardiology',
        departmentName: 'Cardiology',
        experienceYears: 15,
        rating: 4.8,
        reviewCount: 234,
        consultationFee: 500,
        qualification: 'MD, FACC',
        about: 'Specialist in interventional cardiology with over 15 years of experience.',
        isAvailable: true,
        isActive: true,
        registrationNumber: 'MCN-12345',
        email: 'sarah.johnson@hospital.com',
        phone: '+91 98765 43210',
        availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        weeklySlots: {
          'Monday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'Tuesday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'Wednesday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'Thursday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
          'Friday': ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'],
        },
      ),
      Doctor(
        id: 'doc_neurology_001',
        userId: 'doctor_neurology_001',
        name: 'Dr. Michael Chen',
        specialty: 'Neurologist',
        departmentId: 'dept_neurology',
        departmentName: 'Neurology',
        experienceYears: 12,
        rating: 4.7,
        reviewCount: 189,
        consultationFee: 600,
        qualification: 'MD, PhD Neurology',
        about: 'Expert in treating neurological disorders and brain injuries.',
        isAvailable: true,
        isActive: true,
        registrationNumber: 'MCN-12346',
        email: 'michael.chen@hospital.com',
        phone: '+91 98765 43211',
        availableDays: ['Monday', 'Wednesday', 'Friday'],
        weeklySlots: {
          'Monday': ['10:00', '11:00', '14:00', '15:00'],
          'Wednesday': ['10:00', '11:00', '14:00', '15:00'],
          'Friday': ['10:00', '11:00', '14:00', '15:00'],
        },
      ),
      Doctor(
        id: 'doc_orthopedics_001',
        userId: 'doctor_orthopedics_001',
        name: 'Dr. Emily Brown',
        specialty: 'Orthopedic Surgeon',
        departmentId: 'dept_orthopedics',
        departmentName: 'Orthopedics',
        experienceYears: 18,
        rating: 4.9,
        reviewCount: 312,
        consultationFee: 550,
        qualification: 'MS Orthopedics',
        about: 'Specialized in joint replacement and sports injuries.',
        isAvailable: true,
        isActive: true,
        registrationNumber: 'MCN-12347',
        email: 'emily.brown@hospital.com',
        phone: '+91 98765 43212',
        availableDays: ['Tuesday', 'Thursday', 'Saturday'],
        weeklySlots: {
          'Tuesday': ['09:00', '10:00', '11:00', '14:00', '15:00'],
          'Thursday': ['09:00', '10:00', '11:00', '14:00', '15:00'],
          'Saturday': ['09:00', '10:00', '11:00'],
        },
      ),
      Doctor(
        id: 'doc_general_001',
        userId: 'doctor_general_001',
        name: 'Dr. Robert Taylor',
        specialty: 'General Physician',
        departmentId: 'dept_general',
        departmentName: 'General Medicine',
        experienceYears: 10,
        rating: 4.5,
        reviewCount: 156,
        consultationFee: 300,
        qualification: 'MBBS, MD',
        about: 'Providing comprehensive primary care for all ages.',
        isAvailable: true,
        isActive: true,
        registrationNumber: 'MCN-12348',
        email: 'robert.taylor@hospital.com',
        phone: '+91 98765 43213',
        availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
        weeklySlots: {
          'Monday': ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
          'Tuesday': ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
          'Wednesday': ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
          'Thursday': ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
          'Friday': ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
          'Saturday': ['09:00', '10:00', '11:00', '12:00'],
        },
      ),
    ];
  }
}
