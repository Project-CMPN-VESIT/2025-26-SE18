const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const PDFDocument = require("pdfkit");

/**
 * HTTP-callable function: Generate a CSR (Corporate Social Responsibility) report.
 *
 * Accepts:
 *   - dateFrom (string): Start date (YYYY-MM-DD)
 *   - dateTo (string): End date (YYYY-MM-DD)
 *   - zone (string, optional): Filter by zone
 *   - centre (string, optional): Filter by centre
 *
 * Returns:
 *   - { downloadUrl: string, reportId: string }
 */
exports.generateCSRReport = onCall(async (request) => {
  // Verify the caller is a coordinator or admin
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const db = getFirestore();
  const userDoc = await db.collection("users").doc(request.auth.uid).get();

  if (!userDoc.exists) {
    throw new HttpsError("permission-denied", "User profile not found.");
  }

  const userRole = userDoc.data().role;
  if (userRole !== "coordinator" && userRole !== "admin") {
    throw new HttpsError("permission-denied", "Only coordinators and admins can generate reports.");
  }

  const { dateFrom, dateTo, zone, centre } = request.data;

  if (!dateFrom || !dateTo) {
    throw new HttpsError("invalid-argument", "dateFrom and dateTo are required.");
  }

  // ─── Query Attendance Data ──────────────────────────────────────

  let query = db.collection("attendance")
    .where("date", ">=", dateFrom)
    .where("date", "<=", dateTo);

  if (zone) {
    query = query.where("zone", "==", zone);
  }
  if (centre) {
    query = query.where("centre", "==", centre);
  }

  const attendanceSnap = await query.get();
  const records = attendanceSnap.docs.map((doc) => doc.data());

  // ─── Compute Aggregates ─────────────────────────────────────────

  const totalRecords = records.length;
  const presentCount = records.filter((r) => r.status === "present").length;
  const absentCount = records.filter((r) => r.status === "absent").length;
  const attendanceRate = totalRecords > 0 ?
    Math.round((presentCount / totalRecords) * 100) :
    0;

  // Group by centre
  const centreStats = {};
  records.forEach((r) => {
    if (!centreStats[r.centre]) {
      centreStats[r.centre] = { total: 0, present: 0 };
    }
    centreStats[r.centre].total++;
    if (r.status === "present") {
      centreStats[r.centre].present++;
    }
  });

  // Group by date for trends
  const dailyStats = {};
  records.forEach((r) => {
    if (!dailyStats[r.date]) {
      dailyStats[r.date] = { total: 0, present: 0 };
    }
    dailyStats[r.date].total++;
    if (r.status === "present") {
      dailyStats[r.date].present++;
    }
  });

  // ─── Get Student & Teacher Counts ───────────────────────────────

  let studentsQuery = db.collection("students");
  if (zone) studentsQuery = studentsQuery.where("zone", "==", zone);
  if (centre) studentsQuery = studentsQuery.where("centre", "==", centre);
  const studentsSnap = await studentsQuery.get();
  const totalStudents = studentsSnap.size;

  // ─── Generate PDF Report ────────────────────────────────────────

  const reportId = `csr_${Date.now()}`;
  const fileName = `reports/${reportId}.pdf`;

  const pdf = new PDFDocument({ margin: 50 });
  const chunks = [];

  pdf.on("data", (chunk) => chunks.push(chunk));

  // Title
  pdf.fontSize(24).font("Helvetica-Bold")
    .text("Seva Sahyog Foundation", { align: "center" });
  pdf.fontSize(16).font("Helvetica")
    .text("CSR Education Report", { align: "center" });
  pdf.moveDown();

  // Report Period
  pdf.fontSize(12).font("Helvetica-Bold")
    .text(`Report Period: ${dateFrom} to ${dateTo}`);
  if (zone) pdf.text(`Zone: ${zone}`);
  if (centre) pdf.text(`Centre: ${centre}`);
  pdf.moveDown();

  // Summary Stats
  pdf.fontSize(14).font("Helvetica-Bold").text("Summary");
  pdf.fontSize(11).font("Helvetica");
  pdf.text(`Total Students Enrolled: ${totalStudents}`);
  pdf.text(`Total Attendance Records: ${totalRecords}`);
  pdf.text(`Present: ${presentCount} | Absent: ${absentCount}`);
  pdf.text(`Overall Attendance Rate: ${attendanceRate}%`);
  pdf.moveDown();

  // Centre-wise Breakdown
  if (Object.keys(centreStats).length > 0) {
    pdf.fontSize(14).font("Helvetica-Bold").text("Centre-wise Performance");
    pdf.fontSize(11).font("Helvetica");
    Object.entries(centreStats).forEach(([centreName, stats]) => {
      const rate = Math.round((stats.present / stats.total) * 100);
      pdf.text(`  ${centreName}: ${rate}% attendance (${stats.present}/${stats.total})`);
    });
    pdf.moveDown();
  }

  // Daily Trend
  if (Object.keys(dailyStats).length > 0) {
    pdf.fontSize(14).font("Helvetica-Bold").text("Daily Attendance Trend");
    pdf.fontSize(11).font("Helvetica");
    const sortedDates = Object.keys(dailyStats).sort();
    sortedDates.forEach((date) => {
      const stats = dailyStats[date];
      const rate = Math.round((stats.present / stats.total) * 100);
      pdf.text(`  ${date}: ${rate}% (${stats.present}/${stats.total})`);
    });
    pdf.moveDown();
  }

  // Footer
  pdf.fontSize(9).font("Helvetica")
    .text(`Generated on: ${new Date().toISOString()}`, { align: "right" });
  pdf.text(`Report ID: ${reportId}`, { align: "right" });

  pdf.end();

  // Wait for PDF to finish
  const pdfBuffer = await new Promise((resolve) => {
    pdf.on("end", () => resolve(Buffer.concat(chunks)));
  });

  // ─── Upload to Cloud Storage ────────────────────────────────────

  const bucket = getStorage().bucket();
  const file = bucket.file(fileName);

  await file.save(pdfBuffer, {
    metadata: {
      contentType: "application/pdf",
      metadata: {
        reportId,
        dateFrom,
        dateTo,
        zone: zone || "all",
        centre: centre || "all",
        generatedBy: request.auth.uid,
      },
    },
  });

  // Generate a signed download URL (valid for 7 days)
  const [downloadUrl] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
  });

  console.log(`CSR Report generated: ${reportId}`);

  return {
    downloadUrl,
    reportId,
    summary: {
      totalStudents,
      totalRecords,
      presentCount,
      absentCount,
      attendanceRate,
    },
  };
});
