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
    beginRestoreSession: onCall({enforceAppCheck}, beginRestoreSession),
    updateRestoreSession: onCall({enforceAppCheck}, updateRestoreSession),
    fetchRestoreRecordPage: onCall({enforceAppCheck}, fetchRestoreRecordPage),
    getRestorePlan: onCall({enforceAppCheck}, getRestorePlan),
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
  const [member, device, manifest] = await Promise.all([
    db.doc(`orgs/${organizationId}/members/${uid}`).get(),
    db.doc(`users/${uid}/devices/${deviceId}`).get(),
    db.doc(`orgs/${organizationId}/syncManifests/${uid}`).get(),
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
    recordCount: Number(manifest.data()?.recordCount || 0),
    structuredBytes: Number(manifest.data()?.structuredBytes || 0),
    manifestRevision: Number(manifest.data()?.manifestRevision || 0),
  });
  return {
    sessionId,
    authorizationToken,
    expiresAt: expiresAt.toDate().toISOString(),
    recordCount: Number(manifest.data()?.recordCount || 0),
    structuredBytes: Number(manifest.data()?.structuredBytes || 0),
    manifestRevision: Number(manifest.data()?.manifestRevision || 0),
  };
}

async function getRestorePlan(request) {
  const uid = request.auth?.uid || '';
  const organizationId = cleanToken(request.data?.organizationId);
  const deviceId = cleanToken(request.data?.deviceId);
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!organizationId || !deviceId) {
    throw new HttpsError('invalid-argument', 'Invalid restore plan request.');
  }
  const db = getFirestore();
  const [member, device, manifest] = await Promise.all([
    db.doc(`orgs/${organizationId}/members/${uid}`).get(),
    db.doc(`users/${uid}/devices/${deviceId}`).get(),
    db.doc(`orgs/${organizationId}/syncManifests/${uid}`).get(),
  ]);
  if (member.data()?.status !== 'active' ||
      device.data()?.uid !== uid || device.data()?.deviceId !== deviceId ||
      device.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'An active account and registered device are required.',
    );
  }
  return {
    recordCount: Number(manifest.data()?.recordCount || 0),
    structuredBytes: Number(manifest.data()?.structuredBytes || 0),
    manifestRevision: Number(manifest.data()?.manifestRevision || 0),
    mediaBytes: 0,
  };
}

async function beginRestoreSession(request) {
  const input = restoreSessionInput(request);
  const db = getFirestore();
  const sessionRef = db.doc(
    `orgs/${input.organizationId}/restoreSessions/${input.sessionId}`,
  );
  const session = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    const data = requireUsableSession(snapshot, input, {
      allowedStates: new Set(['authorized', 'active', 'paused']),
    });
    if (data.status === 'active') return data;
    const now = Timestamp.now();
    transaction.update(sessionRef, {
      status: 'active',
      startedAt: data.startedAt || now,
      resumedAt: now,
      updatedAt: now,
      lifecycleRevision: Number(data.lifecycleRevision || 0) + 1,
    });
    return {...data, status: 'active'};
  });
  return restoreSessionResult(input.sessionId, session, 'active');
}

async function updateRestoreSession(request) {
  const input = restoreSessionInput(request);
  const action = String(request.data?.action || '').trim();
  if (!['pause', 'cancel', 'complete'].includes(action)) {
    throw new HttpsError('invalid-argument', 'Invalid restore session action.');
  }
  const completedItems = Number(request.data?.completedItems ?? 0);
  const completedBytes = Number(request.data?.completedBytes ?? 0);
  if (!Number.isInteger(completedItems) || completedItems < 0 ||
      completedItems > 10000000 ||
      !Number.isInteger(completedBytes) || completedBytes < 0 ||
      completedBytes > 1024 * 1024 * 1024 * 1024) {
    throw new HttpsError('invalid-argument', 'Invalid restore progress totals.');
  }
  const nextStatus = action === 'pause'
    ? 'paused'
    : action === 'cancel'
      ? 'cancelled'
      : 'completed';
  const db = getFirestore();
  const sessionRef = db.doc(
    `orgs/${input.organizationId}/restoreSessions/${input.sessionId}`,
  );
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    const existing = snapshot.data();
    if (existing?.status === nextStatus &&
        existing.completedItems === completedItems &&
        existing.completedBytes === completedBytes) {
      requireUsableSession(snapshot, input, {
        allowedStates: new Set([nextStatus]),
        allowExpiredTerminal: true,
      });
      return existing;
    }
    const allowedStates = action === 'cancel'
      ? new Set(['authorized', 'active', 'paused'])
      : new Set(['active', 'paused']);
    const data = requireUsableSession(snapshot, input, {allowedStates});
    const previousItems = Number(data.completedItems || 0);
    const previousBytes = Number(data.completedBytes || 0);
    if (completedItems < previousItems || completedBytes < previousBytes) {
      throw new HttpsError(
        'failed-precondition',
        'Restore progress cannot move backward.',
      );
    }
    const now = Timestamp.now();
    transaction.update(sessionRef, {
      status: nextStatus,
      completedItems,
      completedBytes,
      updatedAt: now,
      lifecycleRevision: Number(data.lifecycleRevision || 0) + 1,
      [`${nextStatus}At`]: now,
    });
    return {...data, status: nextStatus, completedItems, completedBytes};
  });
  return restoreSessionResult(input.sessionId, result, nextStatus);
}

async function fetchRestoreRecordPage(request) {
  const input = restoreSessionInput(request);
  const afterRecordKey = String(request.data?.afterRecordKey || '').trim();
  const limit = Number(request.data?.limit || 0);
  if ((afterRecordKey && !SHA256.test(afterRecordKey)) ||
      !Number.isInteger(limit) || limit < 1 || limit > 10) {
    throw new HttpsError('invalid-argument', 'Invalid restore page request.');
  }
  const db = getFirestore();
  const sessionRef = db.doc(
    `orgs/${input.organizationId}/restoreSessions/${input.sessionId}`,
  );
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    requireUsableSession(snapshot, input, {
      allowedStates: new Set(['active']),
    });
  });
  let query = db.collection(`orgs/${input.organizationId}/records`)
    .where('createdByUid', '==', input.uid)
    .where('privateToOwner', '==', true)
    .orderBy('recordKey')
    .limit(limit);
  if (afterRecordKey) query = query.startAfter(afterRecordKey);
  const snapshot = await query.get();
  return {
    documents: snapshot.docs.map((document) => ({
      id: document.id,
      data: document.data(),
    })),
  };
}

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
      !/^[a-f0-9]{64}$/.test(authorizationToken)) {
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

module.exports = {buildRestoreAuthorizationFunctions};
