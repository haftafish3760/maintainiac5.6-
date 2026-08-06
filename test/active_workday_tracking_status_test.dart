// Active Day GPS status regression coverage.
//
// Owns deterministic presentation checks for controller evidence states.
// Does not start native tracking or validate device GPS behavior. Consumed by
// Dashboard regression gates; prevents the UI from calling uncertain GPS live.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_tracking_status_line.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  test('Active Day never calls an initial-fix wait live GPS', () {
    final status = ActiveWorkdayTrackingStatus.forSnapshot(
      gpsAssistanceEnabled: true,
      nativeTracking: true,
      tracking: true,
      lifecycleState: TripTrackingSessionLifecycleState.active,
      platformStatus: 'tracking',
      awaitingInitialFix: true,
      signalReviewRequired: false,
    );

    expect(status.label, contains('acquiring'));
  });

  test('Active Day makes degraded signal evidence visible', () {
    final status = ActiveWorkdayTrackingStatus.forSnapshot(
      gpsAssistanceEnabled: true,
      nativeTracking: true,
      tracking: true,
      lifecycleState: TripTrackingSessionLifecycleState.degraded,
      platformStatus: 'gps_signal_stale',
      awaitingInitialFix: false,
      signalReviewRequired: true,
    );

    expect(status.label, contains('degraded'));
    expect(status.label, isNot(contains('GPS live')));
  });

  test(
    'Active Day reports live GPS only after current evidence is healthy',
    () {
      final status = ActiveWorkdayTrackingStatus.forSnapshot(
        gpsAssistanceEnabled: true,
        nativeTracking: true,
        tracking: true,
        lifecycleState: TripTrackingSessionLifecycleState.active,
        platformStatus: 'tracking',
        awaitingInitialFix: false,
        signalReviewRequired: false,
      );

      expect(status.label, contains('GPS live'));
    },
  );

  test(
    'Active Day keeps an explicit paused state after native collection ends',
    () {
      final status = ActiveWorkdayTrackingStatus.forSnapshot(
        gpsAssistanceEnabled: true,
        nativeTracking: false,
        tracking: false,
        lifecycleState: null,
        platformStatus: 'paused',
        awaitingInitialFix: true,
        signalReviewRequired: false,
      );

      expect(status.label, contains('Location paused'));
    },
  );

  test(
    'Active Day labels accepted GPS distance as evidence, not mileage truth',
    () {
      expect(
        ActiveWorkdayTrackingStatus.evidenceSummaryFor(
          tracking: true,
          nativeTracking: true,
          acceptedMiles: 2.34,
        ),
        'GPS evidence: 2.3 mi accepted. Odometer stays official.',
      );
      expect(
        ActiveWorkdayTrackingStatus.evidenceSummaryFor(
          tracking: true,
          nativeTracking: false,
          acceptedMiles: 2.34,
        ),
        'GPS evidence paused. No new GPS distance is being added.',
      );
      expect(
        ActiveWorkdayTrackingStatus.evidenceSummaryFor(
          tracking: false,
          nativeTracking: false,
          acceptedMiles: 0,
        ),
        isNull,
      );
    },
  );

  test(
    'GPS test details explain live evidence without exposing coordinates',
    () {
      final details = ActiveWorkdayTrackingStatus.diagnosticSummaryFor(
        nativeTracking: true,
        providerRegistered: true,
        awaitingInitialFix: false,
        receivedSamples: 12,
        acceptedSamples: 10,
        rejectedSamples: 2,
        signalQuality: TripTrackingSignalQuality.healthy,
        signalReason: 'accepted_evidence',
        motionState: TripMotionState.stopCandidate,
        signalGapCount: 1,
        pendingStopCount: 1,
        hasAcceptedLocation: true,
        bluetoothLabel: 'Bluetooth recognizes the active vehicle',
      );

      expect(details, contains('Collector: running'));
      expect(details, contains('12 received · 10 accepted · 2 rejected'));
      expect(details, contains('Motion: stopCandidate'));
      expect(details, contains('stops waiting for review: 1'));
      expect(details, contains('No coordinates are shown here'));
      expect(details, contains('odometer and your review remain official'));
    },
  );
}
