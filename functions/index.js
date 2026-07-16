const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

initializeApp();

const MAX_PROOF_BYTES = 20 * 1024 * 1024;
const GRANT_LIFETIME_MS = 5 * 60 * 1000;
const TOKEN = /^[A-Za-z0-9_-]{1,160}$/;
const OWN_RECEIPT_PERMISSIONS = new Set([
  'addOwnReceipts',
  'addCompanyExpenses',
  'editJobs',
  'useMaterials',
  'logMaintenance',
]);

exports.issueExpenseProofUploadGrant = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid || '';
    const organizationId = String(request.data?.organizationId || '').trim();
    const proofId = String(request.data?.proofId || '').trim();
    const requestedBytes = Number(request.data?.requestedBytes);
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
    if (!TOKEN.test(organizationId) || !TOKEN.test(proofId)) {
      throw new HttpsError('invalid-argument', 'Invalid proof identity.');
    }
    if (!Number.isInteger(requestedBytes) || requestedBytes <= 0) {
      throw new HttpsError('invalid-argument', 'Invalid proof size.');
    }
    const db = getFirestore();
    const member = await db.doc(`orgs/${organizationId}/members/${uid}`).get();
    const storedPermissions = member.data()?.permissions;
    const permissions = Array.isArray(storedPermissions) ? storedPermissions : [];
    if (member.data()?.status !== 'active' ||
        !permissions.some((permission) => OWN_RECEIPT_PERMISSIONS.has(permission))) {
      throw new HttpsError('permission-denied', 'Expense proof upload is not allowed.');
    }
    const grantId = randomUUID();
    const maxBytes = Math.min(requestedBytes, MAX_PROOF_BYTES);
    const expiresAt = Timestamp.fromMillis(Date.now() + GRANT_LIFETIME_MS);
    await db.doc(`orgs/${organizationId}/uploadGrants/${grantId}`).create({
      uid,
      proofId,
      status: 'open',
      maxBytes,
      expiresAt,
      createdAt: Timestamp.now(),
    });
    return { grantId, maxBytes, expiresAt: expiresAt.toDate().toISOString() };
  },
);
