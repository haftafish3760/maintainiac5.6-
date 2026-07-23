import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {after, before, describe, test} from 'node:test';

import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDocs,
  setDoc,
  writeBatch,
} from 'firebase/firestore';

import {callFunction, callFunctionError} from './callableTestClient.mjs';
import {durableRecord} from './restoreSnapshotFixtures.mjs';
import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
} from './emulatorGuard.mjs';

let testEnv;

before(async () => {
  assertEmulatorOnly();
  testEnv = await initializeTestEnvironment({
    projectId: emulatorProjectId,
    firestore: {host: firestoreHost, port: firestorePort},
  });
  await testEnv.clearFirestore();
});

after(async () => testEnv?.cleanup());

describe('restore manifest integrity', () => {
  test('fresh accounts may restore zero records without a manifest', async () => {
    const identity = await createIdentity('empty');
    await seedPrincipal(identity.uid, 'orgManifestEmpty');
    const plan = await callFunction('getRestorePlan', identity.token, {
      organizationId: 'orgManifestEmpty',
      deviceId: 'restoreDevice',
    });
    assert.deepEqual(plan, {
      recordCount: 0,
      structuredBytes: 0,
      manifestRevision: 0,
      mediaBytes: 0,
    });
  });

  test('records without a manifest fail closed', async () => {
    const identity = await createIdentity('missing');
    const organizationId = 'orgManifestMissing';
    await seedPrincipal(identity.uid, organizationId);
    await seedRecord(identity.uid, organizationId);
    const result = await callFunctionError('getRestorePlan', identity.token, {
      organizationId,
      deviceId: 'restoreDevice',
    });
    assert.equal(result.status, 400);
    assert.equal(result.body?.error?.status, 'FAILED_PRECONDITION');
  });

  test('manifest checks do not disclose another organization', async () => {
    const identity = await createIdentity('outsider');
    const organizationId = 'orgManifestPrivate';
    await seedRecord(identity.uid, organizationId);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), `users/${identity.uid}/devices/device`),
        {
          uid: identity.uid,
          deviceId: 'device',
          status: 'active',
        },
      );
    });
    const result = await callFunctionError('getRestorePlan', identity.token, {
      organizationId,
      deviceId: 'device',
    });
    assert.equal(result.status, 403);
    assert.equal(result.body?.error?.status, 'PERMISSION_DENIED');
  });

  test('authorization rejects manifest totals that drift from records', async () => {
    const identity = await createIdentity('drift');
    const organizationId = 'orgManifestDrift';
    await seedPrincipal(identity.uid, organizationId);
    const data = await seedRecord(identity.uid, organizationId);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(
          context.firestore(),
          `orgs/${organizationId}/syncManifests/${identity.uid}`,
        ),
        {
          schema: 'maintainiac_sync_manifest_v1',
          uid: identity.uid,
          orgId: organizationId,
          recordCount: 2,
          structuredBytes: Buffer.byteLength(JSON.stringify(data), 'utf8'),
          manifestRevision: 1,
        },
      );
    });
    const result = await callFunctionError(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId,
        deviceId: 'restoreDevice',
        mode: 'recordsOnly',
        requestId: 'manifest-drift-request',
      },
    );
    assert.equal(result.status, 400);
    assert.equal(result.body?.error?.status, 'FAILED_PRECONDITION');
  });

  test('large restore snapshots use bounded Firestore commits', async () => {
    const identity = await createIdentity('large');
    const organizationId = 'orgManifestLarge';
    await seedPrincipal(identity.uid, organizationId);
    const structuredBytes = await seedLargeRecordSet(
      identity.uid,
      organizationId,
    );
    await seedManifest(identity.uid, organizationId, 16, structuredBytes);
    const authorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId,
        deviceId: 'restoreDevice',
        mode: 'recordsOnly',
        requestId: 'large-snapshot-request',
      },
    );
    assert.equal(authorization.recordCount, 16);
    assert.equal(authorization.structuredBytes, structuredBytes);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const chunks = await getDocs(collection(
        context.firestore(),
        `orgs/${organizationId}/restoreSessions/` +
          `${authorization.sessionId}/snapshotChunks`,
      ));
      assert.equal(chunks.size, 16);
    });
  });

  test('restore snapshot streams beyond one query page', async () => {
    const identity = await createIdentity('paged');
    const organizationId = 'orgManifestPaged';
    await seedPrincipal(identity.uid, organizationId);
    const structuredBytes = await seedPagedRecordSet(
      identity.uid,
      organizationId,
      525,
    );
    await seedManifest(identity.uid, organizationId, 525, structuredBytes);
    const authorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId,
        deviceId: 'restoreDevice',
        mode: 'recordsOnly',
        requestId: 'paged-snapshot-request',
      },
    );
    assert.equal(authorization.recordCount, 525);
    assert.equal(authorization.structuredBytes, structuredBytes);
  });

  test('corrupt stored records fail before restore authorization', async () => {
    const identity = await createIdentity('corrupt');
    const organizationId = 'orgManifestCorrupt';
    await seedPrincipal(identity.uid, organizationId);
    const data = durableRecord(
      identity.uid,
      'corrupt-record',
      'preserved',
      organizationId,
    );
    data.contentSha256 = 'f'.repeat(64);
    await seedRecordData(data, organizationId);
    const structuredBytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
    await seedManifest(identity.uid, organizationId, 1, structuredBytes);
    const result = await callFunctionError(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId,
        deviceId: 'restoreDevice',
        mode: 'recordsOnly',
        requestId: 'corrupt-snapshot-request',
      },
    );
    assert.equal(result.body?.error?.status, 'DATA_LOSS');
  });

  test('stale preparing snapshots are rebuilt after admission lease', async () => {
    const identity = await createIdentity('resume');
    const organizationId = 'orgManifestResume';
    const requestId = 'resume-snapshot-request';
    await seedPrincipal(identity.uid, organizationId);
    const data = await seedRecord(identity.uid, organizationId);
    const structuredBytes = Buffer.byteLength(JSON.stringify(data), 'utf8');
    await seedManifest(identity.uid, organizationId, 1, structuredBytes);
    const sessionId = restoreSessionId(
      identity.uid,
      organizationId,
      'restoreDevice',
      requestId,
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const sessionPath = `orgs/${organizationId}/restoreSessions/${sessionId}`;
      await setDoc(doc(db, sessionPath), {
        uid: identity.uid,
        orgId: organizationId,
        deviceId: 'restoreDevice',
        requestId,
        mode: 'recordsOnly',
        status: 'preparing',
      });
      await setDoc(doc(db, `${sessionPath}/snapshotChunks/stale`), {
        partial: true,
      });
    });
    const authorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId,
        deviceId: 'restoreDevice',
        mode: 'recordsOnly',
        requestId,
      },
    );
    assert.equal(authorization.sessionId, sessionId);
    assert.equal(authorization.recordCount, 1);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const chunks = await getDocs(collection(
        context.firestore(),
        `orgs/${organizationId}/restoreSessions/${sessionId}/snapshotChunks`,
      ));
      assert.deepEqual(chunks.docs.map((chunk) => chunk.id), ['000000']);
    });
  });
});

