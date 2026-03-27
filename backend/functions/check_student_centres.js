const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });

async function check() {
  const db = admin.firestore();
  const snap = await db.collection("students").get();
  console.log(`There are ${snap.docs.length} students in the db.`);
  const centresMap = {};
  snap.docs.forEach(doc => {
     const c = doc.data().centre;
     centresMap[c] = (centresMap[c] || 0) + 1;
  });
  console.log("Students by centre in DB:");
  console.log(centresMap);
  
  const centresSnap = await db.collection("centres").get();
  console.log(`There are ${centresSnap.docs.length} centres in the db.`);
  const centresColMap = {};
  centresSnap.docs.forEach(doc => {
     const c = doc.data().name;
     centresColMap[c] = (centresColMap[c] || 0) + 1;
  });
  console.log("Centres by name in DB:");
  console.log(centresColMap);
  
  process.exit(0);
}

check();
