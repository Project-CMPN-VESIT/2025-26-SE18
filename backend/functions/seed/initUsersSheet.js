/**
 * One-time script to populate the Users Directory tab
 * with all existing seeded users.
 *
 * Usage: node seed/initUsersSheet.js
 */

const { initializeApp } = require("firebase-admin/app");
initializeApp({ projectId: "smarteducationanalyticssystem" });

const { addUserRow, ensureUsersTab } = require("../src/sheets/sheetsHelper");

// All demo users with their passwords
const allUsers = [
  { name: "Admin", email: "admin@gmail.com", password: "admin123", phone: "+91 99876 00000", role: "admin", zone: "All", centre: "HQ" },
  { name: "Teacher", email: "teacher@gmail.com", password: "teacher123", phone: "+91 99876 54321", role: "teacher", zone: "North", centre: "East Park Centre" },
  { name: "Coordinator", email: "coordinator@gmail.com", password: "coordinator123", phone: "+91 99876 12345", role: "coordinator", zone: "North", centre: "" },
  { name: "Sarah Johnson", email: "sarah@gmail.com", password: "sarah123", phone: "+91 99876 54321", role: "teacher", zone: "North", centre: "East Park Centre" },
  { name: "Robert Smith", email: "robert@gmail.com", password: "robert123", phone: "+91 99876 54322", role: "teacher", zone: "North", centre: "North Valley" },
  { name: "Maya Williams", email: "maya@gmail.com", password: "maya123456", phone: "+91 99876 54323", role: "teacher", zone: "South", centre: "Urban Hub" },
  { name: "James Chen", email: "james@gmail.com", password: "james123", phone: "+91 99876 54324", role: "teacher", zone: "West", centre: "City Square" },
  { name: "Lisa Park", email: "lisa@gmail.com", password: "lisa123456", phone: "+91 99876 54325", role: "teacher", zone: "North", centre: "East Park Centre" },
  { name: "Dr. Anil Kumar", email: "anil@gmail.com", password: "anil123456", phone: "+91 99876 12345", role: "coordinator", zone: "North", centre: "" },
  { name: "Dr. Priya Nair", email: "priya@gmail.com", password: "priya123", phone: "+91 99876 12346", role: "coordinator", zone: "South", centre: "" },
  { name: "Dr. Raj Mehta", email: "raj@gmail.com", password: "raj1234567", phone: "+91 99876 12347", role: "coordinator", zone: "West", centre: "" },
];

async function init() {
  console.log("\n👥 Populating Users Directory sheet...\n");
  await ensureUsersTab();

  for (const user of allUsers) {
    try {
      await addUserRow(user);
      console.log(`  ✓ ${user.email} (${user.role})`);
    } catch (error) {
      console.error(`  ✗ ${user.email}: ${error.message}`);
    }
  }

  console.log("\n✅ Users Directory populated!\n");
}

init().catch((e) => { console.error("Failed:", e); process.exit(1); });
