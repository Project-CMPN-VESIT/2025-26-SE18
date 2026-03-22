const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { readUsersFromSheet } = require("../sheets/sheetsHelper");

/**
 * Callable Cloud Function: syncUsersFromSheet
 *
 * Reads users from the NGO User Directory Google Sheet and creates
 * Firebase Auth accounts + Firestore profiles for any new users.
 * Existing users (by email) are skipped.
 *
 * Returns: { created: number, skipped: number, errors: string[] }
 */
exports.syncUsersFromSheet = onCall(async (request) => {
  const auth = getAuth();
  const db = getFirestore();
  const validRoles = ["teacher", "coordinator", "admin"];

  let created = 0;
  let skipped = 0;
  const errors = [];
  const results = [];

  try {
    // 1. Read all users from the Sheet
    const sheetUsers = await readUsersFromSheet();
    console.log(`Found ${sheetUsers.length} users in the User Directory sheet`);

    if (sheetUsers.length === 0) {
      return { created: 0, skipped: 0, errors: [], message: "No users found in sheet" };
    }

    // 2. Process each user
    for (const user of sheetUsers) {
      const { name, email, password, phone, role, zone, centre } = user;

      // Validate required fields
      if (!email || !name) {
        errors.push(`Row skipped: missing name or email`);
        skipped++;
        continue;
      }

      if (!password || password.length < 6) {
        errors.push(`${email}: password must be at least 6 characters`);
        skipped++;
        continue;
      }

      const normalizedRole = (role || "teacher").toLowerCase().trim();
      if (!validRoles.includes(normalizedRole)) {
        errors.push(`${email}: invalid role '${role}'`);
        skipped++;
        continue;
      }

      // Check if user already exists in Firebase Auth
      try {
        await auth.getUserByEmail(email);
        // User exists — skip
        skipped++;
        results.push({ email, status: "exists" });
        continue;
      } catch (e) {
        // User doesn't exist — create
      }

      try {
        // Create Firebase Auth user
        const userRecord = await auth.createUser({
          email,
          password,
          displayName: name,
        });

        // Build Firestore profile
        const profile = {
          email,
          name,
          role: normalizedRole,
          status: "active",
          createdAt: new Date().toISOString(),
        };

        if (phone) profile.phone = phone;
        if (zone) profile.zone = zone;
        if (centre) profile.centre = centre;

        // Role-specific defaults
        if (normalizedRole === "teacher") {
          profile.students = 0;
        } else if (normalizedRole === "coordinator") {
          profile.centres = 0;
          profile.teachers = 0;
          profile.students = 0;
        }

        // Write Firestore document
        await db.collection("users").doc(userRecord.uid).set(profile);

        created++;
        results.push({ email, role: normalizedRole, status: "created", uid: userRecord.uid });
        console.log(`Created user: ${email} (${normalizedRole}) → ${userRecord.uid}`);
      } catch (createErr) {
        errors.push(`${email}: ${createErr.message}`);
        skipped++;
      }
    }

    const message = `Sync complete: ${created} created, ${skipped} skipped`;
    console.log(message);
    return { created, skipped, errors, results, message };
  } catch (error) {
    console.error("Error syncing users from sheet:", error);
    if (error.response) {
      console.error("Google API Response Error:", error.response.data);
    }
    console.error("Stack trace:", error.stack);
    throw new HttpsError("internal", `Sync failed: ${error.message}. Check backend logs.`);
  }
});
