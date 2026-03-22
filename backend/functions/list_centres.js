const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

process.env.FIRESTORE_EMULATOR_HOST = "localhost:8086";
initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

async function check() {
  console.log("Fetching all centres...");
  const snap = await db.collection("centres").get();
  snap.forEach(doc => {
    const d = doc.data();
    console.log(`- ${d.name} (${d.zone})`);
  });
}

check().catch(console.error);
