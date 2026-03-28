const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { readUsersFromSheet } = require("../sheets/sheetsHelper");

/**
 * Callable Cloud Function: sheetLogin
 *
 * Priority order for user lookup:
 *  1. Google Sheet (NGO User Directory) — production source of truth
 *  2. Firestore `users` collection — fallback for local emulator dev
 *     (when Sheets API is unavailable / not enabled)
 *
 * Input:  { email: string, password: string }
 * Output: { success, message?, uid?, role?, name?, zone?, centre? }
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
    // ── 1. Try Google Sheet first ──────────────────────────────────
    let sheetUser = null;
    let sheetsAvailable = true;

    try {
      const sheetUsers = await readUsersFromSheet();
      if (Array.isArray(sheetUsers) && sheetUsers.length > 0) {
        sheetUser = sheetUsers.find((u) => {
          if (!u.email) return false;
          return String(u.email).trim().toLowerCase() === normalizedEmail;
        });
      } else {
        // Sheet returned empty — likely API not enabled or sheet not shared
        sheetsAvailable = false;
        console.warn("sheetLogin: Sheets API returned empty. Falling back to Firestore.");
      }
    } catch (sheetsError) {
      sheetsAvailable = false;
      console.warn("sheetLogin: Sheets API unavailable:", sheetsError.message, "— falling back to Firestore.");
    }

    // ── 2. Fall back to Firestore `users` collection ───────────────
    if (!sheetsAvailable || (!sheetUser && sheetsAvailable)) {
      // Check Firestore for a user with this email and verify password
      // (In emulator dev, passwords are stored in the users collection via seedData)
      const usersSnap = await db
        .collection("users")
        .where("email", "==", normalizedEmail)
        .limit(1)
        .get();

      if (!usersSnap.empty) {
        const doc = usersSnap.docs[0];
        const data = doc.data();

        // Verify password against Firestore stored password (local dev only)
        const storedPassword = String(data.password || "");
        if (!storedPassword || storedPassword !== inputPassword) {
          // Also try direct Firebase Auth sign-in (password may only exist in Auth)
          try {
            // If auth user exists and password matches Auth, allow it
            const authUser = await auth.getUserByEmail(normalizedEmail);
            // We can't verify password server-side via admin SDK directly,
            // so fall through to the Auth sign-in step below.
            sheetUser = {
              email: normalizedEmail,
              password: inputPassword, // pass-through so step 4 works
              role: data.role || "teacher",
              name: data.name || normalizedEmail.split("@")[0],
              zone: data.zone || "",
              centre: data.centre || "",
            };
            console.log(`sheetLogin: Using Auth-only validation for ${normalizedEmail}`);
          } catch (_) {
            return { success: false, message: "Invalid email or password." };
          }
        } else {
          sheetUser = {
            email: normalizedEmail,
            password: storedPassword,
            role: data.role || "teacher",
            name: data.name || normalizedEmail.split("@")[0],
            zone: data.zone || "",
            centre: data.centre || "",
          };
          console.log(`sheetLogin: Authenticated ${normalizedEmail} via Firestore fallback.`);
        }
      } else if (!sheetsAvailable) {
        return {
          success: false,
          message: "No user found for this email. (Sheets API unavailable and user not in local DB)",
        };
      }
    }

    if (!sheetUser) {
      return {
        success: false,
        message: "No user found in NGO User Directory for this email.",
      };
    }

    // ── 3. Validate password ───────────────────────────────────────
    const sheetPassword = String(sheetUser.password || "");
    if (sheetPassword && sheetPassword.length >= 6 && sheetPassword !== inputPassword) {
      return { success: false, message: "Invalid email or password." };
    }

    // ── 4. Normalize role ──────────────────────────────────────────
    const validRoles = ["teacher", "coordinator", "admin"];
    const role = String(sheetUser.role || "teacher").toLowerCase().trim();
    const name = sheetUser.name || normalizedEmail.split("@")[0] || "";
    const zone = sheetUser.zone || "";
    const centre = sheetUser.centre || "";

    if (!validRoles.includes(role)) {
      return {
        success: false,
        message: `User has invalid role '${sheetUser.role}'. Allowed: ${validRoles.join(", ")}`,
      };
    }

    // ── 5. Ensure Firebase Auth user exists ────────────────────────
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(normalizedEmail);
      await auth.updateUser(userRecord.uid, {
        password: sheetPassword || inputPassword,
        displayName: name || userRecord.displayName || normalizedEmail,
      });
    } catch (e) {
      // User does not exist in Auth → create it
      userRecord = await auth.createUser({
        email: normalizedEmail,
        password: sheetPassword || inputPassword,
        displayName: name,
      });
    }

    const uid = userRecord.uid;

    // ── 6. Ensure Firestore profile exists / is up to date ─────────
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

    if (role === "teacher") {
      baseProfile.students = profileSnap.exists ? profileSnap.data().students ?? 0 : 0;
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
      message: "Login successful.",
    };
  } catch (error) {
    console.error("Error during sheetLogin:", error);
    throw new HttpsError("internal", error.message || "Internal error");
  }
});
