// Calendar regression for honest confirmed-stop time rendering around DST.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_trip_stop_projection_adapter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('cross-DST stop keeps UTC label when event offset is unavailable', () {
    final event = CalendarTripStopProjectionAdapter.fromReviewEvent(
      review: _review(),
      event: _stop(),
    );
    final details = CalendarTimelineEntry.fromProjection(event).details;

    expect(event.timing.actualTimezoneOffsetMinutes, isNull);
    expect(details, contains('Actual time: 11/1/2026 6:30 AM UTC'));
    expect(details, contains('Source time zone: America/New_York'));
  });
}

TripTrackingReviewRecord _review() => TripTrackingReviewRecord(
  id: 'dst-trip',
  vehicleId: 'vehicle-1',
  startingOdometer: 100,
  estimatedEndingOdometer: 120,
  profile: TripTrackingProfile.roadVehicle,
  profileId: 'delivery',
  startedAt: DateTime.utc(2026, 11, 1, 5),
  finishedAt: DateTime.utc(2026, 11, 1, 8),
  startedTimeZoneOffsetMinutes: -240,
  startedTimeZoneName: 'America/New_York',
  finishedTimeZoneOffsetMinutes: -300,
  finishedTimeZoneName: 'America/New_York',
  engineSnapshot: const TripTrackingEngineSnapshot(
    totalAcceptedMeters: 1000,
    walkingReviewSuggested: false,
  ),
);

TripManualEvent _stop() => TripManualEvent(
  id: 'dst-stop',
  type: TripManualEventType.jobSite,
  occurredAt: DateTime.utc(2026, 11, 1, 6, 30),
  recordedAt: DateTime.utc(2026, 11, 1, 6, 31),
  userConfirmed: true,
  sessionId: 'dst-trip',
  vehicleId: 'vehicle-1',
  profileId: 'delivery',
  initiatingSource: 'trip_screen',
);
