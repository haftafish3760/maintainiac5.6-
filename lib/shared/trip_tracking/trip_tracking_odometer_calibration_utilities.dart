// odometerIsGlobalTruth: true.
part of 'trip_tracking_odometer_calibration.dart';

class _DailyCalibrationTotals {
  var odometerMiles = 0.0;
  var gpsMiles = 0.0;

  void add(TripOdometerReconciliation reconciliation) {
    odometerMiles += reconciliation.confirmedOdometerDeltaMiles;
    gpsMiles += reconciliation.filteredGpsMiles;
  }

  TripOdometerReconciliation toReconciliation() {
    final difference = (odometerMiles - gpsMiles).abs();
    final percent = odometerMiles <= 0
        ? double.nan
        : difference / odometerMiles * 100;
    return TripOdometerReconciliation(
      status: TripOdometerReconciliationStatus.aligned,
      confirmedOdometerDeltaMiles: odometerMiles,
      filteredGpsMiles: gpsMiles,
      absoluteDifferenceMiles: difference,
      differencePercent: percent,
    );
  }
}

String _calibrationDayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

double? _recomputedCalibrationDifferencePercent(
  TripOdometerReconciliation sample,
) {
  if (!sample.confirmedOdometerDeltaMiles.isFinite ||
      sample.confirmedOdometerDeltaMiles <= 0 ||
      !sample.filteredGpsMiles.isFinite ||
      sample.filteredGpsMiles < 0) {
    return null;
  }
  final difference =
      (sample.confirmedOdometerDeltaMiles - sample.filteredGpsMiles).abs();
  if (!difference.isFinite) return null;
  final percent = (difference / sample.confirmedOdometerDeltaMiles) * 100;
  return percent.isFinite && percent >= 0 ? percent : null;
}

const _minimumGpsAssistanceCalibrationMultiplier = 0.8;
const _maximumGpsAssistanceCalibrationMultiplier = 1.25;
