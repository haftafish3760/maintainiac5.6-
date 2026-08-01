import assert from 'node:assert/strict';
import {test} from 'node:test';

import {auditChainFor, emptyAuditChainSha256} from '../../functions/audit_chain.js';

test('audit chain matches the durable client canonicalization vector', () => {
  const events = [
    '2026-08-01T00:00:00.000Z created record',
    '2026-08-01T00:01:00.000Z saved record',
  ];

  assert.equal(
    auditChainFor(events).chainSha256,
    'd6792e7163fbb05dc6b9a79707091dd30e402f4ea44f815e4b9d09180f625726',
  );
  assert.match(emptyAuditChainSha256(), /^[a-f0-9]{64}$/);
});
