import 'trip_tracking_models.dart';

enum TripLocationSampleIntakeStatus { accepted, rejected }

enum TripLocationSampleIntakeReason {
  acceptedNativeSample,
  payloadNotMap,
  schemaVersionUnsupported,
  ownerMismatch,
  sessionMismatch,
  missingRequiredFields,
  invalidCoordinate,
  invalidAccuracy,
  invalidTimestamp,
  futureTimestamp,
  staleTimestamp,
  mockedLocationRejected,
  impossibleReportedSpeed,
}

class TripLocationSampleIntakeDecision {
  const TripLocationSampleIntakeDecision({
    required this.status,
    required this.reason,
    required this.sample,
    required this.schemaVersion,
    required this.ownerVerified,
    required this.sessionVerified,
    required this.acceptedClockSkew,
  });

  final TripLocationSampleIntakeStatus status;
  final TripLocationSampleIntakeReason reason;
  final TripLocationSample? sample;
  final int schemaVersion;
  final bool ownerVerified;
  final bool sessionVerified;
  final Duration acceptedClockSkew;

  bool get canFeedTripEngine =>
      status == TripLocationSampleIntakeStatus.accepted && sample != null;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reason': reason.name,
    'payloadSchemaVersion': schemaVersion,
    'canFeedTripEngine': canFeedTripEngine,
    'ownerVerified': ownerVerified,
    'sessionVerified': sessionVerified,
    'acceptedClockSkewBucket': _clockSkewBucket(acceptedClockSkew),
    'validatedBeforeUse': true,
    'authDoesNotImplyAuthorization': true,
    'localTripSessionRequired': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxResponsesTreatedAsExternalInput': true,
    'remoteSampleCanOverrideLocalTruth': false,
    'sampleCanCreateOfficialStop': false,
    'sampleCanConfirmMileage': false,
    'odometerRemainsOfficialMileageTruth': true,
    'mockLocationAccepted': false,
    'malformedPayloadFailsClosed': true,
    'rawLocationIncluded': false,
    'coordinatesIncluded': false,
    'preciseTimestampIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripLocationSampleIntakeGuard {
  const TripLocationSampleIntakeGuard._();

  static TripLocationSampleIntakeDecision evaluate({
    required Object? payload,
    required String expectedOwnerUid,
    required String expectedSessionId,
    required DateTime receivedAt,
    Duration maximumFutureSkew = const Duration(minutes: 2),
    Duration maximumStaleAge = const Duration(hours: 18),
  }) {
    if (payload is! Map) {
      return _rejected(
        TripLocationSampleIntakeReason.payloadNotMap,
        schemaVersion: 0,
      );
    }
    final schemaVersion = _schemaVersion(payload['schemaVersion']);
    if (schemaVersion != 1) {
      return _rejected(
        TripLocationSampleIntakeReason.schemaVersionUnsupported,
        schemaVersion: schemaVersion,
      );
    }

    final ownerVerified =
        _safeToken(payload['ownerUid']) == _safeToken(expectedOwnerUid);
    if (!ownerVerified) {
      return _rejected(
        TripLocationSampleIntakeReason.ownerMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: false,
      );
    }

    final sessionVerified =
        _safeToken(payload['sessionId']) == _safeToken(expectedSessionId);
    if (!sessionVerified) {
      return _rejected(
        TripLocationSampleIntakeReason.sessionMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: false,
      );
    }

    final samplePayload = payload['sample'];
    if (samplePayload is! Map) {
      return _rejected(
        TripLocationSampleIntakeReason.missingRequiredFields,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
      );
    }
    if (samplePayload['mockedLocation'] == true) {
      return _rejected(
        TripLocationSampleIntakeReason.mockedLocationRejected,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
      );
    }

    final sample = TripLocationSample.tryFromMap(samplePayload);
    if (sample == null) {
      return _rejected(
        _parseFailureReason(samplePayload),
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
      );
    }

    final recordedAt = sample.recordedAt.toUtc();
    final received = receivedAt.toUtc();
    if (recordedAt.isAfter(received.add(maximumFutureSkew))) {
      return _rejected(
        TripLocationSampleIntakeReason.futureTimestamp,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        acceptedClockSkew: recordedAt.difference(received),
      );
    }
    if (recordedAt.isBefore(received.subtract(maximumStaleAge))) {
      return _rejected(
        TripLocationSampleIntakeReason.staleTimestamp,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        acceptedClockSkew: received.difference(recordedAt),
      );
    }
    if ((sample.speedMetersPerSecond ?? 0) > 70) {
      return _rejected(
        TripLocationSampleIntakeReason.impossibleReportedSpeed,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        acceptedClockSkew: _durationAbs(received.difference(recordedAt)),
      );
    }

    return TripLocationSampleIntakeDecision(
      status: TripLocationSampleIntakeStatus.accepted,
      reason: TripLocationSampleIntakeReason.acceptedNativeSample,
      sample: sample,
      schemaVersion: schemaVersion,
      ownerVerified: true,
      sessionVerified: true,
      acceptedClockSkew: received.difference(recordedAt).abs(),
    );
  }
}

TripLocationSampleIntakeDecision _rejected(
  TripLocationSampleIntakeReason reason, {
  required int schemaVersion,
  bool ownerVerified = false,
  bool sessionVerified = false,
  Duration acceptedClockSkew = Duration.zero,
}) {
  return TripLocationSampleIntakeDecision(
    status: TripLocationSampleIntakeStatus.rejected,
    reason: reason,
    sample: null,
    schemaVersion: schemaVersion,
    ownerVerified: ownerVerified,
    sessionVerified: sessionVerified,
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

bool _hasKeys(Map<dynamic, dynamic> map, List<String> keys) {
  return keys.every(map.containsKey);
}

int _schemaVersion(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw.isFinite) return raw.floor();
  return 0;
}

String _safeToken(Object? raw) {
  final clean = '${raw ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
      .trim();
  if (clean.isEmpty || clean.length > 160) return '';
  return clean;
}

String _clockSkewBucket(Duration skew) {
  final seconds = _durationAbs(skew).inSeconds;
  if (seconds <= 5) return '0_to_5_seconds';
  if (seconds <= 120) return '6_to_120_seconds';
  if (seconds <= 3600) return '2_to_60_minutes';
  return 'over_60_minutes';
}

Duration _durationAbs(Duration value) => value.isNegative ? -value : value;
