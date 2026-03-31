/**
 * Seva-Sahyog — Historical Data Migration Script
 * Migrates data FROM Google Sheets → Supabase
 *
 * What this migrates:
 *   1. Users (from User_Credentials_Log sheet → Supabase Auth + profiles)
 *   2. Students (from all zone-centre tabs → students table)
 *   3. Attendance (from attendance columns in each tab → attendance table)
 *   4. Exam Results (from Exam sheet → exam_results table)
 *
 * Spreadsheet IDs (from your sheetsHelper.js):
 *   - Users Directory:  1TcZQQlB4Q0i7YbbNn9nDxnlapdz7YJDNnxj7IMNbB28
 *   - Thane zone:       1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo
 *   - Boisar/NK zone:   1_sYFgpeCgOicL_F2NDjYZFvrgQoUa3fkQvVHuRoFBEU
 *   - Exam results:     1J9tqankIVnQ-de0Jik4voxwnpGsHxwpF1zOM37MSrHo
 *
 * Prerequisites:
 *   1. Run `npm install` in this directory
 *   2. Have a valid service-account.json in backend/functions/ with Sheets API access
 *   3. Set environment variables:
 *      $env:SUPABASE_URL      = "https://wplubsyhbvjmzvtrdgov.supabase.co"
 *      $env:SUPABASE_SERVICE_KEY = "YOUR_SERVICE_ROLE_KEY"
 *
 * Usage:
 *   # Migrate everything:
 *   node supabase/migrate_from_sheets.js
 *
 *   # Dry run (read from sheets, don't write to Supabase):
 *   node supabase/migrate_from_sheets.js --dry-run
 *
 *   # Migrate only specific parts:
 *   node supabase/migrate_from_sheets.js --only=users
 *   node supabase/migrate_from_sheets.js --only=students
 *   node supabase/migrate_from_sheets.js --only=attendance
 *   node supabase/migrate_from_sheets.js --only=exams
 */

require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");
const { google } = require("googleapis");
const path = require("path");
const fs = require("fs");

// ─── Config ──────────────────────────────────────────────────

const SUPABASE_URL = process.env.SUPABASE_URL || "https://wplubsyhbvjmzvtrdgov.supabase.co";
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

const DRY_RUN = process.argv.includes("--dry-run");
const ONLY = (process.argv.find((a) => a.startsWith("--only=")) || "").replace("--only=", "") || null;

// Known spreadsheet IDs from your project
const SPREADSHEET_IDS = {
  "Thane":     "1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo",
  "Boisar":    "1_sYFgpeCgOicL_F2NDjYZFvrgQoUa3fkQvVHuRoFBEU",
  "New Karjat":"1_sYFgpeCgOicL_F2NDjYZFvrgQoUa3fkQvVHuRoFBEU", // shared with Boisar
};
const USERS_SPREADSHEET_ID = "1TcZQQlB4Q0i7YbbNn9nDxnlapdz7YJDNnxj7IMNbB28";
const EXAM_SPREADSHEET_ID  = "1J9tqankIVnQ-de0Jik4voxwnpGsHxwpF1zOM37MSrHo";
const OVERVIEW_TAB = "Zonal Overview";

if (!SUPABASE_SERVICE_KEY) {
  console.error("❌ Missing SUPABASE_SERVICE_KEY environment variable.");
  console.error("   Set it with: $env:SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY'");
  process.exit(1);
}

// ─── Clients ─────────────────────────────────────────────────

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

let _sheetsClient = null;
async function getSheetsClient() {
  if (_sheetsClient) return _sheetsClient;
  const keyPath = path.join(__dirname, "..", "backend", "functions", "service-account.json");
  if (!fs.existsSync(keyPath)) {
    throw new Error(`service-account.json not found at: ${keyPath}`);
  }
  const auth = new google.auth.GoogleAuth({
    keyFile: keyPath,
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });
  _sheetsClient = google.sheets({ version: "v4", auth });
  return _sheetsClient;
}

// ─── Helpers ─────────────────────────────────────────────────

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

async function getTabNames(spreadsheetId) {
  const sheets = await getSheetsClient();
  try {
    const res = await sheets.spreadsheets.get({ spreadsheetId });
    return res.data.sheets.map((s) => s.properties.title);
  } catch (e) {
    console.error("  Error getting tabs:", e.message);
    return [];
  }
}

