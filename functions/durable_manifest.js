const {HttpsError} = require('firebase-functions/v2/https');

const MANIFEST_SCHEMA = 'maintainiac_sync_manifest_v1';

function parseDurableManifest(data, {organizationId, uid, allowMissing}) {
  if (data == null && allowMissing) {
    return {recordCount: 0, structuredBytes: 0, manifestRevision: 0};
  }
  if (data?.schema !== MANIFEST_SCHEMA || data.uid !== uid ||
      data.orgId !== organizationId ||
      !Number.isSafeInteger(data.recordCount) || data.recordCount < 0 ||
      !Number.isSafeInteger(data.structuredBytes) ||
      data.structuredBytes < 0 ||
      !Number.isSafeInteger(data.manifestRevision) ||
      data.manifestRevision < 1) {
    manifestFailure();
  }
  return data;
}

async function loadDurableManifest({db, organizationId, uid}) {
  const reference = db.doc(
    `orgs/${organizationId}/syncManifests/${uid}`,
  );
  const snapshot = await reference.get();
  if (snapshot.exists) {
    return parseDurableManifest(snapshot.data(), {
      organizationId,
      uid,
      allowMissing: false,
    });
  }
  const existingRecord = await db.collection(`orgs/${organizationId}/records`)
    .where('createdByUid', '==', uid)
    .where('privateToOwner', '==', true)
    .limit(1)
    .get();
  if (!existingRecord.empty) manifestFailure();
  return parseDurableManifest(null, {
    organizationId,
    uid,
    allowMissing: true,
  });
}

function requireManifestMatchesSnapshot(manifest, snapshot) {
  if (manifest.recordCount !== snapshot.recordCount ||
      manifest.structuredBytes !== snapshot.structuredBytes) {
    manifestFailure();
  }
}

function manifestFailure() {
  throw new HttpsError(
    'failed-precondition',
    'Durable restore manifest requires reconciliation.',
  );
}

module.exports = {
  loadDurableManifest,
  parseDurableManifest,
  requireManifestMatchesSnapshot,
};
