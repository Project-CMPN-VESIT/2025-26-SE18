const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

/**
 * Callable Cloud Function: createUser
 *
 * Creates a Firebase Auth user AND a matching Firestore profile document.
 * Called from the Flutter admin dashboard when adding teachers/coordinators.
 *
 * Expects: { email, password, name, role, phone?, zone?, centre? }
 * Returns: { uid }
 */
exports.createUser = onCall(async (request) => {
  const { email, password, name, role, phone, zone, centre } = request.data;

  // Validate required fields
  if (!email || !password || !name || !role) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields: email, password, name, role"
    );
  }

  // Validate role
  const validRoles = ["teacher", "coordinator", "admin"];
  if (!validRoles.includes(role)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid role '${role}'. Must be one of: ${validRoles.join(", ")}`
    );
  }

  const auth = getAuth();
  const db = getFirestore();

  // ─── Authorization Check ───────────────────────────────────────
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  try {
    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    const callerData = callerDoc.data();
    
    if (callerData?.role !== "admin") {
      throw new HttpsError(
        "permission-denied",
        "Only administrators can create new users."
      );
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Error verifying permissions.");
  }
  // ───────────────────────────────────────────────────────────────

  try {
    // 1. Create Firebase Auth user
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: name,
    });

    // 2. Build Firestore profile
    const profile = {
      email,
      name,
      role,
      status: "active",
      createdAt: new Date().toISOString(),
    };

    if (phone) profile.phone = phone;
    if (zone) profile.zone = zone;
    if (centre) profile.centre = centre;

    // Role-specific defaults
    if (role === "teacher") {
      profile.students = 0;
    } else if (role === "coordinator") {
      profile.centres = 0;
      profile.teachers = 0;
      profile.students = 0;
    }

    // 3. Write Firestore document (use Auth UID as document ID)
    await db.collection("users").doc(userRecord.uid).set(profile);

    // 4. Sync to Google Sheets "Users Directory" tab
    try {
      const { addUserRow } = require("../sheets/sheetsHelper");
      await addUserRow({ name, email, password, phone: phone || "", role, zone: zone || "", centre: centre || "" });
    } catch (sheetError) {
      console.error("Error syncing user to Google Sheets:", sheetError.message);
      // Don't fail the user creation if sheet sync fails
    }

    console.log(`Created user ${email} (${role}) with UID ${userRecord.uid}`);
    return { uid: userRecord.uid };
  } catch (error) {
    console.error("Error creating user:", error);
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "A user with this email already exists.");
    }
    throw new HttpsError("internal", error.message);
  }
});
