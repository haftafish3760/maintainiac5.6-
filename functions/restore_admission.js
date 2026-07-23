const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');

const WINDOW_MILLIS = 30 * 24 * 60 * 60 * 1000;
const BUILD_LEASE_MILLIS = 5 * 60 * 1000;
const maxSessionsPerWindow = defineInt(
  'RESTORE_MAX_NEW_SESSIONS_PER_30_DAYS',
  {default: 10},
);
const maxEstimatedBytesPerWindow = defineInt(
  'RESTORE_MAX_ESTIMATED_BYTES_PER_30_DAYS',
  {default: 10 * 1024 * 1024 * 1024},
);

async function reserveRestoreAdmission({
  uid,
  organizationId,
  deviceId,
  requestId,
  sessionId,
  estimatedBytes,
}) {
  const limits = validatedLimits();
  if (!Number.isSafeInteger(estimatedBytes) || estimatedBytes < 0) {
    throw new HttpsError(
      'failed-precondition',
      'Restore size estimate is invalid.',
    );
  }
  const db = getFirestore();
  const usageRef = db.doc(`users/${uid}/restoreUsage/rolling30Days`);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(usageRef);
    const now = Timestamp.now();
    const cutoff = now.toMillis() - WINDOW_MILLIS;
    const stored = snapshot.data()?.attempts;
    if (stored != null && !Array.isArray(stored)) invalidUsage();
    const history = stored || [];
    if (history.some((attempt) => !validAttempt(attempt))) invalidUsage();
    const attempts = history.filter((attempt) =>
      validAttempt(attempt) && attempt.at.toMillis() >= cutoff &&
      attempt.at.toMillis() <= now.toMillis(),
    );
    const existing = attempts.find(
      (attempt) => attempt.requestId === requestId,
    );
    if (existing) {
      if (existing.organizationId !== organizationId ||
          existing.deviceId !== deviceId || existing.sessionId !== sessionId) {
        throw new HttpsError(
          'failed-precondition',
          'Restore request ID is already bound to another request.',
        );
      }
      if (existing.leaseUntil.toMillis() > now.toMillis()) {
        return {mayBuild: false};
      }
      existing.leaseUntil = Timestamp.fromMillis(
        now.toMillis() + BUILD_LEASE_MILLIS,
      );
      transaction.set(usageRef, usageDocument(uid, attempts, now));
      return {mayBuild: true};
    }
    const usedBytes = attempts.reduce(
      (total, attempt) => total + attempt.estimatedBytes,
      0,
    );
    if (attempts.length >= limits.sessions ||
        usedBytes + estimatedBytes > limits.bytes) {
      throw new HttpsError(
        'resource-exhausted',
        'Restore protection limit reached. Try again later.',
      );
    }
    attempts.push({
      requestId,
      sessionId,
      organizationId,
      deviceId,
      estimatedBytes,
      at: now,
      leaseUntil: Timestamp.fromMillis(now.toMillis() + BUILD_LEASE_MILLIS),
    });
    transaction.set(usageRef, usageDocument(uid, attempts, now));
    return {mayBuild: true};
  });
}

function validatedLimits() {
  const sessions = maxSessionsPerWindow.value();
  const bytes = maxEstimatedBytesPerWindow.value();
  if (!Number.isInteger(sessions) || sessions < 1 || sessions > 100 ||
      !Number.isSafeInteger(bytes) || bytes < 64 * 1024 * 1024 ||
      bytes > 1024 * 1024 * 1024 * 1024) {
    throw new HttpsError(
      'failed-precondition',
      'Restore protection configuration is invalid.',
    );
  }
  return {sessions, bytes};
}

function validAttempt(value) {
  return value && typeof value.requestId === 'string' &&
    typeof value.sessionId === 'string' &&
    typeof value.organizationId === 'string' &&
    typeof value.deviceId === 'string' &&
    Number.isSafeInteger(value.estimatedBytes) && value.estimatedBytes >= 0 &&
    typeof value.at?.toMillis === 'function' &&
    typeof value.leaseUntil?.toMillis === 'function';
}

function usageDocument(uid, attempts, now) {
  return {
    schema: 'maintainiac_restore_usage_v1',
    uid,
    windowSeconds: WINDOW_MILLIS / 1000,
    attempts,
    updatedAt: now,
  };
}

function invalidUsage() {
  throw new HttpsError(
    'failed-precondition',
    'Restore protection history requires account review.',
  );
}

module.exports = {reserveRestoreAdmission};
