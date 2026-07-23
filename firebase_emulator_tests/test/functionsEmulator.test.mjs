import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { after, before, describe, test } from 'node:test';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
  functionsHost,
  functionsPort,
  storageHost,
  storagePort,
} from './emulatorGuard.mjs';

const callableNames = [
  'issueExpenseProofUploadGrant',
  'finalizeExpenseProofUpload',
  'registerRestoreDevice',
  'issueRestoreAuthorization',
];
let testEnv;

before(async () => {
  assertEmulatorOnly();
  testEnv = await initializeTestEnvironment({
    projectId: emulatorProjectId,
    firestore: {host: firestoreHost, port: firestorePort},
    storage: {host: storageHost, port: storagePort},
  });
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

after(async () => {
  await testEnv?.cleanup();
});

describe('Cloud Functions emulator safety', () => {
  test('two bounded unauthenticated calls are rejected locally', async () => {
    assertEmulatorOnly();
    assert.match(callableUrl(callableNames[0]), /^http:\/\/127\.0\.0\.1:5001\//);
    for (const name of callableNames) {
      const response = await fetch(callableUrl(name), {
        method: 'POST',
        headers: {'content-type': 'application/json'},
        body: JSON.stringify({data: {}}),
      });
      const body = await response.json();
      assert.ok(response.status >= 400 && response.status < 500);
      assert.ok(body?.error, `${name} must return a callable error`);
      assert.match(
        JSON.stringify(body.error).toLowerCase(),
        /(unauthenticated|app.?check)/,
      );
    }
  });

  test('authenticated proof upload finalizes once and charges quota once', async () => {
    const identity = await createEmulatorIdentity();
    await seedMember(identity.uid);
    const proofBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
    const receiptId = 'receiptLifecycleA';
    const proofId = 'proofLifecycleA';
    const contentSha256 = createHash('sha256').update(proofBytes).digest('hex');

    const grant = await callFunction('issueExpenseProofUploadGrant', identity.token, {
      organizationId: 'orgLifecycleA',
      proofId,
      requestedBytes: proofBytes.byteLength,
    });
    assert.match(grant.grantId, /^[a-f0-9-]{36}$/);
    assert.equal(grant.maxBytes, proofBytes.byteLength);

    const storage = testEnv.authenticatedContext(identity.uid).storage();
    const path = `orgs/orgLifecycleA/proof-uploads/${identity.uid}` +
      `/${grant.grantId}/${proofId}`;
    const uploaded = await uploadBytes(ref(storage, path), proofBytes, {
      contentType: 'image/jpeg',
      customMetadata: {
        orgId: 'orgLifecycleA',
        uid: identity.uid,
        receiptId,
        proofId,
        contentSha256,
      },
    });
    assert.equal(
      uploaded.metadata.bucket,
      emulatorProjectId,
      'the client and Admin SDK must use the same emulator bucket',
    );

    const input = {
      organizationId: 'orgLifecycleA',
      receiptId,
      proofId,
      grantId: grant.grantId,
      contentSha256,
    };
    const first = await callFunction('finalizeExpenseProofUpload', identity.token, input);
    const retry = await callFunction('finalizeExpenseProofUpload', identity.token, input);
    assert.deepEqual(retry, first, 'an exact retry must be idempotent');
    assert.equal(first.status, 'finalized');
    assert.equal(first.byteCount, proofBytes.byteLength);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const quota = await getDoc(
        doc(db, `orgs/orgLifecycleA/storageQuotas/${identity.uid}`),
      );
      const storedGrant = await getDoc(
        doc(db, `orgs/orgLifecycleA/uploadGrants/${grant.grantId}`),
      );
      assert.equal(quota.data()?.storageUsedBytes, proofBytes.byteLength);
      assert.equal(storedGrant.data()?.status, 'finalized');
      assert.equal(storedGrant.data()?.receiptId, receiptId);
    });
  });

  test('restore authorization binds account, registered device, and one-time token', async () => {
    const identity = await createEmulatorIdentity();
    await seedMember(identity.uid);
    const installationIdHash = 'c'.repeat(64);
    const registered = await callFunction('registerRestoreDevice', identity.token, {
      deviceId: 'restoreDeviceA',
      installationIdHash,
      platform: 'android',
      appVersion: '1.0.0',
    });
    assert.equal(registered.deviceId, 'restoreDeviceA');
    assert.equal(registered.registrationRevision, 1);

    const authorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId: 'orgLifecycleA',
        deviceId: 'restoreDeviceA',
        mode: 'smart',
      },
    );
    assert.match(authorization.sessionId, /^[a-f0-9-]{36}$/);
    assert.match(authorization.authorizationToken, /^[a-f0-9]{64}$/);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const session = await getDoc(
        doc(
          db,
          `orgs/orgLifecycleA/restoreSessions/${authorization.sessionId}`,
        ),
      );
      const device = await getDoc(
        doc(db, `users/${identity.uid}/devices/restoreDeviceA`),
      );
      const expectedHash = createHash('sha256')
        .update(authorization.authorizationToken)
        .digest('hex');
      assert.equal(device.data()?.uid, identity.uid);
      assert.equal(session.data()?.uid, identity.uid);
      assert.equal(session.data()?.mode, 'smart');
      assert.equal(session.data()?.authorizationTokenHash, expectedHash);
      assert.equal(session.data()?.authorizationToken, undefined);
    });

    const rebound = await callFunctionError(
      'registerRestoreDevice',
      identity.token,
      {
        deviceId: 'restoreDeviceA',
        installationIdHash: 'd'.repeat(64),
        platform: 'android',
        appVersion: '1.0.0',
      },
    );
    assert.equal(rebound.status, 400);
    assert.equal(rebound.body?.error?.status, 'FAILED_PRECONDITION');

    const outsider = await createEmulatorIdentity();
    const denied = await callFunctionError(
      'issueRestoreAuthorization',
      outsider.token,
      {
        organizationId: 'orgLifecycleA',
        deviceId: 'restoreDeviceA',
        mode: 'smart',
      },
    );
    assert.equal(denied.status, 403);
    assert.equal(denied.body?.error?.status, 'PERMISSION_DENIED');
  });
});

function callableUrl(name) {
  return `http://${functionsHost}:${functionsPort}/${emulatorProjectId}` +
    `/us-central1/${name}`;
}

async function createEmulatorIdentity() {
  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/' +
      'accounts:signUp?key=demo-key',
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email: `proof-${Date.now()}@example.test`,
        password: 'emulator-only-password',
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  assert.ok(body.localId);
  assert.ok(body.idToken);
  return {uid: body.localId, token: body.idToken};
}

async function seedMember(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `orgs/orgLifecycleA/members/${uid}`), {
      status: 'active',
      role: 'owner',
      permissions: ['addOwnReceipts'],
    });
  });
}

async function callFunction(name, token, data) {
  const result = await callFunctionError(name, token, data);
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.ok(result.body.result, `${name} must return a callable result`);
  return result.body.result;
}

async function callFunctionError(name, token, data) {
  const response = await fetch(callableUrl(name), {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({data}),
  });
  const body = await response.json();
  return {status: response.status, body};
}
