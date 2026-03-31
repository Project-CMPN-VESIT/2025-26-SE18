/**
 * Seva-Sahyog — Supabase Seed Script
 * Replaces: backend/functions/seed/seedData.js
 *
 * Creates all Supabase Auth users + inserts profile/zone/centre/student data.
 *
 * Usage:
 *   node supabase/seed_users.js
 *
 * Requirements:
 *   npm install @supabase/supabase-js  (install in repo root or supabase/ dir)
 *
 * Set env vars before running:
 *   $env:SUPABASE_URL      = "https://YOUR_PROJECT.supabase.co"
 *   $env:SUPABASE_SERVICE_KEY = "YOUR_SERVICE_ROLE_KEY"   # NOT the anon key!
 */

require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_KEY env vars.");
  console.error("   Set them before running this script.");
  process.exit(1);
}

// Use service role key — bypasses RLS for seeding
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ─── Data ────────────────────────────────────────────────────

const users = [
  // Admin
  { email: "admin@ngo.org",              password: "admin123",    role: "admin",       name: "Admin User",           phone: "1234567890", zone: "",             centre: "" },
  // Coordinators
  { email: "coord.boisar@ngo.org",       password: "coord123",    role: "coordinator", name: "Chetan Modak",         phone: "9876543210", zone: "Boisar",       centre: "" },
  { email: "coord.thane@ngo.org",        password: "coord123",    role: "coordinator", name: "Thane Coordinator",    phone: "2223334444", zone: "Thane",        centre: "" },
  { email: "coord.nkarjat@ngo.org",      password: "coord123",    role: "coordinator", name: "Karjat Coordinator",   phone: "3334445555", zone: "New Karjat",   centre: "" },
  { email: "coord.saphale@ngo.org",      password: "coord123",    role: "coordinator", name: "Saphale Coordinator",  phone: "4445556666", zone: "Saphale",      centre: "" },
  { email: "coord.eastern@ngo.org",      password: "coord123",    role: "coordinator", name: "Eastern Coordinator",  phone: "5556667777", zone: "Eastern Mumbai",centre: "" },
  // Teachers
  { email: "teacher.shivpratap.p@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Shivpratap P",  phone: "1112223333", zone: "Boisar",     centre: "Shivpratap (Primary)" },
  { email: "teacher.shivpratap.s@ngo.org", password: "teacher123", role: "teacher", name: "Teacher Shivpratap S",  phone: "4445556666", zone: "Boisar",     centre: "Shivpratap (Secondary)" },
  { email: "teacher.tejaswini@ngo.org",  password: "teacher123",  role: "teacher",     name: "Teacher Tejaswini",    phone: "5556667777", zone: "Thane",      centre: "Tejaswini" },
  { email: "teacher.mirabai@ngo.org",    password: "teacher123",  role: "teacher",     name: "Teacher Mirabai",      phone: "8889990000", zone: "Thane",      centre: "Mirabai" },
  { email: "teacher.karla@ngo.org",      password: "teacher123",  role: "teacher",     name: "Teacher Karla",        phone: "6667778888", zone: "New Karjat", centre: "Karla Abhyasika" },
  { email: "teacher.ajintha@ngo.org",    password: "teacher123",  role: "teacher",     name: "Teacher Ajintha",      phone: "9990001111", zone: "New Karjat", centre: "Ajintha Abhyasika" },
  { email: "teacher.surya@ngo.org",      password: "teacher123",  role: "teacher",     name: "Teacher Surya",        phone: "7778889999", zone: "Saphale",    centre: "Surya" },
  { email: "teacher.gajanan@ngo.org",    password: "teacher123",  role: "teacher",     name: "Teacher Gajanan",      phone: "0001112222", zone: "Eastern Mumbai", centre: "Gajanan" },
  // Test
  { email: "test3@gmail.com",            password: "test1123",    role: "coordinator", name: "test coordinator",     phone: "1234567890", zone: "",            centre: "" },
  { email: "sarah@gmail.com",            password: "sarah123",    role: "teacher",     name: "Sarah Johnson",        phone: "+91 99876 54321", zone: "Thane", centre: "Tejaswini" },
  { email: "robert@gmail.com",           password: "robert123",   role: "teacher",     name: "Robert Smith",         phone: "+91 99876 54322", zone: "Thane", centre: "Mirabai" },
  { email: "maya@gmail.com",             password: "maya123456",  role: "teacher",     name: "Maya Williams",        phone: "+91 99876 54323", zone: "Boisar", centre: "Shivpratap (Primary)" },
  { email: "anil@gmail.com",             password: "anil123456",  role: "coordinator", name: "Dr. Anil Kumar",       phone: "+91 99876 12345", zone: "Thane", centre: "" },
  { email: "priya@gmail.com",            password: "priya123",    role: "coordinator", name: "Dr. Priya Nair",       phone: "+91 99876 12346", zone: "Boisar", centre: "" },
];

