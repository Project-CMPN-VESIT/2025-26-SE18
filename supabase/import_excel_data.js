/**
 * ============================================================
 *  Seva Sahyog — Excel Attendance Import Script (v2)
 *  Handles the REAL NGO Excel format:
 *    - Sheet 1 (Register): rows = students, student info + monthly totals
 *    - Sheet 2+ (Monthly): rows = dates, columns = students (NMUT codes)
 *      Header row: col 3 = "Unique", col 4+ = NMUT codes
 *      Data rows: col 0=Sr, col 1=Month(Jun-25), col 2=Date, col 3=Day, col 4+=P/A/D
 * ============================================================
 *
 *  SETUP:
 *    1. cd supabase/
 *    2. npm install (already done)
 *    3. Run seed_zones_centres.sql in Supabase → copy the System Import UUID
 *    4. Paste UUID into SYSTEM_TEACHER_ID below
 *    5. Copy all 7 Excel files into: ../excel_data/
 *    6. node import_excel_data.js --dry-run   (preview — no DB writes)
 *    7. node import_excel_data.js             (live import)
 * ============================================================
 */

require('dotenv').config({ path: '.env' });
const XLSX = require('xlsx');
const { createClient } = require('@supabase/supabase-js');
const path = require('path');
const fs = require('fs');

// ─── PASTE THE UUID RETURNED BY seed_zones_centres.sql HERE ──
const SYSTEM_TEACHER_ID = '00000000-0000-0000-0000-000000000000';
// ─────────────────────────────────────────────────────────────

// ─── CONFIG: tweak only if your cells use different values ────
const CONFIG = {
  // Month text substrings to import (case-insensitive, checks col 1 of each data row)
  IMPORT_MONTH_TAGS: ['mar-26', 'apr-26'],  // "Mar-26" and "Apr-26" only

  // What Col index is "Unique" (NMUT codes) label in the header row?
  // We auto-detect it, but set a fallback here (0-indexed)
  UNIQUE_COL_LABEL_COL: 3,  // i.e. col D (0-indexed) typically holds "Unique" label

  // Cell value → Supabase attendance status
  STATUS_MAP: {
    'p': 'present',
    'present': 'present',
    'a': 'absent',
    'absent': 'absent',
    'd': 'dropout',
    'dr': 'dropout',
    'dropout': 'dropout',
    'l': 'late',
    'late': 'late',
  },

  // Register sheet column patterns (case-insensitive substring match)
  REG_COL: {
    roll:   ['code', 'nmut'],       // The NMUT code column header
    name:   ['name of student', 'student name', 'name'],
    class:  ['std', 'standard', 'class', 'grade'],
    gender: ['gender', 'sex'],
    phone:  ['number', 'phone', 'mobile', 'contact'],
  },
};

// ─── MAP: Excel filename → { zone, centre } ───────────────────
const FILE_MAP = {
  'Udan Secondary Abhyasika_2025':    { zone: 'Udan',      centre: 'Udan Secondary Abhyasika' },
  'Mirabai Primary Abhyasika_2025':   { zone: 'Mirabai',   centre: 'Mirabai Primary Abhyasika' },
  'VESIT student data':               { zone: 'VESIT',     centre: 'VESIT Centre' },
  'Tejaswini Primary Abhyasika_2025': { zone: 'Tejaswini', centre: 'Tejaswini Primary Abhyasika' },
  'Raigad Primary Abhyasika_2025':    { zone: 'Raigad',    centre: 'Raigad Primary Abhyasika' },
  'Shivneri Abhyasika_2025':          { zone: 'Shivneri',  centre: 'Shivneri Abhyasika' },
  'Utkarsh Combine Abhyasika_2025':   { zone: 'Utkarsh',   centre: 'Utkarsh Combine Abhyasika' },
};

// ─── Path to Excel files ──────────────────────────────────────
const EXCEL_DIR = path.join(__dirname, '..', 'excel_data');

