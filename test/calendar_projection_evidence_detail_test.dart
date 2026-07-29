import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('timeline entry retains source evidence and audit metadata', () {
    final entry = CalendarTimelineEntry.fromProjection(
      CalendarProjectionEvent(
        eventId: 'proposal-1',
        source: CalendarProjectionSource.stop,
        sourceRecordId: 'stop-1',
        timing: CalendarProjectionTiming(
          eventDate: DateTime(2026, 7, 29),
          recordedAt: DateTime(2026, 7, 29, 10),
          timeSource: CalendarTimeSource.recorded,
        ),
        title: 'Possible customer stop',
        conciseDetail: 'Review GPS and schedule evidence',
        state: CalendarProjectionState.proposed,
        sourceRecordStatus: 'proposed',
        revision: 4,
        deepLink: const CalendarProjectionDeepLink(
          target: CalendarDeepLinkTarget.stopReview,
          sourceRecordId: 'stop-1',
        ),
        evidence: const CalendarProjectionEvidence(
          evidenceId: 'gps-7',
          proposalId: 'proposal-1',
          summary: 'Dwell time near the scheduled address',
          strength: 'Supporting evidence',
          recommendationConfidence: 0.735,
          explanation: 'Arrival is not proof that service was completed.',
          acceptanceImpact: 'Creates a draft stop for source-owner review.',
          ignoreImpact: 'No job, trip, or expense record is created.',
        ),
        auditReference: 'Revision 4 from stop detector',
      ),
    );

    expect(entry.details, contains('Evidence ID: gps-7'));
    expect(entry.details, contains('Proposal ID: proposal-1'));
    expect(entry.details, contains('Evidence strength: Supporting evidence'));
    expect(entry.details, contains('Recommendation confidence: 74%'));
    expect(
      entry.details,
      contains('If accepted: Creates a draft stop for source-owner review.'),
    );
    expect(
      entry.details,
      contains('If ignored: No job, trip, or expense record is created.'),
    );
    expect(entry.details, contains('Audit: Revision 4 from stop detector'));
  });
}
