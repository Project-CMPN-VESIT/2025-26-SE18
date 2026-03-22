const { onCall } = require("firebase-functions/v2/https");
const { readStudentsFromSheet, readAttendanceFromSheet } = require("../sheets/sheetsHelper");

/**
 * Callable: getStudentsFromSheet
 * Reads student data from Google Sheets instead of Firestore.
 * Input: { zone?, centre? }
 * Returns: { students: [{ name, roll, centre, zone, status }] }
 */
exports.getStudentsFromSheet = onCall(async (request) => {
  const { zone, centre } = request.data || {};

  try {
    const students = await readStudentsFromSheet(zone || null, centre || null);
    return { students };
  } catch (error) {
    console.error("Error fetching students from sheet:", error);
    return { students: [], error: error.message };
  }
});

/**
 * Callable: getAttendanceFromSheet
 * Reads attendance data from a specific zone-centre tab.
 * Input: { zone, centre }
 * Returns: { headers: [dates], students: [{ name, roll, centre, zone, attendance: { date: status } }] }
 */
exports.getAttendanceFromSheet = onCall(async (request) => {
  const { zone, centre } = request.data || {};

  if (!zone || !centre) {
    return { headers: [], students: [], error: "zone and centre are required" };
  }

  try {
    const result = await readAttendanceFromSheet(zone, centre);
    return result;
  } catch (error) {
    console.error("Error fetching attendance from sheet:", error);
    return { headers: [], students: [], error: error.message };
  }
});
