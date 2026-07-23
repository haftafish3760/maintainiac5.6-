import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
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

describe('server committed durable records', () => {
  test('one reserved batch is idempotent and client writes stay blocked', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const first = durableDocument(identity.uid, 'settings-a', 1, 'dark');
    const input = {attemptId: 'durable-attempt-a', documents: [first]};

    const committed = await callFunction(
      'commitDurableRecordBatch',
      identity.token,
      input,
    );
    const retry = await callFunction(
      'commitDurableRecordBatch',
      identity.token,
      input,
    );

    assert.equal(committed.attemptedCount, 1);
    assert.equal(committed.writtenCount, 1);
    assert.equal(retry.writtenCount, 0);
    assert.equal(retry.reservationId, committed.reservationId);
    const owner = testEnv.authenticatedContext(identity.uid).firestore();
    const stored = await getDoc(doc(owner, first.path));
    assert.equal(stored.data()?.recordPayload?.theme, 'dark');
    await assert.rejects(setDoc(doc(owner, first.path), first.data));
  });

  test('attempt rebinding and private local evidence fail closed', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const first = durableDocument(identity.uid, 'settings-b', 1, 'dark');
    await callFunction('commitDurableRecordBatch', identity.token, {
      attemptId: 'durable-attempt-b',
      documents: [first],
    });
    const changed = durableDocument(identity.uid, 'settings-b', 2, 'light');
    const rebound = await callFunctionError(
      'commitDurableRecordBatch',
      identity.token,
      {attemptId: 'durable-attempt-b', documents: [changed]},
    );
    assert.equal(rebound.status, 400);

    const unsafe = durableDocument(
      identity.uid,
      'settings-c',
      1,
      'dark',
    );
    unsafe.data.recordPayload = {rawOcrText: 'must remain local'};
    const rejected = await callFunctionError(
      'commitDurableRecordBatch',
      identity.token,
      {attemptId: 'durable-attempt-c', documents: [unsafe]},
    );
    assert.equal(rejected.status, 400);
  });

  test('content, identity, and lifecycle tampering fail before writes', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const tampered = durableDocument(identity.uid, 'tampered', 1, 'dark');
    tampered.data.recordPayload.theme = 'changed-after-hash';
    const wrongKey = durableDocument(identity.uid, 'wrong-key', 1, 'dark');
    wrongKey.data.recordKey = 'f'.repeat(64);
    wrongKey.path = `orgs/orgCommit/records/${wrongKey.data.recordKey}`;
    const backward = durableDocument(identity.uid, 'backward', 1, 'dark');
    backward.data.updatedAt = '2026-07-21T00:00:00.000Z';
    backward.data.contentSha256 = contentHash(backward.data);

    for (const [index, document] of [tampered, wrongKey, backward].entries()) {
      const rejected = await callFunctionError(
        'commitDurableRecordBatch',
        identity.token,
        {attemptId: `tamper-${index}`, documents: [document]},
      );
      assert.equal(rejected.status, 400);
    }
  });
});

function durableDocument(uid, localRecordId, revision, theme) {
  const recordKey = sha256(`settings\u0000${localRecordId}`);
  const document = {
    path: `orgs/orgCommit/records/${recordKey}`,
    data: {
      schema: 'maintainiac_durable_record_v1',
      recordKey,
      module: 'settings',
      localRecordId,
      accountScopeId: `orgCommit.${uid}`,
      recordSchemaVersion: 1,
      contentSha256: '',
      privateToOwner: true,
      orgId: 'orgCommit',
      createdByUid: uid,
      updatedByUid: uid,
      localRevision: revision,
      recordState: 'active',
      createdAt: '2026-07-22T00:00:00.000Z',
      updatedAt: `2026-07-22T0${revision}:00:00.000Z`,
      deletedAt: null,
      auditEvents: [],
      recordPayload: {theme},
    },
  };
  document.data.contentSha256 = contentHash(document.data);
  return document;
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

async function seedHostedAccount(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `orgs/orgCommit/members/${uid}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${uid}/entitlements/current`), {
      uid,
      planId: 'freeCommit',
      status: 'active',
    });
    await setDoc(doc(db, 'hostedPlans/freeCommit'), {
      status: 'active',
      displayName: 'Free commit test',
      storageQuotaBytes: 100 * 1024 * 1024,
      dailySyncLimit: 4,
      immediateSyncAllowed: false,
      policyVersion: 1,
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
        email: `durable-${Date.now()}-${Math.random()}@example.test`,
        password: 'emulator-only-password',
        returnSecureToken: true,
      }),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  return {uid: body.localId, token: body.idToken};
}
