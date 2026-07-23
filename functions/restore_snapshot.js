const {HttpsError} = require('firebase-functions/v2/https');
const {
  parseDurableManifest,
  requireManifestMatchesSnapshot,
} = require('./durable_manifest');
const {validateStoredDurableDocument} = require('./durable_record_commit');

const SNAPSHOT_SCHEMA = 'maintainiac_restore_snapshot_v1';
const MAX_RECORDS = 100000;
const QUERY_PAGE_SIZE = 500;
const MAX_STRUCTURED_BYTES = 64 * 1024 * 1024;
// A valid durable record may use up to 768 KiB before snapshot wrapper
// metadata. Keep the snapshot chunk below Firestore's 1 MiB document limit
// while still allowing every record accepted by the commit boundary.
const MAX_CHUNK_BYTES = 900 * 1024;
const MAX_CHUNKS = 400;
const MAX_BATCH_BYTES = 8 * 1024 * 1024;
const MAX_BATCH_WRITES = 450;

async function createRestoreSnapshot({
  db,
  sessionRef,
  organizationId,
  uid,
  sessionData,
  expiresAt,
  expectedManifest,
}) {
  await prepareSnapshotSession({
    db,
    sessionRef,
    sessionData,
    expectedManifest,
  });
  const writer = snapshotChunkWriter({
    db,
    sessionRef,
    organizationId,
    uid,
    expiresAt,
  });
  let current = [];
  let currentBytes = 2;
  let structuredBytes = 0;
  let recordCount = 0;
  let lastDocument;
  while (true) {
    let query = db.collection(`orgs/${organizationId}/records`)
      .where('createdByUid', '==', uid)
      .where('privateToOwner', '==', true)
      .orderBy('recordKey')
      .limit(QUERY_PAGE_SIZE);
    if (lastDocument) query = query.startAfter(lastDocument);
    const page = await query.get();
    for (const document of page.docs) {
      const data = document.data();
      try {
        validateStoredDurableDocument({
          organizationId,
          uid,
          documentId: document.id,
          data,
        });
      } catch (_) {
        throw new HttpsError(
          'data-loss',
          'A cloud record needs recovery before restore can continue.',
        );
      }
      const entry = {id: document.id, data};
      const entryBytes = Buffer.byteLength(JSON.stringify(entry), 'utf8');
      const dataBytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
      if (entryBytes > MAX_CHUNK_BYTES) {
        throw new HttpsError(
          'resource-exhausted',
          'A cloud record is too large for safe restore.',
        );
      }
      if (current.length && currentBytes + entryBytes + 1 > MAX_CHUNK_BYTES) {
        await writer.add(current);
        current = [];
        currentBytes = 2;
      }
      current.push(entry);
      currentBytes += entryBytes + (current.length > 1 ? 1 : 0);
      structuredBytes += dataBytes;
      recordCount += 1;
      if (recordCount > MAX_RECORDS) {
        throw new HttpsError(
          'resource-exhausted',
          'Restore contains too many records for one bounded session.',
        );
      }
      if (structuredBytes > MAX_STRUCTURED_BYTES) {
        throw new HttpsError(
          'resource-exhausted',
          'Restore exceeds the bounded structured-data allowance.',
        );
      }
    }
    if (page.empty || page.size < QUERY_PAGE_SIZE) break;
    lastDocument = page.docs[page.docs.length - 1];
  }
  if (current.length) await writer.add(current);
  await writer.flush();
  requireManifestMatchesSnapshot(expectedManifest, {
    recordCount,
    structuredBytes,
  });

  const finalSession = {
    ...sessionData,
    snapshotSchema: SNAPSHOT_SCHEMA,
    snapshotChunkCount: writer.chunkCount,
    recordCount,
    structuredBytes,
  };
  await finalizeSnapshotSession({
    db,
    sessionRef,
    organizationId,
    uid,
    expectedManifest,
    finalSession,
  });
  return {recordCount, structuredBytes, chunkCount: writer.chunkCount};
}

