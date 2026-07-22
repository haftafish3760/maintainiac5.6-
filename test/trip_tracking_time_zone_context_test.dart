import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 11, 1, 5, 30);
  final finishedAt = DateTime.utc(2026, 11, 1, 7, 30);

  test('review preserves UTC ordering and both local time-zone contexts', () {
    final review = TripTrackingReviewRecord(
      id: 'trip_dst_boundary',
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1100,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
      finishedAt: finishedAt,
      startedTimeZoneOffsetMinutes: -240,
      startedTimeZoneName: 'EDT',
      finishedTimeZoneOffsetMinutes: -300,
      finishedTimeZoneName: 'EST',
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 100 * 1609.344,
        walkingReviewSuggested: false,
      ),
    );

    final map = review.toMap();
    final restored = TripTrackingReviewRecord.fromMap(map);

    expect(map['startedAt'], endsWith('Z'));
    expect(map['finishedAt'], endsWith('Z'));
    expect(restored.startedAt, startedAt);
    expect(restored.finishedAt, finishedAt);
    expect(restored.startedTimeZoneOffsetMinutes, -240);
    expect(restored.startedTimeZoneName, 'EDT');
    expect(restored.finishedTimeZoneOffsetMinutes, -300);
    expect(restored.finishedTimeZoneName, 'EST');
    expect(restored.hasValidTimeline, isTrue);
  });

  test('legacy records retain explicit unknown time-zone context', () {
    final map =
        TripTrackingReviewRecord(
            id: 'legacy_time_zone',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000,
            estimatedEndingOdometer: 1000,
            profile: TripTrackingProfile.roadVehicle,
            startedAt: startedAt,
            finishedAt: finishedAt,
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 0,
              walkingReviewSuggested: false,
            ),
          ).toMap()
          ..remove('startedTimeZoneOffsetMinutes')
          ..remove('startedTimeZoneName')
          ..remove('finishedTimeZoneOffsetMinutes')
          ..remove('finishedTimeZoneName');
    final legacy = TripTrackingReviewRecord.fromMap(map);

    expect(legacy.startedTimeZoneName, 'unknown');
    expect(legacy.finishedTimeZoneName, 'unknown');
    expect(legacy.hasValidTimeline, isTrue);
  });

  test('records reject malformed time-zone context', () {
    final map = TripTrackingReviewRecord(
      id: 'unsafe_time_zone',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1000,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
      finishedAt: finishedAt,
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
    ).toMap()..['finishedTimeZoneOffsetMinutes'] = 900;

    expect(TripTrackingReviewRecord.fromMap(map).hasValidTimeline, isFalse);
  });
}
