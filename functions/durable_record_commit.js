const {createHash} = require('node:crypto');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {reserveHostedSync} = require('./hosted_plans');
const {parseDurableManifest} = require('./durable_manifest');

const SHA256 = /^[a-f0-9]{64}$/;
const TOKEN = /^[A-Za-z0-9_.-]{1,160}$/;
const PATH = /^orgs\/([A-Za-z0-9_.-]{1,160})\/records\/([a-f0-9]{64})$/;
const MAX_DOCUMENTS = 20;
const MAX_DOCUMENT_BYTES = 768 * 1024;
const MAX_BATCH_BYTES = 2 * 1024 * 1024;
const MAX_VALUE_DEPTH = 32;
const MAX_VALUE_COUNT = 100000;
const REQUIRED_KEYS = new Set([
  'schema', 'recordKey', 'module', 'localRecordId', 'accountScopeId',
  'recordSchemaVersion', 'contentSha256', 'privateToOwner', 'orgId',
  'createdByUid', 'updatedByUid', 'localRevision', 'recordState',
  'createdAt', 'updatedAt', 'deletedAt', 'auditEvents', 'recordPayload',
]);
const BLOCKED_KEYS = new Set([
  'rawReceiptText', 'rawOcrText', 'ocrText', 'importedText', 'localPath',
  'sourceLocalPath', 'vin', 'VIN', 'vehicleIdentificationNumber',
  'licensePlate', 'plate', 'plateNumber', 'tagNumber', 'passengerName',
  'passengerPhone', 'passengerAddress', 'patientName', 'patientPhone',
  'patientAddress', 'medicalRecordNumber', 'diagnosis', 'dateOfBirth', 'dob',
]);

function buildDurableRecordCommitFunctions({enforceAppCheck}) {
  return {
    commitDurableRecordBatch: onCall(
      {enforceAppCheck},
      commitDurableRecordBatch,
    ),
  };
}

async function commitDurableRecordBatch(request) {
  const uid = request.auth?.uid || '';
  const attemptId = String(request.data?.attemptId || '').trim();
  const documents = request.data?.documents;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
  if (!TOKEN.test(attemptId) || !Array.isArray(documents) ||
      documents.length < 1 || documents.length > MAX_DOCUMENTS) {
    throw new HttpsError('invalid-argument', 'Invalid durable record batch.');
  }
  const validated = validateDocuments(uid, documents);
  const batchSha256 = sha256(canonicalJson(documents));
  const reservation = await reserveHostedSync({
    auth: request.auth,
    data: {
      attemptId,
      batchSha256,
      batchBytes: validated.totalBytes,
    },
  });
  const db = getFirestore();
  const memberRef = db.doc(`orgs/${validated.organizationId}/members/${uid}`);
  const manifestRef = db.doc(
    `orgs/${validated.organizationId}/syncManifests/${uid}`,
  );
  const writtenCount = await db.runTransaction(async (transaction) => {
    const references = validated.documents.map((document) =>
      db.doc(document.path));
    const snapshots = await Promise.all([
      transaction.get(memberRef),
      transaction.get(manifestRef),
      ...references.map((reference) => transaction.get(reference)),
    ]);
    const member = snapshots[0];
    const manifest = snapshots[1];
    if (member.data()?.status !== 'active') {
      throw new HttpsError(
        'permission-denied',
        'An active organization membership is required.',
      );
    }
    const existing = snapshots.slice(2);
    let writes = 0;
    let recordCountDelta = 0;
    let structuredBytesDelta = 0;
    for (let index = 0; index < validated.documents.length; index += 1) {
      const incoming = validated.documents[index].data;
      const current = existing[index].data();
      if (current != null) {
        validateRevisionAdvance(
          validated.documents[index].path,
          incoming,
          current,
        );
        if (canonicalJson(incoming) === canonicalJson(current)) continue;
        structuredBytesDelta -= encodedBytes(current);
      } else {
        recordCountDelta += 1;
      }
      structuredBytesDelta += encodedBytes(incoming);
      transaction.set(references[index], incoming, {merge: false});
      writes += 1;
    }
    if (writes > 0) {
      const currentManifest = parseDurableManifest(manifest.data(), {
        organizationId: validated.organizationId,
        uid,
        allowMissing: !manifest.exists,
      });
      const recordCount = currentManifest.recordCount + recordCountDelta;
      const structuredBytes =
        currentManifest.structuredBytes + structuredBytesDelta;
      if (recordCount < 0 || structuredBytes < 0 ||
          !Number.isSafeInteger(recordCount) ||
          !Number.isSafeInteger(structuredBytes)) {
        throw new HttpsError(
          'failed-precondition',
          'Durable restore manifest requires reconciliation.',
        );
      }
      transaction.set(manifestRef, {
        schema: 'maintainiac_sync_manifest_v1',
        uid,
        orgId: validated.organizationId,
        recordCount,
        structuredBytes,
        manifestRevision: currentManifest.manifestRevision + 1,
        updatedAt: Timestamp.now(),
      }, {merge: false});
    }
    return writes;
  });
  return {
    ...reservation,
    attemptedCount: validated.documents.length,
    writtenCount,
    batchSha256,
  };
}

function encodedBytes(data) {
  return Buffer.byteLength(JSON.stringify(data), 'utf8');
}