function mapStatusLetter(letter) {
  switch ((letter || "").toUpperCase()) {
    case "P": return "present";
    case "A": return "absent";
    case "D": return "dropout";
    default:  return null; // "-" or empty = no record
  }
}

async function upsert(table, data, onConflict = null) {
  if (DRY_RUN) {
    console.log(`  [DRY RUN] Would upsert ${data.length} rows into '${table}'`);
    return { error: null };
  }
  const opts = onConflict ? { onConflict } : {};
  const { error } = await supabase.from(table).upsert(data, opts);
  return { error };
}

// ─── Phase 1: Migrate Users ───────────────────────────────────

async function migrateUsers() {
  console.log("\n═══ Phase 1: Migrating Users from Sheets ═══");
  try {
    const rows = await getTabData(USERS_SPREADSHEET_ID, "User_Credentials_Log");
    if (rows.length <= 1) {
      console.log("  ⚠ No user data found in sheet (empty or header only)");
      return {};
    }

    // Headers: Name, Email, Password, Phone, Role, Zone, Centre, Created At
    const users = rows.slice(1).filter((r) => r[1]); // must have email
    console.log(`  Found ${users.length} users in sheet`);

    const uidMap = {}; // email → supabase uid

    for (const r of users) {
      const email    = (r[1] || "").trim().toLowerCase();
      const password = (r[2] || "teacher123").trim();
      const name     = (r[0] || email.split("@")[0]).trim();
      const phone    = (r[3] || "").trim();
      const role     = ((r[4] || "teacher").trim().toLowerCase()) in {"admin":1,"coordinator":1,"teacher":1}
                         ? r[4].trim().toLowerCase() : "teacher";
      const zone     = (r[5] || "").trim();
      const centre   = (r[6] || "").trim();

      try {
        // Try creating Supabase Auth user
        const { data: authData, error: authErr } = await (DRY_RUN
          ? Promise.resolve({ data: { user: { id: `dry-${email}` } }, error: null })
          : supabase.auth.admin.createUser({
              email,
              password,
              email_confirm: true,
              user_metadata: { name, role },
            }));

        let uid = authData?.user?.id;

        if (authErr) {
          if (authErr.message?.includes("already been registered") || authErr.message?.includes("already exists")) {
            // Look up existing user
            const { data: list } = await supabase.auth.admin.listUsers({ perPage: 1000 });
            const found = list?.users?.find((u) => u.email === email);
            uid = found?.id;
            console.log(`  ↺ Existing user: ${email} (uid: ${uid?.slice(0,8)}...)`);
          } else {
            console.error(`  ✗ Auth error for ${email}:`, authErr.message);
            continue;
          }
        } else {
          console.log(`  ✓ Created auth user: ${email} (${role})`);
        }

        if (!uid) { console.warn(`  ⚠ No UID for ${email}, skipping profile`); continue; }
        uidMap[email] = uid;

        // Upsert profile
        if (!DRY_RUN) {
          await supabase.from("profiles").upsert({
            id: uid, email, name, role, zone, centre, phone, status: "active",
          });
        }
      } catch (e) {
        console.error(`  ✗ Error processing ${email}:`, e.message);
      }
    }

    console.log(`  ✅ Users migration done. ${Object.keys(uidMap).length} users processed.`);
    return uidMap;
  } catch (e) {
    console.error("  ✗ Users migration failed:", e.message);
    return {};
  }
}

// ─── Phase 2: Migrate Students + Attendance ───────────────────

