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

describe('hosted sync reservations', () => {
  test('one sync opportunity accepts bounded idempotent batches', async () => {
    const identity = await createIdentity();
    await seedHostedPlan(identity.uid);
    const grant = await callFunction('getHostedUsageGrant', identity.token, {});
    assert.equal(grant.dailySyncLimit, 4);

    const first = await reserve(identity.token, 'attempt-1', '1', 100);
    const retry = await reserve(identity.token, 'attempt-1', '1', 100);
    assert.equal(retry.reservationId, first.reservationId);
    assert.equal(retry.used, 1);
    assert.equal(retry.batchCount, 1);

    const secondBatch = await reserve(
      identity.token,
      'attempt-1',
      '2',
      200,
    );
    assert.equal(secondBatch.used, 1);
    assert.equal(secondBatch.batchCount, 2);
    assert.equal(secondBatch.batchBytesUsed, 300);
    await reserve(identity.token, 'attempt-1', '3', 300);

    const tooManyBatches = await callFunctionError(
      'reserveHostedSync',
      identity.token,
      reservationInput('attempt-1', '4', 400),
    );
    assert.equal(tooManyBatches.status, 429);
    const rebound = await callFunctionError(
      'reserveHostedSync',
      identity.token,
      reservationInput('attempt-1', '1', 101),
    );
    assert.equal(rebound.body?.error?.status, 'FAILED_PRECONDITION');

    for (let attempt = 2; attempt <= 4; attempt += 1) {
      const reserved = await reserve(
        identity.token,
        `attempt-${attempt}`,
        String(attempt + 4),
        100,
      );
      assert.equal(reserved.used, attempt);
    }
    const exhausted = await callFunctionError(
      'reserveHostedSync',
      identity.token,
      reservationInput('attempt-5', '9', 100),
    );
    assert.equal(exhausted.status, 429);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const usage = await getDoc(doc(
        context.firestore(),
        `users/${identity.uid}/syncUsage/rolling24Hours`,
      ));
      assert.equal(usage.data()?.attempts?.length, 4);
      assert.equal(usage.data()?.attempts?.[0]?.batches?.length, 3);
    });
  });
});

function reserve(token, attemptId, hashCharacter, batchBytes) {
  return callFunction(
    'reserveHostedSync',
    token,
    reservationInput(attemptId, hashCharacter, batchBytes),
  );
}

function reservationInput(attemptId, hashCharacter, batchBytes) {
  return {
    attemptId,
    batchSha256: hashCharacter.repeat(64),
    batchBytes,
  };
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

async function createIdentity() {
  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/' +
      'accounts:signUp?key=demo-key',
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email: `sync-${Date.now()}@example.test`,
        password: 'emulator-only-password',
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  return {uid: body.localId, token: body.idToken};
}
