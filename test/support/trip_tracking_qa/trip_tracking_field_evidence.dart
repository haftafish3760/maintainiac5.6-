const _maxWalkingStopsPerRun = 10000;

class TripTrackingFieldEvidence {
  const TripTrackingFieldEvidence({
    required this.platform,
    required this.odometerMiles,
    required this.filteredGpsMiles,
    this.expectedWalkingStops = 0,
    this.detectedWalkingStops = 0,
    this.matchedWalkingStops = 0,
  });

  final String platform;
  final double odometerMiles;
  final double filteredGpsMiles;
  final int expectedWalkingStops;
  final int detectedWalkingStops;
  final int matchedWalkingStops;

  factory TripTrackingFieldEvidence.fromMap(Map<String, Object?> map) {
    const allowedKeys = {
      'platform',
      'odometerMiles',
      'filteredGpsMiles',
      'expectedWalkingStops',
      'detectedWalkingStops',
      'matchedWalkingStops',
    };
    for (final key in map.keys) {
      if (!allowedKeys.contains(key)) {
        throw const FormatException('unsupported_field_evidence_key');
      }
      final lower = key.toLowerCase();
      if (lower == 'lat' ||
          lower == 'lng' ||
          lower.contains('latitude') ||
          lower.contains('longitude') ||
          lower.contains('coordinate') ||
          lower.contains('routegeometry') ||
          lower.contains('polyline') ||
          lower.contains('address') ||
          lower.contains('timestamp') ||
          lower.contains('recordedat')) {
        throw const FormatException(
          'field_evidence_must_not_contain_location_data',
        );
      }
    }
    final platform = map['platform'];
    final odometer = _number(map['odometerMiles']);
    final gps = _number(map['filteredGpsMiles']);
    final expectedStops = _nonNegativeInt(map['expectedWalkingStops']) ?? 0;
    final detectedStops = _nonNegativeInt(map['detectedWalkingStops']) ?? 0;
    final matchedStops = _nonNegativeInt(map['matchedWalkingStops']) ?? 0;
    if (platform is! String ||
        (platform != 'android' && platform != 'ios') ||
        odometer == null ||
        gps == null ||
        odometer < 0 ||
        gps < 0 ||
        (map.containsKey('expectedWalkingStops') &&
            _nonNegativeInt(map['expectedWalkingStops']) == null) ||
        (map.containsKey('detectedWalkingStops') &&
            _nonNegativeInt(map['detectedWalkingStops']) == null) ||
        (map.containsKey('matchedWalkingStops') &&
            _nonNegativeInt(map['matchedWalkingStops']) == null) ||
        matchedStops > expectedStops ||
        matchedStops > detectedStops) {
      throw const FormatException(
        'invalid_coordinate_minimized_field_evidence',
      );
    }
    return TripTrackingFieldEvidence(
      platform: platform,
      odometerMiles: odometer,
      filteredGpsMiles: gps,
      expectedWalkingStops: expectedStops,
      detectedWalkingStops: detectedStops,
      matchedWalkingStops: matchedStops,
    );
  }

  double get absoluteDistanceErrorMiles =>
      (filteredGpsMiles - odometerMiles).abs();

  Map<String, Object?> toSafeSummary() => {
    'platform': platform,
    'odometerMiles': _round(odometerMiles),
    'filteredGpsMiles': _round(filteredGpsMiles),
    'absoluteDistanceErrorMiles': _round(absoluteDistanceErrorMiles),
    'expectedWalkingStops': expectedWalkingStops,
    'detectedWalkingStops': detectedWalkingStops,
    'matchedWalkingStops': matchedWalkingStops,
    'missedWalkingStops': expectedWalkingStops - matchedWalkingStops,
    'falseWalkingStops': detectedWalkingStops - matchedWalkingStops,
    'walkingStopCountDelta': detectedWalkingStops - expectedWalkingStops,
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

int? _nonNegativeInt(Object? value) =>
    value is int && value >= 0 && value <= _maxWalkingStopsPerRun
    ? value
    : null;

double _round(double value) => double.parse(value.toStringAsFixed(3));
