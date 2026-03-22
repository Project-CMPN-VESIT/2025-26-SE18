const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getSpreadsheetId, ensureTab } = require("../sheets/sheetsHelper");

/**
 * Trigger: onCentreCreated
 * When a new centre is added to Firestore, create its tab in the zonal spreadsheet.
 */
exports.onCentreCreated = onDocumentCreated("centres/{centreId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const { name, zone } = data;

  if (!name || !zone) {
    console.error("Missing name or zone in new centre document");
    return;
  }

  try {
    const spreadsheetId = await getSpreadsheetId(zone);
    await ensureTab(spreadsheetId, zone, name);
    console.log(`Successfully initialized sheet tab for new centre: ${name} in zone: ${zone}`);
  } catch (error) {
    console.error(`Error initializing sheet tab for centre ${name}:`, error.message);
  }
});
