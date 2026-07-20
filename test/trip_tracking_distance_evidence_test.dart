import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);

  TripLocationSample sample(
    double longitude,
    int seconds, {
    double accuracy = 5,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: started.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
  );

  test('gap and rejected segment distances remain noncanonical evidence', () {
    final engine = TripTrackingEngine(profile: TripTrackingProfile.roadVehicle);

    expect(
      engine.ingest(sample(-80, 0)).disposition,
      TripSampleDisposition.acceptedAnchor,
    );
    final drift = engine.ingest(sample(-79.999999, 10));
    final gap = engine.ingest(sample(-79.99, 600));

    expect(drift.disposition, TripSampleDisposition.rejectedDrift);
    expect(gap.disposition, TripSampleDisposition.rejectedGap);
    expect(engine.totalAcceptedMeters, 0);
    expect(engine.snapshot.diagnostics.rejectedDistanceMeters, greaterThan(0));
    expect(
      engine.snapshot.diagnostics.estimatedGapDistanceMeters,
      greaterThan(0),
    );
  });

  test('distance evidence survives snapshots without becoming mileage', () {
    final engine = TripTrackingEngine(profile: TripTrackingProfile.roadVehicle);
    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.99, 600));

    final restored = TripTrackingEngineSnapshot.fromMap(
      engine.snapshot.toMap(),
    );

    expect(restored.totalAcceptedMeters, 0);
    expect(restored.diagnostics.estimatedGapDistanceMeters, greaterThan(0));
    expect(
      restored.diagnostics.dispositionCounts[TripSampleDisposition.rejectedGap],
      1,
    );
  });

  test('malformed persisted distance evidence fails neutral', () {
    final diagnostics = TripTrackingDiagnostics.fromMap({
      'receivedSamples': 2,
      'acceptedSamples': 1,
      'dispositionCounts': {'acceptedAnchor': 1, 'rejectedGap': 1},
      'rejectedDistanceMeters': double.nan,
      'estimatedGapDistanceMeters': -20,
    });

    expect(diagnostics.rejectedDistanceMeters, 0);
    expect(diagnostics.estimatedGapDistanceMeters, 0);
    expect(diagnostics.rejectedSamples, 1);
  });
}
