/**
 * Sync students from Google Sheets centre tabs into Firestore.
 * Each zone's spreadsheet has one tab per centre with columns:
 *   A: Student Name, B: Roll Number, C: Centre
 * This script reads all centre tabs and upserts student docs.
 *
 * Usage: node seed/syncStudentsFromSheets.js
 */

const { google } = require("googleapis");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const path = require("path");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8086";
}

initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.join(__dirname, "..", "service-account.json"),
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });
  const sheets = google.sheets({ version: "v4", auth });

  console.log("Fetching zones from Firestore...");
  const zonesSnap = await db.collection("zones").get();

  let totalSynced = 0;

  for (const zoneDoc of zonesSnap.docs) {
    const zone = zoneDoc.data();
    if (!zone.spreadsheetId) {
      console.log(`⏩ Skipping ${zone.name} (no spreadsheetId)`);
      continue;
    }

    console.log(`\n📋 Processing zone: ${zone.name}`);

    // Get all tab names in this spreadsheet
    let tabNames;
    try {
      const spreadsheet = await sheets.spreadsheets.get({
        spreadsheetId: zone.spreadsheetId,
      });
      tabNames = spreadsheet.data.sheets.map((s) => s.properties.title);
    } catch (e) {
      console.log(`  ⚠ Could not access spreadsheet for ${zone.name}: ${e.message}`);
      continue;
    }

    // Get centres for this zone from Firestore
    const centresSnap = await db.collection("centres").where("zone", "==", zone.name).get();
    const centreNames = centresSnap.docs.map((d) => d.data().name);

    for (const centreName of centreNames) {
      // Check if a tab exists for this centre
      if (!tabNames.includes(centreName)) {
        continue;
      }

      try {
        const res = await sheets.spreadsheets.values.get({
          spreadsheetId: zone.spreadsheetId,
          range: `'${centreName}'`,
        });

        const rows = res.data.values;
        if (!rows || rows.length <= 1) {
          continue; // Only header or empty
        }

        // Skip header row (row 0)
        for (let i = 1; i < rows.length; i++) {
          const studentName = (rows[i][0] || "").trim();
          const rollNumber = (rows[i][1] || "").trim();
          if (!studentName) continue;

          let presentCount = 0;
          let absentCount = 0;
          let dropoutCount = 0;
          const attendanceCells = rows[i].slice(3);
          for (const status of attendanceCells) {
            if (status === "P") presentCount++;
            else if (status === "A") absentCount++;
            else if (status === "D") dropoutCount++;
          }

          // Check if student already exists by roll number in this centre
          const existing = rollNumber
            ? await db.collection("students")
                .where("roll", "==", rollNumber)
                .where("centre", "==", centreName)
                .get()
            : { empty: true };

          if (!existing.empty) {
            // Update existing
            await existing.docs[0].ref.update({
              name: studentName,
              zone: zone.name,
              presentCount,
              absentCount,
              dropoutCount,
            });
          } else {
            // Create new student doc
            await db.collection("students").add({
              name: studentName,
              roll: rollNumber || `${centreName.substring(0, 3).toUpperCase()}-${i}`,
              status: "active",
              class: "Primary",
              centre: centreName,
              zone: zone.name,
              teacherId: "",
              presentCount,
              absentCount,
              dropoutCount,
            });
          }
          totalSynced++;
        }
        console.log(`  ✓ ${centreName}: synced ${rows.length - 1} students`);
      } catch (e) {
        console.log(`  ⚠ Skipped tab ${centreName}: ${e.message}`);
      }
    }
  }

  console.log(`\n✅ Done! Total students synced: ${totalSynced}`);
}

main().catch(console.error);
