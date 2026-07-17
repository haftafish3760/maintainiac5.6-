const metersPerMile = 1609.344;

/// Produces a display-only odometer estimate during an active GPS trip. The
/// confirmed odometer is intentionally not overwritten until trip review.
class TripLiveOdometerProjection {
  TripLiveOdometerProjection({
    required this.startingOdometer,
    this.maxSupportedReading = 9999999,
  }) : _lastProjectedReading = _safeStartingOdometer(startingOdometer);

  final int startingOdometer;
  final int maxSupportedReading;
  int _lastProjectedReading;

  int get projectedReading => _lastProjectedReading;

  int updateAcceptedMeters(double acceptedMeters) {
    if (!acceptedMeters.isFinite || acceptedMeters < 0) {
      return _lastProjectedReading;
    }
    final estimated =
        _safeStartingOdometer(startingOdometer) +
        (acceptedMeters / metersPerMile).round();
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
