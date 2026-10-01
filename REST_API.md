# REST API Documentation

## Overview

The Smart Hospital Queue Management application includes a REST API layer built with Firebase Cloud Functions. This API provides HTTP endpoints for appointment management and statistics.

## Deployment

### Prerequisites
- Firebase project with Cloud Functions enabled
- Node.js 18+ installed

### Setup

1. Install dependencies in the `cloud_functions` directory:
```bash
cd cloud_functions
npm install
```

2. Deploy to Firebase:
```bash
firebase deploy --only functions
```

3. Or run locally with emulator:
```bash
firebase emulators:start --only functions
```

## API Endpoints

### Base URL
- Production: `https://us-central1-{PROJECT_ID}.cloudfunctions.net`
- Local Emulator: `http://localhost:5001/{PROJECT_ID}/us-central1`

### Endpoints

#### 1. Get Appointments by Patient
**GET** `/appointments/patient/{patientId}`

Returns all appointments for a specific patient.

**Response:**
```json
[
  {
    "id": "appointment_id",
    "patientId": "patient_uid",
    "doctorId": "doctor_id",
    "status": "confirmed",
    "appointmentDate": "2024-01-15T10:00:00.000Z",
    ...
  }
]
```

#### 2. Get Appointments by Doctor
**GET** `/appointments/doctor/{doctorId}`

Returns all appointments for a specific doctor.

**Response:**
```json
[
  {
    "id": "appointment_id",
    "patientId": "patient_uid",
    "doctorId": "doctor_id",
    "status": "confirmed",
    ...
  }
]
```

#### 3. Create Appointment
**POST** `/appointments`

Creates a new appointment.

**Request Body:**
```json
{
  "patientId": "patient_uid",
  "doctorId": "doctor_id",
  "appointmentDate": "2024-01-15T10:00:00.000Z",
  "timeSlot": "10:00 AM",
  "consultationType": "regular",
  ...
}
```

**Response:** 201 Created
```json
{
  "id": "new_appointment_id",
  "patientId": "patient_uid",
  ...
}
```

#### 4. Update Appointment
**PATCH** `/appointments/{appointmentId}`

Updates an existing appointment.

**Request Body:**
```json
{
  "status": "inConsultation",
  "notes": "Patient arrived"
}
```

**Response:** 200 OK
```json
{
  "id": "appointment_id",
  "status": "inConsultation",
  ...
}
```

#### 5. Cancel Appointment
**POST** `/appointments/{appointmentId}/cancel`

Cancels an appointment.

**Response:** 200 OK
```json
{
  "message": "Appointment cancelled successfully"
}
```

#### 6. Get Appointment Statistics
**GET** `/appointments/statistics`

Returns appointment statistics.

**Response:**
```json
{
  "todayAppointments": 15,
  "totalAppointments": 1234,
  "completedAppointments": 1000,
  "cancelledAppointments": 100,
  "pendingAppointments": 134
}
```

## Flutter Integration

The Flutter app uses the `ApiService` class in `lib/data/remote/api_service.dart` to interact with these endpoints.

### Configuration

Set the API base URL via environment variable or modify the default in `lib/providers/api_provider.dart`:

```dart
const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://us-central1-your-project-id.cloudfunctions.net',
);
```

### Usage Example

```dart
final apiService = ref.read(apiServiceProvider);

// Get patient appointments
final appointments = await apiService.getAppointmentsByPatient(patientId);

// Create appointment
final newAppointment = await apiService.createAppointment(appointment);

// Update appointment
await apiService.updateAppointment(appointmentId, {'status': 'completed'});
```

## Security

- All endpoints are protected by Firebase Security Rules
- CORS is enabled for cross-origin requests
- Authentication should be added using Firebase Auth tokens in production

## Error Handling

All endpoints return appropriate HTTP status codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 405: Method Not Allowed
- 500: Internal Server Error

Error responses include a JSON object with an error message:
```json
{
  "error": "Error message here"
}
```
