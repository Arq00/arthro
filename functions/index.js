// functions/index.js
// Firebase Cloud Functions for ArthroCare Admin Panel
// Deploy: firebase deploy --only functions

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getAuth }            = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Helper: verify the caller is an authenticated admin
// ─────────────────────────────────────────────────────────────────────────────
async function verifyAdmin(auth) {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  const db      = getFirestore();
  const callerDoc = await db.collection("users").doc(auth.uid).get();
  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// deleteAuthUser
// Called by admin_user_controller.dart after Firestore data is already deleted.
// Permanently removes the Firebase Auth account so the user cannot sign in.
//
// Request:  { uid: string }
// Response: { success: true }
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteAuthUser = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { uid } = request.data;
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "uid is required.");
  }

  try {
    await getAuth().deleteUser(uid);
    console.log(`[deleteAuthUser] Deleted Auth account: ${uid}`);
    return { success: true };
  } catch (err) {
    // If user doesn't exist in Auth, treat as success (already gone)
    if (err.code === "auth/user-not-found") {
      console.warn(`[deleteAuthUser] Auth user not found (already deleted): ${uid}`);
      return { success: true };
    }
    console.error(`[deleteAuthUser] Failed for ${uid}:`, err);
    throw new HttpsError("internal", `Failed to delete Auth user: ${err.message}`);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// bulkDeleteAuthUsers
// Convenience: delete multiple Auth accounts in one call.
// Used by autoTerminateInactive to avoid N separate function calls.
//
// Request:  { uids: string[] }
// Response: { deleted: number, failed: string[] }
// ─────────────────────────────────────────────────────────────────────────────
exports.bulkDeleteAuthUsers = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { uids } = request.data;
  if (!Array.isArray(uids) || uids.length === 0) {
    throw new HttpsError("invalid-argument", "uids array is required.");
  }

  // Firebase Auth deleteUsers supports up to 1000 at a time
  const chunks  = [];
  for (let i = 0; i < uids.length; i += 1000) {
    chunks.push(uids.slice(i, i + 1000));
  }

  let deleted = 0;
  const failed = [];

  for (const chunk of chunks) {
    const result = await getAuth().deleteUsers(chunk);
    deleted += result.successCount;
    for (const err of result.errors) {
      failed.push(uids[err.index]);
      console.error(`[bulkDeleteAuthUsers] Failed for index ${err.index}:`, err.error);
    }
  }

  console.log(`[bulkDeleteAuthUsers] Deleted ${deleted}, failed ${failed.length}`);
  return { deleted, failed };
});

// ─────────────────────────────────────────────────────────────────────────────
// getUserAuthInfo
// Returns the Auth account details for a given uid (email, creation time,
// last sign-in time). Used by admin dashboard to show richer user info.
//
// Request:  { uid: string }
// Response: { email, creationTime, lastSignInTime, emailVerified, disabled }
// ─────────────────────────────────────────────────────────────────────────────
exports.getUserAuthInfo = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { uid } = request.data;
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");

  try {
    const user = await getAuth().getUser(uid);
    return {
      email:         user.email          ?? null,
      creationTime:  user.metadata.creationTime     ?? null,
      lastSignInTime:user.metadata.lastSignInTime   ?? null,
      emailVerified: user.emailVerified  ?? false,
      disabled:      user.disabled       ?? false,
    };
  } catch (err) {
    if (err.code === "auth/user-not-found") {
      return { email: null, creationTime: null, lastSignInTime: null,
               emailVerified: false, disabled: false };
    }
    throw new HttpsError("internal", err.message);
  }
});