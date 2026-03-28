const { google } = require("googleapis");
const path = require("path");
const fs = require("fs");
const { getFirestore } = require("firebase-admin/firestore");

// ─── Configuration ───────────────────────────────────────────────
const SCOPES = ["https://www.googleapis.com/auth/spreadsheets"];

// ─── Auth ────────────────────────────────────────────────────────

let _sheetsClient = null;

async function getSheetsClient() {
  if (_sheetsClient) return _sheetsClient;

  const keyPath = path.join(__dirname, "..", "..", "service-account.json");
  if (!fs.existsSync(keyPath)) {
    throw new Error(`Service account file not found at: ${keyPath}. Please ensure it exists in backend/functions/`);
  }

  const auth = new google.auth.GoogleAuth({
    keyFile: keyPath,
    scopes: SCOPES,
  });

  _sheetsClient = google.sheets({ version: "v4", auth });
  return _sheetsClient;
}

/**
 * Look up the Spreadsheet ID for a zone from Firestore.
 */
async function getSpreadsheetId(zone) {
  const db = getFirestore();
  const cleanZone = zone.trim();
  const zoneSnap = await db.collection("zones").where("name", "==", cleanZone).get();
  
  if (zoneSnap.empty) {
    throw new Error(`Spreadsheet ID not found for zone: ${cleanZone}`);
  }
  
  const data = zoneSnap.docs[0].data();
  if (!data.spreadsheetId) {
    throw new Error(`Spreadsheet ID is missing in Firestore for zone: ${cleanZone}`);
  }
  
  return data.spreadsheetId;
}

// ─── Tab Helpers ─────────────────────────────────────────────────

/**
 * Get the tab name for a centre. Format: "Centre Name"
 * (Reduced from "Zone - Centre" since each zone has its own file now)
 */
function getTabName(zone, centre) {
  return centre;
}

/**
 * Get all existing sheet/tab names in the spreadsheet.
 */
async function getExistingTabs(spreadsheetId) {
  const sheets = await getSheetsClient();
  const res = await sheets.spreadsheets.get({ spreadsheetId });
  return res.data.sheets.map((s) => s.properties.title);
}

/**
 * Create a new tab if it doesn't exist. Sets up header row.
 */
async function ensureTab(spreadsheetId, zone, centre) {
  const tabName = getTabName(zone, centre);
  const existingTabs = await getExistingTabs(spreadsheetId);

  if (!existingTabs.includes(tabName)) {
    const sheets = await getSheetsClient();
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [{
          addSheet: {
            properties: { title: tabName },
          },
        }],
      },
    });

    // Set header row
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `'${tabName}'!A1:C1`,
      valueInputOption: "RAW",
      requestBody: {
        values: [["Student Name", "Roll Number", "Centre"]],
      },
    });

    console.log(`Created new sheet tab: ${tabName} in spreadsheet ${spreadsheetId}`);
    
    // Ensure Overview tab exists and lists this centre
    await ensureOverviewTab(spreadsheetId, centre);
  }

  return tabName;
}

// ─── Zonal Overview Management ──────────────────────────────────

const OVERVIEW_TAB = "Zonal Overview";

/**
 * Ensure the Overview tab exists in the zonal spreadsheet.
 */
async function ensureOverviewTab(spreadsheetId, newCentre) {
  const existingTabs = await getExistingTabs(spreadsheetId);
  const sheets = await getSheetsClient();

  if (!existingTabs.includes(OVERVIEW_TAB)) {
    // Create tab
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [{ addSheet: { properties: { title: OVERVIEW_TAB, index: 0 } } }],
      },
    });
    // Set headers
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `'${OVERVIEW_TAB}'!A1:D1`,
      valueInputOption: "RAW",
      requestBody: {
        values: [["Centre Name", "Total Students", "Present Today", "Overall Attendance %"]],
      },
    });
  }

  if (newCentre) {
    // Add centre to Overview if not present
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range: `'${OVERVIEW_TAB}'!A:A`,
    });
    const rows = res.data.values || [];
    const exists = rows.some(r => r[0] === newCentre);
    
    if (!exists) {
      await sheets.spreadsheets.values.append({
        spreadsheetId,
        range: `'${OVERVIEW_TAB}'!A:A`,
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS",
        requestBody: {
          values: [[newCentre, 0, 0, "0%"]],
        },
      });
    }
  }
}