async function seedPrincipal(uid, organizationId) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `orgs/${organizationId}/members/${uid}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${uid}/devices/restoreDevice`), {
      uid,
      deviceId: 'restoreDevice',
      status: 'active',
    });
  });
}

async function seedRecord(uid, organizationId) {
  const data = durableRecord(uid, 'single-record', 'preserved', organizationId);
  await seedRecordData(data, organizationId);
  return data;
}

async function seedRecordData(data, organizationId) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        `orgs/${organizationId}/records/${data.recordKey}`,
      ),
      data,
    );
  });
}

async function seedLargeRecordSet(uid, organizationId) {
  let structuredBytes = 0;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    for (let index = 0; index < 16; index += 1) {
      const data = durableRecord(
        uid,
        `large-${index}`,
        String.fromCharCode(65 + index).repeat(600 * 1024),
        organizationId,
      );
      structuredBytes += Buffer.byteLength(JSON.stringify(data), 'utf8');
      await setDoc(
        doc(
          context.firestore(),
          `orgs/${organizationId}/records/${data.recordKey}`,
        ),
        data,
      );
    }
  });
  return structuredBytes;
}

async function seedPagedRecordSet(uid, organizationId, count) {
  let structuredBytes = 0;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    let batch = writeBatch(db);
    let batchWrites = 0;
    for (let index = 0; index < count; index += 1) {
      const data = durableRecord(
        uid,
        `paged-${String(index).padStart(4, '0')}`,
        `value-${index}`,
        organizationId,
      );
      structuredBytes += Buffer.byteLength(JSON.stringify(data), 'utf8');
      batch.set(
        doc(db, `orgs/${organizationId}/records/${data.recordKey}`),
        data,
      );
      batchWrites += 1;
      if (batchWrites === 400) {
        await batch.commit();
        batch = writeBatch(db);
        batchWrites = 0;
      }
    }
    if (batchWrites > 0) await batch.commit();
  });
  return structuredBytes;
}

async function seedManifest(uid, organizationId, recordCount, structuredBytes) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `orgs/${organizationId}/syncManifests/${uid}`),
      {
        schema: 'maintainiac_sync_manifest_v1',
        uid,
        orgId: organizationId,
        recordCount,
        structuredBytes,
        manifestRevision: 1,
      },
    );
  });
}

async function createIdentity(label) {
  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/' +
      'accounts:signUp?key=demo-key',
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email: `restore-manifest-${label}-${Date.now()}@example.test`,
        password: 'emulator-only-password',
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  return {uid: body.localId, token: body.idToken};
}

function restoreSessionId(uid, organizationId, deviceId, requestId) {
  const value = `${uid}\u0000${organizationId}\u0000${deviceId}\u0000${requestId}`;
  const digest = createHash('sha256').update(value).digest('hex');
  return `restore_${digest.substring(0, 48)}`;
}
