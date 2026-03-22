const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

process.env.FIRESTORE_EMULATOR_HOST = "localhost:8086";
initializeApp({ projectId: "smarteducationanalyticssystem" });
const db = getFirestore();

async function check() {
  console.log("Searching for Mirabai students...");
  const snap = await db.collection("students").where("centre", "==", "Mirabai").get();
  if (snap.empty) {
    console.log("Not found.");
  } else {
    snap.forEach(doc => {
      const d = doc.data();
      console.log(`${d.name}: P=${d.presentCount}, A=${d.absentCount}, D=${d.dropoutCount}`);
    });
  }
}

check().catch(console.error);
