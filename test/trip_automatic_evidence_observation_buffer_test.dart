// Regression coverage for bounded, review-only App Assistant observations.
//
// Owns validation of derived evidence buffering. Does not test native device
// collection, session creation, persistence, or confirmation workflows.
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_observation_buffer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final start = DateTime.utc(2026, 8, 4, 12);

  TripLocationSample sample(
    int seconds, {
    double latitude = 35.0,
    double longitude = -82.0,
    double? speed = 8,
    bool? mocked,
  }) => TripLocationSample(
    latitude: latitude,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: 12,
    speedMetersPerSecond: speed,
    mockedLocation: mocked,
  );

  test('derives bounded movement evidence without retaining coordinates', () {
    final buffer = TripAutomaticEvidenceObservationBuffer();

    expect(buffer.recordLocation(sample(0)), isNotNull);
    final next = buffer.recordLocation(
      sample(20, latitude: 35.0004, longitude: -82.0004),
      bluetoothVehicleId: 'truck-1',
    );

    expect(next, isNotNull);
    expect(next!.displacementMeters, greaterThan(5));
    expect(next.bluetoothVehicleId, 'truck-1');
    expect(buffer.observations, hasLength(2));
    expect(
      buffer.observations
          .singleWhere((item) => item.recordedAt == start)
          .displacementMeters,
      0,
    );
  });

  test(
    'rejects mocked or invalid source evidence before it becomes a proposal',
    () {
      final buffer = TripAutomaticEvidenceObservationBuffer();

      expect(buffer.recordLocation(sample(0, mocked: true)), isNull);
      expect(buffer.recordLocation(sample(1, latitude: 91)), isNull);
      expect(buffer.observations, isEmpty);
    },
  );

  test('allows only one review proposal per evidence window', () {
    final buffer = TripAutomaticEvidenceObservationBuffer();

    expect(buffer.canEmitReviewCandidate, isTrue);
    buffer.markReviewCandidateEmitted();
    expect(buffer.canEmitReviewCandidate, isFalse);
    buffer.reset();
    expect(buffer.canEmitReviewCandidate, isTrue);
    expect(buffer.observations, isEmpty);
  });

  test('bounds old and excess observations', () {
    final buffer = TripAutomaticEvidenceObservationBuffer(
      maximumObservationWindow: const Duration(seconds: 30),
      maximumObservations: 2,
    );

    buffer.recordLocation(sample(0));
    buffer.recordLocation(sample(10, latitude: 35.0001));
    buffer.recordLocation(sample(20, latitude: 35.0002));
    buffer.recordLocation(sample(60, latitude: 35.0003));

    expect(buffer.observations, hasLength(1));
    expect(
      buffer.observations.single.recordedAt,
      start.add(const Duration(seconds: 60)),
    );
  });

  test('rejects a delayed callback without moving the displacement anchor', () {
    final buffer = TripAutomaticEvidenceObservationBuffer();

    buffer.recordLocation(sample(20, longitude: -82.0002));
    expect(buffer.recordLocation(sample(10, longitude: -82.0001)), isNull);
    final next = buffer.recordLocation(sample(30, longitude: -82.0003));

    expect(buffer.observations, hasLength(2));
    expect(next, isNotNull);
    expect(next!.recordedAt, start.add(const Duration(seconds: 30)));
    expect(next.displacementMeters, greaterThan(0));
  });
}
