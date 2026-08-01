import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {after, before, describe, test} from 'node:test';

import {initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, getDoc, setDoc} from 'firebase/firestore';

import {callFunction, callFunctionError} from './callableTestClient.mjs';
import {emptyAuditChainSha256} from '../../functions/audit_chain.js';
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
  test('content hash matches the client canonicalization vector', () => {
    const data = {
      accountScopeId: 'orgVector.userVector',
      module: 'settings',
      localRecordId: 'record-1',
      recordPayload: {
        title: 'HDWR',
        ratio: 12.0,
        nested: {enabled: true},
        count: 1,
      },
      createdAt: '2026-07-22T00:00:00.000Z',
      updatedAt: '2026-07-22T00:00:00.000Z',
      localRevision: 1,
      recordState: 'active',
      deletedAt: null,
      auditEvents: ['2026-07-22T00:00:00.000Z created record'],
    };

    assert.equal(
      contentHash(data),
      '9e34025a498e8ef5c2c1f14d11ba90f16b8081df239c403e033552de7ab01426',
    );
  });

  test('one reserved batch is idempotent and client writes stay blocked', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const first = durableDocument(identity.uid, 'settings-a', 1, 'dark');
    first.data.auditEvents = ['2026-07-22T00:00:00.000Z created record'];
    first.data.contentSha256 = contentHash(first.data);
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
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const manifest = await getDoc(doc(
        context.firestore(),
        `orgs/orgCommit/syncManifests/${identity.uid}`,
      ));
      assert.equal(manifest.data()?.recordCount, 1);
      assert.equal(
        manifest.data()?.structuredBytes,
        Buffer.byteLength(JSON.stringify(first.data), 'utf8'),
      );
      assert.equal(manifest.data()?.manifestRevision, 1);
      const audit = await getDoc(doc(
        context.firestore(),
        `orgs/orgCommit/auditEvents/${first.data.recordKey}_000000000001`,
      ));
      assert.deepEqual(audit.data(), {
        schema: 'maintainiac_durable_audit_event_v1',
        recordKey: first.data.recordKey,
        ownerUid: identity.uid,
        ordinal: 1,
        event: '2026-07-22T00:00:00.000Z created record',
        previousChainSha256: emptyAuditChainSha256(),
        chainSha256: 'a58c1dfa8040c7f1798e3618b3e55874c65ff36bcd7de2c641aff6f02e030812',
        createdAt: '2026-07-22T00:00:00.000Z',
      });
    });
  });

  test('one sync accepts later batches while private evidence fails closed', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const first = durableDocument(identity.uid, 'settings-b', 1, 'dark');
    await callFunction('commitDurableRecordBatch', identity.token, {
      attemptId: 'durable-attempt-b',
      documents: [first],
    });
    const changed = durableDocument(identity.uid, 'settings-b', 2, 'light');
    const updated = await callFunction(
      'commitDurableRecordBatch',
      identity.token,
      {attemptId: 'durable-attempt-b', documents: [changed]},
    );
    assert.equal(updated.writtenCount, 1);
    assert.equal(updated.used, 1);
    assert.equal(updated.batchCount, 2);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const manifest = await getDoc(doc(
        context.firestore(),
        `orgs/orgCommit/syncManifests/${identity.uid}`,
      ));
      assert.equal(manifest.data()?.recordCount, 1);
      assert.equal(
        manifest.data()?.structuredBytes,
        Buffer.byteLength(JSON.stringify(changed.data), 'utf8'),
      );
      assert.equal(manifest.data()?.manifestRevision, 2);
    });

    for (const [index, payload] of [
      {RawOcrText: 'must remain local'},
      {MerchantName: 'private merchant'},
    ].entries()) {
      const unsafe = durableDocument(
        identity.uid,
        `settings-c-${index}`,
        1,
        'dark',
      );
      unsafe.data.recordPayload = payload;
      unsafe.data.contentSha256 = contentHash(unsafe.data);
      const rejected = await callFunctionError(
        'commitDurableRecordBatch',
        identity.token,
        {attemptId: `durable-attempt-c-${index}`, documents: [unsafe]},
      );
      assert.equal(rejected.status, 400);
    }
  });

  test('vehicle mileage allocations use one private versioned durable document', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const allocation = durableDocument(
      identity.uid,
      'allocation-1',
      1,
      'unused',
    );
    allocation.data.module = 'vehicleMileageAllocation';
    allocation.data.recordKey = sha256(
      'vehicleMileageAllocation\u0000allocation-1',
    );
    allocation.path = `orgs/orgCommit/records/${allocation.data.recordKey}`;
    allocation.data.recordPayload = {
      schema: 'vehicle_mileage_allocation_durable_record_v1',
      schemaVersion: 1,
      dateRange: {
        start: '2026-08-01T10:00:00.000Z',
        end: '2026-08-01T10:00:00.000Z',
      },
      reviewStatus: 'split',
      allocation: {
        id: 'allocation-1',
        vehicleId: 'vehicle-1',
        sourceType: 'trip',
        sourceId: 'trip-1',
        sourceRevision: 1,
        occurredAt: '2026-08-01T10:00:00.000Z',
        confirmedAt: '2026-08-01T10:01:00.000Z',
        use: 'split',
        distanceTenths: 555,
        businessTenths: 400,
        personalTenths: 155,
        unclassifiedTenths: 0,
      },
    };
    allocation.data.contentSha256 = contentHash(allocation.data);

    const result = await callFunction(
      'commitDurableRecordBatch',
      identity.token,
      {attemptId: 'vehicle-mileage-allocation-a', documents: [allocation]},
    );

    assert.equal(result.attemptedCount, 1);
    assert.equal(result.writtenCount, 1);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const stored = await getDoc(doc(context.firestore(), allocation.path));
      assert.equal(stored.data()?.module, 'vehicleMileageAllocation');
      assert.equal(
        stored.data()?.recordPayload?.allocation?.businessTenths,
        allocation.data.recordPayload.allocation.businessTenths,
      );
      assert.equal(
        Object.hasOwn(stored.data().recordPayload, 'deviceId'),
        false,
      );
    });
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

  test('record schema upgrades are monotonic and revision bound', async () => {
    const identity = await createIdentity();
    await seedHostedAccount(identity.uid);
    const first = durableDocument(identity.uid, 'schema-upgrade', 1, 'dark');
    await callFunction('commitDurableRecordBatch', identity.token, {
      attemptId: 'schema-migration-attempt',
      documents: [first],
    });
    const upgraded = durableDocument(
      identity.uid,
      'schema-upgrade',
      2,
      'light',
      2,
    );
    const result = await callFunction(
      'commitDurableRecordBatch',
      identity.token,
      {
        attemptId: 'schema-migration-attempt',
        documents: [upgraded],
      },
    );
    assert.equal(result.writtenCount, 1);
    const downgraded = durableDocument(
      identity.uid,
      'schema-upgrade',
      3,
      'unsafe-downgrade',
      1,
    );
    const rejected = await callFunctionError(
      'commitDurableRecordBatch',
      identity.token,
      {
        attemptId: 'schema-migration-attempt',
        documents: [downgraded],
      },
    );
    assert.equal(rejected.body?.error?.status, 'FAILED_PRECONDITION');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const stored = await getDoc(doc(context.firestore(), upgraded.path));
      assert.equal(stored.data()?.recordSchemaVersion, 2);
      assert.equal(stored.data()?.localRevision, 2);
    });
  });
});

function durableDocument(
  uid,
  localRecordId,
  revision,
  theme,
  schemaVersion = 1,
) {
  const recordKey = sha256(`settings\u0000${localRecordId}`);
  const document = {
    path: `orgs/orgCommit/records/${recordKey}`,
    data: {
      schema: 'maintainiac_durable_record_v1',
      recordKey,
      module: 'settings',
      localRecordId,
      accountScopeId: `orgCommit.${uid}`,
      recordSchemaVersion: schemaVersion,
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
