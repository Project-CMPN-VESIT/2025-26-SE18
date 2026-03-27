const { google } = require("googleapis");
const fs = require("fs");
const path = require("path");

const SCOPES = ["https://www.googleapis.com/auth/spreadsheets"];

async function main() {
  const keyPath = path.join(__dirname, "service-account.json");
  const auth = new google.auth.GoogleAuth({ keyFile: keyPath, scopes: SCOPES });
  const sheets = google.sheets({ version: "v4", auth });
  
  const spreadsheetId = "1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo";
  console.log("Attempting to read sheet:", spreadsheetId);
  
  try {
    const res = await sheets.spreadsheets.get({ spreadsheetId });
    console.log("Success! Found tabs:", res.data.sheets.map(s => s.properties.title));
  } catch (err) {
    console.error("FAIL:", err.message);
  }
}

main();
