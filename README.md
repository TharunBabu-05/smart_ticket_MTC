# FareGuard-Smart Bus Ticketing with RealTime Fraud Detection & Passenger Insights

A **Flutter-based smart ticketing application** integrated with Firebase and fraud detection mechanisms, designed for **Metropolitan Transport Corporation (MTC)** buses.  
This project demonstrates **real-time ticketing, fraud prevention, and enhancements across multiple phases of development**.

---

## 📑 Table of Contents
- [🚍 Project Overview](#-project-overview)
- [🛠️ Setup Instructions](#️-setup-instructions)
- [🔑 Firebase Fixes & Configurations](#-firebase-fixes--configurations)
- [📲 Phase 1 Enhancements](#-phase-1-enhancements)
- [🛡️ Fraud Detection System](#️-fraud-detection-system)
- [🔧 Debugging & Session Handling](#-debugging--session-handling)
- [🎬 Demo Guide](#-demo-guide)
- [🚀 Future Work](#-future-work)
- [📂 Repository Structure](#-repository-structure)
- [👥 Contributors](#-contributors)
- [📜 License](#-license)

---

## 🚍 Project Overview
- Flutter app with **Firebase backend**.
- Real-time updates for ticketing and validation.
- Implements **fraud detection measures** to prevent misuse.
- Phase-wise enhancements documented and implemented.
- Debugging and fixes tracked systematically.

---

## 🛠️ Setup Instructions
*(from `SETUP_INSTRUCTIONS.md`)*

1. Clone this repository:
   ```bash
   git clone https://github.com/TharunBabu-05/smart_ticket_MTC.git
   cd smart_ticket_MTC
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Firebase setup:
   - Add your Firebase project configuration in `firebase.json`.
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are added.

4. Run the app:
   ```bash
   flutter run
   ```

---

## 🔑 Firebase Fixes & Configurations
*(from `FIREBASE_FIXES_COMPLETE.md`)*

- Configured Firebase **Realtime Database** & **Authentication**.
- Resolved issues during initial Firebase integration.
- Database security rules implemented for controlled access.
- Structure optimized for ticketing + fraud detection system.

---

## 📲 Phase 1 Enhancements
*(from `PHASE1_ENHANCEMENTS.md`)*

- Improved UI for ticket booking & validation.
- Added **persistent login** mechanism using SharedPreferences.
- Integrated **Google Maps SDK** for real-time bus tracking.
- Dashboard preview showing:
  - Current location
  - Nearby buses
  - 'Track Bus' feature with ETA
- Fixed routing and rendering issues.

🖼️ **[Placeholder: Screenshots of Phase 1 UI enhancements]**

---

## 🛡️ Fraud Detection System
*(from `FRAUD_DETECTION_SYSTEM_READY.md` & `FRAUD_DETECTION_DEMO.md`)*

- Core fraud detection logic:
  - Duplicate ticket usage prevention.
  - Abnormal login behavior checks.
  - Session hijacking detection.
- Real-time monitoring using Firebase.
- Fraud alerts for suspicious cases.

🖼️ **[Placeholder: Fraud detection demo screenshots]**

---

## 🔧 Debugging & Session Handling
*(from `SESSION_DEBUG_GUIDE.md` & `CONNECTION_CODE_IMPLEMENTATION.md`)*

- Debugging guide for session-related issues.
- Stable **Firebase connection** best practices implemented.
- Fixes for session persistence across restarts.
- Step-by-step troubleshooting documented for developers.

---

## 🎬 Demo Guide
*(from `DEMO_GUIDE.md`)*

- Complete **demo walkthrough**:
  1. User signs in and books a ticket.
  2. Ticket validation process.
  3. Fraud detection in action with live Firebase updates.
- Includes demo scenarios for both **legit use cases** and **fraud attempts**.

🖼️ **[Placeholder: Screenshots of demo flow]**

---

## 🚀 Future Work
- Integration with **UPI / payment gateways**.
- **AI-powered demand prediction** for buses.
- Fraud detection enhancements with **ML anomaly detection**.
- Performance optimization for large-scale MTC usage.

---

## 📂 Repository Structure
```
smart_ticket_MTC/
│── android/
│── ios/
│── lib/
│   ├── main.dart
│   ├── services/
│   ├── models/
│── test/
│── web/
│── firebase.json
│── pubspec.yaml
│── README.md  (this file)
```

---

## 👥 Contributors
- **Tharun Babu** – Project Lead & Developer  
- Additional contributors welcome!  

---

## 📜 License
This project is licensed under the **MIT License** – free to use, modify, and distribute.
