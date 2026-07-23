import assert from 'node:assert/strict';
import {describe, test} from 'node:test';

import {assertEmulatorOnly} from './emulatorGuard.mjs';
import {callFunction, callFunctionError} from './callableTestClient.mjs';

describe('restore device registration limits', () => {
  test('server-configured active-device cap fails closed', async () => {
    assertEmulatorOnly();
    const identity = await createEmulatorIdentity();
    for (let index = 0; index < 5; index += 1) {
      const registered = await callFunction(
        'registerRestoreDevice',
        identity.token,
        registration(index),
      );
      assert.equal(registered.registrationRevision, 1);
    }

    const blocked = await callFunctionError(
      'registerRestoreDevice',
      identity.token,
      registration(5),
    );

    assert.equal(blocked.status, 429);
    assert.equal(blocked.body?.error?.status, 'RESOURCE_EXHAUSTED');
  });

  test('concurrent registrations cannot race beyond the device cap', async () => {
    assertEmulatorOnly();
    const identity = await createEmulatorIdentity();
    const outcomes = await Promise.all(
      Array.from({length: 6}, async (_, index) => {
        try {
          await callFunction(
            'registerRestoreDevice',
            identity.token,
            registration(index + 20),
          );
          return 'registered';
        } catch (_) {
          return 'blocked';
        }
      }),
    );

    assert.equal(outcomes.filter((value) => value === 'registered').length, 5);
    assert.equal(outcomes.filter((value) => value === 'blocked').length, 1);
  });
});

function registration(index) {
  return {
    deviceId: `boundedDevice${index}`,
    installationIdHash: index.toString(16).padStart(64, '0'),
    platform: 'android',
    appVersion: '1.0.0',
  };
}

async function createEmulatorIdentity() {
  const response = await fetch(
    'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/' +
      'accounts:signUp?key=demo-key',
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({returnSecureToken: true}),
    },
  );
  assert.equal(response.status, 200);
  const body = await response.json();
  return {uid: body.localId, token: body.idToken};
}
