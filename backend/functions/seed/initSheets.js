/**
 * One-time script to initialize all zone-centre tabs in the Google Sheet
 * and populate them with existing students from Firestore.
 *
 * Usage: node seed/initSheets.js
 */

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

// Import the sheets helper
const { ensureTab, addStudentRow } = require("../src/sheets/sheetsHelper");

// All known zone-centre combinations
const zoneCentres = [
  { zone: "North", centre: "East Park Centre" },
  { zone: "North", centre: "North Valley" },
  { zone: "South", centre: "Urban Hub" },
  { zone: "West", centre: "City Square" },
  { zone: "East", centre: "Green Meadows" },
  { zone: "North", centre: "Bright Future" },
];

async function initSheets() {
  console.log("\n📊 Initializing Google Sheets tabs...\n");

  // 1. Create all zone-centre tabs
  for (const zc of zoneCentres) {
    try {
      await ensureTab(zc.zone, zc.centre);
      console.log(`  ✓ Tab ready: ${zc.zone} - ${zc.centre}`);
    } catch (error) {
      console.error(`  ✗ Error creating tab ${zc.zone} - ${zc.centre}:`, error.message);
    }
  }

  // 2. Fetch all students from Firestore and add them to their respective tabs
  console.log("\n📋 Syncing students to sheets...\n");
  const studentsSnap = await db.collection("students").get();

  for (const doc of studentsSnap.docs) {
    const student = doc.data();
    const zone = student.zone || "Unknown";
    const centre = student.centre || "Unknown";
    const name = student.name || "Unknown";
    const roll = student.roll || "";

    try {
      await addStudentRow(zone, centre, name, roll);
      console.log(`  ✓ ${name} → ${zone} - ${centre}`);
    } catch (error) {
      console.error(`  ✗ Error adding ${name}:`, error.message);
    }
  }

  console.log("\n✅ Google Sheets initialization complete!\n");
}

initSheets().catch((error) => {
  console.error("Sheet init failed:", error);
  process.exit(1);
});
