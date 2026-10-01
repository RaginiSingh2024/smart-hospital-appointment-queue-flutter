# 🏥 MediQueue — Smart Hospital Appointment & Queue Management

<p align="center">
  <strong>Smart Healthcare. Smarter Queues.</strong><br>
  A Flutter-based Smart Hospital Appointment & Queue Management application for multi-specialty hospitals.
</p>

<p align="center">
  <a href="https://raginisingh2024.github.io/smart-hospital-appointment-queue-flutter/">
    <img src="https://img.shields.io/badge/🚀%20Live%20Demo-Open%20Application-2563EB?style=for-the-badge" alt="Live Demo">
  </a>
  &nbsp;
  <a href="https://stitch.withgoogle.com/projects/6637076470176643694">
    <img src="https://img.shields.io/badge/🎨%20Figma%20Design-View%20Design-8B5CF6?style=for-the-badge" alt="Figma Design">
  </a>
  &nbsp;
  <a href="#-documentation">
    <img src="https://img.shields.io/badge/📄%20Documentation-View%20Documentation-059669?style=for-the-badge" alt="Documentation">
  </a>
  &nbsp;
  <a href="https://github.com/RaginiSingh2024/smart-hospital-appointment-queue-flutter">
    <img src="https://img.shields.io/badge/💻%20GitHub%20Repository-View%20Repository-111827?style=for-the-badge&logo=github" alt="GitHub Repository">
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

**MediQueue — Smart Hospital Appointment & Queue Management** is a cross-platform Flutter application developed for **PS 147**. The application provides a digital platform for patients, doctors, and hospital administrators to manage appointments, doctor availability, digital check-in, queues, notifications, and hospital operations.

Patients can discover doctors, search by specialty, view availability, book appointments, receive token/queue information, complete QR-based check-in, track queues, manage appointments, receive notifications, and view consultation history.

Doctors can manage availability, appointments, patient queues, and consultation-related workflows, while administrators can manage doctors, departments, appointments, patient flow, queues, and analytics.

## 🎯 Problem Statement

Hospitals often face challenges such as:

- Long patient waiting times
- Manual appointment management
- Lack of real-time queue visibility
- Difficulty finding available doctors
- Inefficient patient-flow management
- Manual check-in procedures
- Limited communication regarding appointment status

MediQueue provides a digital solution for doctor discovery, appointment booking, dynamic slots, digital check-in, token and queue management, notifications, doctor management, hospital administration, and appointment analytics.

## ✨ Key Features

### 👤 Patient
- 🔐 Role-based authentication
- 🔎 Doctor search and specialty filtering
- 🏥 Department selection
- 👨‍⚕️ Doctor profiles and availability
- 📅 Dynamic appointment slots
- 📌 Appointment booking
- 🔄 Reschedule and cancel appointments
- 🎫 Digital token / queue number
- ⏱️ Estimated waiting time
- 📊 Live queue status
- 📱 QR-based check-in
- 🔔 Appointment and queue notifications
- 💳 Digital payment flow
- 📜 Consultation and appointment history
- 👤 Patient profile

### 👨‍⚕️ Doctor
- 📊 Doctor dashboard
- 📅 Availability management
- 🕐 Appointment slot management
- 📋 Today's appointments
- 🎫 Patient queue
- ▶️ Call next patient
- 🔄 Appointment status management
- 👤 Patient information
- 📈 Appointment statistics

### 👨‍💼 Admin
- 📊 Admin dashboard
- 👨‍⚕️ Doctor management
- 🏥 Department management
- 📅 Appointment management
- 👥 Patient-flow monitoring
- 🎫 Queue monitoring
- 📈 Appointment analytics
- 💰 Payment/revenue overview
- 📊 Hospital statistics
- 📋 Reports and management tools

## 🔄 Appointment Workflow

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

## 🎫 Queue Management

The application provides a digital queue management workflow designed to reduce unnecessary waiting inside hospitals.

Patients can view the current serving token, their token number, queue position, estimated waiting time, appointment status, and queue updates.

Doctors can view waiting patients, call the next patient, update patient status, and complete appointments.

## 📱 QR Code Check-In