// ─── Supabase client (SERVICE ROLE bypasses RLS) ─────────────
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_KEY,
  { auth: { persistSession: false } }
);

const DRY_RUN = process.argv.includes('--dry-run');
const TEACHER_ID = SYSTEM_TEACHER_ID === 'PASTE-YOUR-SYSTEM-UUID-HERE' ? null : SYSTEM_TEACHER_ID;

if (TEACHER_ID === null) {
  console.warn('\n⚠️  WARNING: SYSTEM_TEACHER_ID is not set — teacher_id will be NULL.');
  console.warn('   Run seed_zones_centres.sql and paste the returned UUID.\n');
}

// ─── HELPERS ──────────────────────────────────────────────────

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

function colMatch(header, patterns) {
  const h = String(header ?? '').toLowerCase().trim();
  return patterns.some(p => h.includes(p.toLowerCase()));
}

function mapStatus(val) {
  if (val == null || val === '') return null;
  return CONFIG.STATUS_MAP[String(val).toLowerCase().trim()] ?? null;
}

/** Convert Excel date serial to ISO string YYYY-MM-DD */
function excelSerialToISO(serial) {
  if (typeof serial === 'number' && serial > 0) {
    // Excel epoch is Dec 30, 1899
    const msPerDay = 86400000;
    const excelEpoch = new Date(1899, 11, 30).getTime();
    const d = new Date(excelEpoch + serial * msPerDay);
    return d.toISOString().split('T')[0];
  }
  if (serial instanceof Date) {
    return serial.toISOString().split('T')[0];
  }
  return null;
}

/** Parse "Mar-26" / "Apr-26" / "Jun-25" → { month: 3, year: 2026 } etc */
function parseMonthTag(tag) {
  const t = String(tag ?? '').toLowerCase().trim();
  const parts = t.split('-');
  if (parts.length !== 2) return null;
  const monthNames = { jan:1,feb:2,mar:3,apr:4,may:5,jun:6,jul:7,aug:8,sep:9,oct:10,nov:11,dec:12 };
  const month = monthNames[parts[0].substring(0, 3)];
  const year = parseInt('20' + parts[1], 10);
  if (!month || isNaN(year)) return null;
  return { month, year };
}

function isTargetMonth(monthTag) {
  const tag = String(monthTag ?? '').toLowerCase().trim();
  return CONFIG.IMPORT_MONTH_TAGS.some(t => tag.includes(t.toLowerCase()));
}

// ─── READ STUDENT INFO FROM REGISTER SHEET ───────────────────
function extractStudentsFromRegister(sheet, zone, centre) {
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });
  if (rows.length < 2) return {};

  // Find the header row: look for a row that has "code" or "name of student"
  let headerIdx = -1;
  for (let i = 0; i < Math.min(6, rows.length); i++) {
    const rowStr = rows[i].join(' ').toLowerCase();
    if (rowStr.includes('name of student') || rowStr.includes('student name') || (rowStr.includes('code') && rowStr.includes('name'))) {
      headerIdx = i;
      break;
    }
  }
  if (headerIdx === -1) {
    console.log('     ⚠️  Register header not found — will rely on attendance sheet for student names/codes.');
    return {};
  }

  const headers = rows[headerIdx];
  let rollCol = -1, nameCol = -1, classCol = -1, phoneCol = -1;
  headers.forEach((h, idx) => {
    if (rollCol  === -1 && colMatch(h, CONFIG.REG_COL.roll))   rollCol  = idx;
    if (nameCol  === -1 && colMatch(h, CONFIG.REG_COL.name))   nameCol  = idx;
    if (classCol === -1 && colMatch(h, CONFIG.REG_COL.class))  classCol = idx;
    if (phoneCol === -1 && colMatch(h, CONFIG.REG_COL.phone))  phoneCol = idx;
  });

  if (rollCol === -1 || nameCol === -1) {
    console.log(`     ⚠️  Could not find Roll/Name cols in register. Headers: ${headers.slice(0, 10).join(' | ')}`);
    return {};
  }

  const studentMap = {}; // nmutCode → { name, class, phone }
  for (let i = headerIdx + 1; i < rows.length; i++) {
    const row = rows[i];
    const code = String(row[rollCol] ?? '').trim().toUpperCase();
    const name = String(row[nameCol] ?? '').trim();
    if (!code || !name || code.toLowerCase() === 'code') continue;

    studentMap[code] = {
      name,
      class: classCol >= 0 ? String(row[classCol] ?? '').trim() : '',
      phone: phoneCol >= 0 ? String(row[phoneCol] ?? '').trim() : '',
    };
  }
  console.log(`     ✅ Register: found ${Object.keys(studentMap).length} student entries`);
  return studentMap;
}

