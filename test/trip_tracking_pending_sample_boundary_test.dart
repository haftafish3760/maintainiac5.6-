import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
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
}

TripLocationSample _sample(DateTime recordedAt) => TripLocationSample(
  latitude: 35,
  longitude: -80,
  recordedAt: recordedAt,
  horizontalAccuracyMeters: 5,
);
