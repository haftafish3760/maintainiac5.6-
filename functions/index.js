const { randomUUID } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineInt, defineSecret } = require('firebase-functions/params');
const {
  ReceiptAssistError,
  requestOpenAiAssist,
  validateAssistRequest,
} = require('./receipt_ai_assist');

initializeApp();

const maxProofBytes = defineInt('EXPENSE_MAX_PROOF_BYTES', {
  default: 20 * 1024 * 1024,
});
const proofGrantLifetimeSeconds = defineInt(
  'EXPENSE_PROOF_GRANT_LIFETIME_SECONDS',
  { default: 5 * 60 },
);
const defaultProofQuotaBytes = defineInt(
  'EXPENSE_DEFAULT_PROOF_QUOTA_BYTES',
  { default: 25 * 1024 * 1024 },
);
const maxOpenProofGrants = defineInt('EXPENSE_MAX_OPEN_PROOF_GRANTS', {
  default: 3,
});
const expiredProofCleanupBatch = defineInt(
  'EXPENSE_EXPIRED_PROOF_CLEANUP_BATCH',
  { default: 25 },
);
const receiptAiMaxInputCharacters = defineInt('RECEIPT_AI_MAX_INPUT_CHARACTERS', {
  default: 16000,
});
const receiptAiMaxRequestsPerDay = defineInt('RECEIPT_AI_MAX_REQUESTS_PER_DAY', {
  default: 20,
});
const receiptAiMaxOutputTokens = defineInt('RECEIPT_AI_MAX_OUTPUT_TOKENS', {
  default: 1200,
});
const openAiApiKey = defineSecret('OPENAI_API_KEY');
const TOKEN = /^[A-Za-z0-9_-]{1,160}$/;
const OWN_RECEIPT_PERMISSIONS = new Set([
  'addOwnReceipts',
  'addCompanyExpenses',
  'editJobs',
  'useMaterials',
  'logMaintenance',
]);

function receiptAiUsageDay() {
  return new Date().toISOString().slice(0, 10);
}

async function requireReceiptMember({db, organizationId, uid}) {
  const member = await db.doc(`orgs/${organizationId}/members/${uid}`).get();
  const storedPermissions = member.data()?.permissions;
  const permissions = Array.isArray(storedPermissions) ? storedPermissions : [];
  if (member.data()?.status !== 'active' ||
      !permissions.some((permission) => OWN_RECEIPT_PERMISSIONS.has(permission))) {
    throw new HttpsError('permission-denied', 'Receipt assistance is not allowed.');
  }
}

async function reserveReceiptAiRequest({db, organizationId, uid, maxRequests}) {
  if (!Number.isInteger(maxRequests) || maxRequests < 1 || maxRequests > 1000) {
    throw new HttpsError('failed-precondition', 'Receipt assistance configuration is invalid.');
  }
  const day = receiptAiUsageDay();
  const usageRef = db.doc(`orgs/${organizationId}/receiptAiUsage/${uid}_${day}`);
  await db.runTransaction(async (transaction) => {
    const usage = await transaction.get(usageRef);
    const count = usage.data()?.requestCount ?? 0;
    if (!Number.isInteger(count) || count < 0) {
      throw new HttpsError('failed-precondition', 'Receipt assistance usage is invalid.');
    }
    if (count >= maxRequests) {
      throw new HttpsError('resource-exhausted', 'Receipt assistance limit reached.');
    }
    transaction.set(usageRef, {
      requestCount: count + 1,
      updatedAt: Timestamp.now(),
    }, {merge: true});
  });
}

function validQuotaBytes(value) {
  return Number.isInteger(value) && value >= 1024 &&
      value <= 1024 * 1024 * 1024 * 1024;
}

function quotaValues(data, defaultLimitBytes) {
  const limitBytes = data?.storageLimitBytes ?? defaultLimitBytes;
  const usedBytes = data?.storageUsedBytes ?? 0;
  if (!validQuotaBytes(limitBytes) || !Number.isInteger(usedBytes) ||
      usedBytes < 0 || usedBytes > limitBytes) {
    throw new HttpsError('failed-precondition', 'Proof storage quota is invalid.');
  }
  return {limitBytes, usedBytes};
}