// ─── PARSE THE TRANSPOSED ATTENDANCE SHEET ───────────────────
function extractAttendanceData(sheet) {
  // Use raw 2D array; cellDates: true so Excel dates come back as Date objects
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '', raw: false });
  if (rows.length < 3) return null;

  // Find the row that contains "Unique" somewhere in the first few columns
  let uniqueRowIdx = -1;
  for (let i = 0; i < Math.min(20, rows.length); i++) { // Increased scan range
    for (let c = 0; c < Math.min(10, rows[i].length); c++) {
      const cellVal = String(rows[i][c]).toLowerCase().trim();
      if (cellVal.includes('unique')) { // Changed to includes
        uniqueRowIdx = i;
        break;
      }
    }
    if (uniqueRowIdx !== -1) break;
  }

  if (uniqueRowIdx === -1) return null; // Not the attendance sheet

  // Student names are in the row ABOVE the Unique row
  const nameRowIdx = uniqueRowIdx - 1;

  // Find the column offset where NMUT codes start
  let uniqueLabelCol = 3; 
  for (let c = 0; c < Math.min(10, rows[uniqueRowIdx].length); c++) {
    if (String(rows[uniqueRowIdx][c]).toLowerCase().trim().includes('unique')) {
      uniqueLabelCol = c;
      break;
    }
  }
  const studentStartCol = uniqueLabelCol + 1;

  // Build student list from the unique row
  // [{ col, nmutCode, name }]
  const students = [];
  for (let c = studentStartCol; c < rows[uniqueRowIdx].length; c++) {
    const code = String(rows[uniqueRowIdx][c] ?? '').trim().toUpperCase();
    const name = nameRowIdx >= 0 ? String(rows[nameRowIdx][c] ?? '').trim() : '';
    if (!code || code === '') continue;
    students.push({ col: c, nmutCode: code, name });
  }

  if (students.length === 0) return null;

  // Find data start row (first row after uniqueRowIdx that has a Month value)
  const dataStartRow = uniqueRowIdx + 1;

  // Find which column holds Month and Date
  // These are typically col 1 and col 2 (0-indexed) in the data rows
  // Detect by scanning the first data row's content
  let monthCol = 1, dateCol = 2;
  // Quick heuristic: scan first data row for a cell matching "xxx-xx" pattern (month tag)
  for (let c = 0; c < Math.min(6, (rows[dataStartRow] || []).length); c++) {
    const val = String(rows[dataStartRow][c] ?? '').trim();
    if (/^[a-z]{3}-\d{2}$/i.test(val)) { monthCol = c; break; }
  }
  // Date col is likely monthCol + 1
  dateCol = monthCol + 1;

  console.log(`     Attendance sheet: uniqueRow=${uniqueRowIdx}, nameRow=${nameRowIdx}, studentStartCol=${studentStartCol}`);
  console.log(`     Students found: ${students.length} | monthCol=${monthCol}, dateCol=${dateCol}`);
  if (students.length > 0) {
    console.log(`     Sample NMUTs: ${students.slice(0, 5).map(s => s.nmutCode).join(', ')}`);
  }

  // Collect date rows for Mar-26 and Apr-26
  /** Array of { isoDate, studentAttendance: [{ nmutCode, status }] } */
  const dateRecords = [];

  for (let r = dataStartRow; r < rows.length; r++) {
    const row = rows[r];
    const monthTag = String(row[monthCol] ?? '').trim();
    if (!isTargetMonth(monthTag)) continue;

    // Parse date
    const rawDate = row[dateCol];
    let isoDate = null;

    // Try numeric Excel serial first
    const numericDate = parseFloat(String(rawDate).replace(',', '.'));
    if (!isNaN(numericDate) && numericDate > 40000) {
      isoDate = excelSerialToISO(numericDate);
    }

    // Try constructing from monthTag + day-of-week column
    if (!isoDate) {
      // We know it's Mar or Apr 2026; try to get from the Date column as a string
      const dateStr = String(rawDate ?? '').trim();
      if (dateStr.match(/^\d{4}-\d{2}-\d{2}$/)) {
        isoDate = dateStr;
      }
    }

    // Fallback: derive from monthTag + Sr. number (not ideal but safe)
    if (!isoDate) {
      const parsed = parseMonthTag(monthTag);
      if (parsed) {
        const srVal = parseInt(String(row[0] ?? ''), 10);
        if (!isNaN(srVal) && srVal >= 1 && srVal <= 31) {
          const year = parsed.year;
          const month = String(parsed.month).padStart(2, '0');
          const day = String(srVal).padStart(2, '0');
          isoDate = `${year}-${month}-${day}`;
        }
      }
    }

    if (!isoDate) {
      console.log(`     ⚠️  Row ${r}: Could not parse date. monthTag="${monthTag}", dateCell="${rawDate}" — skipping`);
      continue;
    }

    const studentAttendance = [];
    for (const student of students) {
      const cellVal = row[student.col];
      const status = mapStatus(cellVal);
      if (status) {
        studentAttendance.push({ nmutCode: student.nmutCode, status });
      }
    }
    if (studentAttendance.length > 0) {
      dateRecords.push({ isoDate, studentAttendance });
    }
  }

  console.log(`     ✅ Attendance rows for Mar+Apr: ${dateRecords.length}`);
  return { students, dateRecords };
}

