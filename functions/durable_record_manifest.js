const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onDocumentWritten} = require('firebase-functions/v2/firestore');

function buildDurableRecordManifestFunctions() {
  return {
    updateDurableRecordManifest: onDocumentWritten(
      'orgs/{orgId}/records/{recordId}',
      updateDurableRecordManifest,
    ),
  };
}

async function updateDurableRecordManifest(event) {
  const before = event.data?.before;
  const after = event.data?.after;
  const orgId = String(event.params?.orgId || '').trim();
  const beforeData = before?.exists ? before.data() : null;
  const afterData = after?.exists ? after.data() : null;
  const beforeUid = validOwner(beforeData, orgId);
  const afterUid = validOwner(afterData, orgId);
  if (!beforeUid && !afterUid) return;
  const db = getFirestore();
  const deltas = new Map();
  if (beforeUid) addDelta(deltas, beforeUid, -1, -encodedBytes(beforeData));
  if (afterUid) addDelta(deltas, afterUid, 1, encodedBytes(afterData));
  await db.runTransaction(async (transaction) => {
    for (const [uid, delta] of deltas.entries()) {
      const reference = db.doc(`orgs/${orgId}/syncManifests/${uid}`);
      const snapshot = await transaction.get(reference);
      const current = snapshot.data() || {};
      const recordCount = Math.max(
        0,
        Number(current.recordCount || 0) + delta.recordCount,
      );
      const structuredBytes = Math.max(
        0,
        Number(current.structuredBytes || 0) + delta.structuredBytes,
      );
      transaction.set(reference, {
        schema: 'maintainiac_sync_manifest_v1',
        uid,
        orgId,
        recordCount,
        structuredBytes,
        manifestRevision: Number(current.manifestRevision || 0) + 1,
        updatedAt: Timestamp.now(),
      });
    }
  });
}

function validOwner(data, orgId) {
  if (!data || data.schema !== 'maintainiac_durable_record_v1' ||
      data.orgId !== orgId || data.privateToOwner !== true) return '';
  const uid = String(data.createdByUid || '').trim();
  return /^[A-Za-z0-9_.-]{1,160}$/.test(uid) ? uid : '';
}

function encodedBytes(data) {
  return Buffer.byteLength(JSON.stringify(data), 'utf8');
}

function addDelta(deltas, uid, recordCount, structuredBytes) {
  const current = deltas.get(uid) || {recordCount: 0, structuredBytes: 0};
  current.recordCount += recordCount;
  current.structuredBytes += structuredBytes;
  deltas.set(uid, current);
}

module.exports = {buildDurableRecordManifestFunctions};