/**
 * Update the overview stats for a specific centre in the zonal sheet.
 */
async function updateZonalOverview(zone, centre, date) {
  try {
    const spreadsheetId = await getSpreadsheetId(zone);
    await ensureOverviewTab(spreadsheetId, centre);
    
    const tabName = getTabName(zone, centre);
    const tabData = await getTabData(spreadsheetId, tabName);
    if (tabData.length <= 1) return;

    // 1. Calculate stats
    const totalStudents = tabData.length - 1;
    const headerRow = tabData[0];
    const dateColIndex = headerRow.indexOf(date);
    
    let presentToday = 0;
    let totalPresenceRecords = 0;
    let totalMarkedRecords = 0;

    for (let i = 1; i < tabData.length; i++) {
        const row = tabData[i];
        // Present Today
        if (dateColIndex !== -1 && row[dateColIndex] === "P") {
            presentToday++;
        }
        // Overall Attendance
        const attendanceCells = row.slice(3);
        for (const status of attendanceCells) {
            if (status === "P") {
                totalPresenceRecords++;
                totalMarkedRecords++;
            } else if (status === "A" || status === "D") {
                totalMarkedRecords++;
            }
        }
    }

    const overallPercentage = totalMarkedRecords > 0 ? 
        Math.round((totalPresenceRecords / totalMarkedRecords) * 100) : 0;

    // 2. Write to Overview tab
    const sheets = await getSheetsClient();
    const overviewRes = await sheets.spreadsheets.values.get({
        spreadsheetId,
        range: `'${OVERVIEW_TAB}'!A:A`,
    });
    const overviewRows = overviewRes.data.values || [];
    let rowIndex = -1;
    for (let i = 0; i < overviewRows.length; i++) {
        if (overviewRows[i][0] === centre) {
            rowIndex = i + 1;
            break;
        }
    }

    if (rowIndex !== -1) {
        await sheets.spreadsheets.values.update({
            spreadsheetId,
            range: `'${OVERVIEW_TAB}'!B${rowIndex}:D${rowIndex}`,
            valueInputOption: "RAW",
            requestBody: {
                values: [[totalStudents, presentToday, `${overallPercentage}%`]],
            },
        });
    }

    // 3. Update Zone attendance in Firestore
    const db = getFirestore();
    const zoneSnap = await db.collection("zones").where("name", "==", zone).get();
    if (!zoneSnap.empty) {
        const zoneDoc = zoneSnap.docs[0];
        // Calculate average across all centres in this zone from the Overview tab
        const latestOverview = await sheets.spreadsheets.values.get({
            spreadsheetId,
            range: `'${OVERVIEW_TAB}'!A:D`,
        });
        const rows = latestOverview.data.values || [];
        let totalS = 0;
        let totalP = 0;
        for (let i = 1; i < rows.length; i++) {
            totalS += parseInt(rows[i][1]) || 0;
            totalP += parseInt(rows[i][2]) || 0;
        }
        const zonePercentage = totalS > 0 ? Math.round((totalP / totalS) * 100) : 0;
        await zoneDoc.ref.update({
            attendance: `${zonePercentage}%`,
            updatedAt: new Date().toISOString()
        });
    }

    // 4. Update Centre attendance in Firestore
    const centreSnap = await db.collection("centres").where("name", "==", centre).where("zone", "==", zone).get();
    if (!centreSnap.empty) {
        await centreSnap.docs[0].ref.update({
            attendance: `${overallPercentage}%`,
            updatedAt: new Date().toISOString()
        });
    }

    console.log(`Updated Zonal Overview and Firestore for ${centre} in zone ${zone}`);
  } catch (e) {
    console.error("Error updating Zonal Overview:", e.message);
  }
}

// ─── Student Row Management ──────────────────────────────────────

/**
 * Get all values from a tab.
 */
async function getTabData(spreadsheetId, tabName) {
  const sheets = await getSheetsClient();
  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range: `'${tabName}'`,
    });
    return res.data.values || [];
  } catch (e) {
    return [];
  }
}

/**
 * Find a student's row index in the tab (0-indexed). Returns -1 if not found.
 */
function findStudentRow(tabData, studentName, roll) {
  for (let i = 1; i < tabData.length; i++) {
    if (tabData[i][0] === studentName || tabData[i][1] === roll) {
      return i;
    }
  }
  return -1;
}