async function prepareSnapshotSession({
  db,
  sessionRef,
  sessionData,
  expectedManifest,
}) {
  const existing = await sessionRef.get();
  if (existing.exists) {
    const current = existing.data();
    if (current.status !== 'preparing' ||
        current.uid !== sessionData.uid || current.orgId !== sessionData.orgId ||
        current.deviceId !== sessionData.deviceId ||
        current.requestId !== sessionData.requestId ||
        current.mode !== sessionData.mode) {
      throw new HttpsError(
        'already-exists',
        'Restore snapshot already exists.',
      );
    }
    await deleteRestoreSnapshot({db, sessionRef});
  }
  await sessionRef.set({
    ...sessionData,
    status: 'preparing',
    snapshotSchema: null,
    snapshotChunkCount: 0,
    recordCount: expectedManifest.recordCount,
    structuredBytes: expectedManifest.structuredBytes,
  }, {merge: false});
}

function snapshotChunkWriter({
  db,
  sessionRef,
  organizationId,
  uid,
  expiresAt,
}) {
  let batch = db.batch();
  let batchBytes = 0;
  let batchWrites = 0;
  let chunkCount = 0;
  async function flush() {
    if (batchWrites === 0) return;
    await batch.commit();
    batch = db.batch();
    batchBytes = 0;
    batchWrites = 0;
  }
  async function add(documents) {
    if (chunkCount >= MAX_CHUNKS) {
      throw new HttpsError(
        'resource-exhausted',
        'Restore requires too many snapshot chunks.',
      );
    }
    const index = chunkCount;
    const reference = sessionRef.collection('snapshotChunks')
      .doc(String(index).padStart(6, '0'));
    const data = {
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
    };
    const documentBytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
    if (batchWrites > 0 &&
        (batchWrites >= MAX_BATCH_WRITES ||
          batchBytes + documentBytes > MAX_BATCH_BYTES)) {
      await flush();
    }
    batch.set(reference, data, {merge: false});
    batchBytes += documentBytes;
    batchWrites += 1;
    chunkCount += 1;
  }
  return {add, flush, get chunkCount() { return chunkCount; }};
}

async function finalizeSnapshotSession({
  db,
  sessionRef,
  organizationId,
  uid,
  expectedManifest,
  finalSession,
}) {
  const manifestRef = db.doc(`orgs/${organizationId}/syncManifests/${uid}`);
  await db.runTransaction(async (transaction) => {
    const [session, manifest] = await Promise.all([
      transaction.get(sessionRef),
      transaction.get(manifestRef),
    ]);
    const currentManifest = parseDurableManifest(manifest.data(), {
      organizationId,
      uid,
      allowMissing: !manifest.exists,
    });
    if (session.data()?.status !== 'preparing' ||
        currentManifest.recordCount !== expectedManifest.recordCount ||
        currentManifest.structuredBytes !== expectedManifest.structuredBytes ||
        currentManifest.manifestRevision !== expectedManifest.manifestRevision) {
      throw new HttpsError(
        'aborted',
        'Cloud records changed while the restore snapshot was prepared.',
      );
    }
    transaction.set(sessionRef, finalSession, {merge: false});
  });
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
      .limit(limit)
    : query.orderBy('chunkIndex').limit(limit);
  const snapshot = await query.get();
  if (snapshot.empty) return [];
  const documents = [];
  for (const snapshotDocument of snapshot.docs) {
    const chunk = snapshotDocument.data();
    if (chunk.schema !== SNAPSHOT_SCHEMA ||
        chunk.uid !== session.uid ||
        chunk.orgId !== session.orgId ||
        chunk.sessionId !== sessionRef.id ||
        !Array.isArray(chunk.documents)) {
      throw new HttpsError('data-loss', 'Restore snapshot is corrupt.');
    }
    for (const document of chunk.documents) {
      if ((!afterRecordKey || document.id > afterRecordKey) &&
          documents.length < limit) {
        documents.push(document);
      }
    }
    if (documents.length >= limit) break;
  }
  return documents;
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
