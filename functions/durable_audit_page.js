const {createHash} = require('node:crypto');
const {getFirestore} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {reserveHostedSync} = require('./hosted_plans');
const {appendAuditChain, auditChainFor, emptyAuditChainSha256} =
  require('./audit_chain');

const TOKEN = /^[A-Za-z0-9_.-]{1,160}$/;
const SHA256 = /^[a-f0-9]{64}$/;
const MAX_EVENTS_PER_PAGE = 250;
const MAX_AUDIT_EVENTS = 2000;
const STAGE_SCHEMA = 'maintainiac_durable_audit_stage_v1';

function buildDurableAuditPageFunctions({enforceAppCheck}) {
  return {
    appendDurableAuditPage: onCall({enforceAppCheck}, appendDurableAuditPage),
  };
}

async function appendDurableAuditPage(request) {
  const uid = request.auth?.uid || '';
  const input = parseInput(request.data);
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  const db = getFirestore();
  const registeredDevice = await db.doc(
    `users/${uid}/devices/${input.deviceId}`,
  ).get();
  if (registeredDevice.data()?.uid !== uid ||
      registeredDevice.data()?.deviceId !== input.deviceId ||
      registeredDevice.data()?.status !== 'active') {
    throw new HttpsError(
      'permission-denied',
      'An active registered device is required for cloud backup.',
    );
  }
  const reservation = await reserveHostedSync({
    auth: request.auth,
    data: {
      attemptId: input.attemptId,
      batchSha256: sha256(canonicalJson(input)),
      batchBytes: Buffer.byteLength(JSON.stringify(input), 'utf8'),
    },
  });
  const stage = await db.runTransaction(async (transaction) => {
    const memberRef = db.doc(`orgs/${input.organizationId}/members/${uid}`);
    const deviceRef = db.doc(`users/${uid}/devices/${input.deviceId}`);
    const rootRef = db.doc(`orgs/${input.organizationId}/records/${input.recordKey}`);
    const stageRef = db.doc(
      `orgs/${input.organizationId}/durableAuditStages/${input.recordKey}`,
    );
    const [member, device, root, existing] = await Promise.all([
      transaction.get(memberRef),
      transaction.get(deviceRef),
      transaction.get(rootRef),
      transaction.get(stageRef),
    ]);
    if (member.data()?.status !== 'active') {
      throw new HttpsError(
        'permission-denied',
        'An active organization membership is required.',
      );
    }
    if (device.data()?.uid !== uid || device.data()?.deviceId !== input.deviceId ||
        device.data()?.status !== 'active') {
      throw new HttpsError(
        'permission-denied',
        'The registered device is no longer active.',
      );
    }
    const prior = stageFrom(root.data(), existing.data(), uid, input.recordKey);
    const requestedLastOrdinal = input.firstOrdinal + input.events.length - 1;
    if (prior.targetEventCount === input.targetEventCount &&
        prior.targetChainSha256 === input.targetChainSha256 &&
        requestedLastOrdinal <= prior.archivedEventCount) {
      return {...prior, replayed: true};
    }
    if (input.targetEventCount < prior.archivedEventCount ||
        input.firstOrdinal !== prior.archivedEventCount + 1 ||
        input.previousChainSha256 !== prior.chainSha256) {
      throw new HttpsError(
        'failed-precondition',
        'Audit page does not continue the server checkpoint.',
        {reason: 'audit_checkpoint_conflict'},
      );
    }
    if (requestedLastOrdinal > input.targetEventCount) {
      invalidInput();
    }
    let chainSha256 = prior.chainSha256;
    for (let index = 0; index < input.events.length; index += 1) {
      const ordinal = input.firstOrdinal + index;
      const previousChainSha256 = chainSha256;
      chainSha256 = appendAuditChain({
        previousSha256: previousChainSha256,
        ordinal,
        event: input.events[index],
      });
      transaction.create(
        db.doc(
          `orgs/${input.organizationId}/auditEvents/` +
          `${input.recordKey}_${String(ordinal).padStart(12, '0')}`,
        ),
        {
          schema: 'maintainiac_durable_audit_event_v1',
          recordKey: input.recordKey,
          ownerUid: uid,
          deviceId: input.deviceId,
          ordinal,
          event: input.events[index],
          previousChainSha256,
          chainSha256,
          createdAt: auditOccurredAt(input.events[index]),
        },
      );
    }
    const archivedEventCount = requestedLastOrdinal;
    const isComplete = archivedEventCount === input.targetEventCount;
    if (isComplete && chainSha256 !== input.targetChainSha256) {
      throw new HttpsError(
        'failed-precondition',
        'Audit pages do not match their target chain.',
        {reason: 'audit_chain_conflict'},
      );
    }
    const next = {
      schema: STAGE_SCHEMA,
      recordKey: input.recordKey,
      ownerUid: uid,
      lastDeviceId: input.deviceId,
      archivedEventCount,
      chainSha256,
      targetEventCount: input.targetEventCount,
      targetChainSha256: input.targetChainSha256,
      completed: isComplete,
    };
    transaction.set(stageRef, next, {merge: false});
    return next;
  });
  return {...reservation, ...stage};
}

