import 'package:dio/dio.dart';

import '../../models/appointment.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Get appointments by patient ID via REST API
  Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    try {
      final response = await _dio.get('/appointments/patient/$patientId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Appointment.fromMap(json)).toList();
      }
      throw Exception('Failed to load appointments: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Get appointments by doctor ID via REST API
  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    try {
      final response = await _dio.get('/appointments/doctor/$doctorId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Appointment.fromMap(json)).toList();
      }
      throw Exception('Failed to load appointments: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Create appointment via REST API
  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      final response = await _dio.post(
        '/appointments',
        data: appointment.toMap(),
      );
      if (response.statusCode == 201) {
        return Appointment.fromMap(response.data);
      }
      throw Exception('Failed to create appointment: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Update appointment via REST API
  Future<Appointment> updateAppointment(String appointmentId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch(
        '/appointments/$appointmentId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Appointment.fromMap(response.data);
      }
      throw Exception('Failed to update appointment: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Cancel appointment via REST API
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final response = await _dio.post('/appointments/$appointmentId/cancel');
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel appointment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Get appointment statistics via REST API
  Future<Map<String, dynamic>> getAppointmentStatistics() async {
    try {
      final response = await _dio.get('/appointments/statistics');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to load statistics: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  // Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
