const { onDocumentCreated } = require("firebase-functions/v2/firestore");

/**
 * Firestore trigger: When a new student document is created,
 * add a row for them in the appropriate Google Sheet tab.
 */
exports.onStudentCreated = onDocumentCreated("students/{studentId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const student = snapshot.data();

  console.log("New student created:", {
    name: student.name,
    roll: student.roll,
    centre: student.centre,
    zone: student.zone,
  });

  // ─── Sync to Google Sheet ──────────────────────────────────────
  try {
    const { addStudentRow } = require("../sheets/sheetsHelper");

    const zone = student.zone || "Unknown";
    const centre = student.centre || "Unknown";
    const name = student.name || "Unknown";
    const roll = student.roll || "";

    await addStudentRow(zone, centre, name, roll);
    console.log(`Student ${name} added to Google Sheet tab: ${zone} - ${centre}`);
  } catch (error) {
    console.error("Error syncing student to Google Sheets:", error.message);
    // Don't throw — sheet sync failure shouldn't break student creation
  }

  return null;
});
