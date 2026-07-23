const {randomBytes} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineInt} = require('firebase-functions/params');
const {
  createRestoreSnapshot,
  deleteRestoreSnapshot,
  fetchRestoreSnapshotPage,
} = require('./restore_snapshot');
const {
  SHA256,
  cleanToken,
  requireCurrentRestorePrincipal,
  requireUsableSession,
  restoreSessionInput,
  restoreSessionResult,
  sha256,
  validAuthorizationLifetime,
} = require('./restore_session_contract');
const {reserveRestoreAdmission} = require('./restore_admission');
const {loadDurableManifest} = require('./durable_manifest');

const RESTORE_MODES = new Set(['full', 'smart', 'recordsOnly']);
const snapshotRetentionSeconds = defineInt(
  'RESTORE_SNAPSHOT_RETENTION_SECONDS',
  {default: 7 * 24 * 60 * 60},
);

function buildRestoreAuthorizationFunctions({enforceAppCheck}) {
  return {
    issueRestoreAuthorization: onCall({enforceAppCheck}, issueRestoreAuthorization),
    refreshRestoreAuthorization: onCall(
      {enforceAppCheck},
      refreshRestoreAuthorization,
    ),
    beginRestoreSession: onCall({enforceAppCheck}, beginRestoreSession),
    updateRestoreSession: onCall({enforceAppCheck}, updateRestoreSession),
    fetchRestoreRecordPage: onCall({enforceAppCheck}, fetchRestoreRecordPage),
    getRestorePlan: onCall({enforceAppCheck}, getRestorePlan),
  };
}

async function issueRestoreAuthorization(request) {
  const uid = request.auth?.uid || '';
  const organizationId = cleanToken(request.data?.organizationId);
  const deviceId = cleanToken(request.data?.deviceId);
  const requestId = cleanToken(request.data?.requestId);
  const mode = String(request.data?.mode || '').trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!organizationId || !deviceId || !requestId ||
      !RESTORE_MODES.has(mode)) {
    throw new HttpsError('invalid-argument', 'Invalid restore request.');
  }
  const lifetimeSeconds = validAuthorizationLifetime();
  const retentionSeconds = snapshotRetentionSeconds.value();
  if (!Number.isInteger(retentionSeconds) ||
      retentionSeconds < 24 * 60 * 60 ||
      retentionSeconds > 30 * 24 * 60 * 60) {
    throw new HttpsError(
      'failed-precondition',
      'Restore snapshot retention configuration is invalid.',
    );
  }
  const db = getFirestore();
  const sessionId = `restore_${sha256(
    `${uid}\u0000${organizationId}\u0000${deviceId}\u0000${requestId}`,
  ).substring(0, 48)}`;
  const sessionRef = db.doc(
    `orgs/${organizationId}/restoreSessions/${sessionId}`,
  );
  const [member, device, existingSession] = await Promise.all([
    db.doc(`orgs/${organizationId}/members/${uid}`).get(),
    db.doc(`users/${uid}/devices/${deviceId}`).get(),
    sessionRef.get(),
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
  const manifest = await loadDurableManifest({db, organizationId, uid});
  const authorizationToken = randomBytes(32).toString('hex');
  if (existingSession.exists &&
      existingSession.data()?.status !== 'preparing') {
    return rotateExistingIssue({
      db,
      sessionRef,
      uid,
      organizationId,
      deviceId,
      requestId,
      mode,
      authorizationToken,
      lifetimeSeconds,
    });
  }
  const admission = await reserveRestoreAdmission({
    uid,
    organizationId,
    deviceId,
    requestId,
    sessionId,
    estimatedBytes: manifest.structuredBytes,
  });
  if (!admission.mayBuild) {
    throw new HttpsError(
      'aborted',
      'This restore is already being prepared. Retry shortly.',
    );
  }
  const authorizationTokenHash = sha256(authorizationToken);
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(
    now.toMillis() + lifetimeSeconds * 1000,
  );
  const snapshotExpiresAt = Timestamp.fromMillis(
    now.toMillis() + retentionSeconds * 1000,
  );
  let snapshot;
  try {
    snapshot = await createRestoreSnapshot({
      db,
      sessionRef,
      organizationId,
      uid,
      expiresAt: snapshotExpiresAt,
      sessionData: {
        uid,
        orgId: organizationId,
        deviceId,
        requestId,
        mode,
        status: 'authorized',
        authorizationTokenHash,
        appCheckProtected: true,
        createdAt: now,
        expiresAt,
        snapshotExpiresAt,
        authorizationRevision: 1,
        manifestRevision: manifest.manifestRevision,
      },
      expectedManifest: manifest,
    });
  } catch (error) {
    if (!isAlreadyExists(error)) throw error;
    return rotateExistingIssue({
      db,
      sessionRef,
      uid,
      organizationId,
      deviceId,
      requestId,
      mode,
      authorizationToken,
      lifetimeSeconds,
    });
  }
  return {
    sessionId,
    authorizationToken,
    expiresAt: expiresAt.toDate().toISOString(),
    recordCount: snapshot.recordCount,
    structuredBytes: snapshot.structuredBytes,
    manifestRevision: manifest.manifestRevision,
  };
}

async function rotateExistingIssue({
  db,
  sessionRef,
  uid,
  organizationId,
  deviceId,
  requestId,
  mode,
  authorizationToken,
  lifetimeSeconds,
}) {
  const input = {uid, organizationId, deviceId};
  const data = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    const current = snapshot.data();
    if (!snapshot.exists || current.uid !== uid ||
        current.orgId !== organizationId || current.deviceId !== deviceId ||
        current.requestId !== requestId || current.mode !== mode ||
        !new Set(['authorized', 'active', 'paused']).has(current.status) ||
        (current.snapshotExpiresAt?.toMillis?.() || 0) <= Date.now()) {
      throw new HttpsError(
        'failed-precondition',
        'Restore request ID can no longer be reused.',
      );
    }
    const now = Timestamp.now();
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + lifetimeSeconds * 1000,
    );
    transaction.update(sessionRef, {
      authorizationTokenHash: sha256(authorizationToken),
      expiresAt,
      refreshedAt: now,
      updatedAt: now,
      authorizationRevision:
        Number(current.authorizationRevision || 1) + 1,
    });
    return {...current, expiresAt};
  });
  return {
    sessionId: sessionRef.id,
    authorizationToken,
    expiresAt: data.expiresAt.toDate().toISOString(),
    recordCount: Number(data.recordCount || 0),
    structuredBytes: Number(data.structuredBytes || 0),
    manifestRevision: Number(data.manifestRevision || 0),
  };
}