async function migrateStudentsAndAttendance(uidMap) {
  console.log("\n═══ Phase 2: Migrating Students + Attendance from Zone Sheets ═══");

  let totalStudents = 0;
  let totalAttendance = 0;

  for (const [zone, spreadsheetId] of Object.entries(SPREADSHEET_IDS)) {
    console.log(`\n  ── Zone: ${zone} (${spreadsheetId}) ──`);
    const tabs = await getTabNames(spreadsheetId);
    const centreTabs = tabs.filter((t) => t !== OVERVIEW_TAB);
    console.log(`    Tabs found: ${centreTabs.join(", ") || "(none)"}`);

    for (const centre of centreTabs) {
      console.log(`    Processing centre: ${centre}`);
      const rows = await getTabData(spreadsheetId, centre);
      if (rows.length <= 1) {
        console.log(`      ⚠ No data in tab '${centre}'`);
        continue;
      }

      const headerRow = rows[0]; // [Student Name, Roll Number, Centre, date1, date2, ...]
      const dateHeaders = headerRow.slice(3); // columns after index 2 are dates

      const studentsToInsert = [];
      const attendanceToInsert = [];

      for (let i = 1; i < rows.length; i++) {
        const row = rows[i];
        if (!row[0]) continue; // skip empty rows

        const studentName = (row[0] || "").trim();
        const roll        = (row[1] || "").trim() || null;
        const centreCell  = (row[2] || centre).trim();

        // Calculate attendance totals from columns
        let presentCount = 0;
        let absentCount  = 0;
        let totalClasses = 0;
        let consecutiveAbsences = 0;
        let tempConsecutive = 0;

        const attendanceRows = [];
        for (let j = 0; j < dateHeaders.length; j++) {
          const dateStr = (dateHeaders[j] || "").trim();
          const letter  = (row[j + 3] || "").trim();
          const status  = mapStatusLetter(letter);
          if (!status || !dateStr || dateStr === "-") continue;

          totalClasses++;
          if (status === "present") {
            presentCount++;
            tempConsecutive = 0;
          } else {
            absentCount++;
            tempConsecutive++;
            consecutiveAbsences = Math.max(consecutiveAbsences, tempConsecutive);
          }

          attendanceRows.push({ dateStr, status });
        }

        // Insert student
        const studentRecord = {
          name:                 studentName,
          roll:                 roll,
          class:                "",
          centre:               centreCell,
          zone:                 zone,
          status:               "active",
          present_count:        presentCount,
          absent_count:         absentCount,
          total_classes:        totalClasses,
          consecutive_absences: consecutiveAbsences,
        };
        studentsToInsert.push(studentRecord);
        attendanceRows.forEach((ar) => {
          attendanceToInsert.push({ studentName, roll, zone, centre: centreCell, ...ar });
        });
      }

      // Upsert students in bulk
      if (studentsToInsert.length > 0) {
        const { error } = await upsert("students", studentsToInsert, "roll");
        if (error && !DRY_RUN) {
          console.error(`      ✗ Students upsert error:`, error.message);
          // Try one by one if roll conflict
          for (const s of studentsToInsert) {
            const { error: e2 } = await supabase.from("students").upsert(s, { onConflict: s.roll ? "roll" : undefined });
            if (e2) console.error(`        ✗ Student ${s.name}:`, e2.message);
          }
        }
        totalStudents += studentsToInsert.length;
        console.log(`      ✓ ${studentsToInsert.length} students`);
      }

      // Now resolve student UUIDs for attendance (re-fetch to get ids)
      if (attendanceToInsert.length > 0 && !DRY_RUN) {
        const { data: insertedStudents } = await supabase
          .from("students")
          .select("id, name, roll")
          .eq("zone", zone)
          .eq("centre", attendanceToInsert[0].centre);

        const studentIdMap = {};
        for (const s of (insertedStudents || [])) {
          if (s.roll)  studentIdMap[s.roll] = s.id;
          studentIdMap[s.name] = studentIdMap[s.name] || s.id;
        }

        const attendanceRecords = [];
        for (const ar of attendanceToInsert) {
          const sid = (ar.roll && studentIdMap[ar.roll]) || studentIdMap[ar.studentName];
          if (!sid) continue;

          // Parse date — handles YYYY-MM-DD and DD/MM/YYYY
          let dateValue = ar.dateStr;
          if (/^\d{1,2}\/\d{1,2}\/\d{4}$/.test(dateValue)) {
            const [d, m, y] = dateValue.split("/");
            dateValue = `${y}-${m.padStart(2,"0")}-${d.padStart(2,"0")}`;
          }

          attendanceRecords.push({
            student_id: sid,
            date:       dateValue,
            status:     ar.status,
          });
        }

        if (attendanceRecords.length > 0) {
          // Insert in chunks of 100
          for (let i = 0; i < attendanceRecords.length; i += 100) {
            const chunk = attendanceRecords.slice(i, i + 100);
            const { error } = await supabase.from("attendance").upsert(chunk, { onConflict: "student_id,date" });
            if (error) console.error(`      ✗ Attendance chunk error:`, error.message);
          }
          totalAttendance += attendanceRecords.length;
        }

        console.log(`      ✓ ${attendanceToInsert.length} attendance records`);
      } else if (DRY_RUN && attendanceToInsert.length > 0) {
        console.log(`      [DRY RUN] Would insert ${attendanceToInsert.length} attendance records`);
        totalAttendance += attendanceToInsert.length;
      }
    }
  }

  console.log(`\n  ✅ Students done: ${totalStudents} students, ${totalAttendance} attendance records`);
}