// ─── UPSERT STUDENT ───────────────────────────────────────────
async function upsertStudent(nmutCode, name, classVal, zone, centre) {
  if (DRY_RUN) return `DRY-${nmutCode}`;

  const { data: existing } = await supabase
    .from('students')
    .select('id')
    .eq('roll', nmutCode)
    .maybeSingle();

  if (existing) return existing.id;

  const { data: inserted, error } = await supabase
    .from('students')
    .insert({
      name: name || nmutCode,
      roll: nmutCode,
      class: classVal || '',
      centre,
      zone,
      teacher_id: TEACHER_ID,
      status: 'active',
    })
    .select('id')
    .single();

  if (error) throw new Error(`Insert student "${name}" (${nmutCode}): ${error.message}`);
  return inserted.id;
}

// ─── UPSERT ATTENDANCE ────────────────────────────────────────
async function upsertAttendance(studentId, isoDate, status) {
  if (DRY_RUN) return;
  const { error } = await supabase
    .from('attendance')
    .upsert(
      { student_id: studentId, teacher_id: TEACHER_ID, date: isoDate, status },
      { onConflict: 'student_id,date' }
    );
  if (error) throw new Error(`Attendance ${studentId} on ${isoDate}: ${error.message}`);
}

// ─── UPDATE STUDENT ATTENDANCE COUNTERS ──────────────────────
async function updateStudentCounters() {
  if (DRY_RUN) { console.log('   (Student counters update skipped in dry-run)'); return; }
  console.log('\n🔢  Recomputing student attendance counters from attendance table...');

  // Get all students in our 7 centres
  const { data: students } = await supabase
    .from('students')
    .select('id');

  let updated = 0;
  for (const s of (students ?? [])) {
    const { data: att } = await supabase
      .from('attendance')
      .select('status')
      .eq('student_id', s.id);

    if (!att || att.length === 0) continue;

    const presentCount = att.filter(a => a.status === 'present').length;
    const absentCount  = att.filter(a => a.status === 'absent').length;
    const dropoutCount = att.filter(a => a.status === 'dropout').length;
    const totalClasses = att.length;

    // Compute consecutive absences (streak at the end)
    let consecutive = 0;
    for (let i = att.length - 1; i >= 0; i--) {
      if (att[i].status === 'absent' || att[i].status === 'dropout') consecutive++;
      else break;
    }

    await supabase.from('students').update({
      present_count: presentCount,
      absent_count: absentCount + dropoutCount,
      total_classes: totalClasses,
      consecutive_absences: consecutive,
    }).eq('id', s.id);

    updated++;
    if (updated % 50 === 0) await sleep(100); // rate limit
  }
  console.log(`   ✅ Updated counters for ${updated} students.`);
}

