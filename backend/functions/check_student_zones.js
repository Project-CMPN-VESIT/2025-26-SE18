const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });

async function check() {
  const db = admin.firestore();
  const snap = await db.collection("students").get();
  
  const zonesMap = {};
  snap.docs.forEach(doc => {
     const z = doc.data().zone;
     zonesMap[z] = (zonesMap[z] || 0) + 1;
  });
  console.log("Students by zone in DB:");
  console.log(zonesMap);
  
  process.exit(0);
}

check();
