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
    expect(summary.toSafeDashboardMap()['schemaVersion'], 1);
    expect(summary.toSafeDashboardMap()['advisoryOnly'], isTrue);
    expect(
      summary.toSafeDashboardMap()['diagnosticsCanOnlyRequestReview'],
      isTrue,
    );
    expect(summary.toSafeDashboardMap()['diagnosticsCanEndTrip'], isFalse);
    expect(summary.toSafeDashboardMap()['stopReviewRequiresTrustedGps'], isTrue);
    expect(
      summary.toSafeDashboardMap()['stopReviewSignalQualityEligible'],
      isFalse,
    );
    expect(summary.toSafeDashboardMap()['noGpsCanOpenStopReview'], isFalse);
    expect(summary.toSafeDashboardMap()['officialMileageSource'], 'odometer');
    expect(summary.toSafeDashboardMap()['odometerIsGlobalTruth'], isTrue);
    expect(summary.toSafeDashboardMap()['canReplaceOdometer'], isFalse);
    expect(
      summary.toSafeDashboardMap()['calibrationRequiresTrustedGpsWindow'],
      isTrue,
    );
    expect(
      summary.toSafeDashboardMap()['poorGpsDaysExcludedFromCalibration'],
      isTrue,
    );
    expect(
      summary.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isFalse,
    );
    expect(
      summary.toSafeDashboardMap()['calibrationRequiresMinimumAcceptedSamples'],
      isTrue,
    );
    expect(
      summary.toSafeDashboardMap()['minimumAcceptedSamplesForCalibration'],
      5,
    );
    expect(
      summary.toSafeDashboardMap()['signalQualityCanCreateCalibration'],
      isFalse,
    );
    expect(
      summary.toSafeDashboardMap()['gpsCanWriteConfirmedTripLog'],
      isFalse,
    );
    expect(summary.toSafeDashboardMap()['mapboxCanReplaceOdometer'], isFalse);
    expect(
      summary.toSafeDashboardMap()['mapboxCanWriteConfirmedTripLog'],
      isFalse,
    );
    expect(
      summary.toSafeDashboardMap()['remoteTotalsCanBecomeCanonical'],
      isFalse,
    );
    expect(
      summary
          .toSafeDashboardMap()['externalDiagnosticsTrustedAfterValidationOnly'],
      isTrue,
    );
    expect(
      summary
          .toSafeDashboardMap()['firestoreDiagnosticsCanOverrideLocalTripLog'],
      isFalse,
    );
    expect(summary.toSafeDashboardMap()['localTripLogProtected'], isTrue);
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
    expect(
      summary.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isTrue,
    );
    expect(
      summary.toSafeDashboardMap()['stopReviewSignalQualityEligible'],
      isTrue,
    );
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
    expect(
      summary.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isFalse,
    );
    expect(
      summary.toSafeDashboardMap()['stopReviewSignalQualityEligible'],
      isTrue,
    );
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
    expect(
      summary.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isFalse,
    );
    expect(summary.toSafeDashboardMap()['poorGpsCanOpenStopReview'], isFalse);
    expect(
      summary.toSafeDashboardMap()['stopReviewSignalQualityEligible'],
      isFalse,
    );
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
    expect(
      summary.toSafeDashboardMap()['interruptedGpsCanOpenStopReview'],
      isFalse,
    );
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
    expect(safe['canUploadRawGps'], isFalse);
    expect(safe['unsafeGpsCanOpenStopReview'], isFalse);
    expect(safe['signalQualityCanApplyCalibration'], isFalse);
    expect(safe['signalQualityEligibleForCalibration'], isFalse);
    expect(safe['mapboxGeometryIncluded'], isFalse);
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

  test('sparse accepted samples are not calibration proof', () {
    final summary = TripTrackingSignalQualitySummary.evaluate(
      const TripTrackingDiagnostics(
        receivedSamples: 3,
        acceptedSamples: 3,
        dispositionCounts: {
          TripSampleDisposition.acceptedAnchor: 1,
          TripSampleDisposition.acceptedDistance: 2,
        },
      ),
    );
    final safe = summary.toSafeDashboardMap();

    expect(summary.quality, TripTrackingSignalQuality.healthy);
    expect(safe['stopReviewSignalQualityEligible'], isTrue);
    expect(safe['signalQualityEligibleForCalibration'], isFalse);
    expect(safe['minimumAcceptedSamplesForCalibration'], 5);
  });

  test('safe signal summaries sanitize direct malformed public fields', () {
    const summary = TripTrackingSignalQualitySummary(
      quality: TripTrackingSignalQuality.reduced,
      reasonCode: 'lat=35.1 token=sk.secret',
      receivedSamples: 4,
      acceptedSamples: 2,
      rejectedSamples: 2,
      acceptanceRate: .5,
      requiresUserReview: false,
    );
    final safe = summary.toSafeDashboardMap();

    expect(safe['reasonCode'], 'gps_signal_unsafe_provider_evidence');
    expect(safe['requiresUserReview'], isTrue);
    expect(safe['receivedSamples'], 4);
    expect(safe['acceptedSamples'], 2);
    expect(safe['rejectedSamples'], 2);
    expect(safe['acceptanceRate'], .5);
    expect(safe['diagnosticsCanOnlyRequestReview'], isTrue);
    expect(safe['diagnosticsCanEndTrip'], isFalse);
    expect(safe['remoteTotalsCanBecomeCanonical'], isFalse);
    expect(safe['localTripLogProtected'], isTrue);
    expect(safe.toString(), isNot(contains('35.1')));
    expect(safe.toString(), isNot(contains('sk.secret')));
  });

  test('safe signal summaries clamp malformed direct counters', () {
    const summary = TripTrackingSignalQualitySummary(
      quality: TripTrackingSignalQuality.poor,
      reasonCode: 'gps_signal_poor_measurement_quality',
      receivedSamples: -10,
      acceptedSamples: 9999999,
      rejectedSamples: 9999999,
      acceptanceRate: double.infinity,
      requiresUserReview: true,
    );
    final safe = summary.toSafeDashboardMap();

    expect(safe['receivedSamples'], 0);
    expect(safe['acceptedSamples'], 0);
    expect(safe['rejectedSamples'], 0);
    expect(safe['acceptanceRate'], 0);
    expect(safe['malformedDiagnosticsFailClosed'], isTrue);
    expect(safe['signalQualityEligibleForCalibration'], isFalse);
    expect(safe['cloudFunctionDiagnosticsCanOverrideLocalTripLog'], isFalse);
    expect(safe['mapboxDiagnosticsCanOverrideLocalTripLog'], isFalse);
  });

  test('direct contradictory signal summaries cannot suppress review', () {
    const unsafe = TripTrackingSignalQualitySummary(
      quality: TripTrackingSignalQuality.healthy,
      reasonCode: 'gps_signal_unsafe_provider_evidence',
      receivedSamples: 10,
      acceptedSamples: 10,
      rejectedSamples: 0,
      acceptanceRate: 1,
      requiresUserReview: false,
    );
    const poor = TripTrackingSignalQualitySummary(
      quality: TripTrackingSignalQuality.poor,
      reasonCode: 'gps_signal_healthy',
      receivedSamples: 10,
      acceptedSamples: 10,
      rejectedSamples: 0,
      acceptanceRate: 1,
      requiresUserReview: false,
    );

    expect(unsafe.toSafeDashboardMap()['requiresUserReview'], isTrue);
    expect(poor.toSafeDashboardMap()['requiresUserReview'], isTrue);
    expect(
      unsafe.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isFalse,
    );
    expect(
      poor.toSafeDashboardMap()['signalQualityEligibleForCalibration'],
      isFalse,
    );
    expect(unsafe.toSafeDashboardMap()['gpsCanWriteConfirmedTripLog'], isFalse);
    expect(poor.toSafeDashboardMap()['diagnosticsCanEndTrip'], isFalse);
  });

  test('restored contradictory diagnostics become poor review state', () {
    final diagnostics = TripTrackingDiagnostics.fromMap({
      'receivedSamples': 5,
      'acceptedSamples': 4,
      'dispositionCounts': {
        'acceptedAnchor': 1,
        'acceptedDistance': 4,
        'rejectedMockLocation': 3,
      },
    });
    final summary = TripTrackingSignalQualitySummary.evaluate(diagnostics);

    expect(summary.acceptedSamples, 0);
    expect(summary.rejectedSamples, 5);
    expect(summary.quality, TripTrackingSignalQuality.poor);
    expect(summary.toSafeDashboardMap()['rawSamplesIncluded'], isFalse);
  });
}
