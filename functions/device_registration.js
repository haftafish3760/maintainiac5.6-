const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');
const {SHA256, cleanToken} = require('./restore_session_contract');

const maxActiveDevices = defineInt('RESTORE_MAX_ACTIVE_DEVICES', {default: 5});

function buildDeviceRegistrationFunctions({enforceAppCheck}) {
  return {
    registerRestoreDevice: onCall({enforceAppCheck}, registerRestoreDevice),
    revokeRestoreDevice: onCall({enforceAppCheck}, revokeRestoreDevice),
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
  if (!deviceId || !SHA256.test(deviceId) ||
      !SHA256.test(installationIdHash) || deviceId !== installationIdHash ||
      !['android', 'ios'].includes(platform) ||
      appVersion.length < 1 || appVersion.length > 64) {
    throw new HttpsError('invalid-argument', 'Invalid device registration.');
  }
  const db = getFirestore();
  const deviceRef = db.doc(`users/${uid}/devices/${deviceId}`);
  const activeDeviceLimit = Math.max(1, maxActiveDevices.value());
  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(deviceRef);
    const data = existing.data();
    if (data?.status === 'revoked') {
      throw new HttpsError(
        'permission-denied',
        'This device registration is revoked.',
      );
    }
    if (existing.exists && data?.installationIdHash !== installationIdHash) {
      throw new HttpsError(
        'failed-precondition',
        'This device identity is already bound to another installation.',
      );
    }
    if (!existing.exists) {
      const activeDevices = await transaction.get(
        db.collection(`users/${uid}/devices`)
          .where('status', '==', 'active')
          .limit(activeDeviceLimit),
      );
      if (activeDevices.size >= activeDeviceLimit) {
        throw new HttpsError(
          'resource-exhausted',
          'This account has reached its active device limit.',
        );
      }
    }
    const currentRevision = safeRevision(data?.registrationRevision);
    if (existing.exists && currentRevision > 0 &&
        data?.platform === platform && data?.appVersion === appVersion &&
        data?.status === 'active') {
      return {deviceId, registrationRevision: currentRevision};
    }
    const now = Timestamp.now();
    const registrationRevision = existing.exists
      ? currentRevision + 1
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
}

async function revokeRestoreDevice(request) {
  const uid = request.auth?.uid || '';
  const deviceId = cleanToken(request.data?.deviceId);
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!deviceId) {
    throw new HttpsError('invalid-argument', 'Invalid device revocation.');
  }
  const db = getFirestore();
  const deviceRef = db.doc(`users/${uid}/devices/${deviceId}`);
  return db.runTransaction(async (transaction) => {
    const existing = await transaction.get(deviceRef);
    if (!existing.exists || existing.data()?.uid !== uid) {
      throw new HttpsError('not-found', 'Device registration was not found.');
    }
    const data = existing.data();
    const currentRevision = safeRevision(data.registrationRevision);
    if (data.status === 'revoked') {
      return {
        deviceId,
        status: 'revoked',
        registrationRevision: currentRevision,
      };
    }
    const registrationRevision = currentRevision + 1;
    transaction.update(deviceRef, {
      status: 'revoked',
      revokedAt: Timestamp.now(),
      registrationRevision,
    });
    return {deviceId, status: 'revoked', registrationRevision};
  });
}

function safeRevision(value) {
  return Number.isSafeInteger(value) && value >= 0 ? value : 0;
}

module.exports = {buildDeviceRegistrationFunctions};
