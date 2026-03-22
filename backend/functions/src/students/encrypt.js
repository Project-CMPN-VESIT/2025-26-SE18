const { onCall, HttpsError } = require("firebase-functions/v2/https");
const crypto = require("crypto");

/**
 * Encryption configuration.
 * In production, store the key in Firebase environment config:
 *   firebase functions:config:set encryption.key="YOUR_32_BYTE_HEX_KEY"
 *
 * For development/emulator, a default key is used.
 */
const ALGORITHM = "aes-256-cbc";
const DEFAULT_KEY = "0123456789abcdef0123456789abcdef"; // 32 bytes for AES-256
const IV_LENGTH = 16;

function getEncryptionKey() {
  return process.env.ENCRYPTION_KEY || DEFAULT_KEY;
}

/**
 * Encrypts a given Aadhaar number using AES-256-CBC.
 *
 * Accepts:
 *   - aadhaar (string): 12-digit Aadhaar number
 *
 * Returns:
 *   - { encrypted: string } — Base64-encoded encrypted value
 */
exports.encryptAadhaar = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const { aadhaar } = request.data;

  if (!aadhaar || typeof aadhaar !== "string") {
    throw new HttpsError("invalid-argument", "A valid Aadhaar number is required.");
  }

  // Validate Aadhaar format (12 digits)
  const cleaned = aadhaar.replace(/\s/g, "");
  if (!/^\d{12}$/.test(cleaned)) {
    throw new HttpsError("invalid-argument", "Aadhaar must be exactly 12 digits.");
  }

  try {
    const key = Buffer.from(getEncryptionKey(), "utf8");
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

    let encrypted = cipher.update(cleaned, "utf8", "base64");
    encrypted += cipher.final("base64");

    // Prepend IV for decryption (IV:encrypted)
    const result = iv.toString("base64") + ":" + encrypted;

    return { encrypted: result };
  } catch (error) {
    console.error("Encryption error:", error);
    throw new HttpsError("internal", "Failed to encrypt Aadhaar number.");
  }
});

/**
 * Decrypts an encrypted Aadhaar number. Admin only.
 *
 * Accepts:
 *   - encrypted (string): The encrypted Aadhaar value (IV:ciphertext)
 *
 * Returns:
 *   - { aadhaar: string } — Last 4 digits masked (XXXX-XXXX-1234)
 */
exports.decryptAadhaar = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  // Only admin can decrypt
  const { getFirestore } = require("firebase-admin/firestore");
  const db = getFirestore();
  const userDoc = await db.collection("users").doc(request.auth.uid).get();

  if (!userDoc.exists || userDoc.data().role !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can decrypt Aadhaar numbers.");
  }

  const { encrypted } = request.data;

  if (!encrypted || typeof encrypted !== "string") {
    throw new HttpsError("invalid-argument", "An encrypted Aadhaar value is required.");
  }

  try {
    const [ivBase64, ciphertext] = encrypted.split(":");
    const key = Buffer.from(getEncryptionKey(), "utf8");
    const iv = Buffer.from(ivBase64, "base64");
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);

    let decrypted = decipher.update(ciphertext, "base64", "utf8");
    decrypted += decipher.final("utf8");

    // Mask all but last 4 digits for security
    const masked = `XXXX-XXXX-${decrypted.slice(-4)}`;

    return { aadhaar: masked };
  } catch (error) {
    console.error("Decryption error:", error);
    throw new HttpsError("internal", "Failed to decrypt Aadhaar number.");
  }
});