function validateDocuments(uid, documents) {
  let organizationId = '';
  let totalBytes = 0;
  const seenPaths = new Set();
  const validated = documents.map((document) => {
    const path = String(document?.path || '').trim();
    const match = PATH.exec(path);
    const data = document?.data;
    if (!match || !isPlainObject(data) || seenPaths.has(path)) invalidBatch();
    seenPaths.add(path);
    organizationId ||= match[1];
    if (organizationId !== match[1]) invalidBatch();
    const keys = Object.keys(data);
    if (keys.length !== REQUIRED_KEYS.size ||
        keys.some((key) => !REQUIRED_KEYS.has(key)) ||
        data.schema !== 'maintainiac_durable_record_v1' ||
        data.recordKey !== match[2] || data.orgId !== organizationId ||
        data.accountScopeId !== `${organizationId}.${uid}` ||
        data.createdByUid !== uid || data.updatedByUid !== uid ||
        data.privateToOwner !== true ||
        !validLocalKey(data.module, 80) ||
        !validLocalKey(data.localRecordId, 160) ||
        !Number.isInteger(data.recordSchemaVersion) ||
        data.recordSchemaVersion < 1 || !SHA256.test(data.contentSha256) ||
        !Number.isInteger(data.localRevision) || data.localRevision < 1 ||
        !['active', 'deleted'].includes(data.recordState) ||
        !validDate(data.createdAt) || !validDate(data.updatedAt) ||
        !validAuditEvents(data.auditEvents) ||
        !validPortableValue(data.recordPayload) || containsBlockedKey(data) ||
        (data.recordState === 'active' && data.deletedAt !== null) ||
        (data.recordState === 'deleted' && !validDate(data.deletedAt)) ||
        !validLifecycleOrder(data) ||
        data.recordKey !== expectedRecordKey(data) ||
        data.contentSha256 !== expectedContentSha256(data)) {
      invalidBatch();
    }
    const bytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
    if (bytes > MAX_DOCUMENT_BYTES) invalidBatch();
    totalBytes += bytes;
    if (totalBytes > MAX_BATCH_BYTES) invalidBatch();
    return {path, data};
  });
  return {organizationId, documents: validated, totalBytes};
}

function validateRevisionAdvance(path, incoming, current) {
  if (current.schema !== 'maintainiac_durable_record_v1' ||
      incoming.recordKey !== current.recordKey ||
      incoming.module !== current.module ||
      incoming.localRecordId !== current.localRecordId ||
      incoming.accountScopeId !== current.accountScopeId ||
      incoming.recordSchemaVersion !== current.recordSchemaVersion ||
      incoming.createdAt !== current.createdAt ||
      !Number.isInteger(current.localRevision) ||
      incoming.localRevision < current.localRevision ||
      (incoming.localRevision > current.localRevision &&
        Date.parse(incoming.updatedAt) <= Date.parse(current.updatedAt)) ||
      (incoming.localRevision === current.localRevision &&
        canonicalJson(incoming) !== canonicalJson(current))) {
    throw new HttpsError(
      'failed-precondition',
      'Durable record revision conflicts with the cloud record.',
      {
        reason: 'revision_conflict',
        path,
        localRevision: incoming.localRevision,
        remoteRevision: current.localRevision,
      },
    );
  }
}

function validLocalKey(value, maximumLength) {
  return typeof value === 'string' && value.length >= 1 &&
    value.length <= maximumLength && value === value.trim() &&
    !value.includes(':');
}

function validAuditEvents(value) {
  return Array.isArray(value) && value.length <= 2000 &&
    value.every((event) => typeof event === 'string' &&
      event.trim().length >= 1 && event.length <= 512);
}

function validPortableValue(root) {
  const state = {count: 0};
  function visit(value, depth) {
    state.count += 1;
    if (state.count > MAX_VALUE_COUNT || depth > MAX_VALUE_DEPTH) return false;
    if (value === null || typeof value === 'string' ||
        typeof value === 'boolean') return true;
    if (typeof value === 'number') {
      return Number.isFinite(value) &&
        (!Number.isInteger(value) || Number.isSafeInteger(value));
    }
    if (Array.isArray(value)) {
      return value.every((item) => visit(item, depth + 1));
    }
    if (!isPlainObject(value)) return false;
    return Object.values(value).every((item) => visit(item, depth + 1));
  }
  return isPlainObject(root) && visit(root, 0);
}

function validLifecycleOrder(data) {
  const created = Date.parse(data.createdAt);
  const updated = Date.parse(data.updatedAt);
  if (updated < created) return false;
  if (data.deletedAt === null) return true;
  const deleted = Date.parse(data.deletedAt);
  return deleted >= created && deleted <= updated;
}

function expectedRecordKey(data) {
  return sha256(`${data.module}\u0000${data.localRecordId}`);
}

function expectedContentSha256(data) {
  return sha256(canonicalJson({
    accountScopeId: data.accountScopeId,
    record: {
      module: data.module,
      id: data.localRecordId,
      payload: data.recordPayload,
      lifecycle: {
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        revision: data.localRevision,
        state: data.recordState,
        deletedAt: data.deletedAt,
        auditEvents: data.auditEvents,
      },
    },
  }));
}

function containsBlockedKey(value) {
  if (Array.isArray(value)) return value.some(containsBlockedKey);
  if (!isPlainObject(value)) return false;
  return Object.entries(value).some(([key, nested]) =>
    BLOCKED_KEYS.has(key) || containsBlockedKey(nested));
}

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (isPlainObject(value)) {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function isPlainObject(value) {
  return value != null && typeof value === 'object' &&
    !Array.isArray(value) && Object.getPrototypeOf(value) === Object.prototype;
}

function validDate(value) {
  return typeof value === 'string' &&
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3,6})?Z$/.test(value) &&
    Number.isFinite(Date.parse(value));
}

function invalidBatch() {
  throw new HttpsError('invalid-argument', 'Unsafe durable record batch.');
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

module.exports = {buildDurableRecordCommitFunctions};