function isAlreadyExists(error) {
  return error?.code === 6 || error?.code === 'already-exists' ||
    String(error?.message || '').includes('ALREADY_EXISTS');
}

async function refreshRestoreAuthorization(request) {
  const uid = request.auth?.uid || '';
  const organizationId = cleanToken(request.data?.organizationId);
  const deviceId = cleanToken(request.data?.deviceId);
  const sessionId = cleanToken(request.data?.sessionId);
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!organizationId || !deviceId || !sessionId) {
    throw new HttpsError('invalid-argument', 'Invalid restore refresh request.');
  }
  const lifetimeSeconds = validAuthorizationLifetime();
  const authorizationToken = randomBytes(32).toString('hex');
  const db = getFirestore();
  const input = {uid, organizationId, deviceId, sessionId};
  const sessionRef = db.doc(
    `orgs/${organizationId}/restoreSessions/${sessionId}`,
  );
  const refreshed = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    const data = snapshot.data();
    const snapshotExpiresAt = data?.snapshotExpiresAt?.toMillis?.() || 0;
    if (!snapshot.exists || data.uid !== uid || data.orgId !== organizationId ||
        data.deviceId !== deviceId ||
        !new Set(['authorized', 'active', 'paused']).has(data.status) ||
        snapshotExpiresAt <= Date.now()) {
      throw new HttpsError(
        'permission-denied',
        'Restore session can no longer be refreshed.',
      );
    }
    const now = Timestamp.now();
    const expiresAt = Timestamp.fromMillis(
      now.toMillis() + lifetimeSeconds * 1000,
    );
    transaction.update(sessionRef, {
      authorizationTokenHash: sha256(authorizationToken),
      expiresAt,
      refreshedAt: now,
      updatedAt: now,
      authorizationRevision: Number(data.authorizationRevision || 1) + 1,
    });
    return {...data, expiresAt};
  });
  return {
    sessionId,
    authorizationToken,
    expiresAt: refreshed.expiresAt.toDate().toISOString(),
    recordCount: Number(refreshed.recordCount || 0),
    structuredBytes: Number(refreshed.structuredBytes || 0),
    manifestRevision: Number(refreshed.manifestRevision || 0),
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
  const [member, device] = await Promise.all([
    db.doc(`orgs/${organizationId}/members/${uid}`).get(),
    db.doc(`users/${uid}/devices/${deviceId}`).get(),
  ]);
  if (member.data()?.status !== 'active' ||
      device.data()?.uid !== uid || device.data()?.deviceId !== deviceId ||
      device.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'An active account and registered device are required.',
    );
  }
  const manifest = await loadDurableManifest({db, organizationId, uid});
  return {
    recordCount: manifest.recordCount,
    structuredBytes: manifest.structuredBytes,
    manifestRevision: manifest.manifestRevision,
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
  if (!['progress', 'pause', 'cancel', 'complete'].includes(action)) {
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
  const nextStatus = action === 'progress'
    ? 'active'
    : action === 'pause'
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
      : action === 'progress'
        ? new Set(['active'])
      : new Set(['active', 'paused']);
    const data = requireUsableSession(snapshot, input, {allowedStates});
    const previousItems = Number(data.completedItems || 0);
    const previousBytes = Number(data.completedBytes || 0);
    const plannedItems = Number(data.recordCount || 0);
    const plannedBytes = Number(data.structuredBytes || 0);
    if (completedItems < previousItems || completedBytes < previousBytes ||
        completedItems > plannedItems || completedBytes > plannedBytes ||
        (action === 'complete' &&
          (completedItems !== plannedItems || completedBytes !== plannedBytes))) {
      throw new HttpsError(
        'failed-precondition',
        'Restore progress is outside the authorized plan.',
      );
    }
    const now = Timestamp.now();
    const update = {
      status: nextStatus,
      completedItems,
      completedBytes,
      updatedAt: now,
      lifecycleRevision: Number(data.lifecycleRevision || 0) + 1,
    };
    if (action !== 'progress') update[`${nextStatus}At`] = now;
    transaction.update(sessionRef, update);
    return {...data, status: nextStatus, completedItems, completedBytes};
  });
  if (action === 'cancel' || action === 'complete') {
    await deleteRestoreSnapshot({db, sessionRef});
  }
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
  const session = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(sessionRef);
    await requireCurrentRestorePrincipal(transaction, input, db);
    return requireUsableSession(snapshot, input, {
      allowedStates: new Set(['active']),
    });
  });
  return {
    documents: await fetchRestoreSnapshotPage({
      sessionRef,
      session,
      afterRecordKey,
      limit,
    }),
  };
}

module.exports = {buildRestoreAuthorizationFunctions};
