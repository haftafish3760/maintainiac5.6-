part of 'trip_location_sample_intake_guard.dart';

TripLocationSampleIntakeDecision _rejected(
  TripLocationSampleIntakeReason reason, {
  required int schemaVersion,
  bool ownerVerified = false,
  bool sessionVerified = false,
  bool sourceVerified = false,
  bool simulatorHarnessVerified = false,
  Duration acceptedClockSkew = Duration.zero,
}) {
  return TripLocationSampleIntakeDecision(
    status: TripLocationSampleIntakeStatus.rejected,
    reason: reason,
    sample: null,
    schemaVersion: schemaVersion,
    ownerVerified: ownerVerified,
    sessionVerified: sessionVerified,
    sourceVerified: sourceVerified,
    simulatorHarnessVerified: simulatorHarnessVerified,
    acceptedClockSkew: acceptedClockSkew,
  );
}

TripLocationSampleIntakeReason _parseFailureReason(Map<dynamic, dynamic> map) {
  if (!_hasKeys(map, const [
    'latitude',
    'longitude',
    'horizontalAccuracyMeters',
    'recordedAt',
  ])) {
    return TripLocationSampleIntakeReason.missingRequiredFields;
  }
  final lat = map['latitude'];
  final lon = map['longitude'];
  if (lat is! num ||
      lon is! num ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lon < -180 ||
      lon > 180) {
    return TripLocationSampleIntakeReason.invalidCoordinate;
  }
  final accuracy = map['horizontalAccuracyMeters'];
  if (accuracy is! num ||
      !accuracy.isFinite ||
      accuracy <= 0 ||
      accuracy > 10000) {
    return TripLocationSampleIntakeReason.invalidAccuracy;
  }
  final timestamp = map['recordedAt'];
  if (timestamp == null ||
      (timestamp is num && !timestamp.isFinite) ||
      (timestamp is! num && DateTime.tryParse('$timestamp') == null)) {
    return TripLocationSampleIntakeReason.invalidTimestamp;
  }
  return TripLocationSampleIntakeReason.missingRequiredFields;
}

TripLocationSampleIntakeReason? _reportedSpeedFailureReason(
  Map<dynamic, dynamic> map,
) {
  if (!map.containsKey('speedMetersPerSecond') ||
      map['speedMetersPerSecond'] == null) {
    return null;
  }
  final speed = map['speedMetersPerSecond'];
  if (speed is! num || !speed.isFinite || speed < -0.5) {
    return TripLocationSampleIntakeReason.invalidReportedSpeed;
  }
  if (speed > 70) return TripLocationSampleIntakeReason.impossibleReportedSpeed;
  return null;
}

bool _hasKeys(Map<dynamic, dynamic> map, List<String> keys) {
  return keys.every(map.containsKey);
}

Duration _safePositiveDuration(Duration value, Duration fallback) {
  if (value <= Duration.zero) return fallback;
  return value;
}

bool _claimsRemoteAuthority(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if ((key.startsWith('remote') ||
              key.startsWith('firestore') ||
              key.startsWith('cloudFunction') ||
              key.startsWith('mapbox')) &&
          entry.value != false &&
          entry.value != null) {
        return true;
      }
      if (_claimsRemoteAuthority(entry.value)) return true;
    }
  }
  if (value is Iterable) {
    for (final item in value) {
      if (_claimsRemoteAuthority(item)) return true;
    }
  }
  return false;
}

bool _containsSensitivePayload(Object? value) {
  if (value is String) return _looksSensitive(value);
  if (value is Map) {
    for (final entry in value.entries) {
      if (_containsSensitivePayload(entry.key) ||
          _containsSensitivePayload(entry.value)) {
        return true;
      }
    }
  }
  if (value is Iterable) {
    for (final item in value) {
      if (_containsSensitivePayload(item)) return true;
    }
  }
  return false;
}

int _schemaVersion(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw.isFinite) return raw.floor();
  return 0;
}

String _safeToken(Object? raw) {
  final original = '${raw ?? ''}';
  final clean = original.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  if (clean.isEmpty || clean.length > 160) return '';
  if (clean != original) return '';
  if (clean.startsWith('pk.') || clean.startsWith('sk.')) return '';
  if (clean.toLowerCase().contains('token')) return '';
  if (clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'))) return '';
  if (!RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean)) return '';
  return clean;
}

bool _verifiedToken(Object? raw, String expected) {
  final actual = _safeToken(raw);
  final safeExpected = _safeToken(expected);
  return actual.isNotEmpty && safeExpected.isNotEmpty && actual == safeExpected;
}

String _clockSkewBucket(Duration skew) {
  final seconds = _durationAbs(skew).inSeconds;
  if (seconds <= 5) return '0_to_5_seconds';
  if (seconds <= 120) return '6_to_120_seconds';
  if (seconds <= 3600) return '2_to_60_minutes';
  return 'over_60_minutes';
}

Duration _durationAbs(Duration value) => value.isNegative ? -value : value;

TripLocationSampleIntakeStatus? _safeIntakeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLocationSampleIntakeStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripLocationSampleIntakeReason? _safeIntakeReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripLocationSampleIntakeReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
