const {HttpsError} = require('firebase-functions/v2/https');
const {requireManifestMatchesSnapshot} = require('./durable_manifest');

const SNAPSHOT_SCHEMA = 'maintainiac_restore_snapshot_v1';
const MAX_RECORDS = 10000;
const MAX_STRUCTURED_BYTES = 64 * 1024 * 1024;
const MAX_CHUNK_BYTES = 700 * 1024;
const MAX_CHUNKS = 400;

async function createRestoreSnapshot({
  db,
  sessionRef,
  organizationId,
  uid,
  sessionData,
  expiresAt,
  expectedManifest,
}) {
  const source = await db.collection(`orgs/${organizationId}/records`)
    .where('createdByUid', '==', uid)
    .where('privateToOwner', '==', true)
    .orderBy('recordKey')
    .limit(MAX_RECORDS + 1)
    .get();
  if (source.size > MAX_RECORDS) {
    throw new HttpsError(
      'resource-exhausted',
      'Restore contains too many records for one bounded session.',
    );
  }
  const chunks = [];
  let current = [];
  let currentBytes = 2;
  let structuredBytes = 0;
  for (const document of source.docs) {
    const entry = {id: document.id, data: document.data()};
    const entryBytes = Buffer.byteLength(JSON.stringify(entry), 'utf8');
    const dataBytes = Buffer.byteLength(JSON.stringify(entry.data), 'utf8');
    if (entryBytes > MAX_CHUNK_BYTES) {
      throw new HttpsError(
        'resource-exhausted',
        'A cloud record is too large for safe restore.',
      );
    }
    if (current.length && currentBytes + entryBytes + 1 > MAX_CHUNK_BYTES) {
      chunks.push(current);
      current = [];
      currentBytes = 2;
    }
    current.push(entry);
    currentBytes += entryBytes + (current.length > 1 ? 1 : 0);
    structuredBytes += dataBytes;
    if (structuredBytes > MAX_STRUCTURED_BYTES) {
      throw new HttpsError(
        'resource-exhausted',
        'Restore exceeds the bounded structured-data allowance.',
      );
    }
  }
  if (current.length) chunks.push(current);
  if (chunks.length > MAX_CHUNKS) {
    throw new HttpsError(
      'resource-exhausted',
      'Restore requires too many snapshot chunks.',
    );
  }
  requireManifestMatchesSnapshot(expectedManifest, {
    recordCount: source.size,
    structuredBytes,
  });

  const batch = db.batch();
  batch.create(sessionRef, {
    ...sessionData,
    snapshotSchema: SNAPSHOT_SCHEMA,
    snapshotChunkCount: chunks.length,
    recordCount: source.size,
    structuredBytes,
  });
  chunks.forEach((documents, index) => {
    const reference = sessionRef.collection('snapshotChunks')
      .doc(String(index).padStart(6, '0'));
    batch.create(reference, {
      schema: SNAPSHOT_SCHEMA,
      uid,
      orgId: organizationId,
      sessionId: sessionRef.id,
      chunkIndex: index,
      firstRecordKey: documents[0].id,
      lastRecordKey: documents[documents.length - 1].id,
      recordCount: documents.length,
      expiresAt,
      documents,
    });
  });
  await batch.commit();
  return {recordCount: source.size, structuredBytes, chunkCount: chunks.length};
}

async function fetchRestoreSnapshotPage({
  sessionRef,
  session,
  afterRecordKey,
  limit,
}) {
  if (session.snapshotSchema !== SNAPSHOT_SCHEMA) {
    throw new HttpsError(
      'failed-precondition',
      'Restore snapshot is unavailable.',
    );
  }
  let query = sessionRef.collection('snapshotChunks');
  query = afterRecordKey
    ? query.where('lastRecordKey', '>', afterRecordKey)
      .orderBy('lastRecordKey')
      .limit(1)
    : query.orderBy('chunkIndex').limit(1);
  const snapshot = await query.get();
  if (snapshot.empty) return [];
  const chunk = snapshot.docs[0].data();
  if (chunk.schema !== SNAPSHOT_SCHEMA ||
      chunk.uid !== session.uid ||
      chunk.orgId !== session.orgId ||
      chunk.sessionId !== sessionRef.id ||
      !Array.isArray(chunk.documents)) {
    throw new HttpsError('data-loss', 'Restore snapshot is corrupt.');
  }
  return chunk.documents
    .filter((document) => !afterRecordKey || document.id > afterRecordKey)
    .slice(0, limit);
}

async function deleteRestoreSnapshot({db, sessionRef}) {
  const snapshot = await sessionRef.collection('snapshotChunks').get();
  if (snapshot.empty) return;
  const batch = db.batch();
  snapshot.docs.forEach((document) => batch.delete(document.ref));
  await batch.commit();
}

module.exports = {
  createRestoreSnapshot,
  deleteRestoreSnapshot,
  fetchRestoreSnapshotPage,
};