/**
 * Add a student row to the sheet tab (when a new student is added).
 */
async function addStudentRow(zone, centre, studentName, roll) {
  const spreadsheetId = await getSpreadsheetId(zone);
  const tabName = await ensureTab(spreadsheetId, zone, centre);
  const tabData = await getTabData(spreadsheetId, tabName);

  // Check if already exists
  if (findStudentRow(tabData, studentName, roll) !== -1) {
    console.log(`Student ${studentName} already exists in ${tabName}`);
    return;
  }

  const sheets = await getSheetsClient();

  // New row: [name, roll, centre, then dashes for any existing date columns]
  const headerRow = tabData[0] || ["Student Name", "Roll Number", "Centre"];
  const numDateCols = Math.max(0, headerRow.length - 3);
  const dashes = Array(numDateCols).fill("-");
  const newRow = [studentName, roll, centre, ...dashes];

  await sheets.spreadsheets.values.append({
    spreadsheetId,
    range: `'${tabName}'!A:A`,
    valueInputOption: "RAW",
    insertDataOption: "INSERT_ROWS",
    requestBody: {
      values: [newRow],
    },
  });

  console.log(`Added student ${studentName} to sheet tab ${tabName}`);
  
  // Update overview stats
  await updateZonalOverview(zone, centre, new Date().toISOString().split("T")[0]);
}

// ─── Attendance Sync ─────────────────────────────────────────────

/**
 * Find or create a date column. Returns the column index (0-indexed).
 */
async function ensureDateColumn(spreadsheetId, tabName, date) {
  const tabData = await getTabData(spreadsheetId, tabName);
  const headerRow = tabData[0] || [];

  // Check if date column already exists (columns after index 2)
  const dateColIndex = headerRow.indexOf(date);
  if (dateColIndex !== -1) {
    return { colIndex: dateColIndex, tabData };
  }

  // Add new date column
  const newColIndex = headerRow.length;
  const sheets = await getSheetsClient();

  // Write date header
  const colLetter = columnToLetter(newColIndex);
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `'${tabName}'!${colLetter}1`,
    valueInputOption: "RAW",
    requestBody: {
      values: [[date]],
    },
  });

  // Fill all existing student rows with "-" (unmarked/holiday default)
  if (tabData.length > 1) {
    const dashes = tabData.slice(1).map(() => ["-"]);
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `'${tabName}'!${colLetter}2:${colLetter}${tabData.length}`,
      valueInputOption: "RAW",
      requestBody: {
        values: dashes,
      },
    });
  }

  console.log(`Added date column ${date} at column ${colLetter} in ${tabName}`);

  // Re-fetch data after adding column
  const updatedData = await getTabData(spreadsheetId, tabName);
  return { colIndex: newColIndex, tabData: updatedData };
}

/**
 * Sync a single attendance record to Google Sheets.
 *
 * @param {object} record - { studentName, roll, date, status, centre, zone, startTime, endTime }
 */
async function syncAttendance(record) {
  const { studentName, date, status, centre, zone } = record;
  const roll = record.roll || record.studentId || "";

  const spreadsheetId = await getSpreadsheetId(zone);

  // 1. Ensure the tab exists
  const tabName = await ensureTab(spreadsheetId, zone, centre);

  // 2. Ensure the date column exists (fills "-" for all students by default)
  const { colIndex, tabData } = await ensureDateColumn(spreadsheetId, tabName, date);

  // 3. Find the student row
  let studentRow = findStudentRow(tabData, studentName, roll);

  // If student not found, add them
  if (studentRow === -1) {
    await addStudentRow(zone, centre, studentName, roll);
    const updatedData = await getTabData(spreadsheetId, tabName);
    studentRow = findStudentRow(updatedData, studentName, roll);
  }

  if (studentRow === -1) {
    console.error(`Could not find or create row for student ${studentName}`);
    return;
  }

  // 4. Map status to single letter
  const statusLetter = status === "present" ? "P"
    : status === "absent" ? "A"
    : status === "dropout" ? "D"
    : "-";

  // 5. Write the status to the cell
  const sheets = await getSheetsClient();
  const colLetter = columnToLetter(colIndex);
  const cellRange = `'${tabName}'!${colLetter}${studentRow + 1}`;

  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: cellRange,
    valueInputOption: "RAW",
    requestBody: {
      values: [[statusLetter]],
    },
  });

  console.log(`Synced attendance: ${studentName} → ${statusLetter} on ${date} in ${tabName} (${zone})`);
  
  // 6. Update Zonal Overview
  await updateZonalOverview(zone, centre, date);
}

