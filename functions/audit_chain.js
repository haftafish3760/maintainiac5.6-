const {createHash} = require('node:crypto');

const AUDIT_CHAIN_SCHEMA = 'maintainiac_audit_chain_v1';
const SHA256 = /^[a-f0-9]{64}$/;

function emptyAuditChainSha256() {
  return sha256(canonicalJson({schema: AUDIT_CHAIN_SCHEMA, kind: 'empty'}));
}

function appendAuditChain({previousSha256, ordinal, event}) {
  if (!SHA256.test(previousSha256) || !Number.isInteger(ordinal) ||
      ordinal < 1 || typeof event !== 'string' ||
      event.trim().length === 0 || event.length > 512) {
    throw new TypeError('Invalid audit chain event.');
  }
  return sha256(canonicalJson({
    schema: AUDIT_CHAIN_SCHEMA,
    previousSha256,
    ordinal,
    event,
  }));
}

function auditChainFor(events) {
  if (!Array.isArray(events)) throw new TypeError('Audit events are invalid.');
  let chainSha256 = emptyAuditChainSha256();
  for (let index = 0; index < events.length; index += 1) {
    chainSha256 = appendAuditChain({
      previousSha256: chainSha256,
      ordinal: index + 1,
      event: events[index],
    });
  }
  return {eventCount: events.length, chainSha256};
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

module.exports = {
  AUDIT_CHAIN_SCHEMA,
  appendAuditChain,
  auditChainFor,
  emptyAuditChainSha256,
};