function parseInput(data) {
  const input = {
    attemptId: String(data?.attemptId || '').trim(),
    deviceId: String(data?.deviceId || '').trim(),
    organizationId: String(data?.organizationId || '').trim(),
    recordKey: String(data?.recordKey || '').trim(),
    targetEventCount: Number(data?.targetEventCount),
    targetChainSha256: String(data?.targetChainSha256 || '').trim(),
    firstOrdinal: Number(data?.firstOrdinal),
    previousChainSha256: String(data?.previousChainSha256 || '').trim(),
    events: data?.events,
  };
  if (!TOKEN.test(input.attemptId) || !SHA256.test(input.deviceId) ||
      !TOKEN.test(input.organizationId) ||
      !SHA256.test(input.recordKey) || !Number.isInteger(input.targetEventCount) ||
      input.targetEventCount < 1 || input.targetEventCount > MAX_AUDIT_EVENTS ||
      !SHA256.test(input.targetChainSha256) ||
      !Number.isInteger(input.firstOrdinal) || input.firstOrdinal < 1 ||
      !SHA256.test(input.previousChainSha256) || !Array.isArray(input.events) ||
      input.events.length < 1 || input.events.length > MAX_EVENTS_PER_PAGE ||
      input.events.some((event) => typeof event !== 'string' ||
        event.trim().length === 0 || event.length > 512)) {
    invalidInput();
  }
  return input;
}

function stageFrom(root, stage, uid, recordKey) {
  if (stage != null) {
    if (stage.schema !== STAGE_SCHEMA || stage.recordKey !== recordKey ||
        stage.ownerUid !== uid || !Number.isInteger(stage.archivedEventCount) ||
        stage.archivedEventCount < 0 || stage.archivedEventCount > MAX_AUDIT_EVENTS ||
        !SHA256.test(stage.chainSha256)) {
      throw new HttpsError('data-loss', 'Audit checkpoint needs recovery.');
    }
    return stage;
  }
  const rootEvents = root?.auditEvents;
  if (rootEvents == null) {
    return {archivedEventCount: 0, chainSha256: emptyAuditChainSha256()};
  }
  if (!Array.isArray(rootEvents) || root.createdByUid !== uid ||
      rootEvents.length > MAX_AUDIT_EVENTS) {
    throw new HttpsError('data-loss', 'Durable record audit history is invalid.');
  }
  return auditChainFor(rootEvents);
}

function auditOccurredAt(event) {
  const timestamp = String(event).slice(0, 24);
  return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3,6})?Z$/.test(timestamp) &&
    Number.isFinite(Date.parse(timestamp)) ? timestamp : new Date().toISOString();
}

function invalidInput() {
  throw new HttpsError('invalid-argument', 'Invalid durable audit page.');
}

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (value != null && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

module.exports = {appendDurableAuditPage, buildDurableAuditPageFunctions};
