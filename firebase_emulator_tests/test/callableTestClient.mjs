import assert from 'node:assert/strict';

import {
  emulatorProjectId,
  functionsHost,
  functionsPort,
} from './emulatorGuard.mjs';

export function callableUrl(name) {
  return `http://${functionsHost}:${functionsPort}/${emulatorProjectId}` +
    `/us-central1/${name}`;
}

export async function callFunction(name, token, data) {
  const result = await callFunctionError(name, token, data);
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert.ok(result.body.result, `${name} must return a callable result`);
  return result.body.result;
}

export async function callFunctionError(name, token, data) {
  const response = await fetch(callableUrl(name), {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({data}),
  });
  const body = await response.json();
  return {status: response.status, body};
}
