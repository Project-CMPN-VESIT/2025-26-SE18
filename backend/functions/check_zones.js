const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
admin.initializeApp({ projectId: "demo-ngo" });
const db = admin.firestore();

async function check() {
  const snap = await db.collection("zones").get();
  for (const doc of snap.docs) {
    console.log(doc.data().name, "->", doc.data().spreadsheetId);
  }
  process.exit(0);
}
check();