// ─── Utility ─────────────────────────────────────────────────────

/**
 * Convert 0-indexed column number to letter(s). 0→A, 1→B, 25→Z, 26→AA
 */
function columnToLetter(col) {
  let letter = "";
  let temp = col;
  while (temp >= 0) {
    letter = String.fromCharCode((temp % 26) + 65) + letter;
    temp = Math.floor(temp / 26) - 1;
  }
  return letter;
}

// ─── Users Directory (SEPARATE SHEET — admin only) ───────────────

const USERS_SPREADSHEET_ID = "1TcZQQlB4Q0i7YbbNn9nDxnlapdz7YJDNnxj7IMNbB28";
const USERS_TAB = "User_Credentials_Log";

/**
 * Ensure the Users Directory sheet has headers on the first row.
 */
async function ensureUsersTab() {
  const sheets = await getSheetsClient();
  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: USERS_SPREADSHEET_ID,
      range: `'${USERS_TAB}'!A1:H1`,
    });
    const row = res.data.values?.[0];
    if (!row || row[0] !== "Name") {
      await sheets.spreadsheets.values.update({
        spreadsheetId: USERS_SPREADSHEET_ID,
        range: `'${USERS_TAB}'!A1:H1`,
        valueInputOption: "RAW",
        requestBody: {
          values: [["Name", "Email", "Password", "Phone", "Role", "Zone", "Centre", "Created At"]],
        },
      });
      console.log("Set up Users Directory headers");
    }
  } catch (e) {
    console.error("Error setting up Users Directory:", e.message);
  }
  return USERS_TAB;
}

/**
 * Add a user row to the separate Users Directory sheet.
 */
async function addUserRow({ name, email, password, phone, role, zone, centre }) {
  await ensureUsersTab();
  const sheets = await getSheetsClient();

  // Check if user already exists by email
  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: USERS_SPREADSHEET_ID,
      range: `'${USERS_TAB}'`,
    });
    const rows = res.data.values || [];
    for (let i = 1; i < rows.length; i++) {
      if (rows[i] && rows[i][1] === email) {
        console.log(`User ${email} already exists in Users Directory`);
        return;
      }
    }
  } catch (e) {
    // If sheet is empty, continue to add
  }

  const now = new Date().toISOString().split("T")[0];
  await sheets.spreadsheets.values.append({
    spreadsheetId: USERS_SPREADSHEET_ID,
    range: `'${USERS_TAB}'!A:A`,
    valueInputOption: "RAW",
    insertDataOption: "INSERT_ROWS",
    requestBody: {
      values: [[name || "", email || "", password || "", phone || "", role || "", zone || "", centre || "", now]],
    },
  });

  console.log(`Added user ${email} (${role}) to Users Directory`);
}

/**
 * Read all users from the Users Directory sheet.
 * Returns array of { name, email, password, phone, role, zone, centre }.
 */
async function readUsersFromSheet() {
  await ensureUsersTab();
  let sheets;
  try {
    sheets = await getSheetsClient();
  } catch (e) {
    throw new Error(`Google Sheets Auth failed: ${e.message}. (Did you add service-account.json?)`);
  }

  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: USERS_SPREADSHEET_ID,
      range: `'${USERS_TAB}'`,
    });
    const rows = res.data.values || [];
    if (rows.length <= 1) return [];

    return rows.slice(1).filter((r) => r[1]).map((r) => ({
      name: r[0] || "",
      email: r[1] || "",
      password: r[2] || "",
      phone: r[3] || "",
      role: r[4] || "teacher",
      zone: r[5] || "",
      centre: r[6] || "",
      createdAt: r[7] || "",
    }));
  } catch (e) {
    if (e.code === 404 || e.message.includes("not found")) {
      throw new Error(`Spreadsheet not found (ID: ${USERS_SPREADSHEET_ID}).`);
    }
    if (e.code === 403) {
      throw new Error(`Permission denied for spreadsheet (ID: ${USERS_SPREADSHEET_ID}).`);
    }
    throw new Error(`Error reading Users Directory: ${e.message}`);
  }
}

// ─── Read Functions (fetch FROM Google Sheets) ───────────────────

