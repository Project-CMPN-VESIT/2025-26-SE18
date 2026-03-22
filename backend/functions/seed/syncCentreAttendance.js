const { google } = require("googleapis");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const path = require("path");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = "localhost:8086";
}

initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

const OVERVIEW_TAB = "Zonal Overview";

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.join(__dirname, "..", "service-account.json"),
    scopes: ["https://www.googleapis.com/auth/spreadsheets"],
  });
  const sheets = google.sheets({ version: "v4", auth });

  console.log("Fetching zones from Firestore...");
  const zonesSnap = await db.collection("zones").get();

  for (const zoneDoc of zonesSnap.docs) {
    const zone = zoneDoc.data();
    if (!zone.spreadsheetId) continue;
    
    console.log(`\nSyncing ${zone.name}...`);
    try {
      const res = await sheets.spreadsheets.values.get({
        spreadsheetId: zone.spreadsheetId,
        range: `'${OVERVIEW_TAB}'!A:D`,
      });
      
      const rows = res.data.values;
      if (!rows || rows.length <= 1) {
        console.log(`  No data in ${OVERVIEW_TAB} for ${zone.name}`);
        continue;
      }
      
      for (let i = 1; i < rows.length; i++) {
        const centreName = rows[i][0];
        const overallAtt = rows[i][3];
        if (!centreName || !overallAtt) continue;

        // Update firestore
        const cSnap = await db.collection("centres")
          .where("name", "==", centreName)
          .where("zone", "==", zone.name)
          .get();

        if (!cSnap.empty) {
          const totalStudents = parseInt(rows[i][1]) || 0;
          await cSnap.docs[0].ref.update({ attendance: overallAtt, totalStudents: totalStudents });
          console.log(`  ✓ Updated ${centreName} -> ${overallAtt}, ${totalStudents} students`);
        }
      }
    } catch (e) {
      console.log(`  ⚠ Skipped ${zone.name}: ${e.message}`);
    }
  }
}

main().catch(console.error);
