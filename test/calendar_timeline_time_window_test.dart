import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('timeline detail keeps the owner-provided planned end visible', () {
    final entry = CalendarTimelineEntry.fromProjection(
      CalendarProjectionEvent(
        eventId: 'job:window',
        source: CalendarProjectionSource.job,
        sourceRecordId: 'window',
        timing: CalendarProjectionTiming(
          eventDate: DateTime(2026, 7, 29),
          recordedAt: DateTime(2026, 7, 1),
          scheduledAt: DateTime(2026, 7, 29, 8),
          scheduledEndAt: DateTime(2026, 7, 29, 10, 30),
          timeSource: CalendarTimeSource.scheduled,
        ),
        title: 'Jones Plumbing',
        conciseDetail: 'Scheduled job',
        state: CalendarProjectionState.confirmed,
        sourceRecordStatus: 'scheduled',
        revision: 1,
        evidence: const CalendarProjectionEvidence(),
        deepLink: const CalendarProjectionDeepLink(
          target: CalendarDeepLinkTarget.jobDetail,
          sourceRecordId: 'window',
        ),
      ),
    );

    expect(entry.details, contains('Planned end: 7/29/2026 10:30 AM'));
  });
}
