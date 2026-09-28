# 🏥 Smart Hospital Appointment & Queue Management

<p align="center">
  A Flutter-based Smart Hospital Appointment & Queue Management application for multi-specialty hospitals.
</p>

<p align="center">
  <a href="YOUR_DEPLOYMENT_LINK">
    <img src="https://img.shields.io/badge/🚀%20Live%20Demo-Open%20Application-2563EB?style=for-the-badge" alt="Live Demo">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=flat-square&logo=firebase" alt="Firebase">
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-00A98F?style=flat-square" alt="Riverpod">
  <img src="https://img.shields.io/badge/PS-147-111827?style=flat-square" alt="PS 147">
</p>

---

## 📌 Project Overview

**Smart Hospital Appointment & Queue Management** is a cross-platform Flutter application developed for **PS 147**.

The application provides a digital platform for patients, doctors, and hospital administrators to manage the complete appointment and patient-flow process.

Patients can discover doctors, search by specialty, view doctor availability, book appointments, receive queue/token numbers, complete QR-based check-in, track live queues, manage appointments, receive notifications, and view consultation history.

Doctors can manage their availability, appointments, and patient queues, while administrators can manage doctors, departments, appointments, patient flow, and hospital analytics.

---

## 🎯 Problem Statement

Hospitals often face challenges such as:

- Long patient waiting times
- Manual appointment management
- Lack of real-time queue visibility
- Difficulty finding available doctors
- Inefficient patient flow management
- Manual check-in procedures
- Limited communication regarding appointment status

This project provides a digital solution for:

- Doctor discovery
- Appointment booking
- Dynamic time slots
- Digital check-in
- Token and queue management
- Real-time queue tracking
- Notifications
- Doctor management
- Hospital administration
- Appointment analytics

---

# ✨ Features

## 👤 Patient Features

- 🔐 Role-based authentication
- 🔎 Doctor search
- 🏥 Department selection
- 🩺 Specialty-based doctor filtering
- 👨‍⚕️ Doctor profile and details
- 📅 Doctor availability
- 🕐 Dynamic appointment slots
- 📌 Appointment booking
- 🔄 Appointment rescheduling
- ❌ Appointment cancellation
- 🎫 Digital token / queue number
- ⏱️ Estimated waiting time
- 📊 Live queue status
- 📱 QR-based check-in
- 🔔 Appointment and queue notifications
- 💳 Digital payment flow
- 📜 Consultation history
- 📋 Appointment history
- 👤 Patient profile

---

## 👨‍⚕️ Doctor Features

- 📊 Doctor dashboard
- 📅 Availability management
- 🕐 Appointment slot management
- 📋 Today's appointments
- 🎫 Patient queue
- ▶️ Call next patient
- 🔄 Appointment status management
- 👤 Patient information
- 📈 Appointment statistics

---

## 👨‍💼 Admin Features

- 📊 Admin dashboard
- 👨‍⚕️ Doctor management
- 🏥 Department management
- 📅 Appointment management
- 👥 Patient flow monitoring
- 🎫 Queue monitoring
- 📈 Appointment analytics
- 💰 Payment/revenue overview
- 📊 Hospital statistics
- 📋 Reports and management tools

---

# 🏥 Product Information

The application provides the following important information:

| Information | Description |
|---|---|
| Doctor Availability | Shows available doctors and their schedules |
| Department | Hospital department associated with the doctor |
| Specialty | Doctor's medical specialization |
| Consultation Fee | Consultation charges |
| Appointment Slot | Available date and time |
| Queue Number | Digital patient token |
| Waiting Time | Estimated patient waiting time |
| Appointment Status | Current appointment state |

---

# 🔄 Appointment Flow

```text
Patient Login
      ↓
Find Doctor
      ↓
Select Department / Specialty
      ↓
View Doctor Details
      ↓
Check Availability
      ↓
Select Appointment Slot
      ↓
Book Appointment
      ↓
Digital Payment
      ↓
Appointment Confirmation
      ↓
Token / Queue Number
      ↓
QR Check-in
      ↓
Live Queue Tracking
      ↓
Doctor Consultation
      ↓
Consultation History

```
# 🎫 Queue Management

The application provides a digital queue management system to reduce unnecessary waiting inside hospitals.

• Patient can view:
• Current serving token
• Patient token number
• Queue position
• Estimated waiting time
• Appointment status
• Live queue updates
• Doctor can:
• View waiting patients
• Call the next patient
• Update patient status
• Complete appointments


# 📱 QR Code Check-In

Patients can use a generated QR code for digital appointment check-in.

Check-In Flow
Appointment Confirmation
        ↓
Generate QR Code
        ↓
Patient Arrives
        ↓
Scan QR Code
        ↓
Digital Check-In
        ↓
Queue Activation

This reduces dependency on manual reception-based check-in.


# 🔔 Notifications

The application supports notifications for important appointment and queue events.

Notifications may include:

Appointment confirmation
Appointment reminders
Queue updates
Doctor availability updates
Appointment status changes
Patient turn notifications

# 💳 Pricing Strategy

The pricing model follows the PS 147 requirements.

Appointment Convenience Fee

₹20 – ₹50

Premium Priority Consultation

₹100 – ₹300

Hospital Subscription Packages

Subscription-based packages can be provided to hospitals.

Corporate Healthcare Packages

Healthcare packages can be offered to organizations and corporate users.

The payment functionality is implemented as a demonstration/development flow for the academic project.

# 🔥 Firebase Integration

Firebase is used as the backend infrastructure for the application.

Firebase Services
Firebase Authentication
Cloud Firestore
Firebase Cloud Messaging
Real-time data synchronization
Firebase backend services
Authentication

