const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });

// We need to simulate the Cloud Function manually because emulator triggers are tricky
// The function is `syncStudentsFromSheet` from `./src/students/syncStudents.js`
const { syncStudentsFromSheet } = require("./src/students/syncStudents");

async function manualSync() {
  console.log("Triggering manual sync for Thane zone...");
  try {
    // We send a mock request object. The function is defined as `onCall(async (request) => ...)`
    const mockRequest = {
      auth: { uid: "admin" }, // Bypass auth check
      data: { zone: "Thane" } // Specifically sync Thane
    };
    
    // BUT since v2 `onCall` wraps it, we can't just call it easily if it's the wrapped version.
    // Let's call the underlying logic directly by looking at what it imports!
    const { readStudentsFromSheet, getExistingTabs, getSpreadsheetId, getZoneNames } = require("./src/sheets/sheetsHelper");
    const db = admin.firestore();
    
    const zoneName = "Thane";
    const spreadsheetId = await getSpreadsheetId(zoneName);
    console.log(`Found spreadsheetId for ${zoneName}: ${spreadsheetId}`);
    
    const tabs = await getExistingTabs(spreadsheetId);
    console.log(`Found ${tabs.length} tabs including Overview.`);
    
    // Sync Centres
    let totalCentresSynced = 0;
    const centreBatch = db.batch();
    for (const tab of tabs) {
        if (tab === "Zonal Overview" || tab === "Overview" || tab === "Template") continue;
        const centreName = tab.trim();
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
    console.log(`Synced ${totalCentresSynced} centres.`);
    
    // Sync Students
    const sheetStudents = await readStudentsFromSheet(zoneName);
    let totalStudentsSynced = 0;
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
    console.log(`Synced ${totalStudentsSynced} students.`);
    
  } catch (err) {
    console.error("Error during manual sync:", err);
  }
  process.exit(0);
}

manualSync();
