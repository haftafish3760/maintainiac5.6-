const {createHash, randomBytes, randomUUID} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');

const TOKEN = /^[A-Za-z0-9_-]{1,160}$/;
const SHA256 = /^[a-f0-9]{64}$/;
const RESTORE_MODES = new Set(['full', 'smart', 'recordsOnly']);
const authorizationLifetimeSeconds = defineInt(
  'RESTORE_AUTHORIZATION_LIFETIME_SECONDS',
  {default: 15 * 60},
);

function buildRestoreAuthorizationFunctions({enforceAppCheck}) {
  return {
    registerRestoreDevice: onCall({enforceAppCheck}, registerRestoreDevice),
    issueRestoreAuthorization: onCall({enforceAppCheck}, issueRestoreAuthorization),
  };
}

async function registerRestoreDevice(request) {
  const uid = request.auth?.uid || '';
  const deviceId = cleanToken(request.data?.deviceId);
  const installationIdHash = String(
    request.data?.installationIdHash || '',
  ).trim();
  const platform = String(request.data?.platform || '').trim();
  const appVersion = String(request.data?.appVersion || '').trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!deviceId || !SHA256.test(installationIdHash) ||
      !['android', 'ios'].includes(platform) ||
      appVersion.length < 1 || appVersion.length > 64) {
    throw new HttpsError('invalid-argument', 'Invalid device registration.');
  }
  const db = getFirestore();
  const deviceRef = db.doc(`users/${uid}/devices/${deviceId}`);
  const registered = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(deviceRef);
    const data = existing.data();
    if (data?.status === 'revoked') {
      throw new HttpsError('permission-denied', 'This device registration is revoked.');
    }
    if (existing.exists && data?.installationIdHash !== installationIdHash) {
      throw new HttpsError(
        'failed-precondition',
        'This device identity is already bound to another installation.',
      );
    }
    const now = Timestamp.now();
    const registrationRevision = existing.exists
      ? Number(data?.registrationRevision || 0) + 1
      : 1;
    transaction.set(deviceRef, {
      uid,
      deviceId,
      installationIdHash,
      platform,
      appVersion,
      status: 'active',
      appCheckProtected: true,
      registrationRevision,
      registeredAt: data?.registeredAt || now,
      lastSeenAt: now,
    });
    return {deviceId, registrationRevision};
  });
  return registered;
}

async function issueRestoreAuthorization(request) {
  const uid = request.auth?.uid || '';
  const organizationId = cleanToken(request.data?.organizationId);
  const deviceId = cleanToken(request.data?.deviceId);
  const mode = String(request.data?.mode || '').trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!organizationId || !deviceId || !RESTORE_MODES.has(mode)) {
    throw new HttpsError('invalid-argument', 'Invalid restore request.');
  }
  const lifetimeSeconds = authorizationLifetimeSeconds.value();
  if (!Number.isInteger(lifetimeSeconds) ||
      lifetimeSeconds < 5 * 60 || lifetimeSeconds > 60 * 60) {
    throw new HttpsError(
      'failed-precondition',
      'Restore authorization configuration is invalid.',
    );
  }
  const db = getFirestore();
  const [member, device] = await Promise.all([
    db.doc(`orgs/${organizationId}/members/${uid}`).get(),
    db.doc(`users/${uid}/devices/${deviceId}`).get(),
  ]);
  if (member.data()?.status !== 'active' ||
      !device.exists || device.data()?.uid !== uid ||
      device.data()?.deviceId !== deviceId ||
      device.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'An active account and registered device are required.',
    );
  }
  const authorizationToken = randomBytes(32).toString('hex');
  const authorizationTokenHash = sha256(authorizationToken);
  const sessionId = randomUUID();
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(
    now.toMillis() + lifetimeSeconds * 1000,
  );
  await db.doc(`orgs/${organizationId}/restoreSessions/${sessionId}`).create({
    uid,
    orgId: organizationId,
    deviceId,
    mode,
    status: 'authorized',
    authorizationTokenHash,
    appCheckProtected: true,
    createdAt: now,
    expiresAt,
  });
  return {
    sessionId,
    authorizationToken,
    expiresAt: expiresAt.toDate().toISOString(),
  };
}

function cleanToken(value) {
  const token = String(value || '').trim();
  return TOKEN.test(token) ? token : '';
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

module.exports = {buildRestoreAuthorizationFunctions};
