import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../models/department.dart';
import '../../repositories/department_repository.dart';

class FirestoreDepartmentRepository implements DepartmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  FirestoreDepartmentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<List<Department>> getDepartments() async {
    print('[FIRESTORE DEPARTMENT] Getting all departments');
    try {
      final snapshot = await _firestore.collection('departments').get();
      final departments = snapshot.docs.map((doc) => _departmentFromFirestore(doc)).toList();
      print('[FIRESTORE DEPARTMENT] Retrieved ${departments.length} departments');
      return departments;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error getting departments: ${e.code} - ${e.message}');
      throw Exception('Failed to load departments: ${e.message}');
    }
  }

  @override
  Future<Department?> getDepartmentById(String id) async {
    print('[FIRESTORE DEPARTMENT] Getting department by ID: $id');
    try {
      final doc = await _firestore.collection('departments').doc(id).get();
      if (!doc.exists) {
        print('[FIRESTORE DEPARTMENT] Department not found: $id');
        return null;
      }
      return _departmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error getting department: ${e.code} - ${e.message}');
      throw Exception('Failed to load department: ${e.message}');
    }
  }

  @override
  Future<Department> createDepartment(Department department) async {
    print('[FIRESTORE DEPARTMENT] Creating department: ${department.name}');
    try {
      final departmentId = department.id.isEmpty ? _uuid.v4() : department.id;
      await _firestore.collection('departments').doc(departmentId).set({
        'id': departmentId,
        'name': department.name,
        'description': department.description,
        'icon': department.icon,
        'color': department.color,
        'isActive': department.isActive,
        'totalDoctors': department.totalDoctors,
        'headDoctorName': department.headDoctorName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[FIRESTORE DEPARTMENT] Department created successfully: $departmentId');
      return department.copyWith(id: departmentId);
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error creating department: ${e.code} - ${e.message}');
      throw Exception('Failed to create department: ${e.message}');
    }
  }

  @override
  Future<Department> updateDepartment(Department department) async {
    print('[FIRESTORE DEPARTMENT] Updating department: ${department.id}');
    try {
      await _firestore.collection('departments').doc(department.id).update({
        'name': department.name,
        'description': department.description,
        'icon': department.icon,
        'color': department.color,
        'isActive': department.isActive,
        'totalDoctors': department.totalDoctors,
        'headDoctorName': department.headDoctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DEPARTMENT] Department updated successfully');
      return department;
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error updating department: ${e.code} - ${e.message}');
      throw Exception('Failed to update department: ${e.message}');
    }
  }

  @override
  Future<void> deleteDepartment(String id) async {
    print('[FIRESTORE DEPARTMENT] Deleting department: $id');
    try {
      await _firestore.collection('departments').doc(id).delete();
      print('[FIRESTORE DEPARTMENT] Department deleted successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error deleting department: ${e.code} - ${e.message}');
      throw Exception('Failed to delete department: ${e.message}');
    }
  }

  @override
  Future<void> updateDoctorCount(String departmentId, int count) async {
    print('[FIRESTORE DEPARTMENT] Updating doctor count for department: $departmentId to $count');
    try {
      await _firestore.collection('departments').doc(departmentId).update({
        'totalDoctors': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[FIRESTORE DEPARTMENT] Doctor count updated successfully');
    } on FirebaseException catch (e) {
      print('[FIRESTORE DEPARTMENT] Error updating doctor count: ${e.code} - ${e.message}');
      throw Exception('Failed to update doctor count: ${e.message}');
    }
  }

  Department _departmentFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Department(
      id: doc.id,
      name: _stringValue(data['name']) ?? '',
      description: _stringValue(data['description']) ?? '',
      icon: _stringValue(data['icon']) ?? '',
      color: _stringValue(data['color']) ?? '',
      isActive: data['isActive'] as bool? ?? true,
      totalDoctors: _intValue(data['totalDoctors']) ?? 0,
      headDoctorName: _stringValue(data['headDoctorName']) ?? '',
    );
  }

  String? _stringValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
