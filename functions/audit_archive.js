const {FieldPath} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const {appendAuditChain, auditChainFor} = require('./audit_chain');

const ARCHIVE_PAGE_SIZE = 250;
const MAX_AUDIT_EVENTS = 2000;
const SHA256 = /^[a-f0-9]{64}$/;

/// Verifies the immutable cloud archive against the root record's complete
/// lifecycle. This is intentionally used only by restore preparation, where
/// correctness matters more than minimizing one-time recovery reads.
async function verifyDurableAuditArchive({
  db,
  organizationId,
  recordKey,
  ownerUid,
  expectedEvents,
}) {
  if (!SHA256.test(recordKey) || typeof ownerUid !== 'string' ||
      !Array.isArray(expectedEvents) || expectedEvents.length > MAX_AUDIT_EVENTS) {
    throw new HttpsError('data-loss', 'Durable audit evidence is malformed.');
  }
  let expectedState = auditChainFor([]);
  let ordinal = 0;
  let lastDocument = null;
  while (ordinal < expectedEvents.length) {
    let query = db.collection(`orgs/${organizationId}/auditEvents`)
      .orderBy(FieldPath.documentId())
      .startAt(`${recordKey}_`)
      .endAt(`${recordKey}_\uf8ff`)
      .limit(ARCHIVE_PAGE_SIZE);
    if (lastDocument) query = query.startAfter(lastDocument);
    const page = await query.get();
    if (page.empty) break;
    for (const archive of page.docs) {
      if (ordinal >= expectedEvents.length) corruptArchive();
      const expectedOrdinal = ordinal + 1;
      const event = expectedEvents[ordinal];
      const data = archive.data();
      const previousChainSha256 = expectedState.chainSha256;
      const chainSha256 = appendAuditChain({
        previousSha256: previousChainSha256,
        ordinal: expectedOrdinal,
        event,
      });
      if (archive.id !== `${recordKey}_` +
            String(expectedOrdinal).padStart(12, '0') ||
          data.schema !== 'maintainiac_durable_audit_event_v1' ||
          data.recordKey !== recordKey || data.ownerUid !== ownerUid ||
          data.ordinal !== expectedOrdinal || data.event !== event ||
          data.previousChainSha256 !== previousChainSha256 ||
          data.chainSha256 !== chainSha256) {
        corruptArchive();
      }
      expectedState = {eventCount: expectedOrdinal, chainSha256};
      ordinal += 1;
    }
    lastDocument = page.docs[page.docs.length - 1];
    if (page.size < ARCHIVE_PAGE_SIZE) break;
  }
  if (ordinal !== expectedEvents.length ||
      expectedState.chainSha256 !== auditChainFor(expectedEvents).chainSha256) {
    corruptArchive();
  }
  return expectedState;
}

function corruptArchive() {
  throw new HttpsError(
    'data-loss',
    'Immutable audit evidence needs recovery before restore can continue.',
  );
}

module.exports = {verifyDurableAuditArchive};
