import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_audit_sync_plan.dart';

void main() {
  List<String> events(int count) => List.generate(
    count,
    (index) => '2026-08-01T00:00:00.000Z saved event ${index + 1}',
  );

  test('plans bounded sequential audit pages with one target chain', () {
    final plan = MaintainiacAuditSyncPlan.fromEvents(events(501));

    expect(plan.target.eventCount, 501);
    expect(plan.pages.map((page) => page.events.length), [250, 250, 1]);
    expect(plan.pages.map((page) => page.firstOrdinal), [1, 251, 501]);
    expect(
      plan.pages[1].previousChainSha256,
      plan.pages[0].resultingChainSha256,
    );
    expect(plan.pages.last.resultingChainSha256, plan.target.chainSha256);
  });

  test('resumes a partially archived page without resending its prefix', () {
    final plan = MaintainiacAuditSyncPlan.fromEvents(events(501));
    final remaining = plan.pagesAfter(275);

    expect(remaining.first.firstOrdinal, 276);
    expect(remaining.first.events.length, 225);
    expect(remaining.last.lastOrdinal, 501);
    expect(remaining.last.resultingChainSha256, plan.target.chainSha256);
  });

  test('rejects an impossible checkpoint or unsafe page limit', () {
    final plan = MaintainiacAuditSyncPlan.fromEvents(events(2));

    expect(() => plan.pagesAfter(3), throwsArgumentError);
    expect(
      () => MaintainiacAuditSyncPlan.fromEvents(
        events(1),
        maximumEventsPerPage: 251,
      ),
      throwsArgumentError,
    );
  });
}
