class TripTrackingFieldEvidence {
  const TripTrackingFieldEvidence({
    required this.platform,
    required this.odometerMiles,
    required this.filteredGpsMiles,
  });

  final String platform;
  final double odometerMiles;
  final double filteredGpsMiles;

  factory TripTrackingFieldEvidence.fromMap(Map<String, Object?> map) {
    for (final key in map.keys) {
      final lower = key.toLowerCase();
      if (lower.contains('latitude') ||
          lower.contains('longitude') ||
          lower.contains('coordinate') ||
          lower.contains('routegeometry') ||
          lower.contains('address')) {
        throw const FormatException(
          'field_evidence_must_not_contain_location_data',
        );
      }
    }
    final platform = map['platform'];
    final odometer = _number(map['odometerMiles']);
    final gps = _number(map['filteredGpsMiles']);
    if (platform is! String ||
        (platform != 'android' && platform != 'ios') ||
        odometer == null ||
        gps == null ||
        odometer < 0 ||
        gps < 0) {
      throw const FormatException(
        'invalid_coordinate_minimized_field_evidence',
      );
    }
    return TripTrackingFieldEvidence(
      platform: platform,
      odometerMiles: odometer,
      filteredGpsMiles: gps,
    );
  }

  double get absoluteDistanceErrorMiles =>
      (filteredGpsMiles - odometerMiles).abs();

  Map<String, Object?> toSafeSummary() => {
    'platform': platform,
    'odometerMiles': _round(odometerMiles),
    'filteredGpsMiles': _round(filteredGpsMiles),
    'absoluteDistanceErrorMiles': _round(absoluteDistanceErrorMiles),
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'realDeviceEvidenceIsNotAutomaticCertification': true,
  };
}

double? _number(Object? value) {
  if (value is int) return value.toDouble();
  if (value is double && value.isFinite) return value;
  return null;
}

double _round(double value) => double.parse(value.toStringAsFixed(3));