const zones = [
  { name: "Thane",               coordinator: "Chetan Modak", centres: 10, teachers: 5,  students: 50, status: "active" },
  { name: "Boisar",              coordinator: "Chetan Modak", centres: 11, teachers: 3,  students: 30, status: "active" },
  { name: "New Karjat",          coordinator: "Chetan Modak", centres: 10, teachers: 2,  students: 20, status: "active" },
  { name: "Saphale",             coordinator: "Pending",      centres: 11, teachers: 0,  students: 0,  status: "active" },
  { name: "Eastern Mumbai",      coordinator: "Pending",      centres: 15, teachers: 0,  students: 0,  status: "active" },
  { name: "Navi Mumbai",         coordinator: "Pending",      centres: 16, teachers: 0,  students: 0,  status: "active" },
  { name: "Karjat",              coordinator: "Pending",      centres: 14, teachers: 0,  students: 0,  status: "active" },
  { name: "Western Mumbai",      coordinator: "Pending",      centres: 12, teachers: 0,  students: 0,  status: "active" },
  { name: "Aarey Colony",        coordinator: "Pending",      centres: 5,  teachers: 0,  students: 0,  status: "active" },
  { name: "Western Central Mumbai", coordinator: "Pending",   centres: 7,  teachers: 0,  students: 0,  status: "active" },
  { name: "New Boisar",          coordinator: "Pending",      centres: 13, teachers: 0,  students: 0,  status: "active" },
];

const centreMapping = {
  "Thane":            ["Tejaswini","Mirabai","Manikarnika","Chanakya","Laxmi","Hari Om","Ekveera","Sant Rohidas Maharaj","Shree Samarth","Krushna"],
  "Eastern Mumbai":   ["Gajanan","Vaishnavi","Radha Raman","Bhavani (Secondary)","Bhavani (Primary)","Siddharth","Azad","Samarth","Vedika","Samarth (Primary)","Vedika (Primary)","Azad (Primary)","Sidharth (Primary)","Pragati","Chaitanya"],
  "Navi Mumbai":      ["Unnati (Secondary)","Unnati (Primary)","Udan","Utkarsh","Utthan","Ujwal (Primary)","Ujwal (Secondary)","Umang","Uddesh (Secondary)","Uddesh (Primary)","Urja (Secondary)","Urja (Primary)","Umedh","Urmi (Primary)","Urmi (Secondary)","Utkal"],
  "Karjat":           ["Bhivgad","Rajmachi (Secondary)","sondai","kothaligad","Shivneri","Raigad","Rajmachi (Primary)","Saras Gad","Prabalgad (Primary)","Prabalgad (Secondary)","Purandar (Primary)","Purandar (Secondary)","Vishalgad (Primary)","Vishalgad (Secondary)"],
  "Western Mumbai":   ["Panhala","Lohagad Madhyamik","Lohagad Prathamik","Pratapgad","Torna","Ratangad","Sinhgad","Sinhgad Secondary","Sindhudurg Abhyasika","Naldurg Abhyasika","Devgad Prathamik","Devgad Madhyamik"],
  "Aarey Colony":     ["Gingee Abhyasika (Primary)","Gingee Abhyasika (Secondary)","Harihar Abhyasika","Sudhagad Abhyasika","Sajjangad Abhyasika"],
  "Western Central Mumbai": ["Maheshwar","Avanti (Primary)","Avanti (Secondary)","Devgiri Secondary","Mahikavati Secondary","Mahikavati Primary","Devgiri Primary"],
  "Saphale":          ["Surya","Tapi","Vaitarna (Secondary)","Shivaganga","Godavari","Bhima","Kaveri","Koyana","Narmada","Vaitarna (Primary)","Sindhu"],
  "Boisar":           ["Shivpratap (Primary)","Shivpratap (Secondary)","Birsa Munda (Primary)","Birsa Munda (Secondary)","Tararani","Hambirarao","Tanaji","Fulaji (Primary)","Bajiprabhu (Secondary)","Suryaji","Prataprao"],
  "New Boisar":       ["Sant Dnyaneshwar Abhyasika (Secondary)","Sant Dnyaneshwar Abhyasika (Primary)","Sant Namdev Abhyasika (Secondary)","Sant Namdev Abhyasika (Primary)","Sant Eknath Abhyasika (Secondary)","Sant Muktabai Abhyasika (Secondary)","Sant Bahinabai Abhyasika (Secondary)","Sant Sopandev Abhyasika (Secondary)","Sant Tukaram Abhyasika (Secondary)","Sant nivruttinath Abhyasika (Secondary)","Sant nivruttinath Abhyasika (Primary)","Sant kabir Abhyasika (Secondary)","Sant janabai (Secondary)"],
  "New Karjat":       ["Karla Abhyasika","Ajintha Abhyasika","Kondhane Abhyasika","Verul Abhyasika","Kanheri Abhyasika","Gharapuri Abhyasika","Lenyadri Abhyasika","Dharashiv Abhyasika","Manikdoh Abhyasika","Junnar Abhyasika"],
};

// Build flat centres array
const centresData = [];
for (const [zone, names] of Object.entries(centreMapping)) {
  for (const name of names) {
    centresData.push({ name, zone, address: `${zone} Area Centre`, teachers: 0, students: 0, status: "active" });
  }
}

