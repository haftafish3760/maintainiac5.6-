import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, test } from 'node:test';

import { mockSeedProjectId, mockSeedRecords } from '../seed/mockSeedData.mjs';
import { assertEmulatorOnly } from './emulatorGuard.mjs';

const forbiddenFields = [
  'vin',
  'VIN',
  'vehicleIdentificationNumber',
  'licensePlate',
  'plateNumber',
  'tagNumber',
  'passengerName',
  'passengerPhone',
  'passengerAddress',
  'patientName',
  'patientPhone',
  'patientAddress',
  'medicalRecordNumber',
  'diagnosis',
  'dateOfBirth',
  'dob',
];

describe('Firestore data model guardrails', () => {
  test('project and emulator guard stay demo-only', () => {
    assertEmulatorOnly();
    assert.equal(mockSeedProjectId, 'demo-maintainiac-rules-test');
  });

  test('Firebase config declares rules and indexes', () => {
    const config = JSON.parse(readFileSync('../firebase.json', 'utf8'));

    assert.equal(config.firestore.rules, 'firestore.rules');
    assert.equal(config.firestore.indexes, 'firestore.indexes.json');
  });

  test('indexes cover first-release operational collections', () => {
    const indexes = JSON.parse(
      readFileSync('../firestore.indexes.json', 'utf8'),
    ).indexes;
    const collectionGroups = new Set(
      indexes.map((index) => index.collectionGroup),
    );

    for (const group of [
      'expenses',
      'mileageRecords',
      'jobs',
      'estimates',
      'invoices',
      'inventoryItems',
      'inventoryTransactions',
      'maintenanceRecords',
      'auditEvents',
      'invites',
    ]) {
      assert.equal(collectionGroups.has(group), true, `${group} index missing`);
    }
  });

  test('data model and deploy checklist lock region and production safety', () => {
    const model = readFileSync('../docs/firestore_data_model.md', 'utf8');
    const checklist = readFileSync(
      '../docs/firebase_production_deploy_checklist.md',
      'utf8',
    );

    assert.match(model, /NAM7/);
    assert.match(checklist, /NAM7/);
    assert.match(checklist, /Do not seed production/);
    assert.match(checklist, /Do not enable Firestore test mode/);
    assert.match(checklist, /explicit owner approval/);
  });

  test('rules reject forbidden sensitive field names', () => {
    const rules = readFileSync('../firestore.rules', 'utf8');

    for (const field of forbiddenFields) {
      assert.match(rules, new RegExp(`'${field}'`));
    }
    assert.match(rules, /noForbiddenSensitiveFields/);
  });

  test('emulator seed data contains no forbidden sensitive fields', () => {
    for (const record of mockSeedRecords) {
      const keys = new Set(Object.keys(record.data));
      for (const field of forbiddenFields) {
        assert.equal(
          keys.has(field),
          false,
          `${record.path} must not contain ${field}`,
        );
      }
    }
  });
});
