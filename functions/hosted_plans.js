const {randomUUID} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');

const PLAN_TOKEN = /^[A-Za-z0-9_.-]{1,80}$/;
const ATTEMPT_TOKEN = /^[A-Za-z0-9_.-]{1,160}$/;
const DAY_MILLIS = 24 * 60 * 60 * 1000;
const maxBatchesPerSync = defineInt(
  'HOSTED_SYNC_MAX_BATCHES',
  {default: 20},
);
const maxBytesPerSync = defineInt(
  'HOSTED_SYNC_MAX_BYTES',
  {default: 8 * 1024 * 1024},
);

function buildHostedPlanFunctions({enforceAppCheck}) {
  return {
    getHostedUsageGrant: onCall({enforceAppCheck}, getHostedUsageGrant),
    reserveHostedSync: onCall({enforceAppCheck}, reserveHostedSync),
  };
}

async function getHostedUsageGrant(request) {
  const uid = requireUid(request);
  const db = getFirestore();
  const grant = await loadHostedGrantForUid(db, uid);
  return publicGrant(grant);
}

async function reserveHostedSync(request) {
  const uid = requireUid(request);
  const attemptId = String(request.data?.attemptId || '').trim();
  const batchSha256 = String(request.data?.batchSha256 || '').trim();
  const batchBytes = Number(request.data?.batchBytes || 0);
  const syncBounds = validatedSyncBounds();
  if (!ATTEMPT_TOKEN.test(attemptId) ||
      !/^[a-f0-9]{64}$/.test(batchSha256) ||
      !Number.isSafeInteger(batchBytes) || batchBytes < 1 ||
      batchBytes > syncBounds.bytes) {
    throw new HttpsError(
      'invalid-argument',
      'A durable sync attempt ID and batch hash are required.',
    );
  }
  const db = getFirestore();
  const entitlementRef = db.doc(`users/${uid}/entitlements/current`);
  const usageRef = db.doc(`users/${uid}/syncUsage/rolling24Hours`);
  return db.runTransaction(async (transaction) => {
    const entitlement = await transaction.get(entitlementRef);
    const planId = activePlanId(entitlement.data());
    const planRef = db.doc(`hostedPlans/${planId}`);
    const [plan, usage] = await Promise.all([
      transaction.get(planRef),
      transaction.get(usageRef),
    ]);
    const grant = validatedGrant(planId, plan.data());
    if (grant.dailySyncLimit < 1 || grant.storageQuotaBytes < 1) {
      throw new HttpsError(
        'failed-precondition',
        'Cloud synchronization is not enabled for this plan.',
      );
    }
    const now = Timestamp.now();
    const cutoff = now.toMillis() - DAY_MILLIS;
    const storedAttempts = usage.data()?.attempts;
    if (storedAttempts != null && !Array.isArray(storedAttempts)) {
      invalidSyncHistory();
    }
    if ((storedAttempts || []).some(
      (entry) => !validSyncAttempt(entry, syncBounds),
    )) {
      invalidSyncHistory();
    }
    const existingAttempts = storedAttempts || [];
    const attempts = existingAttempts.filter((entry) =>
      entry && typeof entry.id === 'string' &&
      entry.at?.toMillis?.() >= cutoff &&
      entry.at.toMillis() <= now.toMillis(),
    );
    const existing = attempts.find((entry) => entry.attemptId === attemptId);
    if (existing != null) {
      const sameBatch = existing.batches.find(
        (batch) => batch.sha256 === batchSha256,
      );
      if (sameBatch != null && sameBatch.bytes !== batchBytes) {
        throw new HttpsError(
          'failed-precondition',
          'The sync batch identity is already bound to another payload.',
        );
      }
      if (sameBatch == null) {
        const usedBytes = existing.batches.reduce(
          (total, batch) => total + batch.bytes,
          0,
        );
        if (existing.batches.length >= syncBounds.batches ||
            usedBytes + batchBytes > syncBounds.bytes) {
          throw new HttpsError(
            'resource-exhausted',
            'This sync opportunity reached its bounded batch allowance.',
          );
        }
        existing.batches.push({sha256: batchSha256, bytes: batchBytes});
        transaction.set(usageRef, {
          uid,
          planId,
          policyVersion: grant.policyVersion,
          attempts,
          updatedAt: now,
        });
      }
      return reservationResult(existing, attempts.length, grant.dailySyncLimit);
    }
    if (attempts.length >= grant.dailySyncLimit) {
      const nextEligibleAt = attempts
        .map((entry) => entry.at.toMillis())
        .sort((left, right) => left - right)[0] + DAY_MILLIS;
      throw new HttpsError(
        'resource-exhausted',
        `Sync allowance renews after ${new Date(nextEligibleAt).toISOString()}.`,
      );
    }
    const reservationId = randomUUID();
    const reserved = {
      id: reservationId,
      attemptId,
      batches: [{sha256: batchSha256, bytes: batchBytes}],
      at: now,
    };
    attempts.push(reserved);
    transaction.set(usageRef, {
      uid,
      planId,
      policyVersion: grant.policyVersion,
      attempts,
      updatedAt: now,
    });
    return reservationResult(reserved, attempts.length, grant.dailySyncLimit);
  });
}