// ─── Seed Functions ──────────────────────────────────────────

async function seedUsers() {
  console.log("\n─── Creating Auth Users + Profiles ───");
  for (const u of users) {
    try {
      // Create in Supabase Auth
      const { data: authData, error: authErr } = await supabase.auth.admin.createUser({
        email: u.email,
        password: u.password,
        email_confirm: true,
        user_metadata: { name: u.name, role: u.role },
      });

      if (authErr && !authErr.message.includes("already been registered")) {
        console.error(`  ✗ Auth error for ${u.email}: ${authErr.message}`);
        continue;
      }

      const uid = authData?.user?.id;
      if (!uid) {
        // User likely already exists — try to look them up
        const { data: existing } = await supabase.auth.admin.listUsers();
        const found = existing?.users?.find((x) => x.email === u.email);
        if (!found) { console.warn(`  ⚠ Could not resolve UID for ${u.email}`); continue; }
        const existingUid = found.id;
        await upsertProfile(existingUid, u);
        console.log(`  ↺ Updated profile: ${u.email} (${u.role})`);
        continue;
      }

      await upsertProfile(uid, u);
      console.log(`  ✓ Created: ${u.email} (${u.role})`);
    } catch (e) {
      console.error(`  ✗ Unexpected error for ${u.email}:`, e.message);
    }
  }
}

async function upsertProfile(uid, u) {
  const { error } = await supabase.from("profiles").upsert({
    id: uid,
    email: u.email,
    name: u.name,
    role: u.role,
    zone: u.zone ?? "",
    centre: u.centre ?? "",
    phone: u.phone ?? "",
    status: "active",
  });
  if (error) console.error(`    Profile upsert error (${u.email}):`, error.message);
}

async function seedZones() {
  console.log("\n─── Seeding Zones ───");
  const { error } = await supabase.from("zones").upsert(zones, { onConflict: "name" });
  if (error) console.error("  ✗ Zones error:", error.message);
  else console.log(`  ✓ Seeded ${zones.length} zones`);
}

async function seedCentres() {
  console.log("\n─── Seeding Centres ───");
  // Insert in chunks of 50 to avoid request limit
  for (let i = 0; i < centresData.length; i += 50) {
    const chunk = centresData.slice(i, i + 50);
    const { error } = await supabase.from("centres").upsert(chunk, { onConflict: "name,zone" });
    if (error) console.error(`  ✗ Centres chunk error:`, error.message);
  }
  console.log(`  ✓ Seeded ${centresData.length} centres`);
}

async function seedSampleStudents() {
  console.log("\n─── Seeding Sample Students ───");
  // Look up teacher UIDs for assignment
  const { data: teacherRows } = await supabase
    .from("profiles")
    .select("id, email")
    .eq("role", "teacher");

  const teacherMap = {};
  for (const t of (teacherRows ?? [])) teacherMap[t.email] = t.id;

  const sarahId  = teacherMap["sarah@gmail.com"]  ?? null;
  const robertId = teacherMap["robert@gmail.com"] ?? null;

  const students = [
    { name: "Aarav Sharma",   roll: "T-TEJ-101", status: "active", class: "Primary",       centre: "Tejaswini",          zone: "Thane",     teacher_id: sarahId },
    { name: "Ananya Singh",   roll: "T-TEJ-102", status: "active", class: "Primary",       centre: "Tejaswini",          zone: "Thane",     teacher_id: sarahId },
    { name: "Vihaan Gupta",   roll: "T-MIR-101", status: "active", class: "Secondary",     centre: "Mirabai",            zone: "Thane",     teacher_id: robertId },
    { name: "Sai Patil",      roll: "B-SHI-101", status: "active", class: "Primary",       centre: "Shivpratap (Primary)", zone: "Boisar",  teacher_id: null },
    { name: "Arjun Kulkarni", roll: "NK-KAR-101", status: "active", class: "Support Class", centre: "Karla Abhyasika",   zone: "New Karjat", teacher_id: null },
  ];

  const { error } = await supabase.from("students").upsert(students, { onConflict: "roll" });
  if (error) console.error("  ✗ Students error:", error.message);
  else console.log(`  ✓ Seeded ${students.length} sample students`);
}

async function seed() {
  console.log("\n🌱 Seeding Seva-Sahyog Supabase database...");
  console.log(`   Target: ${SUPABASE_URL}\n`);

  await seedZones();
  await seedCentres();
  await seedUsers();
  await seedSampleStudents();

  console.log("\n✅ Seeding complete!");
  console.log("\nDemo credentials:");
  console.log("  Admin:       admin@ngo.org      / admin123");
  console.log("  Coordinator: coord.thane@ngo.org / coord123");
  console.log("  Teacher:     sarah@gmail.com     / sarah123");
  console.log("  Teacher:     robert@gmail.com    / robert123");
}

seed().catch((e) => {
  console.error("Seeding failed:", e);
  process.exit(1);
});
