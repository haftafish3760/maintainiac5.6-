const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
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

exports.finalizeExpenseProofUpload = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid || '';
    const organizationId = String(request.data?.organizationId || '').trim();
    const receiptId = String(request.data?.receiptId || '').trim();
    const proofId = String(request.data?.proofId || '').trim();
    const grantId = String(request.data?.grantId || '').trim();
    const contentSha256 = String(request.data?.contentSha256 || '').trim();
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
    if (![organizationId, receiptId, proofId, grantId].every((value) => TOKEN.test(value)) ||
        !/^[a-f0-9]{64}$/.test(contentSha256)) {
      throw new HttpsError('invalid-argument', 'Invalid proof finalization identity.');
    }
    const db = getFirestore();
    const member = await db.doc(`orgs/${organizationId}/members/${uid}`).get();
    if (member.data()?.status !== 'active') {
      throw new HttpsError('permission-denied', 'Expense proof upload is not allowed.');
    }
    const grantRef = db.doc(`orgs/${organizationId}/uploadGrants/${grantId}`);
    const grant = await grantRef.get();
    const data = grant.data();
    if (!grant.exists || data?.uid !== uid || data.proofId !== proofId ||
        data.status !== 'open' || !Number.isInteger(data.maxBytes) || data.maxBytes <= 0 ||
        !data.expiresAt || data.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError('failed-precondition', 'The proof upload grant is no longer usable.');
    }
    const path = `orgs/${organizationId}/proof-uploads/${uid}/${grantId}/${proofId}`;
    const [metadata] = await getStorage().bucket().file(path).getMetadata();
    const custom = metadata.metadata || {};
    const size = Number(metadata.size);
    if (!Number.isInteger(size) || size <= 0 || size > data.maxBytes ||
        !String(metadata.contentType || '').startsWith('image/') ||
        custom.orgId !== organizationId || custom.uid !== uid ||
        custom.receiptId !== receiptId || custom.proofId !== proofId ||
        custom.contentSha256 !== contentSha256) {
      throw new HttpsError('failed-precondition', 'The uploaded proof does not match its grant.');
    }
    await grantRef.update({
      status: 'finalized',
      finalizedAt: Timestamp.now(),
      receiptId,
      byteCount: size,
      contentType: metadata.contentType,
      contentSha256,
    });
    return { status: 'finalized', byteCount: size, contentSha256 };
  },
);
