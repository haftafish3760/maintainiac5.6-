import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
} from './emulatorGuard.mjs';
import { callFunction } from './callableTestClient.mjs';

let testEnv;

before(async () => {
  assertEmulatorOnly();
  testEnv = await initializeTestEnvironment({
    projectId: emulatorProjectId,
    firestore: {host: firestoreHost, port: firestorePort},
  });
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'hostedPlans/freeConfigurable'), {
      status: 'active',
      displayName: 'Free configurable test plan',
      storageQuotaBytes: 100 * 1024 * 1024,
      dailySyncLimit: 4,
      immediateSyncAllowed: false,
      policyVersion: 1,
      downloadAllowanceBytes: 25 * 1024 * 1024,
    });
  });
});

after(async () => {
  await testEnv?.cleanup();
});

describe('personal workspace bootstrap', () => {
  test('atomically creates one private workspace and initial entitlement', async () => {
    const identity = await createEmulatorIdentity();
    const appInstallationHash = 'a'.repeat(64);

    const first = await callFunction(
      'requestHostedAccountCreation',
      identity.token,
      {appInstallationHash},
    );
    let organizationUpdatedAt;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const snapshot = await getDoc(
        doc(context.firestore(), `orgs/${first.organizationId}`),
      );
      organizationUpdatedAt = snapshot.data()?.updatedAt;
    });
    const retry = await callFunction(
      'requestHostedAccountCreation',
      identity.token,
      {appInstallationHash},
    );

    assert.deepEqual(retry, first, 'exact retries must be idempotent');
    assert.match(first.organizationId, /^personal_[a-f0-9]{32}$/);
    assert.equal(first.ownerUid, identity.uid);
    assert.equal(first.planId, 'freeConfigurable');
    assert.equal(first.installationHash, appInstallationHash);

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const organization = await getDoc(
        doc(db, `orgs/${first.organizationId}`),
      );
      const member = await getDoc(
        doc(db, `orgs/${first.organizationId}/members/${identity.uid}`),
      );
      const entitlement = await getDoc(
        doc(db, `users/${identity.uid}/entitlements/current`),
      );
      const install = await getDoc(
        doc(db, `accountAbuseInstalls/${appInstallationHash}`),
      );
      assert.equal(organization.data()?.ownerUid, identity.uid);
      assert.equal(organization.data()?.organizationKind, 'independent_personal');
      assert.ok(
        organization.data()?.updatedAt.isEqual(
          organizationUpdatedAt,
        ),
        'an exact retry must not rewrite an unchanged workspace',
      );
      assert.equal(member.data()?.role, 'owner');
      assert.equal(member.data()?.status, 'active');
      assert.ok(member.data()?.allowedModules?.includes('records'));
      assert.equal(entitlement.data()?.uid, identity.uid);
      assert.equal(entitlement.data()?.planId, 'freeConfigurable');
      assert.equal(entitlement.data()?.status, 'active');
      assert.equal(entitlement.data()?.initialAppInstallationHash,
        appInstallationHash);
      assert.deepEqual(install.data()?.accountUids, [identity.uid]);
      assert.equal(install.data()?.accountCount, 1);
    });
  });

  test('rejects missing installation evidence before granting free storage', async () => {
    const identity = await createEmulatorIdentity();
    await assert.rejects(
      callFunction('requestHostedAccountCreation', identity.token, {}),
      /valid app installation identity/i,
    );
  });

  test('one installation cannot mint unbounded free entitlements', async () => {
    const appInstallationHash = 'b'.repeat(64);
    const first = await createEmulatorIdentity();
    const second = await createEmulatorIdentity();
    const third = await createEmulatorIdentity();
    await callFunction('requestHostedAccountCreation', first.token, {
      appInstallationHash,
    });
    await callFunction('requestHostedAccountCreation', second.token, {
      appInstallationHash,
    });
    await assert.rejects(
      callFunction('requestHostedAccountCreation', third.token, {
        appInstallationHash,
      }),
      /additional account verification is required/i,
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const blockedEntitlement = await getDoc(
        doc(db, `users/${third.uid}/entitlements/current`),
      );
      const install = await getDoc(
        doc(db, `accountAbuseInstalls/${appInstallationHash}`),
      );
      assert.equal(blockedEntitlement.exists(), false);
      assert.equal(install.data()?.accountCount, 2);
    });
  });

  test('signed-in clients cannot create organizations or memberships', async () => {
    const identity = await createEmulatorIdentity();
    const db = testEnv.authenticatedContext(identity.uid).firestore();

    await assert.rejects(
      setDoc(doc(db, 'orgs/clientCreated'), {ownerUid: identity.uid}),
    );
    await assert.rejects(
      setDoc(doc(db, `orgs/clientCreated/members/${identity.uid}`), {
        uid: identity.uid,
        orgId: 'clientCreated',
        role: 'owner',
        status: 'active',
      }),
    );
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
        email: `workspace-${Date.now()}-${Math.random()}@example.test`,
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
