const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });

async function check() {
  const snap = await admin.firestore().collection("users").get();
  snap.docs.forEach(doc => {
     if (doc.data().name === 'Thane Coordinator') {
         console.log('Thane Coordinator doc:', doc.data());
     }
  });
  process.exit(0);
}
check();
