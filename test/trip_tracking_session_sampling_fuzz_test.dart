import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('recovered sampling records never exceed a valid persisted ceiling', () {
    final random = Random(48109);
    final startedAt = DateTime.utc(2026, 7, 19, 12);

    for (var index = 0; index < 400; index++) {
      final session = TripTrackingSessionRecord.fromMap({
        'id': 'trip_sampling_fuzz_$index',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'profile': 'roadVehicle',
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': startedAt
            .add(const Duration(minutes: 1))
            .toIso8601String(),
        'engineSnapshot': const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ).toMap(),
        'adaptiveSamplingEnabled': random.nextBool(),
        'nativeSampling': _randomSamplingMap(random),
        'samplingCeiling': _randomSamplingMap(random),
      });

      final ceiling = session.samplingCeiling;
      final native = session.nativeSampling;
      expect(
        session.adaptiveSamplingEnabled && ceiling == null,
        isFalse,
        reason: 'seed=48109 index=$index',
      );
      if (ceiling == null) continue;
      expect(native, isNotNull, reason: 'seed=48109 index=$index');
      expect(
        _isMoreAggressiveThan(native!, ceiling),
        isFalse,
        reason: 'seed=48109 index=$index',
      );
    }
  });

  test(
    'sampling recovery normalization remains safe after persistence replay',
    () {
      final random = Random(48110);
      final startedAt = DateTime.utc(2026, 7, 19, 13);

      for (var index = 0; index < 400; index++) {
        final restored = TripTrackingSessionRecord.fromMap({
          'id': 'trip_sampling_replay_$index',
          'vehicleId': 'vehicle_1',
          'startingOdometer': 1000,
          'profile': 'roadVehicle',
          'startedAt': startedAt.toIso8601String(),
          'updatedAt': startedAt
              .add(const Duration(minutes: 1))
              .toIso8601String(),
          'engineSnapshot': const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ).toMap(),
          'adaptiveSamplingEnabled': random.nextBool(),
          'nativeSampling': _randomSamplingMap(random),
          'samplingCeiling': _randomSamplingMap(random),
        });
        final replayed = TripTrackingSessionRecord.fromMap(restored.toMap());

        expect(
          replayed.adaptiveSamplingEnabled && replayed.samplingCeiling == null,
          isFalse,
          reason: 'seed=48110 index=$index',
        );
        if (replayed.samplingCeiling case final ceiling?) {
          expect(
            replayed.nativeSampling,
            isNotNull,
            reason: 'seed=48110 index=$index',
          );
          expect(
            _isMoreAggressiveThan(replayed.nativeSampling!, ceiling),
            isFalse,
            reason: 'seed=48110 index=$index',
          );
        }
      }
    },
  );

  test('live sampling updates cannot exceed the persisted ceiling', () {
    final record = TripTrackingSessionRecord.fromMap({
      'id': 'trip_sampling_live_guard',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': 'roadVehicle',
      'startedAt': DateTime.utc(2026, 7, 19, 14).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 19, 14, 1).toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'nativeSampling': _samplingMap(TripSamplingMode.economy, 60, 20),
      'samplingCeiling': _samplingMap(TripSamplingMode.balanced, 15, 8),
      'adaptiveSamplingEnabled': true,
    });
    const moreAggressive = TripSamplingRecommendation(
      mode: TripSamplingMode.precision,
      interval: Duration(seconds: 3),
      minimumDisplacementMeters: 1,
    );
    final guarded = record.copyWith(nativeSampling: moreAggressive);

    expect(guarded.nativeSampling, guarded.samplingCeiling);
    expect(guarded.adaptiveSamplingEnabled, isTrue);

    final cleared = guarded.copyWith(clearSamplingCeiling: true);
    expect(cleared.samplingCeiling, isNull);
  });
}

Map<String, Object> _samplingMap(
  TripSamplingMode mode,
  int intervalSeconds,
  double minimumDisplacementMeters,
) => {
  'mode': mode.name,
  'intervalSeconds': intervalSeconds,
  'minimumDisplacementMeters': minimumDisplacementMeters,
};

Object _randomSamplingMap(Random random) {
  final modes = [
    TripSamplingMode.precision.name,
    TripSamplingMode.balanced.name,
    TripSamplingMode.economy.name,
    'invalid',
    1,
  ];
  final intervals = [-1, 0, 1, 2, 3, 15, 30, 60, 61, double.infinity];
  final displacements = [-1, 0, 1, 3, 8, 20, 100, 101, double.infinity];
  if (random.nextInt(8) == 0) return 'not-a-map';
  return {
    'mode': modes[random.nextInt(modes.length)],
    'intervalSeconds': intervals[random.nextInt(intervals.length)],
    'minimumDisplacementMeters':
        displacements[random.nextInt(displacements.length)],
  };
}

bool _isMoreAggressiveThan(
  TripSamplingRecommendation candidate,
  TripSamplingRecommendation ceiling,
) =>
    candidate.interval < ceiling.interval ||
    candidate.minimumDisplacementMeters < ceiling.minimumDisplacementMeters ||
    _aggressiveness(candidate.mode) > _aggressiveness(ceiling.mode);

int _aggressiveness(TripSamplingMode mode) => switch (mode) {
  TripSamplingMode.precision => 3,
  TripSamplingMode.balanced => 2,
  TripSamplingMode.economy => 1,
};
