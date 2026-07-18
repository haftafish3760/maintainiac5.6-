import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_state.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';

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
    expect(TripTrackingCalibrationState.initial(double.nan).multiplier, 1);
    expect(TripTrackingCalibrationState.initial(-2).multiplier, 1);
    expect(TripTrackingCalibrationState.initial(.1).multiplier, .8);
    expect(TripTrackingCalibrationState.initial(9).multiplier, 1.25);
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
}
