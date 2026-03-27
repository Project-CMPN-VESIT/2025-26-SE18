const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
admin.initializeApp({ projectId: "demo-ngo" });
const db = admin.firestore();

async function main() {
  const usersRef = await db.collection("users").get();
  const batch = db.batch();
  for (const doc of usersRef.docs) {
    batch.update(doc.ref, { zone: "North Zone" });
  }
  await batch.commit();
  console.log(`Assigned ${usersRef.size} users to 'North Zone'`);
  process.exit(0);
}
main();
