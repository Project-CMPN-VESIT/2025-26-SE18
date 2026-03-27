const admin = require("firebase-admin");
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8086";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
admin.initializeApp({ projectId: "smarteducationanalyticssystem" });

const { readUsersFromSheet } = require("./src/sheets/sheetsHelper");

async function main() {
  console.log("Executing via sheets helper bypass...");
  const users = await readUsersFromSheet();
  console.log(`Fetched ${users.length} users from sheet`);
  for (const u of users) {
     try {
        const userRec = await admin.auth().createUser({ email: u.email, password: u.password, displayName: u.name });
        await admin.firestore().collection("users").doc(userRec.uid).set({
           ...u, uid: userRec.uid, createdAt: new Date().toISOString()
        });
        console.log("Created", u.email);
     } catch(e) {
        console.log("Error creating", u.email, e.message);
     }
  }
  process.exit(0);
}

main();
