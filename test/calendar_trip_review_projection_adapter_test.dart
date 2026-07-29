import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_trip_review_projection_adapter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'trip review stays a proposed evidence event in its source timezone',
    () {
      final event = CalendarTripReviewProjectionAdapter.fromReview(
        _review(
          startedAt: DateTime.utc(2026, 11, 1, 5, 30),
          finishedAt: DateTime.utc(2026, 11, 1, 7, 30),
          startedOffsetMinutes: -240,
          finishedOffsetMinutes: -300,
        ),
      );

      expect(event.timing.eventDate, DateTime(2026, 11, 1));
      expect(event.timing.timezoneId, 'America/New_York');
      expect(event.timing.timeSource, CalendarTimeSource.actual);
      expect(event.state, CalendarProjectionState.proposed);
      expect(event.deepLink.target, CalendarDeepLinkTarget.tripReview);
      expect(event.evidence.explanation, contains('does not confirm business'));
      expect(
        CalendarTimelineEntry.fromProjection(event).details,
        contains('Actual time: 11/1/2026 1:30 AM'),
      );
      expect(
        CalendarTimelineEntry.fromProjection(event).details,
        contains('Recorded: 11/1/2026 2:30 AM'),
      );
    },
  );

  test('overnight trip review appears on its continuation day', () {
    final event = CalendarTripReviewProjectionAdapter.eventsForDay([
      _review(
        startedAt: DateTime.utc(2026, 7, 1, 23, 30),
        finishedAt: DateTime.utc(2026, 7, 2, 1),
      ),
    ], DateTime(2026, 7, 2)).single;

    expect(event.timing.eventDate, DateTime(2026, 7, 1));
    expect(event.conciseDetail, contains('Continues from previous day'));
  });

  test('invalid GPS timeline is blocked instead of displayed as a trip', () {
    final event = CalendarTripReviewProjectionAdapter.fromReview(
      _review(hasValidTimeline: false),
    );

    expect(event.state, CalendarProjectionState.blocked);
    expect(event.sourceRecordStatus, 'timeline unavailable');
  });
}

TripTrackingReviewRecord _review({
  DateTime? startedAt,
  DateTime? finishedAt,
  int startedOffsetMinutes = 0,
  int finishedOffsetMinutes = 0,
  bool hasValidTimeline = true,
}) => TripTrackingReviewRecord(
  id: 'trip-review-1',
  vehicleId: 'vehicle-1',
  startingOdometer: 1000,
  estimatedEndingOdometer: 1010,
  profile: TripTrackingProfile.roadVehicle,
  profileId: 'delivery',
  startedAt: startedAt ?? DateTime.utc(2026, 7, 1, 9),
  finishedAt: finishedAt ?? DateTime.utc(2026, 7, 1, 10),
  startedTimeZoneOffsetMinutes: startedOffsetMinutes,
  startedTimeZoneName: 'America/New_York',
  finishedTimeZoneOffsetMinutes: finishedOffsetMinutes,
  finishedTimeZoneName: 'America/New_York',
  engineSnapshot: const TripTrackingEngineSnapshot(
    totalAcceptedMeters: 1610,
    walkingReviewSuggested: false,
  ),
  hasValidTimeline: hasValidTimeline,
  revision: 4,
);