Patients can use a generated QR code for digital appointment check-in.

```text
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
```

## 🔔 Notifications

Notifications may include appointment confirmation, reminders, queue updates, doctor availability updates, appointment status changes, and patient-turn notifications.

## 💳 Pricing Strategy

| Pricing Component | Indicative Range |
|---|---:|
| Appointment Convenience Fee | ₹20 – ₹50 |
| Premium Priority Consultation | ₹100 – ₹300 |
| Hospital Subscription Packages | Subscription-based |
| Corporate Healthcare Packages | Organization-based |

The payment functionality is implemented as a demonstration/development flow for the academic project.

## 🔥 Firebase Integration

Firebase is used as the backend infrastructure for authentication, cloud data storage, and real-time application services.

### Firebase Services
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Real-time data synchronization

Firestore application data includes users, doctors, departments, appointments, time slots, queues, notifications, payments, and consultations.

## 🌐 REST API Integration

The application follows a service/repository architecture for REST API integration. The API layer is separated from the presentation layer to maintain a modular architecture.

REST API communication can support appointment management, patient records, doctor information, doctor availability, and queue-related operations.

## 📡 Offline Caching

The application supports offline caching for important previously loaded information such as appointment details, doctor information, previous appointment data, and queue-related information.

## 🧑‍💻 Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Database |
| Firebase Cloud Messaging | Notifications |
| Riverpod | State management |
| GoRouter | Application navigation |
| Dio | REST API communication |
| Hive / Shared Preferences | Local caching |
| QR Flutter | QR generation |
| Mobile Scanner | QR scanning |
| Connectivity Plus | Network connectivity |
| FL Chart | Analytics and charts |
| Intl | Date and time handling |

## 🏗️ Application Architecture

The application follows a modular and repository-based architecture.

```text
lib/
├── app/
│   ├── routes/
│   └── theme/
├── core/
│   ├── constants/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── models/
├── providers/
├── repositories/
├── features/
│   ├── auth/
│   ├── patient/
│   ├── doctor/
│   └── admin/
└── main.dart
```

## 👥 User Roles

| Role | Main Responsibilities |
|---|---|
| 👤 Patient | Doctor discovery, booking, QR check-in, queue tracking, notifications, history |
| 👨‍⚕️ Doctor | Availability, appointments, patient queue, consultation workflow |
| 👨‍💼 Administrator | Doctors, departments, appointments, queues, analytics and hospital operations |

## 📸 Screenshots

The following screenshots demonstrate the implemented application interfaces across patient, doctor, administrator, Firebase, and project workflows.

### Patient Registration

<p align="center"><img src="Screenshots/02_Patient_Registration.png" alt="Patient Registration" width="850"></p>

### Admin Login

<p align="center"><img src="Screenshots/03_Admin_Login.png" alt="Admin Login" width="850"></p>

### Patient Dashboard

<p align="center"><img src="Screenshots/04_Patient_Dashboard.png" alt="Patient Dashboard" width="850"></p>

### Doctor Search

<p align="center"><img src="Screenshots/05_Doctor_Search.png" alt="Doctor Search" width="850"></p>

### Appointment Booking

<p align="center"><img src="Screenshots/09_Appointment_Booking.png" alt="Appointment Booking" width="850"></p>

### Booking Confirmation

<p align="center"><img src="Screenshots/10_Booking_Confirmation.png" alt="Booking Confirmation" width="850"></p>

### Appointment Detail

<p align="center"><img src="Screenshots/Appointment_detail.png" alt="Appointment Detail" width="850"></p>

### Home Dashboard

<p align="center"><img src="Screenshots/Home_dashboard.png" alt="Home Dashboard" width="850"></p>

### Notifications

<p align="center"><img src="Screenshots/Notification.png" alt="Notifications" width="850"></p>

### Patient Profile

<p align="center"><img src="Screenshots/Patient-profile.png" alt="Patient Profile" width="850"></p>

### QR Check-in

<p align="center"><img src="Screenshots/QR_Check-in.png" alt="QR Check-in" width="850"></p>

### Admin Profile

