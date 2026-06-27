import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export const emulatorProjectId = 'demo-maintainiac-rules-test';
export const firestoreHost = '127.0.0.1';
export const firestorePort = 8080;

export function assertEmulatorOnly() {
  const firebaseRc = JSON.parse(
    readFileSync(resolve('..', '.firebaserc'), 'utf8'),
  );
  const configuredProject = firebaseRc.projects?.default;

  assert.equal(
    configuredProject,
    emulatorProjectId,
    'Firebase rules tests must use the demo emulator project only.',
  );
  assert.match(
    emulatorProjectId,
    /^demo-/,
    'Firebase rules tests must never point at a production Firebase project.',
  );
  assert.equal(
    process.env.GCLOUD_PROJECT ?? emulatorProjectId,
    emulatorProjectId,
    'GCLOUD_PROJECT must be the demo emulator project.',
  );
  assert.equal(
    process.env.FIRESTORE_EMULATOR_HOST,
    `${firestoreHost}:${firestorePort}`,
    'FIRESTORE_EMULATOR_HOST must point at the local Firestore emulator.',
  );
  assert.equal(
    process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099',
    '127.0.0.1:9099',
    'Auth emulator host must be local when set.',
  );
}
