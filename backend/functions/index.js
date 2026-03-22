const { initializeApp } = require("firebase-admin/app");

// Initialize Firebase Admin SDK
initializeApp();

// ─── Import Cloud Functions ───────────────────────────────────────

// Auth / User profile triggers
const { onUserProfileCreated } = require("./src/auth/onCreate");

// Auth / User creation (callable)
const { createUser } = require("./src/auth/createUser");

// Attendance triggers
const { onAttendanceCreated } = require("./src/attendance/onWrite");

// Student creation trigger (Google Sheets sync)
const { onStudentCreated } = require("./src/students/onStudentCreated");

// CSR Report generation
const { generateCSRReport } = require("./src/reports/generateCSR");

// Aadhaar encryption utilities
const { encryptAadhaar, decryptAadhaar } = require("./src/students/encrypt");

// Google Sheets read functions (callable)
const { getStudentsFromSheet, getAttendanceFromSheet } = require("./src/sheets/sheetReaders");

// Exam results trigger (Google Sheets sync)
const { onExamResultCreated } = require("./src/exams/onExamCreated");

// Sync users from Google Sheet to Firebase Auth
const { syncUsersFromSheet } = require("./src/auth/syncFromSheet");

// Login validation against NGO User Directory Google Sheet
const { sheetLogin } = require("./src/auth/sheetLogin");

// Centre creation trigger (Google Sheets sync)
const { onCentreCreated } = require("./src/centres/onCentreCreated");

// ─── Export Cloud Functions ───────────────────────────────────────

exports.onUserProfileCreated = onUserProfileCreated;
exports.createUser = createUser;
exports.onAttendanceCreated = onAttendanceCreated;
exports.onStudentCreated = onStudentCreated;
exports.onCentreCreated = onCentreCreated;
exports.generateCSRReport = generateCSRReport;
exports.encryptAadhaar = encryptAadhaar;
exports.decryptAadhaar = decryptAadhaar;
exports.getStudentsFromSheet = getStudentsFromSheet;
exports.getAttendanceFromSheet = getAttendanceFromSheet;
exports.onExamResultCreated = onExamResultCreated;
exports.syncUsersFromSheet = syncUsersFromSheet;
exports.sheetLogin = sheetLogin;
