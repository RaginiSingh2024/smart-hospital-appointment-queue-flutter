import '../../models/department.dart';

abstract class DepartmentRepository {
  Future<List<Department>> getDepartments();
  Future<Department?> getDepartmentById(String id);
  Future<Department> createDepartment(Department department);
  Future<Department> updateDepartment(Department department);
  Future<void> deleteDepartment(String id);
  Future<void> updateDoctorCount(String departmentId, int count);
}
