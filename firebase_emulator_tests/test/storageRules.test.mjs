import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} from 'firebase/storage';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  firestoreHost,
  firestorePort,
  storageHost,
  storagePort,
} from './emulatorGuard.mjs';

let testEnv;

before(async () => {
  assertEmulatorOnly();
  testEnv = await initializeTestEnvironment({
    projectId: emulatorProjectId,
    firestore: {
      host: firestoreHost,
      port: firestorePort,
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
    storage: {
      host: storageHost,
      port: storagePort,
      rules: readFileSync('../storage.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
  await seedMemberAndGrant();
});

after(async () => {
  await testEnv?.cleanup();
});

describe('Storage rules emulator safety', () => {
  test('matching owner grant permits upload until server finalization', async () => {
    const proof = proofRef('ownerUid');
    await assertSucceeds(uploadBytes(proof, imageBytes(), validMetadata()));
    await finalizeGrant();
    await assertFails(uploadBytes(proof, imageBytes(), validMetadata()));
    await assertFails(deleteObject(proof));
  });

  test('upload rejects missing grant, mismatched metadata, and non-image data', async () => {
    const storage = testEnv.authenticatedContext('ownerUid').storage();
    await assertFails(
      uploadBytes(
        ref(storage, 'orgs/orgA/proof-uploads/ownerUid/missing/proofA'),
        imageBytes(),
        validMetadata(),
      ),
    );
    await assertFails(
      uploadBytes(
        proofRef('ownerUid'),
        imageBytes(),
        validMetadata({orgId: 'orgB'}),
      ),
    );
    await assertFails(
      uploadBytes(
        proofRef('ownerUid'),
        imageBytes(),
        validMetadata({}, 'application/pdf'),
      ),
    );
  });

  test('another user cannot spend or read the owners grant', async () => {
    await assertFails(
      uploadBytes(proofRef('outsiderUid', 'ownerUid'), imageBytes(), validMetadata()),
    );
    await assertSucceeds(
      uploadBytes(proofRef('ownerUid'), imageBytes(), validMetadata()),
    );
    await finalizeGrant();
    await assertFails(getBytes(proofRef('outsiderUid', 'ownerUid')));
    await assertSucceeds(getBytes(proofRef('ownerUid')));
  });

  test('final proof and export paths are never client writable', async () => {
    const storage = testEnv.authenticatedContext('ownerUid').storage();
    await assertFails(
      uploadBytes(
        ref(storage, 'orgs/orgA/proofs/expenses/receiptA/proofA'),
        imageBytes(),
        validMetadata(),
      ),
    );
    await assertFails(
      uploadBytes(
        ref(storage, 'orgs/orgA/exports/ownerUid/exportA.pdf'),
        imageBytes(),
        validMetadata({}, 'application/pdf'),
      ),
    );
  });
});

function proofRef(authUid, pathUid = authUid) {
  const storage = testEnv.authenticatedContext(authUid).storage();
  return ref(storage, `orgs/orgA/proof-uploads/${pathUid}/grantA/proofA`);
}

function imageBytes() {
  return new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
}

function validMetadata(overrides = {}, contentType = 'image/jpeg') {
  return {
    contentType,
    customMetadata: {
      orgId: 'orgA',
      uid: 'ownerUid',
      proofId: 'proofA',
      ...overrides,
    },
  };
}

async function seedMemberAndGrant() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'orgs/orgA/members/ownerUid'), {
      status: 'active',
      role: 'owner',
      permissions: ['addOwnReceipts'],
    });
    await setDoc(doc(db, 'orgs/orgA/uploadGrants/grantA'), {
      uid: 'ownerUid',
      proofId: 'proofA',
      status: 'open',
      maxBytes: 1024,
      expiresAt: new Date(Date.now() + 60_000),
    });
  });
}

async function finalizeGrant() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'orgs/orgA/uploadGrants/grantA'), {
      status: 'finalized',
    });
  });
}
