import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_trip_stop_projection_adapter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('user-confirmed stop projects without claiming completed work', () {
    final event = CalendarTripStopProjectionAdapter.fromReviewEvent(
      review: _review(),
      event: _stop(),
    );

    expect(event.source, CalendarProjectionSource.stop);
    expect(event.state, CalendarProjectionState.confirmed);
    expect(event.timing.timeSource, CalendarTimeSource.actual);
    expect(event.deepLink.target, CalendarDeepLinkTarget.stopReview);
    expect(event.evidence.explanation, contains('not that a job'));
  });

  test('only supported confirmed stop events project on the business day', () {
    final review = _review(
      events: [
        _stop(),
        _stop(id: 'note', type: TripManualEventType.note),
        _stop(
          id: 'other-day',
          occurredAt: DateTime.utc(2026, 7, 23, 12),
          recordedAt: DateTime.utc(2026, 7, 23, 12, 5),
        ),
      ],
    );

    final events = CalendarTripStopProjectionAdapter.eventsForDay([
      review,
    ], DateTime(2026, 7, 22));

    expect(events.map((event) => event.sourceRecordId), ['stop-1']);
  });

  test('unconfirmed or unsupported events cannot become Calendar stops', () {
    expect(
      () => CalendarTripStopProjectionAdapter.fromReviewEvent(
        review: _review(),
        event: _stop(userConfirmed: false),
      ),
      throwsArgumentError,
    );
  });
}

TripTrackingReviewRecord _review({List<TripManualEvent> events = const []}) =>
    TripTrackingReviewRecord(
      id: 'trip-1',
      vehicleId: 'vehicle-1',
      startingOdometer: 100,
      estimatedEndingOdometer: 110,
      profile: TripTrackingProfile.roadVehicle,
      profileId: 'delivery',
      startedAt: DateTime.utc(2026, 7, 22, 8),
      finishedAt: DateTime.utc(2026, 7, 22, 18),
      startedTimeZoneOffsetMinutes: -240,
      startedTimeZoneName: 'America/New_York',
      finishedTimeZoneOffsetMinutes: -240,
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1000,
        walkingReviewSuggested: false,
      ),
      tripEvents: events,
      revision: 2,
    );

TripManualEvent _stop({
  String id = 'stop-1',
  TripManualEventType type = TripManualEventType.jobSite,
  bool userConfirmed = true,
  DateTime? occurredAt,
  DateTime? recordedAt,
}) => TripManualEvent(
  id: id,
  type: type,
  occurredAt: occurredAt ?? DateTime.utc(2026, 7, 22, 12),
  recordedAt: recordedAt ?? DateTime.utc(2026, 7, 22, 12, 5),
  userConfirmed: userConfirmed,
  sessionId: 'trip-1',
  vehicleId: 'vehicle-1',
  profileId: 'delivery',
  initiatingSource: 'trip_screen',
  note: 'Jones Plumbing',
);
