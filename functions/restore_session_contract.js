const {createHash} = require('node:crypto');
const {HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');

const TOKEN = /^[A-Za-z0-9_-]{1,160}$/;
const SHA256 = /^[a-f0-9]{64}$/;
const authorizationLifetimeSeconds = defineInt(
  'RESTORE_AUTHORIZATION_LIFETIME_SECONDS',
  {default: 15 * 60},
);

async function requireCurrentRestorePrincipal(transaction, input, db) {
  const [member, device] = await Promise.all([
    transaction.get(
      db.doc(`orgs/${input.organizationId}/members/${input.uid}`),
    ),
    transaction.get(
      db.doc(`users/${input.uid}/devices/${input.deviceId}`),
    ),
  ]);
  if (member.data()?.status !== 'active' ||
      device.data()?.uid !== input.uid ||
      device.data()?.deviceId !== input.deviceId ||
      device.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'Restore account or device is no longer active.',
    );
  }
}

function restoreSessionInput(request) {
  const uid = request.auth?.uid || '';
  const organizationId = cleanToken(request.data?.organizationId);
  const deviceId = cleanToken(request.data?.deviceId);
  const sessionId = cleanToken(request.data?.sessionId);
  const authorizationToken = String(
    request.data?.authorizationToken || '',
  ).trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!organizationId || !deviceId || !sessionId ||
      !SHA256.test(authorizationToken)) {
    throw new HttpsError('invalid-argument', 'Invalid restore authorization.');
  }
  return {uid, organizationId, deviceId, sessionId, authorizationToken};
}

function requireUsableSession(
  snapshot,
  input,
  {allowedStates, allowExpiredTerminal = false},
) {
  const data = snapshot.data();
  const expiresAt = data?.expiresAt?.toMillis?.() || 0;
  if (!snapshot.exists || data.uid !== input.uid ||
      data.orgId !== input.organizationId ||
      data.deviceId !== input.deviceId ||
      data.authorizationTokenHash !== sha256(input.authorizationToken) ||
      !allowedStates.has(data.status) ||
      (!allowExpiredTerminal && expiresAt <= Date.now())) {
    throw new HttpsError(
      'permission-denied',
      'Restore authorization is invalid or expired.',
    );
  }
  return data;
}

function restoreSessionResult(sessionId, data, status) {
  return {
    sessionId,
    mode: data.mode,
    status,
    completedItems: Number(data.completedItems || 0),
    completedBytes: Number(data.completedBytes || 0),
    expiresAt: data.expiresAt.toDate().toISOString(),
  };
}

function cleanToken(value) {
  const token = String(value || '').trim();
  return TOKEN.test(token) ? token : '';
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function validAuthorizationLifetime() {
  const lifetimeSeconds = authorizationLifetimeSeconds.value();
  if (!Number.isInteger(lifetimeSeconds) ||
      lifetimeSeconds < 5 * 60 || lifetimeSeconds > 60 * 60) {
    throw new HttpsError(
      'failed-precondition',
      'Restore authorization configuration is invalid.',
    );
  }
  return lifetimeSeconds;
}

module.exports = {
  SHA256,
  cleanToken,
  requireCurrentRestorePrincipal,
  requireUsableSession,
  restoreSessionInput,
  restoreSessionResult,
  sha256,
  validAuthorizationLifetime,
};
