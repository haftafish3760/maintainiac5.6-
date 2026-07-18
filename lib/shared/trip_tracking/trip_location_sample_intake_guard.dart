import 'trip_tracking_models.dart';

enum TripLocationSampleIntakeStatus { accepted, rejected }

enum TripLocationSampleIntakeReason {
  acceptedNativeSample,
  payloadNotMap,
  schemaVersionUnsupported,
  ownerMismatch,
  sessionMismatch,
  sourceMismatch,
  missingRequiredFields,
  invalidCoordinate,
  invalidAccuracy,
  invalidTimestamp,
  futureTimestamp,
  staleTimestamp,
  duplicateTimestamp,
  outOfOrderTimestamp,
  mockedLocationRejected,
  invalidReportedSpeed,
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
    required this.sourceVerified,
    required this.acceptedClockSkew,
  });

  final TripLocationSampleIntakeStatus status;
  final TripLocationSampleIntakeReason reason;
  final TripLocationSample? sample;
  final int schemaVersion;
  final bool ownerVerified;
  final bool sessionVerified;
  final bool sourceVerified;
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
    'sourceVerified': sourceVerified,
    'acceptedClockSkewBucket': _clockSkewBucket(acceptedClockSkew),
    'orderedAfterAcceptedSample':
        reason != TripLocationSampleIntakeReason.duplicateTimestamp &&
        reason != TripLocationSampleIntakeReason.outOfOrderTimestamp,
    'validatedBeforeUse': true,
    'authDoesNotImplyAuthorization': true,
    'localTripSessionRequired': true,
    'nativeLocationSourceRequired': true,
    'simulatorSampleRequiresExplicitTestHarness': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxResponsesTreatedAsExternalInput': true,
    'mapboxDirectionsCanSupplyOfficialSample': false,
    'mapboxMapMatchingCanReplaceSample': false,
    'mapboxOptimizationCanCreateMileage': false,
    'publicMapboxTokenIncluded': false,
    'secretMapboxTokenIncluded': false,
    'authenticatedUserStillNeedsAuthorization': true,
    'remoteSampleCanOverrideLocalTruth': false,
    'remoteSampleCanMasqueradeAsNative': false,
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

class TripLocationSampleIntakeSummaryValidation {
  const TripLocationSampleIntakeSummaryValidation._({
    required this.isRenderable,
    required this.status,
    required this.reason,
    required this.reasons,
  });

  factory TripLocationSampleIntakeSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeIntakeStatus(summary['status']);
    final reason = _safeIntakeReason(summary['reason']);

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_intake_status');
    if (reason == null) reasons.add('invalid_intake_reason');
    if (summary['payloadSchemaVersion'] is! int) {
      reasons.add('invalid_payload_schema_version');
    }
    for (final key in const [
      'canFeedTripEngine',
      'ownerVerified',
      'sessionVerified',
      'sourceVerified',
      'validatedBeforeUse',
      'authDoesNotImplyAuthorization',
      'authenticatedUserStillNeedsAuthorization',
      'localTripSessionRequired',
      'nativeLocationSourceRequired',
      'simulatorSampleRequiresExplicitTestHarness',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['canFeedTripEngine'] == true &&
        (status != TripLocationSampleIntakeStatus.accepted ||
            reason != TripLocationSampleIntakeReason.acceptedNativeSample ||
            summary['ownerVerified'] != true ||
            summary['sessionVerified'] != true ||
            summary['sourceVerified'] != true)) {
      reasons.add('unsafe_engine_feed_claim');
    }
    if (summary['validatedBeforeUse'] != true ||
        summary['authDoesNotImplyAuthorization'] != true ||
        summary['authenticatedUserStillNeedsAuthorization'] != true ||
        summary['localTripSessionRequired'] != true ||
        summary['nativeLocationSourceRequired'] != true ||
        summary['simulatorSampleRequiresExplicitTestHarness'] != true) {
      reasons.add('authorization_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true) {
      reasons.add('local_truth_boundary_missing');
    }
    if (summary['mapboxResponsesTreatedAsExternalInput'] != true ||
        summary['mapboxDirectionsCanSupplyOfficialSample'] != false ||
        summary['mapboxMapMatchingCanReplaceSample'] != false ||
        summary['mapboxOptimizationCanCreateMileage'] != false) {
      reasons.add('mapbox_can_control_sample_truth');
    }
    if (summary['remoteSampleCanOverrideLocalTruth'] != false ||
        summary['remoteSampleCanMasqueradeAsNative'] != false ||
        summary['sampleCanCreateOfficialStop'] != false ||
        summary['sampleCanConfirmMileage'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['mockLocationAccepted'] != false) {
      reasons.add('sample_can_create_trip_truth');
    }
    if (summary['malformedPayloadFailsClosed'] != true) {
      reasons.add('malformed_payload_not_fail_closed');
    }
    if (summary['rawLocationIncluded'] != false ||
        summary['coordinatesIncluded'] != false ||
        summary['preciseTimestampIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary['publicMapboxTokenIncluded'] != false ||
        summary['secretMapboxTokenIncluded'] != false) {
      reasons.add('summary_contains_sensitive_trip_material');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripLocationSampleIntakeSummaryValidation._(
      isRenderable: reasons.isEmpty,
      status: reasons.isEmpty ? status : null,
      reason: reasons.isEmpty ? reason : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripLocationSampleIntakeStatus? status;
  final TripLocationSampleIntakeReason? reason;
  final List<String> reasons;
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
    DateTime? latestAcceptedRecordedAt,
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

    final ownerVerified = _verifiedToken(payload['ownerUid'], expectedOwnerUid);
    if (!ownerVerified) {
      return _rejected(
        TripLocationSampleIntakeReason.ownerMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: false,
      );
    }

    final sessionVerified = _verifiedToken(
      payload['sessionId'],
      expectedSessionId,
    );
    if (!sessionVerified) {
      return _rejected(
        TripLocationSampleIntakeReason.sessionMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: false,
      );
    }
    final sourceVerified =
        payload['source'] == 'native_location' ||
        payload['source'] == 'validated_native_location';
    if (!sourceVerified) {
      return _rejected(
        TripLocationSampleIntakeReason.sourceMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: false,
      );
    }

    final samplePayload = payload['sample'];
    if (samplePayload is! Map) {
      return _rejected(
        TripLocationSampleIntakeReason.missingRequiredFields,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
      );
    }
    if (samplePayload['mockedLocation'] == true) {
      return _rejected(
        TripLocationSampleIntakeReason.mockedLocationRejected,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
      );
    }
    final reportedSpeedFailure = _reportedSpeedFailureReason(samplePayload);
    if (reportedSpeedFailure != null) {
      return _rejected(
        reportedSpeedFailure,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
      );
    }

    final sample = TripLocationSample.tryFromMap(samplePayload);
    if (sample == null) {
      return _rejected(
        _parseFailureReason(samplePayload),
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
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
        sourceVerified: true,
        acceptedClockSkew: recordedAt.difference(received),
      );
    }
    if (recordedAt.isBefore(received.subtract(maximumStaleAge))) {
      return _rejected(
        TripLocationSampleIntakeReason.staleTimestamp,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
        acceptedClockSkew: received.difference(recordedAt),
      );
    }
    final latestAccepted = latestAcceptedRecordedAt?.toUtc();
    if (latestAccepted != null) {
      if (recordedAt.isAtSameMomentAs(latestAccepted)) {
        return _rejected(
          TripLocationSampleIntakeReason.duplicateTimestamp,
          schemaVersion: schemaVersion,
          ownerVerified: true,
          sessionVerified: true,
          sourceVerified: true,
          acceptedClockSkew: Duration.zero,
        );
      }
      if (recordedAt.isBefore(latestAccepted)) {
        return _rejected(
          TripLocationSampleIntakeReason.outOfOrderTimestamp,
          schemaVersion: schemaVersion,
          ownerVerified: true,
          sessionVerified: true,
          sourceVerified: true,
          acceptedClockSkew: latestAccepted.difference(recordedAt),
        );
      }
    }
    if ((sample.speedMetersPerSecond ?? 0) > 70) {
      return _rejected(
        TripLocationSampleIntakeReason.impossibleReportedSpeed,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
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
      sourceVerified: true,
      acceptedClockSkew: received.difference(recordedAt).abs(),
    );
  }
}

TripLocationSampleIntakeDecision _rejected(
  TripLocationSampleIntakeReason reason, {
  required int schemaVersion,
  bool ownerVerified = false,
  bool sessionVerified = false,
  bool sourceVerified = false,
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
  if (clean.startsWith('pk.') || clean.startsWith('sk.')) return '';
  if (clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'))) return '';
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
