import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('pending GPS recovery requires supported schema version', () {
    final sampleAt = DateTime.utc(2026, 7, 18, 12);
    Map<String, Object?> pendingWithSchema(Object? schemaVersion) => {
      'schemaVersion': schemaVersion,
      'sessionId': 'trip_pending_schema',
      'sample': _sample(sampleAt).toMap(),
    };

    for (final schema in const [null, 1.0, 2, '1', true]) {
      expect(
        TripTrackingPendingSample.tryFromMap(pendingWithSchema(schema)),
        isNull,
        reason: '$schema',
      );
    }

    final supported = TripTrackingPendingSample.tryFromMap(
      pendingWithSchema(1),
    );

    expect(supported?.schemaVersion, 1);
    expect(supported?.sessionId, 'trip_pending_schema');
  });

  test('pending GPS writes reject impossible activity confidence', () async {
    final store = TripTrackingSessionStore.memory();
    final sampleAt = DateTime.utc(2026, 7, 18, 12);

    await expectLater(
      store.savePending(
        TripTrackingPendingSample(
          sessionId: 'trip_pending_activity_confidence',
          sample: _sample(sampleAt),
          activity: TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 101,
            recordedAt: sampleAt,
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(store.pendingSampleFor('trip_pending_activity_confidence'), isNull);
  });

  test('pending GPS writes reject future activity evidence', () async {
    final store = TripTrackingSessionStore.memory();
    final sampleAt = DateTime.utc(2026, 7, 18, 12);

    await expectLater(
      store.savePending(
        TripTrackingPendingSample(
          sessionId: 'trip_pending_activity_future',
          sample: _sample(sampleAt),
          activity: TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 90,
            recordedAt: sampleAt.add(const Duration(seconds: 1)),
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(store.pendingSampleFor('trip_pending_activity_future'), isNull);
  });

  test('pending GPS boundary summary does not expose precise route data', () {
    final sampleAt = DateTime.utc(2026, 7, 18, 12);
    final pending = TripTrackingPendingSample(
      sessionId: 'trip_pending_summary',
      sample: _sample(sampleAt).copyWithMockedLocationForTest(true),
      activity: TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 85,
        recordedAt: sampleAt.subtract(const Duration(seconds: 30)),
      ),
    );

    expect(pending.toMap()['schemaVersion'], 1);
    expect(pending.schemaVersion, 1);
    expect(pending.toBoundarySummary(), {
      'schemaVersion': 1,
      'hasSafeSessionId': true,
      'hasValidCoordinate': true,
      'hasValidAccuracy': true,
      'hasActivityEvidence': true,
      'hasSafeActivityEvidence': true,
      'mockedLocationReported': true,
      'preciseLocationIncluded': false,
      'preciseTimestampIncluded': false,
      'rawProviderPayloadIncluded': false,
      'authoritativeForMileage': false,
      'canOverrideOdometer': false,
      'canCreateTripLogEntry': false,
    });
  });
}

TripLocationSample _sample(DateTime recordedAt) => TripLocationSample(
  latitude: 35,
  longitude: -80,
  recordedAt: recordedAt,
  horizontalAccuracyMeters: 5,
);

extension on TripLocationSample {
  TripLocationSample copyWithMockedLocationForTest(bool value) =>
      TripLocationSample(
        latitude: latitude,
        longitude: longitude,
        recordedAt: recordedAt,
        horizontalAccuracyMeters: horizontalAccuracyMeters,
        speedMetersPerSecond: speedMetersPerSecond,
        mockedLocation: value,
      );
}
