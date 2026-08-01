import {createHash} from 'node:crypto';
import {doc, setDoc} from 'firebase/firestore';

export async function seedRestoreRecordsAndManifest(testEnv, uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    let structuredBytes = 0;
    for (const localRecordId of ['restore-3', 'restore-4']) {
      const data = durableRecord(uid, localRecordId, localRecordId.slice(-1));
      structuredBytes += Buffer.byteLength(JSON.stringify(data), 'utf8');
      await setDoc(
        doc(db, `orgs/orgLifecycleA/records/${data.recordKey}`),
        data,
      );
    }
    await setDoc(doc(db, `orgs/orgLifecycleA/syncManifests/${uid}`), {
      schema: 'maintainiac_sync_manifest_v1',
      uid,
      orgId: 'orgLifecycleA',
      recordCount: 2,
      structuredBytes,
      manifestRevision: 1,
    });
  });
}

export async function mutateRestoreRecordsAfterAuthorization(testEnv, uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(
      doc(
        db,
        `orgs/orgLifecycleA/records/${recordKey('settings', 'restore-3')}`,
      ),
      durableRecord(uid, 'restore-3', 'mutated-after-authorization'),
    );
    const added = durableRecord(uid, 'restore-5', 'added-after-authorization');
    await setDoc(
      doc(db, `orgs/orgLifecycleA/records/${added.recordKey}`),
      added,
    );
  });
}

export function durableRecord(
  uid,
  localRecordId,
  value,
  organizationId = 'orgLifecycleA',
  auditEvents = [],
) {
  const data = {
    schema: 'maintainiac_durable_record_v1',
    recordKey: recordKey('settings', localRecordId),
    module: 'settings',
    localRecordId,
    accountScopeId: `${organizationId}.${uid}`,
    recordSchemaVersion: 1,
    contentSha256: '',
    orgId: organizationId,
    createdByUid: uid,
    updatedByUid: uid,
    privateToOwner: true,
    localRevision: 1,
    recordState: 'active',
    createdAt: '2026-07-22T00:00:00.000Z',
    updatedAt: '2026-07-22T00:00:00.000Z',
    deletedAt: null,
    auditEvents,
    recordPayload: {value},
  };
  data.contentSha256 = contentHash(data);
  return data;
}

function contentHash(data) {
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

function recordKey(module, id) {
  return sha256(`${module}\u0000${id}`);
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