/**
 * Read all students from all zone-centre tabs.
 * Returns array of { name, roll, centre, zone }
 */
async function readStudentsFromSheet(filterZone, filterCentre) {
  const allStudents = [];
  
  // If a specific zone is filtered, only read that zone's spreadsheet
  const zonesToRead = (filterZone && filterZone !== "All") ? [filterZone] : await getZoneNames();

  // Fetch all zone data in parallel
  const zonePromises = zonesToRead.map(async (zone) => {
    try {
      const spreadsheetId = await getSpreadsheetId(zone);
      const tabs = await getExistingTabs(spreadsheetId);
      const sheets = await getSheetsClient();

      // Fetch all tabs in this zone in parallel
      const tabPromises = tabs.map(async (tab) => {
        if (tab === OVERVIEW_TAB) return [];

        const centre = tab.trim();
        if (filterCentre && filterCentre !== "All" && centre !== filterCentre) return [];

        try {
          const res = await sheets.spreadsheets.values.get({
            spreadsheetId,
            range: `'${tab}'`,
          });
          const rows = res.data.values || [];
          if (rows.length <= 1) return [];

          const students = [];
          for (let i = 1; i < rows.length; i++) {
            const row = rows[i];
            if (!row[0]) continue;

            const attendanceCells = row.slice(3);
            let presentCount = 0;
            let totalMarked = 0;

            for (const status of attendanceCells) {
              if (status === "P") {
                presentCount++;
                totalMarked++;
              } else if (status === "A" || status === "D") {
                totalMarked++;
              }
            }

            const percentage = totalMarked > 0 ? Math.round((presentCount / totalMarked) * 100) : 0;
            const absentCount = totalMarked - presentCount;

            students.push({
              name: row[0] || "",
              roll: row[1] || "",
              centre: row[2] || centre,
              zone,
              status: "active",
              class: "",
              attendance: totalMarked > 0 ? `${percentage}%` : "0%",
              presentCount: presentCount,
              absentCount: absentCount,
              totalClasses: totalMarked,
            });
          }
          return students;
        } catch (tabErr) {
          console.error(`Error reading tab ${tab} in zone ${zone}:`, tabErr.message);
          return [];
        }
      });

      const tabResults = await Promise.all(tabPromises);
      return tabResults.flat();
    } catch (e) {
      console.error(`Error reading spreadsheet for zone ${zone}:`, e.message);
      return [];
    }
  });

  const zoneResults = await Promise.all(zonePromises);
  return zoneResults.flat();
}

/**
 * Get all available zone names from Firestore.
 */
async function getZoneNames() {
    const db = getFirestore();
    const snap = await db.collection("zones").get();
    return snap.docs.map(doc => doc.data().name);
}

/**
 * Read attendance data from a specific zone-centre tab.
 * Returns { headers: [...dates], students: [{ name, roll, centre, attendance: { date: status } }] }
 */
async function readAttendanceFromSheet(zone, centre) {
  try {
    const spreadsheetId = await getSpreadsheetId(zone);
    const tabName = getTabName(zone, centre);
    const sheets = await getSheetsClient();

    const res = await sheets.spreadsheets.values.get({
      spreadsheetId,
      range: `'${tabName}'`,
    });
    const rows = res.data.values || [];
    if (rows.length === 0) return { headers: [], students: [] };

    const headerRow = rows[0];
    const dateHeaders = headerRow.slice(3);

    const students = [];
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      if (!row[0]) continue;

      const attendance = {};
      for (let j = 0; j < dateHeaders.length; j++) {
        attendance[dateHeaders[j]] = row[j + 3] || "-";
      }

      students.push({
        name: row[0] || "",
        roll: row[1] || "",
        centre: row[2] || centre,
        zone,
        attendance,
      });
    }

    return { headers: dateHeaders, students };
  } catch (e) {
    console.error(`Error reading attendance from ${zone} - ${centre}:`, e.message);
    return { headers: [], students: [] };
  }
}

// ─── Exam Results Sheet Sync ─────────────────────────────────────

const EXAM_SPREADSHEET_ID = "1J9tqankIVnQ-de0Jik4voxwnpGsHxwpF1zOM37MSrHo";

/**
 * Ensure exam tab exists (same Zone - Centre format as attendance).
 */
