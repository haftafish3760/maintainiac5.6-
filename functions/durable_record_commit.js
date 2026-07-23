const {createHash} = require('node:crypto');
const {getFirestore} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {reserveHostedSync} = require('./hosted_plans');

const SHA256 = /^[a-f0-9]{64}$/;
const TOKEN = /^[A-Za-z0-9_.-]{1,160}$/;
const PATH = /^orgs\/([A-Za-z0-9_.-]{1,160})\/records\/([a-f0-9]{64})$/;
const MAX_DOCUMENTS = 20;
const MAX_DOCUMENT_BYTES = 768 * 1024;
const MAX_BATCH_BYTES = 2 * 1024 * 1024;
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
    data: {attemptId, batchSha256},
  });
  const db = getFirestore();
  const memberRef = db.doc(`orgs/${validated.organizationId}/members/${uid}`);
  const writtenCount = await db.runTransaction(async (transaction) => {
    const member = await transaction.get(memberRef);
    if (member.data()?.status !== 'active') {
      throw new HttpsError(
        'permission-denied',
        'An active organization membership is required.',
      );
    }
    const references = validated.documents.map((document) =>
      db.doc(document.path));
    const existing = await Promise.all(
      references.map((reference) => transaction.get(reference)),
    );
    let writes = 0;
    for (let index = 0; index < validated.documents.length; index += 1) {
      const incoming = validated.documents[index].data;
      const current = existing[index].data();
      if (current != null) {
        validateRevisionAdvance(incoming, current);
        if (canonicalJson(incoming) === canonicalJson(current)) continue;
      }
      transaction.set(references[index], incoming, {merge: false});
      writes += 1;
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
        typeof data.module !== 'string' || data.module.length < 1 ||
        data.module.length > 80 || typeof data.localRecordId !== 'string' ||
        data.localRecordId.length < 1 || data.localRecordId.length > 160 ||
        !Number.isInteger(data.recordSchemaVersion) ||
        data.recordSchemaVersion < 1 || !SHA256.test(data.contentSha256) ||
        !Number.isInteger(data.localRevision) || data.localRevision < 1 ||
        !['active', 'deleted'].includes(data.recordState) ||
        !validDate(data.createdAt) || !validDate(data.updatedAt) ||
        !Array.isArray(data.auditEvents) || data.auditEvents.length > 2000 ||
        !isPlainObject(data.recordPayload) || containsBlockedKey(data) ||
        (data.recordState === 'active' && data.deletedAt !== null) ||
        (data.recordState === 'deleted' && !validDate(data.deletedAt))) {
      invalidBatch();
    }
    const bytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
    if (bytes > MAX_DOCUMENT_BYTES) invalidBatch();
    totalBytes += bytes;
    if (totalBytes > MAX_BATCH_BYTES) invalidBatch();
    return {path, data};
  });
  return {organizationId, documents: validated};
}

function validateRevisionAdvance(incoming, current) {
  if (current.schema !== 'maintainiac_durable_record_v1' ||
      incoming.recordKey !== current.recordKey ||
      incoming.module !== current.module ||
      incoming.localRecordId !== current.localRecordId ||
      incoming.accountScopeId !== current.accountScopeId ||
      incoming.recordSchemaVersion !== current.recordSchemaVersion ||
      incoming.createdAt !== current.createdAt ||
      !Number.isInteger(current.localRevision) ||
      incoming.localRevision < current.localRevision ||
      (incoming.localRevision === current.localRevision &&
        canonicalJson(incoming) !== canonicalJson(current))) {
    throw new HttpsError(
      'failed-precondition',
      'Durable record revision conflicts with the cloud record.',
    );
  }
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
  return typeof value === 'string' && Number.isFinite(Date.parse(value));
}

function invalidBatch() {
  throw new HttpsError('invalid-argument', 'Unsafe durable record batch.');
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

module.exports = {buildDurableRecordCommitFunctions};
