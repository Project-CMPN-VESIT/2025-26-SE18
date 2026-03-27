const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { readStudentsFromSheet, getExistingTabs, getSpreadsheetId, getZoneNames } = require("../sheets/sheetsHelper");

/**
 * Callable Cloud Function: syncStudentsFromSheet
 * 
 * Reads students and centres from zonal Google Sheets and syncs them to Firestore.
 * Input: { zone?, centre? }
 */
exports.syncStudentsFromSheet = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const { zone: filterZone, centre: filterCentre } = request.data || {};
  const db = getFirestore();
  
  try {
    const zonesToSync = (filterZone && filterZone !== "All") ? [filterZone] : await getZoneNames();
    let totalStudentsSynced = 0;
    let totalCentresSynced = 0;

    for (const zoneName of zonesToSync) {
      console.log(`Syncing zone: ${zoneName}`);
      
      // 1. Sync Centres (Tabs) for this zone
      const spreadsheetId = await getSpreadsheetId(zoneName);
      const tabs = await getExistingTabs(spreadsheetId);
      
      const centreBatch = db.batch();
      for (const tab of tabs) {
          if (tab === "Overview" || tab === "Template") continue;
          
          const centreName = tab.trim();
          if (filterCentre && filterCentre !== "All" && centreName !== filterCentre) continue;

          // Find zone ID (needed for reference)
          const zoneSnap = await db.collection("zones").where("name", "==", zoneName).get();
          const zoneId = zoneSnap.empty ? null : zoneSnap.docs[0].id;

          const centreId = `${zoneName}_${centreName}`.replace(/\s+/g, '_').toLowerCase();
          const centreRef = db.collection("centres").doc(centreId);
          
          centreBatch.set(centreRef, {
            name: centreName,
            zone: zoneName,
            zoneId: zoneId,
            status: "active",
            lastSyncSource: "google_sheets",
            updatedAt: new Date().toISOString()
          }, { merge: true });
          totalCentresSynced++;
      }
      await centreBatch.commit();

      // 2. Sync Students for this zone
      const sheetStudents = await readStudentsFromSheet(zoneName, filterCentre);
      
      const batchSize = 500;
      for (let i = 0; i < sheetStudents.length; i += batchSize) {
        const studentBatch = db.batch();
        const currentBatch = sheetStudents.slice(i, i + batchSize);

        for (const student of currentBatch) {
          if (!student.roll) continue;

          const studentId = student.roll.replace(/[^a-zA-Z0-9]/g, '_').toLowerCase();
          const studentRef = db.collection("students").doc(studentId);
          
          studentBatch.set(studentRef, {
            ...student,
            updatedAt: new Date().toISOString(),
            lastSyncSource: "google_sheets"
          }, { merge: true });
          
          totalStudentsSynced++;
        }
        await studentBatch.commit();
      }
    }

    return { 
      syncedStudents: totalStudentsSynced,
      syncedCentres: totalCentresSynced,
      message: `Sync complete: ${totalCentresSynced} centres and ${totalStudentsSynced} students processed.` 
    };
  } catch (error) {
    console.error("Error in syncStudentsFromSheet:", error);
    throw new HttpsError("internal", `Sync failed: ${error.message}`);
  }
});
