/**
 * Seed script — populates Firestore with mock data matching
 * the Flutter app's existing mock_data.dart.
 *
 * Usage:
 *   # With emulators running:
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node seed/seedData.js
 *
 *   # Or via npm:
 *   npm run seed
 */

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

// Point to emulator if env var is set
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8087";
}
if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = "localhost:9099";
}

initializeApp({ projectId: "smarteducationanalyticssystem" });

const db = getFirestore();
const auth = getAuth();

// ─── Real NGO Users (from User_Credentials_Log sheet) ───────────
// password field is stored so sheetLogin's Firestore fallback works locally

const users = [
  // Admin
  { uid: "admin-001", email: "admin@ngo.org", password: "admin123", role: "admin", name: "Admin User", phone: "1234567890", zone: "", centre: "", status: "active" },

  // Coordinators
  { uid: "coord-boisar-001", email: "coord.boisar@ngo.org", password: "coord123", role: "coordinator", name: "Chetan Modak", phone: "9876543210", zone: "Boisar", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },
  { uid: "coord-thane-001", email: "coord.thane@ngo.org", password: "coord123", role: "coordinator", name: "Thane Coordinator", phone: "2223334444", zone: "Thane", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },
  { uid: "coord-nkarjat-001", email: "coord.nkarjat@ngo.org", password: "coord123", role: "coordinator", name: "Karjat Coordinator", phone: "3334445555", zone: "New Karjat", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },
  { uid: "coord-saphale-001", email: "coord.saphale@ngo.org", password: "coord123", role: "coordinator", name: "Saphale Coordinator", phone: "4445556666", zone: "Saphale", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },
  { uid: "coord-eastern-001", email: "coord.eastern@ngo.org", password: "coord123", role: "coordinator", name: "Eastern Coordinator", phone: "5556667777", zone: "Eastern Mumbai", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },

  // Teachers
  { uid: "teacher-shivpratap-p-001", email: "teacher.shivpratap.p@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Shivpratap P", phone: "1112223333", zone: "Boisar", centre: "Shivpratap (Primary)", status: "active", students: 0 },
  { uid: "teacher-shivpratap-s-001", email: "teacher.shivpratap.s@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Shivpratap S", phone: "4445556666", zone: "Boisar", centre: "Shivpratap (Secondary)", status: "active", students: 0 },
  { uid: "teacher-tejaswini-001", email: "teacher.tejaswini@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Tejaswini", phone: "5556667777", zone: "Thane", centre: "Tejaswini", status: "active", students: 0 },
  { uid: "teacher-mirabai-001", email: "teacher.mirabai@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Mirabai", phone: "8889990000", zone: "Thane", centre: "Mirabai", status: "active", students: 0 },
  { uid: "teacher-karla-001", email: "teacher.karla@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Karla", phone: "6667778888", zone: "New Karjat", centre: "Karla Abhyasika", status: "active", students: 0 },
  { uid: "teacher-ajintha-001", email: "teacher.ajintha@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Ajintha", phone: "9990001111", zone: "New Karjat", centre: "Ajintha Abhyasika", status: "active", students: 0 },
  { uid: "teacher-surya-001", email: "teacher.surya@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Surya", phone: "7778889999", zone: "Saphale", centre: "Surya", status: "active", students: 0 },
  { uid: "teacher-gajanan-001", email: "teacher.gajanan@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Gajanan", phone: "0001112222", zone: "Eastern Mumbai", centre: "Gajanan", status: "active", students: 0 },

  // Test coordinator
  { uid: "coord-test3-001", email: "test3@gmail.com", password: "test1123", role: "coordinator", name: "test coordinator", phone: "1234567890", zone: "", centre: "", status: "active", centres: 0, teachers: 0, students: 0 },
];