function reservationResult(entry, used, limit) {
  const batchBytesUsed = entry.batches.reduce(
    (total, batch) => total + batch.bytes,
    0,
  );
  return {
    reservationId: entry.id,
    used,
    remaining: limit - used,
    limit,
    windowSeconds: DAY_MILLIS / 1000,
    reservedAt: entry.at.toDate().toISOString(),
    batchCount: entry.batches.length,
    batchBytesUsed,
  };
}

function validatedSyncBounds() {
  const batches = maxBatchesPerSync.value();
  const bytes = maxBytesPerSync.value();
  if (!Number.isInteger(batches) || batches < 1 || batches > 100 ||
      !Number.isSafeInteger(bytes) || bytes < 1024 ||
      bytes > 64 * 1024 * 1024) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted sync batch configuration is invalid.',
    );
  }
  return {batches, bytes};
}

function validSyncAttempt(entry, syncBounds) {
  if (!entry || typeof entry.id !== 'string' ||
      !ATTEMPT_TOKEN.test(entry.attemptId) ||
      typeof entry.at?.toMillis !== 'function' ||
      !Array.isArray(entry.batches) || entry.batches.length < 1 ||
      entry.batches.length > syncBounds.batches) {
    return false;
  }
  const hashes = new Set();
  let bytes = 0;
  for (const batch of entry.batches) {
    if (!/^[a-f0-9]{64}$/.test(batch?.sha256 || '') ||
        !Number.isSafeInteger(batch?.bytes) || batch.bytes < 1 ||
        hashes.has(batch.sha256)) {
      return false;
    }
    hashes.add(batch.sha256);
    bytes += batch.bytes;
  }
  return bytes <= syncBounds.bytes;
}

function invalidSyncHistory() {
  throw new HttpsError(
    'failed-precondition',
    'Hosted sync history requires account review.',
  );
}

async function loadHostedGrantForUid(db, uid) {
  const entitlement = await db.doc(`users/${uid}/entitlements/current`).get();
  const planId = activePlanId(entitlement.data());
  const plan = await db.doc(`hostedPlans/${planId}`).get();
  return validatedGrant(planId, plan.data());
}

function activePlanId(data) {
  const planId = data?.planId;
  if (data?.status !== 'active' ||
      typeof planId !== 'string' || !PLAN_TOKEN.test(planId)) {
    throw new HttpsError(
      'failed-precondition',
      'No active hosted backup entitlement is assigned.',
    );
  }
  return planId;
}

function validatedGrant(planId, data) {
  const displayName = data?.displayName;
  const storageQuotaBytes = data?.storageQuotaBytes;
  const dailySyncLimit = data?.dailySyncLimit;
  const immediateSyncAllowed = data?.immediateSyncAllowed;
  const policyVersion = data?.policyVersion;
  const downloadAllowanceBytes = data?.downloadAllowanceBytes;
  if (data?.status !== 'active' ||
      typeof displayName !== 'string' || displayName.length < 1 ||
      displayName.length > 120 ||
      !Number.isInteger(storageQuotaBytes) || storageQuotaBytes < 0 ||
      (storageQuotaBytes > 0 && storageQuotaBytes < 1024) ||
      storageQuotaBytes > 1024 * 1024 * 1024 * 1024 ||
      !Number.isInteger(dailySyncLimit) || dailySyncLimit < 0 ||
      dailySyncLimit > 100 ||
      typeof immediateSyncAllowed !== 'boolean' ||
      !Number.isInteger(policyVersion) || policyVersion < 1 ||
      !Number.isInteger(downloadAllowanceBytes) ||
      downloadAllowanceBytes < 0 ||
      downloadAllowanceBytes > 1024 * 1024 * 1024 * 1024) {
    throw new HttpsError(
      'failed-precondition',
      'Hosted backup plan configuration is invalid.',
    );
  }
  return {
    planId,
    displayName,
    storageQuotaBytes,
    dailySyncLimit,
    immediateSyncAllowed,
    policyVersion,
    downloadAllowanceBytes,
  };
}

function publicGrant(grant) {
  return {...grant};
}

function requireUid(request) {
  const uid = request.auth?.uid || '';
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  return uid;
}

module.exports = {
  buildHostedPlanFunctions,
  loadHostedGrantForUid,
  reserveHostedSync,
};
