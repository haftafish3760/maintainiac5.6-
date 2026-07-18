import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_state.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  TripOdometerCalibrationSignal signal(double multiplier) =>
      TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        reasonCode: 'persistent_gps_odometer_drift',
        eligibleSampleCount: 7,
        averageGpsToOdometerRatio: multiplier <= 0 || !multiplier.isFinite
            ? multiplier
            : 1 / multiplier,
        averageDifferencePercent: 10,
      );

  test('initial calibration multiplier is bounded and advisory only', () {
    final initial = TripTrackingCalibrationState.initial(double.nan);

    expect(initial.multiplier, 1);
    expect(TripTrackingCalibrationState.initial(-2).multiplier, 1);
    expect(TripTrackingCalibrationState.initial(.1).multiplier, .8);
    expect(TripTrackingCalibrationState.initial(9).multiplier, 1.25);
    expect(initial.toSafeSummary()['advisoryOnly'], isTrue);
    expect(
      initial.toSafeSummary()['calibrationCanReplaceConfirmedOdometer'],
      isFalse,
    );
    expect(initial.toSafeSummary()['odometerRemainsCanonical'], isTrue);
  });

  test('disabled calibration always uses neutral multiplier', () {
    final state = TripTrackingCalibrationState.initial(
      .8,
    ).refresh(enabled: false, signal: signal(.9));

    expect(state.enabled, isFalse);
    expect(state.multiplier, 1);
  });

  test('enabled calibration follows bounded reviewed-history signal', () {
    final low = TripTrackingCalibrationState.initial(
      1,
    ).refresh(enabled: true, signal: signal(.25));
    final high = TripTrackingCalibrationState.initial(
      1,
    ).refresh(enabled: true, signal: signal(4));

    expect(low.enabled, isTrue);
    expect(low.multiplier, .8);
    expect(high.multiplier, 1.25);
  });

  test('enabled refresh is a no-op when calibration assist is off', () {
    final state = TripTrackingCalibrationState.initial(.9);

    expect(state.refreshEnabled(signal(.8)), same(state));
  });

  test('calibration summary keeps remote and map data advisory-only', () {
    final state = TripTrackingCalibrationState.initial(
      1,
    ).refresh(enabled: true, signal: signal(.9));
    final summary = state.toSafeSummary();

    expect(summary['enabled'], isTrue);
    expect(summary['requiresReviewedOdometerHistory'], isTrue);
    expect(summary['continuousCalibrationAverageRequired'], isTrue);
    expect(summary['singleDayCalibrationRejected'], isTrue);
    expect(summary['calibrationRequiresVehicleScopedHistory'], isTrue);
    expect(summary['calibrationCanRewritePastTrips'], isFalse);
    expect(summary['calibrationCanLowerConfirmedOdometer'], isFalse);
    expect(summary['calibrationCanCreateMaintenanceRecord'], isFalse);
    expect(summary['calibrationAppliesToFutureGpsProjectionOnly'], isTrue);
    expect(summary['gpsEstimateRemainsNonCanonical'], isTrue);
    expect(summary['remoteCalibrationCanOverrideLocalState'], isFalse);
    expect(summary['remoteCalibrationCanEnableSetting'], isFalse);
    expect(summary['remoteCalibrationCanResetPrompt'], isFalse);
    expect(summary['mapboxCanOverrideCalibration'], isFalse);
    expect(summary['mapboxCanTriggerTirePrompt'], isFalse);
    expect(summary['gpsCanAutoApplyCalibration'], isFalse);
    expect(summary['malformedCalibrationSignalFailsNeutral'], isTrue);
    expect(summary['rawGpsIncluded'], isFalse);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
  });

  test('calibration signal cannot mutate trip logs or confirmed miles', () {
    final summary = signal(.9).toSafeDashboardMap();

    expect(summary['gpsAssistCanOnlyScaleFutureProjectionAfterOptIn'], isTrue);
    expect(summary['continuousCalibrationAverageRequired'], isTrue);
    expect(summary['singleDayCalibrationRejected'], isTrue);
    expect(summary['calibrationRequiresVehicleScopedHistory'], isTrue);
    expect(summary['calibrationCanChangeDisplayedConfirmedMiles'], isFalse);
    expect(summary['calibrationCanMutateTripLog'], isFalse);
    expect(summary['calibrationCanLowerConfirmedOdometer'], isFalse);
    expect(summary['calibrationCanCreateMaintenanceRecord'], isFalse);
    expect(summary['mapboxRouteDistanceCanBecomeOfficial'], isFalse);
    expect(summary['mapboxCanTriggerTirePrompt'], isFalse);
    expect(summary['gpsCanAutoApplyCalibration'], isFalse);
    expect(summary['calibrationCanRewritePastTrips'], isFalse);
    expect(summary['canOverwriteConfirmedOdometer'], isFalse);
    expect(summary['rawReviewedTripsIncluded'], isFalse);
    expect(summary['rawLocationIncluded'], isFalse);
  });
}
