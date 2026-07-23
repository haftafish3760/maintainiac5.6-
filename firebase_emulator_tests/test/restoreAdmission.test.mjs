import assert from 'node:assert/strict';
import {after, before, describe, test} from 'node:test';

import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc} from 'firebase/firestore';

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

describe('restore admission protection', () => {
  test('new sessions are bounded while exact retries reuse snapshots', async () => {
    const identity = await createIdentity();
    await seedPrincipal(identity.uid);
    const firstInput = request('restore-admission-a');
    const first = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      firstInput,
    );
    const retry = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      firstInput,
    );
    assert.equal(retry.sessionId, first.sessionId);

    await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      request('restore-admission-b'),
    );
    await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      request('restore-admission-c'),
    );
    const exhausted = await callFunctionError(
      'issueRestoreAuthorization',
      identity.token,
      request('restore-admission-d'),
    );
    assert.equal(exhausted.status, 429);
    assert.equal(exhausted.body?.error?.status, 'RESOURCE_EXHAUSTED');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const usage = await getDoc(doc(
        context.firestore(),
        `users/${identity.uid}/restoreUsage/rolling30Days`,
      ));
      assert.equal(usage.data()?.attempts?.length, 3);
    });

    const clientDb = testEnv.authenticatedContext(identity.uid).firestore();
    await assert.rejects(setDoc(
      doc(clientDb, `users/${identity.uid}/restoreUsage/rolling30Days`),
      {attempts: []},
    ));
  });
});

function request(requestId) {
  return {
    organizationId: 'orgRestoreAdmission',
    deviceId: 'restoreDevice',
    mode: 'recordsOnly',
    requestId,
  };
}

async function seedPrincipal(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `orgs/orgRestoreAdmission/members/${uid}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${uid}/devices/restoreDevice`), {
      uid,
      deviceId: 'restoreDevice',
      status: 'active',
    });
    await setDoc(
      doc(db, `orgs/orgRestoreAdmission/syncManifests/${uid}`),
      {
        schema: 'maintainiac_sync_manifest_v1',
        uid,
        orgId: 'orgRestoreAdmission',
        recordCount: 0,
        structuredBytes: 0,
        manifestRevision: 1,
      },
    );
  });
}

async function createIdentity() {
  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/' +
      'accounts:signUp?key=demo-key',
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email: `restore-admission-${Date.now()}@example.test`,
        password: 'emulator-only-password',
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  return {uid: body.localId, token: body.idToken};
}
