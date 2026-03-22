const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { syncExamResult } = require("../sheets/sheetsHelper");

/**
 * Firestore trigger: when a new examResults document is created,
 * sync the marks to the Exam Results Google Sheet.
 */
exports.onExamResultCreated = onDocumentCreated(
  "examResults/{docId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) {
      console.error("No data in exam result document");
      return;
    }

    const { zone, centre, date, topic, marks } = data;

    if (!zone || !centre || !date || !marks) {
      console.error("Missing required fields in exam result:", { zone, centre, date, topic });
      return;
    }

    console.log(`Syncing exam result: ${date} (${topic}) for ${zone} - ${centre}`);

    try {
      await syncExamResult({ zone, centre, date, topic, marks });
      console.log("Exam result synced to Google Sheets successfully");
    } catch (error) {
      console.error("Error syncing exam result to sheet:", error);
    }
  }
);