// ─── UPDATE ZONE & CENTRE COUNTS ─────────────────────────────
async function updateZoneCentreCounts() {
  if (DRY_RUN) return;
  console.log('\n🏛️  Updating zone & centre student counts...');
  const { data: zones } = await supabase.from('zones').select('id, name');
  for (const z of (zones ?? [])) {
    const { count } = await supabase.from('students').select('*', { count: 'exact', head: true }).eq('zone', z.name);
    await supabase.from('zones').update({ students: count ?? 0 }).eq('id', z.id);
  }
  const { data: centres } = await supabase.from('centres').select('id, name, zone');
  for (const c of (centres ?? [])) {
    const { count } = await supabase.from('students').select('*', { count: 'exact', head: true }).eq('centre', c.name).eq('zone', c.zone);
    await supabase.from('centres').update({ students: count ?? 0 }).eq('id', c.id);
  }
  console.log('   ✅ Zone & centre counts updated.');
}

// ─── MAIN IMPORT FUNCTION ─────────────────────────────────────
async function importFile(filePath, zone, centre) {
  console.log(`\n📂  Processing: ${path.basename(filePath)}`);
  console.log(`    Zone: ${zone}  |  Centre: ${centre}`);

  const workbook = XLSX.readFile(filePath, { cellDates: false, raw: true });
  let newStudents = 0, attendanceRecords = 0;

  // Build a map of nmutCode → student info from the register sheet
  let registerMap = {};
  for (const sheetName of workbook.SheetNames) {
    const sheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '', raw: false });
    const rowsText = rows.slice(0, 5).map(r => r.join(' ')).join(' ').toLowerCase();

    // Register sheet: has "name of student" and "code" in header area
    if (rowsText.includes('name of student') || (rowsText.includes('code') && rowsText.includes('name'))) {
      console.log(`  📋 Register sheet: "${sheetName}"`);
      registerMap = extractStudentsFromRegister(sheet, zone, centre);
      break;
    }
  }

  // Build in-memory studentId cache: nmutCode → supabase UUID
  const studentIdCache = {};

  // Pre-upsert all students found in register
  for (const [nmutCode, info] of Object.entries(registerMap)) {
    try {
      const sid = await upsertStudent(nmutCode, info.name, info.class, zone, centre);
      studentIdCache[nmutCode] = sid;
      if (!DRY_RUN) newStudents++;
    } catch (e) {
      console.error(`     ❌ Student error: ${e.message}`);
    }
  }

  // Now process attendance sheets
  for (const sheetName of workbook.SheetNames) {
    const sheet = workbook.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });
    const rowsText = rows.slice(0, 3).map(r => r.join(' ')).join(' ').toLowerCase();

    // Skip the register sheet (no "unique" row)
    if (!rowsText.includes('unique')) continue;

    console.log(`  📋 Attendance sheet: "${sheetName}"`);
    const result = extractAttendanceData(sheet);
    if (!result) {
      console.log(`     ⚠️  Could not parse attendance structure — skipping this sheet.`);
      continue;
    }

    const { students, dateRecords } = result;

    // Upsert any students not already in our cache (from register)
    for (const s of students) {
      if (!studentIdCache[s.nmutCode]) {
        const info = registerMap[s.nmutCode];
        try {
          const sid = await upsertStudent(
            s.nmutCode,
            info?.name || s.name || s.nmutCode,
            info?.class || '',
            zone, centre
          );
          studentIdCache[s.nmutCode] = sid;
          newStudents++;
        } catch (e) {
          console.error(`     ❌ Student error for ${s.nmutCode}: ${e.message}`);
        }
      }
    }

    // Insert attendance records
    let inserted = 0;
    for (const { isoDate, studentAttendance } of dateRecords) {
      for (const { nmutCode, status } of studentAttendance) {
        const studentId = studentIdCache[nmutCode];
        if (!studentId) continue;

        if (!DRY_RUN) {
          try {
            await upsertAttendance(studentId, isoDate, status);
            inserted++;
            attendanceRecords++;
            if (inserted % 100 === 0) await sleep(150); // rate limit Supabase
          } catch (e) {
            console.error(`     ❌ Attendance error (${nmutCode} on ${isoDate}): ${e.message}`);
          }
        } else {
          inserted++;
          attendanceRecords++;
          if (inserted <= 3) {
            console.log(`     🔍 DRY: ${nmutCode} → ${status} on ${isoDate}`);
          }
        }
      }
    }
    console.log(`     Inserted ${inserted} attendance records for this sheet.`);
  }

  console.log(`  ✅ File done: ${newStudents} new students, ${attendanceRecords} attendance records`);
  return { newStudents, attendanceRecords };
}

