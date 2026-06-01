# Pet Care App 🐾

[![Flutter](https://img.shields.io/badge/Flutter-v3.7.2+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-inset)](https://riverpod.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, beautifully designed Flutter application tailored for pet owners to manage their pets' daily needs, health records, and routines with ease.

---

## 📖 Table of Contents
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Screenshots](#-screenshots)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Future Enhancements](#-future-enhancements)

---

## 🚀 Features

### 🐾 Core Management
*   **Dynamic Pet Profiles**: Detailed management of multiple pet profiles including photos, vital statistics, and specific needs.
*   **Health Record Management**: Secure storage for vaccination history, veterinary visit logs, medication schedules, and medical documents.
*   **Appointment Scheduler**: Integrated calendar system for tracking veterinary visits and grooming appointments.

### 🍽️ Intelligent Routine Tracking
*   **Smart Meal Logs**: Automated daily routine cloning that persists a 7-day history while resetting tasks each morning.
*   **AI-Powered Assistance**: Integrated **Dr. PetPal AI** (Powered by Gemini) for personalized pet care advice and custom diet plan generation.
*   **Growth Monitoring**: Visual data representation of weight trends and health metrics over time.

### 🛠️ Utility & Safety
*   **Nearby Services**: GPS-integrated search for veterinary clinics and pet supply stores.
*   **Professional Reporting**: Generate and export comprehensive health reports in PDF format for vet sharing.
*   **Smart Reminders**: Local notification system for feeding, medications, and routine activities.
*   **Emergency Quick-Access**: Dedicated section for immediate access to emergency veterinary contacts.

---

## 🏗 Architecture

The project follows a **Layered Architecture** pattern to ensure scalability, maintainability, and testability:

*   **Presentation**: UI components built with Flutter widgets and managed using Riverpod.
*   **Application (Logic)**: Services and State Notifiers handling the business logic and state transitions.
*   **Data**: Data models, repositories, and local/remote data source implementations (Shared Preferences & Firebase).
*   **Core**: Centralized constants, theme configurations, and utility helpers.

---

## 🛠 Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **State Management**: [Hooks Riverpod](https://riverpod.dev/)
*   **Local Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
*   **Backend Services**: [Firebase](https://firebase.google.com/)
*   **AI Integration**: [Google Gemini AI](https://ai.google.dev/)
*   **Networking**: [HTTP](https://pub.dev/packages/http)
*   **Geolocation**: [Geolocator](https://pub.dev/packages/geolocator)
*   **Local Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
*   **PDF Generation**: [PDF](https://pub.dev/packages/pdf) & [Printing](https://pub.dev/packages/printing)

---

## 📸 Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/ade97de9-7fd1-48ca-89b5-633b7436742e" width="400" alt="App Preview">
</p>

---

## 🛠️ Getting Started

### Prerequisites
*   Flutter SDK (^3.7.2)
*   Dart SDK
*   Android Studio / VS Code
*   Active Firebase Project

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/aqibtufail7546/flutter_pet_care_app.git
    cd flutter_pet_care_app
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**
    *   Configure your Firebase project using the FlutterFire CLI:
    ```bash
    flutterfire configure
    ```

4.  **Run the application**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```text
lib/
├── application/       # State providers and services
├── core/              # Theme, constants, and utilities
├── data/              # Models and data source implementations
└── presentation/      # UI screens and shared widgets
```

---

## 🔮 Future Enhancements
*   [ ] Cloud synchronization across multiple devices.
*   [ ] Community forum for pet owners.
*   [ ] Integration with wearable pet trackers.
*   [ ] Multi-language support (i18n).

---

## ⚖️ License

Distributed under the MIT License. See `LICENSE` for more information.
