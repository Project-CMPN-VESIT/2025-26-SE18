const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");

/**
 * Firestore trigger: When a new attendance record is created,
 * sync it to Google Sheets and update the student's attendance %.
 */
exports.onAttendanceCreated = onDocumentCreated("attendance/{recordId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const record = snapshot.data();
  const db = getFirestore();

  console.log("New attendance record:", {
    studentId: record.studentId,
    studentName: record.studentName,
    teacherId: record.teacherId,
    centre: record.centre,
    zone: record.zone,
    date: record.date,
    status: record.status,
  });

  // ─── Update student's attendance percentage ───────────────────
  if (record.studentId) {
    try {
      const studentRef = db.collection("students").doc(record.studentId);
      const studentDoc = await studentRef.get();

      if (studentDoc.exists) {
        const attendanceSnap = await db.collection("attendance")
          .where("studentId", "==", record.studentId)
          .get();

        const studentData = studentDoc.data() || {};
        let presentCount = studentData.presentCount || 0;
        let absentCount = studentData.absentCount || 0;
        let dropoutCount = studentData.dropoutCount || 0;

        if (record.status === 'present') presentCount++;
        else if (record.status === 'absent') absentCount++;
        else if (record.status === 'dropout') dropoutCount++;

        const totalRecords = presentCount + absentCount + dropoutCount;
        const percentage = totalRecords > 0 ?
          Math.round((presentCount / totalRecords) * 100) :
          0;

        await studentRef.update({
          attendance: `${percentage}%`,
          presentCount,
          absentCount,
          dropoutCount,
        });

        console.log(`Updated ${record.studentId} attendance to ${percentage}%`);
      }
    } catch (error) {
      console.error("Error updating student attendance:", error);
    }
  }

  // ─── Google Sheets Sync ─────────────────────────────────────────
  try {
    const { syncAttendance } = require("../sheets/sheetsHelper");

    // Get student roll number from Firestore for the sheet
    let roll = "";
    if (record.studentId) {
      const studentDoc = await db.collection("students").doc(record.studentId).get();
      if (studentDoc.exists) {
        roll = studentDoc.data().roll || "";
      }
    }

    await syncAttendance({
      studentName: record.studentName || "Unknown",
      roll: roll,
      date: record.date,
      status: record.status,
      centre: record.centre || "Unknown",
      zone: record.zone || "Unknown",
      startTime: record.startTime || "",
      endTime: record.endTime || "",
    });

    console.log("Attendance synced to Google Sheets");
  } catch (error) {
    console.error("Error syncing to Google Sheets:", error.message);
    // Don't throw — Sheets sync failure shouldn't break the attendance flow
  }

  return null;
});
