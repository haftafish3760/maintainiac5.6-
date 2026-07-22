import assert from 'node:assert/strict';
import { describe, test } from 'node:test';

import {
  assertEmulatorOnly,
  emulatorProjectId,
  functionsHost,
  functionsPort,
} from './emulatorGuard.mjs';

const callableNames = [
  'issueExpenseProofUploadGrant',
  'finalizeExpenseProofUpload',
];

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
});

function callableUrl(name) {
  return `http://${functionsHost}:${functionsPort}/${emulatorProjectId}` +
    `/us-central1/${name}`;
}