# Firebase Authentication supports role-based access for:

Patients
Doctors
Administrators
Firestore

# Firestore is used for application data such as:

Users
Doctors
Departments
Appointments
Time Slots
Queues
Notifications
Payments
Consultations

# 🌐 REST API Integration

The application follows a service/repository architecture for REST API integration.

REST API communication can be used for:

Appointment management
Patient records
Doctor information
Doctor availability
Queue-related operations

The API layer is separated from the presentation layer to maintain a modular architecture.

# 📡 Offline Caching

The application supports offline caching for important previously loaded information.

Cached information may include:

Appointment details
Doctor information
Previous appointment data
Queue-related information

This allows important information to remain accessible during temporary connectivity issues.

# 🧑‍💻 Technology Stack
Technology	Purpose
Flutter	Cross-platform application development
Dart	Programming language
Firebase Authentication	User authentication
Cloud Firestore	Database
Firebase Cloud Messaging	Notifications
Riverpod	State management
GoRouter	Application navigation
Dio	REST API communication
Hive / Shared Preferences	Local caching
QR Flutter	QR generation
Mobile Scanner	QR scanning
Connectivity Plus	Network connectivity
FL Chart	Analytics and charts
Intl	Date and time handling

# 🏗️ Application Architecture

The application follows a modular and repository-based architecture.

lib/
│
├── app/
│   ├── routes/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── models/
│   ├── appointment.dart
│   ├── doctor.dart
│   ├── department.dart
│   ├── patient.dart
│   ├── queue.dart
│   ├── notification.dart
│   ├── payment.dart
│   └── time_slot.dart
│
├── providers/
│
├── repositories/
│
├── features/
│   ├── auth/
│   ├── patient/
│   ├── doctor/
│   └── admin/
│
└── main.dart

# 👥 User Roles
👤 Patient

The patient can:

Register and login
Search doctors
Filter doctors by specialty
View doctor availability
Book appointments
Reschedule appointments
Cancel appointments
Make payments
Generate QR check-in
Track live queue
Receive notifications
View consultation history

👨‍⚕️ Doctor

The doctor can:

Login to the doctor dashboard
Manage availability
View appointments
View patient queue
Call the next patient
Update appointment status
View patient information
Monitor daily appointment statistics

👨‍💼 Administrator

The administrator can:

Manage doctors
Manage departments
Manage appointments
Monitor patient flow
Monitor queues
View analytics
Manage hospital operations
View reports
🖥️ Application Screens
Authentication
Login
Registration
Role-based authentication
Patient Screens
Patient Dashboard
Find Doctors
Doctor Details
Appointment Booking
Appointment Details
Appointments
Live Queue
QR Check-in
Notifications
Consultation History
Profile
Doctor Screens
Doctor Dashboard
Availability
Appointments
Queue Management
Patient Management
Admin Screens
Admin Dashboard
Doctor Management
Department Management
Appointment Management
Patient Flow
Analytics
Reports
Settings

# 📊 Analytics

The Admin Dashboard provides insights into hospital operations.

Analytics include:

Total appointments
Completed appointments
Pending appointments
Cancelled appointments
Doctor availability
Department-wise appointments
Patient flow
Queue statistics
Appointment trends

## 🚀 Getting Started
Prerequisites

Before running the project, make sure you have:

Flutter SDK
Dart SDK
Git
Android Studio
Xcode for iOS development
Firebase project
VS Code or Android Studio

Check Flutter installation:

flutter doctor
📥 Installation

Clone the repository:

git clone https://github.com/RaginiSingh2024/smart-hospital-appointment-queue-flutter.git

Navigate to the project:

cd smart-hospital-appointment-queue-flutter

Install dependencies:

flutter pub get

# 🔥 Firebase Setup

Create a Firebase project and configure the required Firebase services.

Enable:

Firebase Authentication
Cloud Firestore
Firebase Cloud Messaging

Install FlutterFire CLI:

dart pub global activate flutterfire_cli

Configure Firebase:

flutterfire configure

Run the project:

flutter run

Never commit private API keys, secrets, service-account credentials, or other sensitive configuration to the repository.

▶️ Run the Application
Check available devices
flutter devices
Run normally
flutter run
Run on Chrome
flutter run -d chrome
Run on Android
flutter run -d android
Run on iOS Simulator
flutter run -d ios
🧪 Testing & Validation

Run Flutter analyzer:

flutter analyze

Run tests:

flutter test

Build the web version:

flutter build web

Build Android APK:

flutter build apk

Build iOS:

flutter build ios

# 🔐 Demo Credentials

Replace these credentials with the actual demo credentials configured in the application.

Patient
Email: patient@demo.com
Password: ********
Doctor
Email: doctor@demo.com
Password: ********
Administrator
Email: admin@demo.com
Password: ********
🎬 Recommended Demo Flow
Patient Demo
Login
 ↓
Find Doctor
 ↓
Apply Specialty Filter
 ↓
Open Doctor Details
 ↓
Check Availability
 ↓
Select Slot
 ↓
Book Appointment
 ↓
Complete Payment
 ↓
Receive Token
 ↓
Generate QR Code
 ↓
Check In
 ↓
Track Live Queue
 ↓
View Appointment History
Doctor Demo
Doctor Login
 ↓
Doctor Dashboard
 ↓
View Today's Appointments
 ↓
View Patient Queue
 ↓
Call Next Patient
 ↓
Update Appointment Status
Admin Demo
Admin Login
 ↓
Admin Dashboard
 ↓
View Doctors
 ↓
View Departments
 ↓
View Appointments
 ↓
Monitor Patient Flow
 ↓
View Queue Statistics
 ↓
View Analytics


