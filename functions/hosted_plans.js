const {randomUUID} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');

const PLAN_TOKEN = /^[A-Za-z0-9_.-]{1,80}$/;
const ATTEMPT_TOKEN = /^[A-Za-z0-9_.-]{1,160}$/;
const DAY_MILLIS = 24 * 60 * 60 * 1000;

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
  if (!ATTEMPT_TOKEN.test(attemptId) || !/^[a-f0-9]{64}$/.test(batchSha256)) {
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
    const existingAttempts = Array.isArray(usage.data()?.attempts)
      ? usage.data().attempts
      : [];
    const attempts = existingAttempts.filter((entry) =>
      entry && typeof entry.id === 'string' &&
      entry.at?.toMillis?.() >= cutoff &&
      entry.at.toMillis() <= now.toMillis(),
    );
    const existing = attempts.find((entry) => entry.attemptId === attemptId);
    if (existing != null) {
      if (existing.batchSha256 !== batchSha256) {
        throw new HttpsError(
          'failed-precondition',
          'The sync attempt is already bound to another batch.',
        );
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
    const reserved = {id: reservationId, attemptId, batchSha256, at: now};
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
  return {
    reservationId: entry.id,
    used,
    remaining: limit - used,
    limit,
    windowSeconds: DAY_MILLIS / 1000,
    reservedAt: entry.at.toDate().toISOString(),
  };
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
      dailySyncLimit > 1000 ||
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
