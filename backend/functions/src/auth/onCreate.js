const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");

/**
 * Auth trigger: When a new user document is created in Firestore,
 * this function validates the required fields and sets defaults.
 *
 * Note: User creation is handled by Admin SDK in the admin dashboard,
 * which creates both the Auth user and the Firestore profile.
 * This trigger ensures data consistency.
 */
exports.onUserProfileCreated = onDocumentCreated("users/{userId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const userData = snapshot.data();
  const userId = event.params.userId;
  const db = getFirestore();

  // Ensure required fields have defaults
  const updates = {};

  if (!userData.status) {
    updates.status = "active";
  }

  if (!userData.createdAt) {
    updates.createdAt = new Date().toISOString();
  }

  if (!userData.role) {
    console.error(`User ${userId} created without a role!`);
    updates.role = "teacher"; // Default to lowest privilege
  }

  // If the user is a coordinator, initialize their stats
  if (userData.role === "coordinator") {
    if (userData.centres === undefined) updates.centres = 0;
    if (userData.teachers === undefined) updates.teachers = 0;
    if (userData.students === undefined) updates.students = 0;
  }

  // If the user is a teacher, initialize their stats
  if (userData.role === "teacher") {
    if (userData.students === undefined) updates.students = 0;
  }

  if (Object.keys(updates).length > 0) {
    await db.collection("users").doc(userId).update(updates);
    console.log(`User ${userId} profile updated with defaults:`, updates);
  }

  return null;
});
