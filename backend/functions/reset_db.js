const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = admin.firestore();
const auth = admin.auth();

async function deleteCollection(collectionPath) {
  const snapshot = await db.collection(collectionPath).get();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
}

async function main() {
  console.log("Wiping old database...");

  // Delete all old FIRESTORE data
  await deleteCollection("users");
  await deleteCollection("zones");
  await deleteCollection("centres");
  await deleteCollection("students");
  await deleteCollection("leaves");
  await deleteCollection("attendance");
  await deleteCollection("examResults");
  await deleteCollection("resources");
  await deleteCollection("diaryEntries");

  // Delete all AUTH users
  const { users } = await auth.listUsers();
  const uids = users.map(u => u.uid);
  if (uids.length > 0) {
    await auth.deleteUsers(uids);
  }

  // Set up the correct authentic zones based on the Users Directory screenshot!
  console.log("Setting up REAL zones...");

  // 1. Thane Zone (Using the specific Sheet ID provided by the user)
  await db.collection("zones").doc("thane").set({
    name: "Thane",
    status: "active",
    spreadsheetId: "1YQZpO4TL1u-1ULm0sTXmeWDqsmQ643lhtTJAkHNSFyo",
    centres: 10,
    students: 0,
    teachers: 0,
    createdAt: new Date().toISOString()
  });

  // 2. Boisar Zone
  await db.collection("zones").doc("boisar").set({
    name: "Boisar",
    status: "active",
    spreadsheetId: "PLACEHOLDER_BOISAR", // User hasn't provided this yet
    centres: 2,
    students: 0,
    teachers: 0,
    createdAt: new Date().toISOString()
  });

  // 3. New Karjat Zone
  await db.collection("zones").doc("new_karjat").set({
    name: "New Karjat",
    status: "active",
    spreadsheetId: "PLACEHOLDER_KARJAT",
    centres: 2,
    students: 0,
    teachers: 0,
    createdAt: new Date().toISOString()
  });

  // 4. Saphale Zone
  await db.collection("zones").doc("saphale").set({
    name: "Saphale",
    status: "active",
    spreadsheetId: "PLACEHOLDER_SAPHALE",
    centres: 1,
    students: 0,
    teachers: 0,
    createdAt: new Date().toISOString()
  });

  // 5. Eastern Mumbai Zone
  await db.collection("zones").doc("eastern").set({
    name: "Eastern Mumbai",
    status: "active",
    spreadsheetId: "PLACEHOLDER_EASTERN",
    centres: 1,
    students: 0,
    teachers: 0,
    createdAt: new Date().toISOString()
  });

  console.log("Database wiped perfectly. Authentic Zones configured.");
  process.exit(0);
}

main().catch(console.error);
