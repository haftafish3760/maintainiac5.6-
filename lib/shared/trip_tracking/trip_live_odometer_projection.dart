const metersPerMile = 1609.344;

/// Produces a display-only odometer estimate during an active GPS trip. The
/// confirmed odometer is intentionally not overwritten until trip review.
class TripLiveOdometerProjection {
  TripLiveOdometerProjection({
    required this.startingOdometer,
    int maxSupportedReading = 9999999,
  }) : maxSupportedReading = _safeMaxSupportedReading(maxSupportedReading),
       _lastProjectedReading = _safeInitialProjection(
         startingOdometer: startingOdometer,
         maxSupportedReading: maxSupportedReading,
       );

  final int startingOdometer;
  final int maxSupportedReading;
  int _lastProjectedReading;

  int get projectedReading => _lastProjectedReading;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'projectedReading': projectedReading,
    'startingOdometer': _safeStartingOdometer(startingOdometer),
    'maxSupportedReading': maxSupportedReading,
    'advisoryOnly': true,
    'dashboardLiveUpdateReady': true,
    'displayCanUpdateBeforeReview': true,
    'writesConfirmedOdometer': false,
    'confirmedOdometerRemainsCanonical': true,
    'manualConfirmationRequired': true,
    'gpsCanReplaceOdometer': false,
    'mapboxCanReplaceOdometer': false,
    'mapsRequiredForTracking': false,
    'mapboxCanChangeProjection': false,
    'localTripLogProtected': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
  };

  int updateAcceptedMeters(
    double acceptedMeters, {
    double gpsAssistanceCalibrationMultiplier = 1,
  }) {
    if (!acceptedMeters.isFinite || acceptedMeters < 0) {
      return _lastProjectedReading;
    }
    final safeStart = _safeStartingOdometer(startingOdometer);
    final multiplier = _safeCalibrationMultiplier(
      gpsAssistanceCalibrationMultiplier,
    );
    final acceptedMiles = (acceptedMeters / metersPerMile) * multiplier;
    if (!acceptedMiles.isFinite ||
        acceptedMiles > maxSupportedReading - safeStart) {
      return _lastProjectedReading;
    }
    final estimated = safeStart + acceptedMiles.round();
    if (estimated > maxSupportedReading) {
      return _lastProjectedReading;
    }
    if (estimated > _lastProjectedReading) {
      _lastProjectedReading = estimated;
    }
    return _lastProjectedReading;
  }
}

int _safeStartingOdometer(int value) => value < 0 ? 0 : value;

int _safeMaxSupportedReading(int value) => value < 0 ? 0 : value;

double _safeCalibrationMultiplier(double value) {
  if (!value.isFinite || value <= 0) return 1;
  return value.clamp(0.8, 1.25).toDouble();
}

int _safeInitialProjection({
  required int startingOdometer,
  required int maxSupportedReading,
}) {
  final safeStart = _safeStartingOdometer(startingOdometer);
  final safeMax = _safeMaxSupportedReading(maxSupportedReading);
  return safeStart > safeMax ? safeMax : safeStart;
}
