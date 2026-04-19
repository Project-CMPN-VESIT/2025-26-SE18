# 📚 Seva Sahyog — Education Platform

<p align="center">
  <img src="seva-sahayog.png" alt="Seva Sahyog Logo" width="200"/>
</p>

<p align="center">
  A <strong>100% Supabase-native education management system</strong> built for NGOs to manage student enrollment, daily attendance, exam results, and teacher workflows — across 11 zones and 130+ learning centres.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase" />
  <img src="https://img.shields.io/badge/Edge_Functions-Deno-000000?logo=deno" />
  <img src="https://img.shields.io/badge/Security-Aadhaar_Encryption-red" />
</p>

---

## 🧭 Table of Contents
- [About the Project](#-about-the-project)
- [🚀 Getting Started (Fork & Clone)](#-getting-started-fork--clone)
- [🏗 Project Structure](#-project-structure)
- [🛠 Local Setup](#-local-setup)
- [📊 Data Migration & Seeding](#-data-migration--seeding)
- [User Roles & Flows](#-user-roles--flows)
- [Security & Encryption](#-security--encryption)

---

## 📖 About the Project
Seva Sahyog is a high-performance management platform designed to streamline NGO operations. By migrating to a **fully serverless, cloud-native architecture on Supabase**, the platform provides instant synchronization, robust security, and a simplified deployment pipeline.

![System architecture and workflow diagram](System%20architecture%20and%20workflow%20diagram.png)

---

## 🚀 Getting Started (Fork & Clone)

If you want to contribute to this project or set up your own instance for development, follow these steps:

### 1. Fork the Repository
Click the **Fork** button at the top right of this page to create your own copy of the repository under your GitHub account.

### 2. Clone the Repository
Clone your forked repository to your local machine:
```bash
git clone https://github.com/YOUR_USERNAME/Seva-Sahyog-Education-Platform.git
cd Seva-Sahyog-Education-Platform
```

### 3. Prerequisites
Ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Node.js](https://nodejs.org/) (for running migration and seed scripts)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Git](https://git-scm.com/)

---

## 🏗 Project Structure

```text
.
├── flutter_app/         # Flutter frontend application (Web/Mobile)
│   ├── assets/          # Images, logos, and fonts
│   ├── lib/             # Core Dart logic
│   │   ├── layouts/     # Role-based dashboard layouts
│   │   ├── providers/   # State management (Provider)
│   │   ├── screens/     # UI screens organized by role (Admin, Teacher, etc.)
│   │   └── widgets/     # Reusable UI components
├── supabase/            # Backend configuration & logic
│   ├── migrations/      # SQL schema, RLS policies, and RPC scripts
│   ├── functions/       # Edge Functions (TypeScript/Deno)
│   ├── seed_users.js    # Script to populate initial auth users
│   └── migrate_from_sheets.js  # Script to import spreadsheet data
└── excel_data/          # Folder for historical data files (Excel/CSV)
```

---

## 🛠 Local Setup

### 1. Supabase Initialization
Create a new project on [Supabase.com](https://supabase.com/) and follow these steps:

**Database Schema:**
Apply migration scripts in `supabase/migrations/` via the SQL Editor:
1. `001_initial_schema.sql` — Core tables and relationships.
2. `002_row_level_security.sql` — Zone-based access policies.
3. `003_rpc_helpers.sql` — Remote Procedure Calls for data fetching.
4. `004_schema_patch.sql` — Aadhaar encryption setup.

**Edge Functions Deployment:**
```powershell
npx supabase login
npx supabase link --project-ref <your-project-id>
npx supabase functions deploy create-user
```
*Note: Ensure `SUPABASE_SERVICE_ROLE_KEY` is added to your Project Secrets.*

### 2. Flutter Configuration
Configure your credentials in `flutter_app/lib/supabase_config.dart`:
```dart
const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'YOUR_ANON_PUBLIC_KEY';
```

Then run:
```powershell
cd flutter_app
flutter pub get
flutter run -d chrome
```

---

## 📊 Data Migration & Seeding

The platform includes robust scripts to import existing data from legacy sources.

### Environment Setup
Create a `.env` file in the `supabase/` directory:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
```

### Running Scripts
1. **Install dependencies**:
   ```bash
   cd supabase
   npm install
   ```
2. **Seed Initial Users**:
   ```bash
   npm run seed
   ```
3. **Import Spreadsheet Data**:
   Place source data in `excel_data/` and run:
   ```bash
   npm run migrate
   ```

---

## 👥 User Roles & Flows

- **🔴 Admin (Super User)**: Full visibility across all 11 Zones and 130+ Centres. Manages coordinators and center audits.
- **🟡 Coordinator (Zone Lead)**: Scoped access to assigned Zone. Approves leave requests and monitors performance.
- **🟢 Teacher (Center Lead)**: Manages center specific enrollment, daily attendance, and exam results.

---

## 🔒 Security & Encryption

- **Aadhaar Protection**: Student Aadhaar numbers are **encrypted at rest** using `pgcrypto`.
- **Zone Isolation**: Row Level Security (RLS) ensures teachers only access data for their centers.
- **Service Role Isolation**: Administrative actions are restricted to Edge Functions running with service-level privileges.

---

<p align="center">
  <strong>Seva Sahyog Foundation</strong><br>
  Modern. Secure. Cloud Native.<br>
  Made with ❤️ using Flutter & Supabase
</p>
e with ❤️ using Flutter & Supabase
</p>