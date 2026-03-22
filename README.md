# 📚 Seva Sahayog — NGO Education Platform

<p align="center">
  <img src="seva-sahayog.png" alt="Seva Sahayog Logo" width="200"/>
</p>

A **role-based education management system** built for NGOs to streamline student enrollment, attendance tracking, exam management, and automated CSR report generation across multiple centres and zones.

---

## 🧭 Table of Contents

- [About the Project](#-about-the-project)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Backend Setup (Firebase)](#2-backend-setup-firebase)
  - [3. Frontend Setup (Flutter)](#3-frontend-setup-flutter)
  - [4. Running the App](#4-running-the-app)
- [Firebase Emulators](#-firebase-emulators)
- [User Roles](#-user-roles)
- [Cloud Functions](#-cloud-functions)
- [Troubleshooting](#-troubleshooting)

---

## 📖 About the Project

Seva Sahayog is a comprehensive education management platform designed for NGOs that operate learning centres across multiple zones. The system provides **three distinct user roles** — Admin, Coordinator, and Teacher — each with a tailored dashboard and feature set.

### Key Features

| Feature | Description |
|---|---|
| **Role-Based Access** | Separate dashboards for Admin, Coordinator, and Teacher |
| **Student Management** | Register students with encrypted Aadhaar data |
| **Attendance Tracking** | Daily attendance with automatic Google Sheets sync |
| **Exam Management** | Upload and track exam results |
| **CSR Report Generation** | Automated PDF/Excel reports with charts and analytics |
| **Zone & Centre Management** | Hierarchical structure for managing multiple locations |
| **Global Analytics** | Org-wide metrics and performance dashboards |
| **Leave Management** | Teacher leave requests with coordinator approval |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) |
| **Authentication** | Firebase Authentication |
| **Database** | Cloud Firestore |
| **Backend / Serverless** | Firebase Cloud Functions (Node.js 18) |
| **File Storage** | Firebase Cloud Storage |
| **Reporting** | Google Sheets API, PDFKit |
| **State Management** | Provider |
| **Routing** | GoRouter |
| **Charts** | fl_chart |
| **Typography** | Google Fonts |

---

## 📁 Project Structure

```
NGO-Education-Platform/
├── backend/                        # Firebase backend
│   ├── firebase.json               # Firebase project configuration
│   ├── firestore.rules             # Firestore security rules
│   ├── firestore.indexes.json      # Firestore composite indexes
│   ├── storage.rules               # Cloud Storage security rules
│   └── functions/                  # Cloud Functions (Node.js)
│       ├── index.js                # Function entry point & exports
│       ├── package.json            # Node.js dependencies
│       ├── seed/                   # Database seeding scripts
│       └── src/
│           ├── auth/               # User creation, login, sync
│           ├── attendance/         # Attendance triggers
│           ├── students/           # Student creation & encryption
│           ├── exams/              # Exam result triggers
│           ├── reports/            # CSR report generation
│           └── sheets/            # Google Sheets integration
│
├── flutter_app/                    # Flutter frontend
│   ├── pubspec.yaml                # Flutter dependencies
│   ├── firebase.json               # Flutter-side Firebase config
│   └── lib/
│       ├── main.dart               # App entry point
│       ├── firebase_options.dart   # Firebase project credentials
│       ├── data/                   # Data models & repositories
│       ├── providers/              # State management (Provider)
│       ├── router/                 # GoRouter navigation config
│       ├── screens/                # UI screens per role
│       ├── theme/                  # App theme & styling
│       ├── utils/                  # Utility functions
│       ├── widgets/                # Reusable UI components
│       └── layouts/                # Layout scaffolds
│
├── README.md                       # ← You are here
└── seva-sahayog.png                # Project logo
```

---

## ✅ Prerequisites

Ensure the following are installed on your machine before proceeding:

| Tool | Version | Install Guide |
|---|---|---|
| **Flutter SDK** | ≥ 3.11.0 | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | Bundled with Flutter | Included with Flutter |
| **Node.js** | 18.x | [nodejs.org](https://nodejs.org/) |
| **npm** | Bundled with Node.js | Included with Node.js |
| **Firebase CLI** | Latest | `npm install -g firebase-tools` |
| **Git** | Latest | [git-scm.com](https://git-scm.com/) |
| **Chrome / Edge** | Latest | For web debugging |

### Verify Installation

```bash
flutter --version
node --version
npm --version
firebase --version
git --version
```

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/NGO-Education-Platform.git
cd NGO-Education-Platform
```

---

### 2. Backend Setup (Firebase)

#### a) Navigate to the backend directory

```bash
cd backend
```

#### b) Install Cloud Functions dependencies

```bash
cd functions
npm install
cd ..
```

#### c) Login to Firebase (first time only)

```bash
firebase login
```

#### d) Set the active Firebase project

```bash
firebase use smarteducationanalyticssystem
```
> If you're using your own Firebase project, update `.firebaserc` with your project ID.

#### e) Start Firebase Emulators

```bash
firebase emulators:start
```

This starts the following local emulators:

| Service | Port | URL |
|---|---|---|
| **Emulator UI** | 4000 | http://localhost:4000 |
| **Firestore** | 8086 | http://localhost:8086 |
| **Auth** | 9099 | http://localhost:9099 |
| **Cloud Functions** | 5001 | http://localhost:5001 |
| **Storage** | 9199 | http://localhost:9199 |

> 💡 The Emulator UI at **http://localhost:4000** provides a visual dashboard to inspect Auth users, Firestore data, and function logs.

#### f) Seed initial data (optional)

In a new terminal:

```bash
cd backend/functions
npm run seed
```

---

### 3. Frontend Setup (Flutter)

Open a **new terminal** (keep the emulators running in the previous one).

#### a) Navigate to the Flutter app

```bash
cd flutter_app
```

#### b) Install Flutter dependencies

```bash
flutter pub get
```

#### c) Verify connected devices

```bash
flutter devices
```

---

### 4. Running the App

> ⚠️ **Important:** Make sure the Firebase emulators are running before launching the Flutter app.

#### Run on Edge (recommended for Windows)

```bash
flutter run -d edge
```

#### Run on Chrome

```bash
flutter run -d chrome
```

> If Chrome gives a WebSocket connection error, try:
> ```bash
> flutter run -d chrome --web-browser-flag="--disable-extensions"
> ```

#### Run on Windows Desktop

```bash
flutter run -d windows
```

#### Run on Android Emulator

```bash
flutter run -d emulator-5554
```
> Replace `emulator-5554` with your actual device ID from `flutter devices`.

---

## 🔥 Firebase Emulators

The project uses Firebase Emulators for **local development** — no live Firebase quota is consumed during development.

### Emulator Configuration

Defined in [`backend/firebase.json`](backend/firebase.json):

```json
{
  "emulators": {
    "auth":      { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8086 },
    "storage":   { "port": 9199 },
    "ui":        { "enabled": true, "port": 4000 }
  }
}
```

### Emulator Data Persistence

Emulator data is automatically exported on exit to the `emulator-data/` directory and reimported on next start, so your test data persists across sessions.

### Fixing Port Conflicts

If emulators fail to start due to port conflicts, find and kill the blocking process:

**Windows (PowerShell):**

```powershell
# Find what's using a port (e.g., 8085)
netstat -ano | findstr :8085

# Kill the process by PID
taskkill /PID <PID> /F

# 🚀 QUICK KILL (Kills all Node/Firebase processes at once)
Stop-Process -Name node -Force -ErrorAction SilentlyContinue
```

---

## 👥 User Roles

### 🔴 Admin
- Create and manage Teacher & Coordinator accounts
- Create zones and centres
- View global analytics and org-wide dashboards

### 🟡 Coordinator
- Monitor attendance across assigned centres
- Manage teachers within their zone
- Generate and download CSR reports (PDF)
- Approve/reject teacher leave requests

### 🟢 Teacher
- Register new students (with Aadhaar encryption)
- Mark daily attendance (auto-synced to Google Sheets)
- Upload exam results
- Submit leave requests

---

## ⚡ Cloud Functions

The backend exposes the following Firebase Cloud Functions:

| Function | Type | Description |
|---|---|---|
| `createUser` | Callable | Creates a new user with role assignment |
| `onUserProfileCreated` | Firestore Trigger | Initializes user profile on creation |
| `onAttendanceCreated` | Firestore Trigger | Syncs attendance to Google Sheets |
| `onStudentCreated` | Firestore Trigger | Syncs student data to Google Sheets |
| `onExamResultCreated` | Firestore Trigger | Syncs exam results to Google Sheets |
| `generateCSRReport` | Callable | Generates PDF CSR reports |
| `encryptAadhaar` | Callable | Encrypts student Aadhaar numbers |
| `decryptAadhaar` | Callable | Decrypts Aadhaar for authorized access |
| `getStudentsFromSheet` | Callable | Reads student data from Google Sheets |
| `getAttendanceFromSheet` | Callable | Reads attendance from Google Sheets |
| `syncUsersFromSheet` | Callable | Imports users from Google Sheets to Auth |
| `sheetLogin` | Callable | Validates login against NGO directory sheet |

---

## 🐛 Troubleshooting

| Problem | Solution |
|---|---|
| `flutter pub get` fails | Run `flutter clean` then `flutter pub get` |
| Chrome WebSocket error | Use `flutter run -d edge` or add `--web-browser-flag="--disable-extensions"` |
| Emulator port conflict | Kill the blocking process (see [Fixing Port Conflicts](#fixing-port-conflicts)) |
| Firebase CLI not found | Install with `npm install -g firebase-tools` |
| Functions not deploying | Ensure Node.js 18 is installed (`node --version`) |
| `firebase use` fails | Run `firebase login` first, then `firebase use smarteducationanalyticssystem` |
| App can't connect to emulators | Verify emulators are running and check `firebase_options.dart` for correct ports |

---

## 📄 License

This project is developed for **Seva Sahayog Foundation** and is intended for internal use.

---

<p align="center">
  Made with ❤️ using Flutter & Firebase
</p>