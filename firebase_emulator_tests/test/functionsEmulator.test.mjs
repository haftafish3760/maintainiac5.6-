import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { after, before, describe, test } from 'node:test';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
  storageHost,
  storagePort,
} from './emulatorGuard.mjs';
import {
  callableUrl,
  callFunction,
  callFunctionError,
} from './callableTestClient.mjs';
import {
  mutateRestoreRecordsAfterAuthorization,
  seedRestoreRecordsAndManifest,
} from './restoreSnapshotFixtures.mjs';

const callableNames = [
  'issueExpenseProofUploadGrant',
  'finalizeExpenseProofUpload',
  'registerRestoreDevice',
  'revokeRestoreDevice',
  'issueRestoreAuthorization',
  'refreshRestoreAuthorization',
  'beginRestoreSession',
  'updateRestoreSession',
  'getHostedUsageGrant',
  'reserveHostedSync',
  'commitDurableRecordBatch',
  'bootstrapPersonalWorkspace',
  'requestHostedAccountCreation',
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
    await seedHostedPlan(identity.uid);
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const quota = await getDoc(
        doc(context.firestore(), `orgs/orgLifecycleA/storageQuotas/${identity.uid}`),
      );
      assert.equal(quota.data()?.storageReservedBytes, proofBytes.byteLength);
      assert.equal(quota.data()?.storageUsedBytes, 0);
    });

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
      assert.equal(quota.data()?.storageReservedBytes, 0);
      assert.equal(quota.data()?.storageLimitBytes, 100 * 1024 * 1024);
      assert.equal(quota.data()?.planId, 'freeConfigurable');
      assert.equal(storedGrant.data()?.status, 'finalized');
      assert.equal(storedGrant.data()?.receiptId, receiptId);
    });
  });

  test('expired upload grants keep abandoned bytes reserved', async () => {
    const identity = await createEmulatorIdentity();
    await seedMember(identity.uid);
    await seedHostedPlan(identity.uid);
    const requestedBytes = 20 * 1024 * 1024;
    for (let index = 0; index < 5; index += 1) {
      const grant = await callFunction(
        'issueExpenseProofUploadGrant',
        identity.token,
        {
          organizationId: 'orgLifecycleA',
          proofId: `abandonedProof${index}`,
          requestedBytes,
        },
      );
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(
          doc(context.firestore(), `orgs/orgLifecycleA/uploadGrants/${grant.grantId}`),
          {status: 'expired'},
          {merge: true},
        );
      });
    }
    const blocked = await callFunctionError(
      'issueExpenseProofUploadGrant',
      identity.token,
      {
        organizationId: 'orgLifecycleA',
        proofId: 'abandonedProofBlocked',
        requestedBytes: 1024,
      },
    );
    assert.equal(blocked.status, 429);
    assert.equal(blocked.body?.error?.status, 'RESOURCE_EXHAUSTED');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const quota = await getDoc(
        doc(context.firestore(), `orgs/orgLifecycleA/storageQuotas/${identity.uid}`),
      );
      assert.equal(quota.data()?.storageUsedBytes, 0);
      assert.equal(quota.data()?.storageReservedBytes, 100 * 1024 * 1024);
    });
  });

  test('restore authorization binds account, registered device, and one-time token', async () => {
    const identity = await createEmulatorIdentity();
    await seedMember(identity.uid);
    const installationIdHash = 'c'.repeat(64);
    const registered = await callFunction('registerRestoreDevice', identity.token, {
      deviceId: installationIdHash,
      installationIdHash,
      platform: 'android',
      appVersion: '1.0.0',
    });
    assert.equal(registered.deviceId, installationIdHash);
    assert.equal(registered.registrationRevision, 1);
    await seedRestoreRecordsAndManifest(testEnv, identity.uid);
    const restorePlan = await waitForRestorePlan(identity.token, {
      organizationId: 'orgLifecycleA',
      deviceId: installationIdHash,
    }, 2);
    assert.equal(restorePlan.recordCount, 2);
    assert.ok(restorePlan.structuredBytes > 0);

    const authorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId: 'orgLifecycleA',
        deviceId: installationIdHash,
        mode: 'smart',
        requestId: 'restore-request-a',
      },
    );
    const retriedAuthorization = await callFunction(
      'issueRestoreAuthorization',
      identity.token,
      {
        organizationId: 'orgLifecycleA',
        deviceId: installationIdHash,
        mode: 'smart',
        requestId: 'restore-request-a',
      },
    );
    assert.match(authorization.sessionId, /^restore_[a-f0-9]{48}$/);
    assert.match(authorization.authorizationToken, /^[a-f0-9]{64}$/);
    assert.equal(authorization.recordCount, restorePlan.recordCount);
    assert.equal(authorization.structuredBytes, restorePlan.structuredBytes);
    assert.equal(retriedAuthorization.sessionId, authorization.sessionId);
    assert.notEqual(
      retriedAuthorization.authorizationToken,
      authorization.authorizationToken,
    );
    authorization.authorizationToken = retriedAuthorization.authorizationToken;
    await mutateRestoreRecordsAfterAuthorization(testEnv, identity.uid);

    let sessionInput = {
      organizationId: 'orgLifecycleA',
      deviceId: installationIdHash,
      sessionId: authorization.sessionId,
      authorizationToken: authorization.authorizationToken,
    };
    const badToken = await callFunctionError(
      'beginRestoreSession',
      identity.token,
      {...sessionInput, authorizationToken: '0'.repeat(64)},
    );
    assert.equal(badToken.status, 403);
    const refreshed = await callFunction(
      'refreshRestoreAuthorization',
      identity.token,
      sessionInput,
    );
    const rotatedToken = await callFunctionError(
      'beginRestoreSession',
      identity.token,
      sessionInput,
    );
    assert.equal(rotatedToken.status, 403);
    sessionInput = {
      ...sessionInput,
      authorizationToken: refreshed.authorizationToken,
    };
    const started = await callFunction(
      'beginRestoreSession',
      identity.token,
      sessionInput,
    );
    assert.equal(started.status, 'active');
    const restorePage = await callFunction(
      'fetchRestoreRecordPage',
      identity.token,
      {...sessionInput, limit: 10},
    );
    assert.equal(restorePage.documents.length, 2);
    assert.equal(restorePage.documents[0].data.createdByUid, identity.uid);
    assert.equal(restorePage.documents[0].data.recordPayload.value, '3');
    assert.equal(
      restorePage.documents.some((document) =>
        document.data.recordPayload.value === 'added-after-authorization'),
      false,
    );
    const badPageToken = await callFunctionError(
      'fetchRestoreRecordPage',
      identity.token,
      {...sessionInput, authorizationToken: '0'.repeat(64), limit: 1},
    );
    assert.equal(badPageToken.status, 403);
    const paused = await callFunction(
      'updateRestoreSession',
      identity.token,
      {
        ...sessionInput,
        action: 'progress',
        completedItems: 1,
        completedBytes: Math.floor(authorization.structuredBytes / 2),
      },
    );
    assert.equal(paused.status, 'active');
    const actuallyPaused = await callFunction(
      'updateRestoreSession',
      identity.token,
      {
        ...sessionInput,
        action: 'pause',
        completedItems: 1,
        completedBytes: Math.floor(authorization.structuredBytes / 2),
      },
    );
    assert.equal(actuallyPaused.status, 'paused');
    const progressWhilePaused = await callFunctionError(
      'updateRestoreSession',
      identity.token,
      {
        ...sessionInput,
        action: 'progress',
        completedItems: 1,
        completedBytes: Math.floor(authorization.structuredBytes / 2),
      },
    );
    assert.equal(progressWhilePaused.status, 403);
    const resumed = await callFunction(
      'beginRestoreSession',
      identity.token,
      sessionInput,
    );
    assert.equal(resumed.status, 'active');
    const completed = await callFunction(
      'updateRestoreSession',
      identity.token,
      {
        ...sessionInput,
        action: 'complete',
        completedItems: authorization.recordCount,
        completedBytes: authorization.structuredBytes,
      },
    );
    const completionRetry = await callFunction(
      'updateRestoreSession',
      identity.token,
      {
        ...sessionInput,
        action: 'complete',
        completedItems: authorization.recordCount,
        completedBytes: authorization.structuredBytes,
      },
    );
    assert.deepEqual(completionRetry, completed);
    assert.equal(completed.status, 'completed');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const session = await getDoc(
        doc(
          db,
          `orgs/orgLifecycleA/restoreSessions/${authorization.sessionId}`,
        ),
      );
      const device = await getDoc(
        doc(db, `users/${identity.uid}/devices/${installationIdHash}`),
      );
      const expectedHash = createHash('sha256')
        .update(sessionInput.authorizationToken)
        .digest('hex');
      assert.equal(device.data()?.uid, identity.uid);
      assert.equal(session.data()?.uid, identity.uid);
      assert.equal(session.data()?.mode, 'smart');
      assert.equal(session.data()?.status, 'completed');
      assert.equal(session.data()?.completedItems, authorization.recordCount);
      assert.equal(session.data()?.authorizationTokenHash, expectedHash);
      assert.equal(session.data()?.authorizationToken, undefined);
      const snapshotChunks = await getDocs(
        collection(
          db,
          `orgs/orgLifecycleA/restoreSessions/${authorization.sessionId}/snapshotChunks`,
        ),
      );
      assert.equal(snapshotChunks.empty, true);
    });

    const rebound = await callFunctionError(
      'registerRestoreDevice',
      identity.token,
      {
        deviceId: installationIdHash,
        installationIdHash: 'd'.repeat(64),
        platform: 'android',
        appVersion: '1.0.0',
      },
    );
    assert.equal(rebound.status, 400);
    assert.equal(rebound.body?.error?.status, 'INVALID_ARGUMENT');

    const outsider = await createEmulatorIdentity();
    const denied = await callFunctionError(
      'issueRestoreAuthorization',
      outsider.token,
      {
        organizationId: 'orgLifecycleA',
        deviceId: installationIdHash,
        mode: 'smart',
        requestId: 'outsider-restore-request',
      },
    );
    assert.equal(denied.status, 403);
    assert.equal(denied.body?.error?.status, 'PERMISSION_DENIED');
  });

  test('device registration is idempotent and revocation is permanent', async () => {
    const identity = await createEmulatorIdentity();
    await seedMember(identity.uid);
    const installationIdHash = 'e'.repeat(64);
    const registration = {
      deviceId: installationIdHash,
      installationIdHash,
      platform: 'ios',
      appVersion: '1.0.0',
    };
    const first = await callFunction(
      'registerRestoreDevice', identity.token, registration,
    );
    const retry = await callFunction(
      'registerRestoreDevice', identity.token, registration,
    );
    assert.equal(first.registrationRevision, 1);
    assert.equal(retry.registrationRevision, 1);

    const revoked = await callFunction(
      'revokeRestoreDevice', identity.token, {deviceId: installationIdHash},
    );
    const revokeRetry = await callFunction(
      'revokeRestoreDevice', identity.token, {deviceId: installationIdHash},
    );
    assert.equal(revoked.status, 'revoked');
    assert.equal(revoked.registrationRevision, 2);
    assert.equal(revokeRetry.registrationRevision, 2);

    const denied = await callFunctionError(
      'registerRestoreDevice', identity.token, registration,
    );
    assert.equal(denied.status, 403);
    assert.equal(denied.body?.error?.status, 'PERMISSION_DENIED');
  });

});

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

async function seedHostedPlan(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `users/${uid}/entitlements/current`), {
      uid,
      planId: 'freeConfigurable',
      status: 'active',
    });
    await setDoc(doc(db, 'hostedPlans/freeConfigurable'), {
      status: 'active',
      displayName: 'Free configurable test plan',
      storageQuotaBytes: 100 * 1024 * 1024,
      dailySyncLimit: 4,
      immediateSyncAllowed: false,
      policyVersion: 7,
      downloadAllowanceBytes: 25 * 1024 * 1024,
    });
  });
}

async function waitForRestorePlan(token, data, expectedCount) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const plan = await callFunction('getRestorePlan', token, data);
    if (plan.recordCount === expectedCount) return plan;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error('Timed out waiting for the durable restore manifest.');
}
