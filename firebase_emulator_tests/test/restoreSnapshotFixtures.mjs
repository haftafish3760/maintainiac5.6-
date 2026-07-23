import {doc, setDoc} from 'firebase/firestore';

export async function seedRestoreRecordsAndManifest(testEnv, uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    let structuredBytes = 0;
    for (const recordKey of ['3'.repeat(64), '4'.repeat(64)]) {
      const data = durableRecord(uid, recordKey, recordKey.substring(0, 1));
      structuredBytes += Buffer.byteLength(JSON.stringify(data), 'utf8');
      await setDoc(doc(db, `orgs/orgLifecycleA/records/${recordKey}`), data);
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
      doc(db, `orgs/orgLifecycleA/records/${'3'.repeat(64)}`),
      durableRecord(uid, '3'.repeat(64), 'mutated-after-authorization'),
    );
    const addedKey = '5'.repeat(64);
    await setDoc(
      doc(db, `orgs/orgLifecycleA/records/${addedKey}`),
      durableRecord(uid, addedKey, 'added-after-authorization'),
    );
  });
}

function durableRecord(uid, recordKey, value) {
  return {
    schema: 'maintainiac_durable_record_v1',
    recordKey,
    orgId: 'orgLifecycleA',
    createdByUid: uid,
    updatedByUid: uid,
    privateToOwner: true,
    recordPayload: {value},
  };
}