<p align="center"><img src="Screenshots/admin-profile.png" alt="Admin Profile" width="850"></p>

### Admin Dashboard

<p align="center"><img src="Screenshots/admin_dashboard.png" alt="Admin Dashboard" width="850"></p>

### Doctor List

<p align="center"><img src="Screenshots/dr-list.png" alt="Doctor List" width="850"></p>

### Doctor Dashboard

<p align="center"><img src="Screenshots/dr_dashboard.png" alt="Doctor Dashboard" width="850"></p>

### Doctor Profile

<p align="center"><img src="Screenshots/dr_profile.png" alt="Doctor Profile" width="850"></p>

### Doctor Today's Appointments

<p align="center"><img src="Screenshots/dr_today_appoinment.png" alt="Doctor Today's Appointments" width="850"></p>

### Firebase

<p align="center"><img src="Screenshots/firebase.png" alt="Firebase" width="850"></p>

### Firebase Project Connected

<p align="center"><img src="Screenshots/firebase_project_connected.png" alt="Firebase Project Connected" width="850"></p>

### GitHub Repository

<p align="center"><img src="Screenshots/github.png" alt="GitHub Repository" width="850"></p>

### Patient List

<p align="center"><img src="Screenshots/patientlist.png" alt="Patient List" width="850"></p>

## 📊 Analytics

The Admin Dashboard provides operational insights such as total appointments, completed appointments, pending appointments, cancelled appointments, doctor availability, department-wise appointments, patient flow, queue statistics, and appointment trends.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Git
- Android Studio / VS Code
- Firebase project
- Xcode for iOS development (if required)

Check Flutter installation:

```bash
flutter doctor
```

### 📥 Installation

Clone the repository:

```bash
git clone https://github.com/RaginiSingh2024/smart-hospital-appointment-queue-flutter.git
cd smart-hospital-appointment-queue-flutter
flutter pub get
```

### 🔥 Firebase Setup

Configure the required Firebase services:

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging

Install FlutterFire CLI if required:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Run the application:

```bash
flutter run
```

### ▶️ Run on Web

```bash
flutter run -d chrome
```

### 🧪 Testing & Validation

```bash
flutter analyze
flutter test
flutter build web
```

## 🔐 Demo Credentials

| Role | Email | Password |
|---|---|---|
| Patient | Register through the app | User-defined |
| Doctor | `dr@gmail.com` | `dr1234` |
| Administrator | `admin@gmail.com` | `admin1234` |

## 🎬 Recommended Demo Flow

### Patient Demo
```text
Login → Find Doctor → Filter Specialty → Doctor Details
→ Check Availability → Select Slot → Book Appointment
→ Payment → Token → QR Check-in → Live Queue → History
```

### Doctor Demo
```text
Doctor Login → Doctor Dashboard → Today's Appointments
→ Patient Queue → Call Next Patient → Update Status
```

### Admin Demo
```text
Admin Login → Admin Dashboard → Doctors → Departments
→ Appointments → Patient Flow → Queue Statistics → Analytics
```

## 📄 Documentation

The project documentation/report contains the problem understanding, application design, implementation details, screenshots/demonstration, workflow, and feature documentation.

> **Documentation link:** Add the final uploaded DOCX/PDF documentation link here before submission.

## 🔗 Project Links

- 🚀 **Live Demo:** https://raginisingh2024.github.io/smart-hospital-appointment-queue-flutter/
- 🎨 **Design:** https://stitch.withgoogle.com/projects/6637076470176643694
- 💻 **GitHub Repository:** https://github.com/RaginiSingh2024/smart-hospital-appointment-queue-flutter

## 📌 Project Information

**Problem Statement:** PS 147 — Smart Hospital Appointment & Queue Management

**Industry:** HealthTech & Healthcare

**Platform:** Flutter / Cross-platform

**Backend:** Firebase

**Application Name:** MediQueue

## 👩‍💻 Project

Developed as an academic HealthTech application for demonstrating cross-platform application development, role-based workflows, appointment management, digital queue management, and Firebase integration.

---

<p align="center">
  <strong>🏥 MediQueue — Smart Healthcare. Smarter Queues.</strong>
</p>