const zones = [
  { name: "Thane", spreadsheetId: "1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo", centres: 10, teachers: 5, students: 50, coordinator: "Chetan Modak", status: "active" },
  { name: "Boisar", spreadsheetId: "1_sYFgpeCgOicL_F2NDjYZFvrgQoUa3fkQvVHuRoFBEU", centres: 11, teachers: 3, students: 30, coordinator: "Chetan Modak", status: "active" },
  { name: "New Karjat", spreadsheetId: "1_sYFgpeCgOicL_F2NDjYZFvrgQoUa3fkQvVHuRoFBEU", centres: 10, teachers: 2, students: 20, coordinator: "Chetan Modak", status: "active" },
  { name: "Saphale", centres: 11, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Eastern Mumbai", centres: 15, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Navi Mumbai", centres: 16, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Karjat", centres: 14, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Western Mumbai", centres: 12, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Aarey Colony", centres: 5, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "Western Central Mumbai", centres: 7, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
  { name: "New Boisar", centres: 13, teachers: 0, students: 0, coordinator: "Pending", status: "active" },
];

const mapping = {
  "Thane": ["Tejaswini", "Mirabai", "Manikarnika", "Chanakya", "Laxmi", "Hari Om", "Ekveera", "Sant Rohidas Maharaj", "Shree Samarth", "Krushna"],
  "Eastern Mumbai": ["Gajanan", "Vaishnavi", "Radha Raman", "Bhavani (Secondary)", "Bhavani (Primary)", "Siddharth", "Azad", "Samarth", "Vedika", "Samarth (Primary)", "Vedika (Primary)", "Azad (Primary)", "Sidharth (Primary)", "Pragati", "Chaitanya"],
  "Navi Mumbai": ["Unnati (Secondary)", "Unnati (Primary)", "Udan", "Utkarsh", "Utthan", "Ujwal (Primary)", "Ujwal (Secondary)", "Umang", "Uddesh (Secondary)", "Uddesh (Primary)", "Urja (Secondary)", "Urja (Primary)", "Umedh", "Urmi (Primary)", "Urmi (Secondary)", "Utkal"],
  "Karjat": ["Bhivgad", "Rajmachi (Secondary)", "sondai", "kothaligad", "Shivneri", "Raigad", "Rajmachi (Primary)", "Saras Gad", "Prabalgad (Primary)", "Prabalgad (Secondary)", "Purandar (Primary)", "Purandar (Secondary)", "Vishalgad (Primary)", "Vishalgad (Secondary)"],
  "Western Mumbai": ["Panhala", "Lohagad Madhyamik", "Lohagad Prathamik", "Pratapgad", "Torna", "Ratangad", "Sinhgad", "Sinhgad Secondary", "Sindhudurg Abhyasika", "Naldurg Abhyasika", "Devgad Prathamik", "Devgad Madhyamik"],
  "Aarey Colony": ["Gingee Abhyasika (Primary)", "Gingee Abhyasika (Secondary)", "Harihar Abhyasika", "Sudhagad Abhyasika", "Sajjangad Abhyasika"],
  "Western Central Mumbai": ["Maheshwar", "Avanti (Primary)", "Avanti (Secondary)", "Devgiri Secondary", "Mahikavati Secondary", "Mahikavati Primary", "Devgiri Primary"],
  "Saphale": ["Surya", "Tapi", "Vaitarna (Secondary)", "Shivaganga", "Godavari", "Bhima", "Kaveri", "Koyana", "Narmada", "Vaitarna (Primary)", "Sindhu"],
  "Boisar": ["Shivpratap (Primary)", "Shivpratap (Secondary)", "Birsa Munda (Primary)", "Birsa Munda (Secondary)", "Tararani", "Hambirarao", "Tanaji", "Fulaji (Primary)", "Bajiprabhu (Secondary)", "Suryaji", "Prataprao"],
  "New Boisar": ["Sant Dnyaneshwar Abhyasika (Secondary)", "Sant Dnyaneshwar Abhyasika (Primary)", "Sant Namdev Abhyasika (Secondary)", "Sant Namdev Abhyasika (Primary)", "Sant Eknath Abhyasika (Secondary)", "Sant Muktabai Abhyasika (Secondary)", "Sant Bahinabai Abhyasika (Secondary)", "Sant Sopandev Abhyasika (Secondary)", "Sant Tukaram Abhyasika (Secondary)", "Sant nivruttinath Abhyasika (Secondary)", "Sant nivruttinath Abhyasika (Primary)", "Sant kabir Abhyasika (Secondary)", "Sant janabai (Secondary)"],
  "New Karjat": ["Karla Abhyasika", "Ajintha Abhyasika", "Kondhane Abhyasika", "Verul Abhyasika", "Kanheri Abhyasika", "Gharapuri Abhyasika", "Lenyadri Abhyasika", "Dharashiv Abhyasika", "Manikdoh Abhyasika", "Junnar Abhyasika"]
};

const centres = [];
for (const zone in mapping) {
  mapping[zone].forEach(c => {
    centres.push({ name: c, zone: zone, address: `${zone} Area Centre`, teachers: 0, students: 0 });
  });
}

const students = [
  { name: "Aarav Sharma", roll: "T-TEJ-101", status: "active", class: "Primary", centre: "Tejaswini", zone: "Thane", teacherId: "teacher-001" },
  { name: "Ananya Singh", roll: "T-TEJ-102", status: "active", class: "Primary", centre: "Tejaswini", zone: "Thane", teacherId: "teacher-001" },
  { name: "Vihaan Gupta", roll: "T-MIR-101", status: "active", class: "Secondary", centre: "Mirabai", zone: "Thane", teacherId: "teacher-001" },
  { name: "Sai Patil", roll: "B-SHI-101", status: "active", class: "Primary", centre: "Shivpratap (Primary)", zone: "Boisar", teacherId: "teacher-001" },
  { name: "Arjun Kulkarni", roll: "NK-KAR-101", status: "active", class: "Support Class", centre: "Karla Abhyasika", zone: "New Karjat", teacherId: "teacher-001" },
];

const teachers = [
  { uid: "teacher-001", email: "sarah@gmail.com", password: "sarah123", name: "Sarah Johnson", phone: "+91 99876 54321", zone: "Thane", centre: "Tejaswini", status: "active", students: 5, role: "teacher" },
  { uid: "teacher-002", email: "robert@gmail.com", password: "robert123", name: "Robert Smith", phone: "+91 99876 54322", zone: "Thane", centre: "Mirabai", status: "active", students: 5, role: "teacher" },
  { uid: "teacher-003", email: "maya@gmail.com", password: "maya123456", name: "Maya Williams", phone: "+91 99876 54323", zone: "Boisar", centre: "Shivpratap (Primary)", status: "active", students: 10, role: "teacher" },
];

const coordinators = [
  { uid: "coordinator-001", email: "anil@gmail.com", password: "anil123456", name: "Dr. Anil Kumar", phone: "+91 99876 12345", zone: "Thane", status: "active", role: "coordinator" },
  { uid: "coordinator-002", email: "priya@gmail.com", password: "priya123", name: "Dr. Priya Nair", phone: "+91 99876 12346", zone: "Boisar", status: "active", role: "coordinator" },
];

const leaves = [
  { name: "Sarah Johnson", userId: "teacher-001", role: "teacher", type: "Sick Leave", from: "2026-03-20", to: "2026-03-22", days: 3, status: "pending", reason: "Fever", zone: "Thane" },
];

const examResults = [
  { studentId: "student-001", name: "Aarav Sharma", roll: "T-TEJ-101", math: 88, science: 92, english: 85, total: 265, grade: "A", teacherId: "teacher-001" },
  { studentId: "student-002", name: "Ananya Singh", roll: "T-TEJ-102", math: 92, science: 95, english: 88, total: 275, grade: "A+", teacherId: "teacher-001" },
];

const diaryEntries = [
  { teacherId: "teacher-001", title: "Morning Reading Circle", body: "Focused on phonics today. Students showed significant improvement. Used the new picture books from the NGO kit.", category: "event", time: "09:15 AM", date: "2026-03-19", tags: ["Literacy", "Thane"] },
];

const resources = [
  { teacherId: "teacher-001", name: "Algebra_Basics.pdf", type: "pdf", size: "1.4 MB", date: "2026-03-19", subject: "Mathematics" },
];

// ─── Seed Functions ─────────────────────────────────────────────

async function seedCollection(collectionName, data) {
  const batch = db.batch();
  data.forEach((item, index) => {
    const docRef = db.collection(collectionName).doc(`${collectionName.slice(0, -1)}-${String(index + 1).padStart(3, "0")}`);
    batch.set(docRef, {
      ...item,
      createdAt: new Date().toISOString(),
    });
  });
  await batch.commit();
  console.log(`  ✓ Seeded ${data.length} documents in '${collectionName}'`);
}

async function seedUsers() {
  for (const user of users) {
    try {
      // Try to create Auth user
      try {
        await auth.createUser({
          uid: user.uid,
          email: user.email,
          password: user.password,
          displayName: user.name,
        });
        console.log(`  ✓ Created auth user: ${user.email} (${user.role})`);
      } catch (authError) {
        if (authError.code === "auth/uid-already-exists" || authError.code === "auth/email-already-exists") {
          console.log(`  ⚠ Auth user ${user.email} already exists, updating profile...`);
        } else {
          throw authError;
        }
      }

      // ALWAYS write/update Firestore profile (including password for local fallback)
      const { uid, ...profile } = user;
      await db.collection("users").doc(uid).set({
        ...profile,
        createdAt: new Date().toISOString(),
      });
    } catch (error) {
      console.error(`  ✗ Error with user ${user.email}:`, error.message);
    }
  }
}

async function seed() {
  console.log("\n🌱 Seeding NGO Education Platform database...\n");

  // Check if data already exists (skip seeding to preserve user-created data)
  const forceFlag = process.argv.includes("--force");
  if (!forceFlag) {
    try {
      const existingUser = await auth.getUserByEmail("admin@ngo.org");
      if (existingUser) {
        console.log("⚠ Data already exists (admin user found). Skipping seed to preserve your data.");
        console.log("  To force re-seed, run: npm run seed -- --force");
        console.log("");
        return;
      }
    } catch (e) {
      // User not found — proceed with seeding
    }
  }

  console.log("─── Auth Users (main accounts) ───");
  await seedUsers();

  console.log("\n─── Auth Users (teachers) ───");
  for (let i = 0; i < teachers.length; i++) {
    const t = teachers[i];
    const uid = `teacher-${String(i + 1).padStart(3, "0")}`;
    try {
      await auth.createUser({ uid, email: t.email, password: t.password, displayName: t.name });
      const { password: _pw, ...profile } = t;
      await db.collection("users").doc(uid).set({ ...profile, createdAt: new Date().toISOString() });
      console.log(`  ✓ Created auth user: ${t.email} (teacher) — password: ${t.password}`);
    } catch (error) {
      if (error.code === "auth/uid-already-exists" || error.code === "auth/email-already-exists") {
        console.log(`  ⚠ User ${t.email} already exists, skipping...`);
      } else {
        console.error(`  ✗ Error creating ${t.email}:`, error.message);
      }
    }
  }

  console.log("\n─── Auth Users (coordinators) ───");
  for (let i = 0; i < coordinators.length; i++) {
    const c = coordinators[i];
    const uid = `coordinator-${String(i + 1).padStart(3, "0")}`;
    try {
      await auth.createUser({ uid, email: c.email, password: c.password, displayName: c.name });
      const { password: _pw, ...profile } = c;
      await db.collection("users").doc(uid).set({ ...profile, createdAt: new Date().toISOString() });
      console.log(`  ✓ Created auth user: ${c.email} (coordinator) — password: ${c.password}`);
    } catch (error) {
      if (error.code === "auth/uid-already-exists" || error.code === "auth/email-already-exists") {
        console.log(`  ⚠ User ${c.email} already exists, skipping...`);
      } else {
        console.error(`  ✗ Error creating ${c.email}:`, error.message);
      }
    }
  }

  console.log("\n─── Firestore Collections ───");
  await seedCollection("students", students);
  await seedCollection("leaves", leaves);
  await seedCollection("zones", zones);
  await seedCollection("centres", centres);
  await seedCollection("examResults", examResults);
  await seedCollection("diaryEntries", diaryEntries);
  await seedCollection("resources", resources);

  console.log("\n✅ Seeding complete!\n");
  console.log("Demo credentials:");
  console.log("  Admin:        admin@gmail.com / admin123");
  console.log("  Teacher:      teacher@gmail.com / teacher123");
  console.log("  Coordinator:  coordinator@gmail.com / coordinator123");
  console.log("  Sarah (T):    sarah@gmail.com / sarah123");
  console.log("  Robert (T):   robert@gmail.com / robert123");
  console.log("  Maya (T):     maya@gmail.com / maya123456");
  console.log("  James (T):    james@gmail.com / james123");
  console.log("  Lisa (T):     lisa@gmail.com / lisa123456");
  console.log("  Anil (C):     anil@gmail.com / anil123456");
  console.log("  Priya (C):    priya@gmail.com / priya123");
  console.log("  Raj (C):      raj@gmail.com / raj1234567");
  console.log("");
}

seed().catch((error) => {
  console.error("Seeding failed:", error);
  process.exit(1);
});