// ─── ENTRY POINT ─────────────────────────────────────────────
async function main() {
  console.log('\n═══════════════════════════════════════════════════');
  console.log('  Seva Sahyog — Excel Attendance Importer v2');
  console.log(DRY_RUN ? '  MODE: 🔍 DRY RUN (no DB writes)' : '  MODE: 🚀 LIVE IMPORT');
  console.log('═══════════════════════════════════════════════════\n');

  if (!fs.existsSync(EXCEL_DIR)) {
    console.error(`❌  Excel folder not found: ${EXCEL_DIR}`);
    console.error('   Place your 7 Excel files in: excel_data/');
    process.exit(1);
  }

  const files = fs.readdirSync(EXCEL_DIR).filter(f =>
    f.endsWith('.xlsx') || f.endsWith('.xls') || f.endsWith('.xlsm')
  );

  if (files.length === 0) {
    console.error(`❌  No Excel files in: ${EXCEL_DIR}`);
    process.exit(1);
  }

  let grandStudents = 0, grandAttendance = 0;

  for (const file of files) {
    const key = Object.keys(FILE_MAP).find(k => file.includes(k));
    if (!key) {
      console.warn(`⚠️  Skipping "${file}" — no match in FILE_MAP. Add it to the script.\n`);
      continue;
    }
    try {
      const { zone, centre } = FILE_MAP[key];
      const result = await importFile(path.join(EXCEL_DIR, file), zone, centre);
      grandStudents  += result.newStudents;
      grandAttendance += result.attendanceRecords;
    } catch (err) {
      console.error(`💥  Fatal error processing "${file}":`, err.message);
    }
  }

  await updateStudentCounters();
  await updateZoneCentreCounts();

  console.log('\n═══════════════════════════════════════════════════');
  console.log('  ✅ Import Complete!');
  console.log(`  Total new students : ${grandStudents}`);
  console.log(`  Total attendance   : ${grandAttendance} records`);
  console.log(DRY_RUN ? '  (Dry-run: nothing written to Supabase)' : '  All data in Supabase!');
  console.log('═══════════════════════════════════════════════════\n');
}

main().catch(err => {
  console.error('\n💥 Fatal:', err);
  process.exit(1);
});
