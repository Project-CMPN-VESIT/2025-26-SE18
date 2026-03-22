const { google } = require("googleapis");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const path = require("path");

process.env.FIRESTORE_EMULATOR_HOST = "localhost:8086";
initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

const SPREADSHEET_ID = "1WoyLFFGf5O8ybLf4UsywMc0aEcq-J2CADA5x7t0znNc";

async function sync() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.join(__dirname, "service-account.json"),
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });
  const sheets = google.sheets({ version: "v4", auth });

  console.log("Fetching spreadsheet metadata...");
  const spreadsheet = await sheets.spreadsheets.get({
    spreadsheetId: SPREADSHEET_ID,
  });
  
  const tabs = spreadsheet.data.sheets.map(s => s.properties.title);
  console.log(`Found ${tabs.length} tabs: ${tabs.join(", ")}`);

  const centresData = [];

  for (const tab of tabs) {
    console.log(`Reading tab: ${tab}...`);
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: SPREADSHEET_ID,
      range: `'${tab}'!A:J`, // Read first 10 columns
    });

    const rows = res.data.values;
    if (!rows || rows.length < 2) continue;

    const header = rows[1]; // Header is usually on row 2 (index 1)
    const nameIdx = header.findIndex(h => h.includes("Name of Abhyasika"));
    const addressIdx = header.findIndex(h => h.includes("Detail Address"));
    const mapLinkIdx = header.findIndex(h => h.includes("Google Location of the Centre"));
    const zoneIdx = header.findIndex(h => h.includes("Zone"));

    if (nameIdx === -1 || mapLinkIdx === -1) {
      console.log(`  ⚠ Skipping tab ${tab}: Could not find Name or Map Link headers.`);
      continue;
    }

    for (let i = 2; i < rows.length; i++) {
        const row = rows[i];
        const name = row[nameIdx];
        if (!name) continue;

        centresData.push({
            name: name.trim(),
            zone: row[zoneIdx] || tab,
            address: row[addressIdx] || "",
            mapLink: row[mapLinkIdx] || ""
        });
    }
  }

  console.log(`Total centres found in spreadsheet: ${centresData.length}`);

  const centresSnap = await db.collection("centres").get();
  let updated = 0;
  let missing = 0;

  for (const doc of centresSnap.docs) {
    const centre = doc.data();
    // Try exact mirror first, then lowercase match
    let match = centresData.find(d => d.name === centre.name);
    if (!match) {
        match = centresData.find(d => d.name.toLowerCase() === centre.name.toLowerCase());
    }

    if (match) {
      await doc.ref.update({
        address: match.address,
        mapLink: match.mapLink
      });
      updated++;
    } else {
        missing++;
        console.log(`  ? No match for Firestore centre: ${centre.name} (${centre.zone})`);
    }
  }

  console.log(`\n✅ Sync complete.`);
  console.log(`Updated: ${updated}`);
  console.log(`Missing: ${missing}`);
}

sync().catch(console.error);
