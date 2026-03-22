const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { readUsersFromSheet } = require("../sheets/sheetsHelper");

/**
 * Callable Cloud Function: sheetLogin
 *
 * Purpose:
 * - Treat the NGO User Directory Google Sheet as the source of truth
 *   for who is allowed to access the app.
 * - On login:
 *   1. Validate email/password against the Users Directory sheet.
 *   2. Ensure a matching Firebase Auth user exists (and password matches).
 *   3. Ensure a matching Firestore profile exists in "users" collection.
 *
 * Input:  { email: string, password: string }
 * Output: {
 *   success: boolean,
 *   message?: string,
 *   uid?: string,
 *   role?: string,
 *   name?: string,
 *   zone?: string,
 *   centre?: string
 * }
 */
exports.sheetLogin = onCall(async (request) => {
  const { email, password } = request.data || {};

  if (!email || !password) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: email, password"
    );
  }

  const normalizedEmail = String(email).trim().toLowerCase();
  const inputPassword = String(password);

  const auth = getAuth();
  const db = getFirestore();

  try {
    // 1. Load all users from the NGO User Directory sheet
    const sheetUsers = await readUsersFromSheet();

    if (!Array.isArray(sheetUsers) || sheetUsers.length === 0) {
      return {
        success: false,
        message: "No users defined in NGO User Directory sheet.",
      };
    }

    // 2. Find matching user by email (case-insensitive)
    const sheetUser = sheetUsers.find((u) => {
      if (!u.email) return false;
      return String(u.email).trim().toLowerCase() === normalizedEmail;
    });

    if (!sheetUser) {
      return {
        success: false,
        message: "No user found in NGO User Directory for this email.",
      };
    }

    // 3. Validate password against sheet
    const sheetPassword = String(sheetUser.password || "");
    if (!sheetPassword || sheetPassword.length < 6) {
      return {
        success: false,
        message:
          "User in NGO User Directory has an invalid or empty password. Please contact admin.",
      };
    }

    if (sheetPassword !== inputPassword) {
      return {
        success: false,
        message: "Invalid email or password.",
      };
    }

    // 4. Normalize role and basic fields
    const validRoles = ["teacher", "coordinator", "admin"];
    const role = String(sheetUser.role || "teacher").toLowerCase().trim();
    const name = sheetUser.name || normalizedEmail.split("@")[0] || "";
    const zone = sheetUser.zone || "";
    const centre = sheetUser.centre || "";

    if (!validRoles.includes(role)) {
      return {
        success: false,
        message: `User has invalid role '${sheetUser.role}'. Allowed: ${validRoles.join(
          ", "
        )}`,
      };
    }

    // 5. Ensure Firebase Auth user exists and password matches sheet
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(normalizedEmail);

      // Optional: keep Auth password in sync with sheet password.
      // This ensures the client can always sign in with the sheet password.
      await auth.updateUser(userRecord.uid, {
        password: sheetPassword,
        displayName: name || userRecord.displayName || normalizedEmail,
      });
    } catch (e) {
      // User does not exist in Auth -> create it
      userRecord = await auth.createUser({
        email: normalizedEmail,
        password: sheetPassword,
        displayName: name,
      });
    }

    const uid = userRecord.uid;

    // 6. Ensure Firestore profile exists / up to date in "users" collection
    const profileRef = db.collection("users").doc(uid);
    const profileSnap = await profileRef.get();

    const baseProfile = {
      email: normalizedEmail,
      name,
      role,
      status: "active",
    };

    if (zone) baseProfile.zone = zone;
    if (centre) baseProfile.centre = centre;

    // Role-specific defaults
    if (role === "teacher") {
      baseProfile.students = profileSnap.exists
        ? profileSnap.data().students ?? 0
        : 0;
    } else if (role === "coordinator") {
      const existing = profileSnap.exists ? profileSnap.data() : {};
      baseProfile.centres = existing.centres ?? 0;
      baseProfile.teachers = existing.teachers ?? 0;
      baseProfile.students = existing.students ?? 0;
    }

    if (profileSnap.exists) {
      await profileRef.update(baseProfile);
    } else {
      baseProfile.createdAt = new Date().toISOString();
      await profileRef.set(baseProfile);
    }

    return {
      success: true,
      uid,
      role,
      name,
      zone,
      centre,
      message: "Login allowed via NGO User Directory.",
    };
  } catch (error) {
    console.error("Error during sheetLogin:", error);
    throw new HttpsError("internal", error.message || "Internal error");
  }
});

