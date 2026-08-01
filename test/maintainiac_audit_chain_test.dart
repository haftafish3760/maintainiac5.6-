import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_audit_chain.dart';

void main() {
  const events = [
    '2026-08-01T00:00:00.000Z created record',
    '2026-08-01T00:01:00.000Z saved record',
  ];

  test('chains append-only audit evidence deterministically', () {
    final state = MaintainiacAuditChain.fromEvents(events);

    expect(state.eventCount, 2);
    expect(
      state.chainSha256,
      'd6792e7163fbb05dc6b9a79707091dd30e402f4ea44f815e4b9d09180f625726',
    );
    expect(
      MaintainiacAuditChain.verifies(
        events: events,
        expectedCount: state.eventCount,
        expectedSha256: state.chainSha256,
      ),
      isTrue,
    );
  });

  test('detects missing, rewritten, or reordered audit evidence', () {
    final state = MaintainiacAuditChain.fromEvents(events);

    for (final invalid in [
      events.take(1),
      [events[0], '2026-08-01T00:01:00.000Z rewritten'],
      events.reversed,
    ]) {
      expect(
        MaintainiacAuditChain.verifies(
          events: invalid,
          expectedCount: state.eventCount,
          expectedSha256: state.chainSha256,
        ),
        isFalse,
      );
    }
  });

  test('can resume from a trusted archive checkpoint', () {
    final first = MaintainiacAuditChain.fromEvents(events.take(1));
    final resumed = first.appendAll(events.skip(1));
    final complete = MaintainiacAuditChain.fromEvents(events);

    expect(resumed.eventCount, complete.eventCount);
    expect(resumed.chainSha256, complete.chainSha256);
  });
}
