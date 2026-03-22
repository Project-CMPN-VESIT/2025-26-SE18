/**
 * One-off script to initialize the Exam Results Google Sheet
 * with all 11 Zone tabs and clean up old/default tabs.
 */
const { google } = require("googleapis");
const path = require("path");

const EXAM_SPREADSHEET_ID = "1J9tqankIVnQ-de0Jik4voxwnpGsHxwpF1zOM37MSrHo";

// The 11 real zones
const ZONES = [
  "Thane", "Boisar", "New Karjat", "Saphale", "Eastern Mumbai", 
  "Navi Mumbai", "Karjat", "Western Mumbai", "Aarey Colony", 
  "Western Central Mumbai", "New Boisar"
];

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: path.join(__dirname, "..", "service-account.json"),
    scopes: ["https://www.googleapis.com/auth/spreadsheets"],
  });
  const sheets = google.sheets({ version: "v4", auth });

  // 1. Get existing tabs
  const meta = await sheets.spreadsheets.get({ spreadsheetId: EXAM_SPREADSHEET_ID });
  const existingSheets = meta.data.sheets;
  const existingTabs = existingSheets.map((s) => s.properties.title);
  console.log("Existing tabs:", existingTabs);

  const requests = [];

  // 2. Create the 11 Zone tabs if they don't exist
  for (const zone of ZONES) {
    if (!existingTabs.includes(zone)) {
      requests.push({ addSheet: { properties: { title: zone } } });
      console.log(`  Will create tab: ${zone}`);
    } else {
      console.log(`  Tab already exists: ${zone}`);
    }
  }

  // Execute tab creations first so we don't accidentally delete everything
  if (requests.length > 0) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: EXAM_SPREADSHEET_ID,
      requestBody: { requests },
    });
    console.log(`\n✓ Created ${requests.length} new Zone tabs`);
  }

  // 3. Set headers for all Zone tabs
  for (const zone of ZONES) {
    try {
      await sheets.spreadsheets.values.update({
        spreadsheetId: EXAM_SPREADSHEET_ID,
        range: `'${zone}'!A1:C1`,
        valueInputOption: "RAW",
        requestBody: { values: [["Student Name", "Roll Number", "Centre"]] },
      });
      console.log(`  Set headers for: ${zone}`);
    } catch (e) {
      console.error(`  Error setting headers for ${zone}:`, e.message);
    }
  }

  // 4. Delete old tabs (like Sheet1 or old Zone-Centre tabs)
  // We re-fetch to get the updated sheet IDs
  const updatedMeta = await sheets.spreadsheets.get({ spreadsheetId: EXAM_SPREADSHEET_ID });
  const deleteRequests = [];
  
  for (const sheet of updatedMeta.data.sheets) {
    const title = sheet.properties.title;
    if (!ZONES.includes(title)) {
      deleteRequests.push({ deleteSheet: { sheetId: sheet.properties.sheetId } });
      console.log(`  Will delete unrecognized tab: ${title}`);
    }
  }

  if (deleteRequests.length > 0) {
    try {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId: EXAM_SPREADSHEET_ID,
        requestBody: { requests: deleteRequests },
      });
      console.log(`\n✓ Removed ${deleteRequests.length} old/unrecognized tabs`);
    } catch (e) {
      console.log("\n⚠ Error removing old tabs:", e.message);
    }
  } else {
    console.log("\n✓ No old tabs to remove.");
  }

  console.log("\n🎉 Exam Sheet perfectly initialized with the 11 Zone format!");
}

main().catch((e) => {
  console.error("Error:", e.message);
  process.exit(1);
});