function finalizedProofResult(data, {uid, proofId, receiptId, contentSha256}) {
  if (data?.status !== 'finalized' || data.uid !== uid ||
      data.proofId !== proofId || data.receiptId !== receiptId ||
      data.contentSha256 !== contentSha256 ||
      !Number.isInteger(data.byteCount) || data.byteCount <= 0) {
    return null;
  }
  return {
    status: 'finalized',
    byteCount: data.byteCount,
    contentSha256: data.contentSha256,
  };
}

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
    const configuredMaxBytes = maxProofBytes.value();
    if (!Number.isInteger(configuredMaxBytes) || configuredMaxBytes < 1024 ||
        configuredMaxBytes > 100 * 1024 * 1024) {
      throw new HttpsError('failed-precondition', 'Proof size configuration is invalid.');
    }
    if (requestedBytes > configuredMaxBytes) {
      throw new HttpsError('resource-exhausted', 'Proof exceeds the configured upload limit.');
    }
    const configuredQuotaBytes = defaultProofQuotaBytes.value();
    if (!validQuotaBytes(configuredQuotaBytes)) {
      throw new HttpsError('failed-precondition', 'Default proof storage quota is invalid.');
    }
    const configuredOpenGrantLimit = maxOpenProofGrants.value();
    if (!Number.isInteger(configuredOpenGrantLimit) ||
        configuredOpenGrantLimit < 1 || configuredOpenGrantLimit > 10) {
      throw new HttpsError('failed-precondition', 'Open proof grant configuration is invalid.');
    }
    const grantId = randomUUID();
    const maxBytes = requestedBytes;
    const lifetimeSeconds = proofGrantLifetimeSeconds.value();
    if (!Number.isInteger(lifetimeSeconds) || lifetimeSeconds < 60 ||
        lifetimeSeconds > 60 * 60) {
      throw new HttpsError('failed-precondition', 'Proof grant lifetime configuration is invalid.');
    }
    const expiresAt = Timestamp.fromMillis(Date.now() + lifetimeSeconds * 1000);
    const grants = db.collection(`orgs/${organizationId}/uploadGrants`);
    const grantRef = grants.doc(grantId);
    const quotaRef = db.doc(`orgs/${organizationId}/storageQuotas/${uid}`);
    const issuedGrant = await db.runTransaction(async (transaction) => {
      const [quota, openGrants] = await Promise.all([
        transaction.get(quotaRef),
        transaction.get(
          grants.where('uid', '==', uid).where('status', '==', 'open').limit(
            configuredOpenGrantLimit + 1,
          ),
        ),
      ]);
      const existingGrant = openGrants.docs.find((openGrant) => {
          const data = openGrant.data();
          return data.proofId === proofId && data.maxBytes === maxBytes &&
              data.expiresAt?.toMillis() > Date.now();
        });
      if (existingGrant != null) {
        const existing = existingGrant.data();
        return {
          grantId: existingGrant.id,
          maxBytes: existing.maxBytes,
          expiresAt: existing.expiresAt,
        };
      }
      if (openGrants.size > configuredOpenGrantLimit) {
        throw new HttpsError('resource-exhausted', 'Too many proof uploads are pending.');
      }
      const quotaData = quotaValues(quota.data(), configuredQuotaBytes);
      const reservedBytes = openGrants.docs.fold(0, (total, openGrant) => {
        const data = openGrant.data();
        return data.expiresAt?.toMillis() > Date.now() &&
            Number.isInteger(data.maxBytes) && data.maxBytes > 0
          ? total + data.maxBytes
          : total;
      });
      if (quotaData.usedBytes + reservedBytes + maxBytes > quotaData.limitBytes) {
        throw new HttpsError('resource-exhausted', 'Proof storage quota is exhausted.');
      }
      if (!quota.exists) {
        transaction.create(quotaRef, {
          storageLimitBytes: quotaData.limitBytes,
          storageUsedBytes: 0,
          createdAt: Timestamp.now(),
        });
      }
      transaction.create(grantRef, {
        uid,
        proofId,
        status: 'open',
        maxBytes,
        expiresAt,
        createdAt: Timestamp.now(),
      });
      return {grantId, maxBytes, expiresAt};
    });
    return {
      grantId: issuedGrant.grantId,
      maxBytes: issuedGrant.maxBytes,
      expiresAt: issuedGrant.expiresAt.toDate().toISOString(),
    };
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
    const storedPermissions = member.data()?.permissions;
    const permissions = Array.isArray(storedPermissions) ? storedPermissions : [];
    if (member.data()?.status !== 'active' ||
        !permissions.some((permission) => OWN_RECEIPT_PERMISSIONS.has(permission))) {
      throw new HttpsError('permission-denied', 'Expense proof upload is not allowed.');
    }
    const grantRef = db.doc(`orgs/${organizationId}/uploadGrants/${grantId}`);
    const grant = await grantRef.get();
    const data = grant.data();
    const completed = finalizedProofResult(data, {
      uid,
      proofId,
      receiptId,
      contentSha256,
    });
    if (completed != null) return completed;
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
    const quotaRef = db.doc(`orgs/${organizationId}/storageQuotas/${uid}`);
    return db.runTransaction(async (transaction) => {
      const [currentGrant, quota] = await Promise.all([
        transaction.get(grantRef),
        transaction.get(quotaRef),
      ]);
      const current = currentGrant.data();
      const alreadyFinalized = finalizedProofResult(current, {
        uid,
        proofId,
        receiptId,
        contentSha256,
      });
      if (alreadyFinalized != null) return alreadyFinalized;
      if (!currentGrant.exists || current?.uid !== uid ||
          current.proofId !== proofId || current.status !== 'open' ||
          current.expiresAt?.toMillis() <= Date.now()) {
        throw new HttpsError('failed-precondition', 'The proof upload grant is no longer usable.');
      }
      const quotaData = quotaValues(quota.data(), 0);
      if (quotaData.usedBytes + size > quotaData.limitBytes) {
        throw new HttpsError('resource-exhausted', 'Proof storage quota is exhausted.');
      }
      transaction.update(grantRef, {
        status: 'finalized',
        finalizedAt: Timestamp.now(),
        receiptId,
        byteCount: size,
        contentType: metadata.contentType,
        contentSha256,
      });
      transaction.update(quotaRef, {
        storageUsedBytes: quotaData.usedBytes + size,
        updatedAt: Timestamp.now(),
      });
      return { status: 'finalized', byteCount: size, contentSha256 };
    });
  },
);

