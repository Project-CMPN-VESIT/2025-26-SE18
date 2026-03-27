const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = admin.firestore();

async function main() {
  const SPREADSHEET_ID = "1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo";
  console.log("Updating all zones to use spreadsheet ID:", SPREADSHEET_ID);
  
  const snap = await db.collection("zones").get();
  const batch = db.batch();
  
  let count = 0;
  for (const doc of snap.docs) {
    batch.update(doc.ref, { spreadsheetId: SPREADSHEET_ID });
    count++;
  }
  
  if (count > 0) {
    await batch.commit();
    console.log(`Successfully updated ${count} zones to point to the new Google Sheet.`);
  } else {
    // If no zones exist, let's create a default one
    console.log("No zones found. Creating a default 'North Zone'...");
    const zoneRef = db.collection("zones").doc();
    await zoneRef.set({
      name: "North Zone",
      spreadsheetId: SPREADSHEET_ID,
      status: "active",
      centres: 11, // Matching the number of tabs
      students: 0,
      teachers: 0
    });
    console.log("Created 'North Zone' and securely linked the Google Sheet.");
  }
  process.exit(0);
}

main().catch(console.error);
