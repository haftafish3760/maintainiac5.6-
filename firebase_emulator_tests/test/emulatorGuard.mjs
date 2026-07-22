import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export const emulatorProjectId = 'demo-maintainiac-rules-test';
export const firestoreHost = '127.0.0.1';
export const firestorePort = 8080;
export const storageHost = '127.0.0.1';
export const storagePort = 9199;
export const authHost = '127.0.0.1';
export const authPort = 9099;
export const functionsHost = '127.0.0.1';
export const functionsPort = 5001;

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
    process.env.FIREBASE_AUTH_EMULATOR_HOST,
    `${authHost}:${authPort}`,
    'FIREBASE_AUTH_EMULATOR_HOST must point at the local Auth emulator.',
  );
  assert.equal(
    process.env.FIREBASE_STORAGE_EMULATOR_HOST,
    `${storageHost}:${storagePort}`,
    'FIREBASE_STORAGE_EMULATOR_HOST must point at the local Storage emulator.',
  );
}