exports.requestReceiptAiAssist = onCall(
  { enforceAppCheck: true, secrets: [openAiApiKey] },
  async (request) => {
    const uid = request.auth?.uid || '';
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
    const maxInputCharacters = receiptAiMaxInputCharacters.value();
    if (!Number.isInteger(maxInputCharacters) || maxInputCharacters < 1000 ||
        maxInputCharacters > 100000) {
      throw new HttpsError('failed-precondition', 'Receipt assistance configuration is invalid.');
    }
    let evidence;
    try {
      evidence = validateAssistRequest(request.data, maxInputCharacters);
    } catch (error) {
      if (error instanceof ReceiptAssistError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
    const db = getFirestore();
    await requireReceiptMember({
      db,
      organizationId: evidence.organizationId,
      uid,
    });
    await reserveReceiptAiRequest({
      db,
      organizationId: evidence.organizationId,
      uid,
      maxRequests: receiptAiMaxRequestsPerDay.value(),
    });
    const apiKey = openAiApiKey.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'Receipt assistance is not configured.');
    }
    try {
      return await requestOpenAiAssist({
        apiKey,
        evidence,
        maxOutputTokens: receiptAiMaxOutputTokens.value(),
      });
    } catch (error) {
      if (error instanceof ReceiptAssistError) {
        throw new HttpsError(error.code, error.message);
      }
      throw error;
    }
  },
);

exports.cleanupExpiredExpenseProofUploads = onSchedule(
  'every 5 minutes',
  async () => {
    const limit = expiredProofCleanupBatch.value();
    if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
      throw new Error('Expired proof cleanup configuration is invalid.');
    }
    const db = getFirestore();
    const expired = await db.collectionGroup('uploadGrants')
        .where('status', '==', 'open')
        .where('expiresAt', '<=', Timestamp.now())
        .limit(limit)
        .get();
    await Promise.all(expired.docs.map(async (grant) => {
      const data = grant.data();
      const parts = grant.ref.path.split('/');
      const organizationId = parts.length === 4 ? parts[1] : '';
      const grantId = parts.length === 4 ? parts[3] : '';
      if (TOKEN.test(organizationId) && TOKEN.test(grantId) &&
          TOKEN.test(data.uid) && TOKEN.test(data.proofId)) {
        const path = `orgs/${organizationId}/proof-uploads/${data.uid}` +
            `/${grantId}/${data.proofId}`;
        await getStorage().bucket().file(path).delete({ignoreNotFound: true});
      }
      await grant.ref.update({status: 'expired', expiredAt: Timestamp.now()});
    }));
    return null;
  },
);