// ─── Phase 3: Migrate Exam Results ────────────────────────────

async function migrateExamResults() {
  console.log("\n═══ Phase 3: Migrating Exam Results ═══");

  const tabs = await getTabNames(EXAM_SPREADSHEET_ID);
  console.log(`  Exam tabs found: ${tabs.join(", ") || "(none)"}`);

  let total = 0;

  for (const zone of tabs) {
    console.log(`  Processing zone: ${zone}`);
    const rows = await getTabData(EXAM_SPREADSHEET_ID, zone);
    if (rows.length <= 1) { console.log("    ⚠ No data"); continue; }

    // Headers: Student Name, Roll Number, Centre, "date (topic)", "date2 (topic2)", ...
    const headerRow = rows[0];
    const examCols = headerRow.slice(3); // each is "YYYY-MM-DD (topic)"

    const results = [];
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      if (!row[0]) continue;

      const name   = (row[0] || "").trim();
      const roll   = (row[1] || "").trim();
      const centre = (row[2] || "").trim();

      for (let j = 0; j < examCols.length; j++) {
        const colHeader = examCols[j];
        const marksRaw  = row[j + 3];
        if (!marksRaw) continue;

        const marks = parseInt(marksRaw, 10);
        if (isNaN(marks)) continue;

        // Parse "2026-03-10 (Math)" → date and subject
        const match = colHeader.match(/^(.+?)\s*\((.+?)\)$/);
        const dateStr = match ? match[1].trim() : colHeader;
        const topic   = match ? match[2].trim() : "General";

        results.push({
          name,
          roll:       roll || null,
          zone,
          centre,
          math:       topic.toLowerCase().includes("math")    ? marks : null,
          science:    topic.toLowerCase().includes("science") ? marks : null,
          english:    topic.toLowerCase().includes("english") ? marks : null,
          total:      marks,
          grade:      marks >= 90 ? "A+" : marks >= 80 ? "A" : marks >= 70 ? "B" : marks >= 60 ? "C" : "D",
          created_at: new Date(dateStr).toISOString(),
        });
      }
    }

    if (results.length > 0) {
      const { error } = await upsert("exam_results", results);
      if (error && !DRY_RUN) console.error(`  ✗ Exam results error for ${zone}:`, error.message);
      total += results.length;
      console.log(`    ✓ ${results.length} exam records from ${zone}`);
    }
  }

  console.log(`  ✅ Exam results done: ${total} records`);
}

// ─── Main ─────────────────────────────────────────────────────

async function main() {
  console.log("╔══════════════════════════════════════════════════╗");
  console.log("║   Seva-Sahyog: Sheets → Supabase Migration       ║");
  console.log("╚══════════════════════════════════════════════════╝");
  console.log(`Target: ${SUPABASE_URL}`);
  if (DRY_RUN) console.log("🧪 DRY RUN MODE — no data will be written to Supabase");
  if (ONLY) console.log(`Only migrating: ${ONLY}`);
  console.log("");

  try {
    let uidMap = {};

    if (!ONLY || ONLY === "users") {
      uidMap = await migrateUsers();
    }

    if (!ONLY || ONLY === "students" || ONLY === "attendance") {
      await migrateStudentsAndAttendance(uidMap);
    }

    if (!ONLY || ONLY === "exams") {
      await migrateExamResults();
    }

    console.log("\n╔══════════════════════════════════════════════════╗");
    console.log("║   ✅ MIGRATION COMPLETE                           ║");
    console.log("╚══════════════════════════════════════════════════╝");
    console.log("\nNext steps:");
    console.log("  1. Check Supabase Dashboard → Table Editor to verify data");
    console.log("  2. Run the Flutter app and log in to test");
    console.log("  3. Enable Realtime on students, leaves, announcements tables");
  } catch (e) {
    console.error("\n✗ Migration failed:", e.message);
    process.exit(1);
  }
}

main();
