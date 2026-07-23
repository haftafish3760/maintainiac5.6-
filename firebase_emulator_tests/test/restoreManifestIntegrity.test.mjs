import assert from 'node:assert/strict';
import {after, before, describe, test} from 'node:test';

import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, setDoc} from 'firebase/firestore';

import {callFunction, callFunctionError} from './callableTestClient.mjs';
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
  const recordKey = '6'.repeat(64);
  const data = {
    schema: 'maintainiac_durable_record_v1',
    recordKey,
    orgId: organizationId,
    createdByUid: uid,
    updatedByUid: uid,
    privateToOwner: true,
    recordPayload: {value: 'preserved'},
  };
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `orgs/${organizationId}/records/${recordKey}`),
      data,
    );
  });
  return data;
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