async function ensureExamTab(zone) {
  const tabName = zone;
  const sheets = await getSheetsClient();

  // Check existing tabs in exam sheet
  let existingTabs = [];
  try {
    const res = await sheets.spreadsheets.get({ spreadsheetId: EXAM_SPREADSHEET_ID });
    existingTabs = res.data.sheets.map((s) => s.properties.title);
  } catch (e) {
    console.error("Error getting exam spreadsheet:", e.message);
    return tabName;
  }

  if (!existingTabs.includes(tabName)) {
    await sheets.spreadsheets.batchUpdate({
      spreadsheetId: EXAM_SPREADSHEET_ID,
      requestBody: {
        requests: [{ addSheet: { properties: { title: tabName } } }],
      },
    });

    // Set header row: Student Name, Roll Number, Centre
    await sheets.spreadsheets.values.update({
      spreadsheetId: EXAM_SPREADSHEET_ID,
      range: `'${tabName}'!A1:C1`,
      valueInputOption: "RAW",
      requestBody: {
        values: [["Student Name", "Roll Number", "Centre"]],
      },
    });

    console.log(`Created exam tab: ${tabName}`);
  }

  return tabName;
}

/**
 * Sync exam result to Google Sheet.
 * Adds date+topic as column header, student marks in rows.
 *
 * @param {object} data - { zone, centre, date, topic, marks: [{ name, roll, marks }] }
 */
async function syncExamResult(data) {
  const { zone, centre, date, topic, marks } = data;
  const tabName = await ensureExamTab(zone);
  const sheets = await getSheetsClient();

  // 1. Get current tab data
  let tabData = [];
  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: EXAM_SPREADSHEET_ID,
      range: `'${tabName}'`,
    });
    tabData = res.data.values || [];
  } catch (e) {
    tabData = [["Student Name", "Roll Number", "Centre"]];
  }

  const headerRow = tabData[0] || ["Student Name", "Roll Number", "Centre"];

  // 2. Create column header: "date (topic)"
  const colHeader = `${date} (${topic})`;
  let colIndex = headerRow.indexOf(colHeader);

  if (colIndex === -1) {
    // Add new column
    colIndex = headerRow.length;
    headerRow.push(colHeader);
    const colLetter = columnToLetter(colIndex);
    await sheets.spreadsheets.values.update({
      spreadsheetId: EXAM_SPREADSHEET_ID,
      range: `'${tabName}'!${colLetter}1`,
      valueInputOption: "RAW",
      requestBody: { values: [[colHeader]] },
    });
    console.log(`Added exam column: ${colHeader} at ${colLetter}`);
  }

  // 3. For each student, find or create row, set marks
  for (const student of marks) {
    const { name, roll, marks: studentMarks } = student;

    // Find student row
    let rowIndex = -1;
    for (let i = 1; i < tabData.length; i++) {
      if (tabData[i] && (tabData[i][0] === name || tabData[i][1] === roll)) {
        rowIndex = i;
        break;
      }
    }

    if (rowIndex === -1) {
      // Add new student row
      rowIndex = tabData.length;
      const newRow = [name, roll, centre];
      // Pad with empty values up to the column
      while (newRow.length < colIndex) newRow.push("");
      newRow.push(String(studentMarks));
      tabData.push(newRow);

      await sheets.spreadsheets.values.append({
        spreadsheetId: EXAM_SPREADSHEET_ID,
        range: `'${tabName}'!A:A`,
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS",
        requestBody: { values: [newRow] },
      });
    } else {
      // Update existing student row at the exam date column
      const colLetter = columnToLetter(colIndex);
      const sheetRow = rowIndex + 1; // 1-indexed
      await sheets.spreadsheets.values.update({
        spreadsheetId: EXAM_SPREADSHEET_ID,
        range: `'${tabName}'!${colLetter}${sheetRow}`,
        valueInputOption: "RAW",
        requestBody: { values: [[String(studentMarks)]] },
      });
    }
  }

  console.log(`Synced exam results for ${date} (${topic}) in ${tabName}`);
}

module.exports = {
  syncAttendance,
  addStudentRow,
  addUserRow,
  ensureTab,
  ensureUsersTab,
  getTabName,
  getExistingTabs,
  readStudentsFromSheet,
  readAttendanceFromSheet,
  readUsersFromSheet,
  syncExamResult,
  ensureExamTab,
  getSheetsClient,
  getSpreadsheetId,
  getZoneNames,
  EXAM_SPREADSHEET_ID,
};
