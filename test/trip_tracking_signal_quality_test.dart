import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  test('no samples remain a waiting non-location dashboard state', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(),
    );

    expect(summary.quality, TripTrackingSignalQuality.noSamples);
    expect(summary.healthState, TripTrackingHealthState.reduced);
    expect(summary.requiresUserReview, isFalse);
    expect(summary.toSafeDashboardMap()['coordinatesIncluded'], isFalse);
  });

  test('accepted samples with no rejects are healthy', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 5,
        acceptedSamples: 5,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.acceptedDistance: 4,
        },
      ),
    );

    expect(summary.quality, TripTrackingSignalQuality.healthy);
    expect(summary.reasonCode, 'gps_signal_healthy');
    expect(summary.acceptanceRate, 1);
    expect(summary.healthState, TripTrackingHealthState.healthy);
  });

  test('normal drift is reduced but does not force review by itself', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 6,
        acceptedSamples: 4,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.acceptedDistance: 3,
          TripSampleDisposition.rejectedDrift: 2,
        },
      ),
    );

    expect(summary.quality, TripTrackingSignalQuality.reduced);
    expect(summary.requiresUserReview, isFalse);
    expect(summary.healthState, TripTrackingHealthState.reduced);
  });

  test('repeated poor measurements recommend review', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 8,
        acceptedSamples: 3,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.acceptedDistance: 2,
          TripSampleDisposition.rejectedAccuracy: 3,
          TripSampleDisposition.rejectedSpeedConflict: 2,
        },
      ),
    );

    expect(summary.quality, TripTrackingSignalQuality.poor);
    expect(summary.requiresUserReview, isTrue);
    expect(summary.healthState, TripTrackingHealthState.poor);
  });

  test('provider gaps become interrupted signal quality', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 4,
        acceptedSamples: 3,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.acceptedDistance: 2,
          TripSampleDisposition.rejectedGap: 1,
        },
      ),
    );

    expect(summary.quality, TripTrackingSignalQuality.interrupted);
    expect(summary.reasonCode, 'gps_signal_interrupted_by_gap');
    expect(summary.requiresUserReview, isTrue);
  });

  test('unsafe provider evidence fails closed without raw location data', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 5,
        acceptedSamples: 1,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.rejectedMockLocation: 1,
          TripSampleDisposition.rejectedInvalid: 1,
          TripSampleDisposition.rejectedOutOfOrder: 2,
        },
      ),
    );

    final safe = summary.toSafeDashboardMap();

    expect(summary.quality, TripTrackingSignalQuality.unsafe);
    expect(summary.healthState, TripTrackingHealthState.unavailable);
    expect(summary.requiresUserReview, isTrue);
    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('-79.')));
  });

  test('malformed accepted counts are sanitized', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(receivedSamples: 3, acceptedSamples: 99),
    );

    expect(summary.acceptedSamples, 0);
    expect(summary.rejectedSamples, 3);
    expect(summary.quality, TripTrackingSignalQuality.poor);
  });
}
