import 'trip_tracking_models.dart';

part 'trip_location_sample_intake_guard_helpers.dart';

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
  remoteAuthorityRejected,
  sensitivePayloadRejected,
  mockedLocationRejected,
  simulatorHarnessRequired,
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
    required this.simulatorHarnessVerified,
    required this.acceptedClockSkew,
  });

  final TripLocationSampleIntakeStatus status;
  final TripLocationSampleIntakeReason reason;
  final TripLocationSample? sample;
  final int schemaVersion;
  final bool ownerVerified;
  final bool sessionVerified;
  final bool sourceVerified;
  final bool simulatorHarnessVerified;
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
    'simulatorHarnessVerified': simulatorHarnessVerified,
    'acceptedClockSkewBucket': _clockSkewBucket(acceptedClockSkew),
    'orderedAfterAcceptedSample':
        reason != TripLocationSampleIntakeReason.duplicateTimestamp &&
        reason != TripLocationSampleIntakeReason.outOfOrderTimestamp,
    'validatedBeforeUse': true,
    'authDoesNotImplyAuthorization': true,
    'localTripSessionRequired': true,
    'nativeLocationSourceRequired': true,
    'sampleRequiresDeviceCapabilityTier': true,
    'sampleRequiresForegroundOrBackgroundPermission': true,
    'sampleRequiresMonotonicDeviceClock': true,
    'simulatorSampleRequiresExplicitTestHarness': true,
    'simulatorHarnessCanFeedTripEngine': simulatorHarnessVerified,
    'simulatorHarnessCannotWriteProductionHistory': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxResponsesTreatedAsExternalInput': true,
    'mapboxDirectionsCanSupplyOfficialSample': false,
    'mapboxMapMatchingCanReplaceSample': false,
    'mapboxOptimizationCanCreateMileage': false,
    'mapboxCanRepairRejectedSample': false,
    'mapboxCanInferMissingSample': false,
    'publicMapboxTokenIncluded': false,
    'secretMapboxTokenIncluded': false,
    'authenticatedUserStillNeedsAuthorization': true,
    'remoteSampleCanOverrideLocalTruth': false,
    'remoteSampleCanMasqueradeAsNative': false,
    'sampleCanCreateOfficialStop': false,
    'sampleCanConfirmMileage': false,
    'sampleCanSetGlobalTruth': false,
    'sampleCanConfirmOfficialMileage': false,
    'sampleCanChangeOfficialMileage': false,
    'sampleCanAdvanceOdometerWithoutWindowQuality': false,
    'sampleCanBypassStopDebounce': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
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
      'simulatorHarnessVerified',
      'validatedBeforeUse',
      'authDoesNotImplyAuthorization',
      'authenticatedUserStillNeedsAuthorization',
      'localTripSessionRequired',
      'nativeLocationSourceRequired',
      'sampleRequiresDeviceCapabilityTier',
      'sampleRequiresForegroundOrBackgroundPermission',
      'sampleRequiresMonotonicDeviceClock',
      'simulatorSampleRequiresExplicitTestHarness',
      'simulatorHarnessCanFeedTripEngine',
      'simulatorHarnessCannotWriteProductionHistory',
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
    if (summary['simulatorHarnessVerified'] == true &&
        summary['simulatorHarnessCanFeedTripEngine'] != true) {
      reasons.add('simulator_harness_claim_inconsistent');
    }
    if (summary['validatedBeforeUse'] != true ||
        summary['authDoesNotImplyAuthorization'] != true ||
        summary['authenticatedUserStillNeedsAuthorization'] != true ||
        summary['localTripSessionRequired'] != true ||
        summary['nativeLocationSourceRequired'] != true ||
        summary['sampleRequiresDeviceCapabilityTier'] != true ||
        summary['sampleRequiresForegroundOrBackgroundPermission'] != true ||
        summary['sampleRequiresMonotonicDeviceClock'] != true ||
        summary['simulatorSampleRequiresExplicitTestHarness'] != true ||
        summary['simulatorHarnessCannotWriteProductionHistory'] != true) {
      reasons.add('authorization_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true) {
      reasons.add('local_truth_boundary_missing');
    }
    if (summary['mapboxResponsesTreatedAsExternalInput'] != true ||
        summary['mapboxDirectionsCanSupplyOfficialSample'] != false ||
        summary['mapboxMapMatchingCanReplaceSample'] != false ||
        summary['mapboxOptimizationCanCreateMileage'] != false ||
        summary['mapboxCanRepairRejectedSample'] != false ||
        summary['mapboxCanInferMissingSample'] != false) {
      reasons.add('mapbox_can_control_sample_truth');
    }
    if (summary['remoteSampleCanOverrideLocalTruth'] != false ||
        summary['remoteSampleCanMasqueradeAsNative'] != false ||
        summary['sampleCanCreateOfficialStop'] != false ||
        summary['sampleCanConfirmMileage'] != false ||
        summary['sampleCanSetGlobalTruth'] != false ||
        summary['sampleCanConfirmOfficialMileage'] != false ||
        summary['sampleCanChangeOfficialMileage'] != false ||
        summary['sampleCanAdvanceOdometerWithoutWindowQuality'] != false ||
        summary['sampleCanBypassStopDebounce'] != false ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true ||
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
    bool allowExplicitSimulatorHarness = false,
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
    final simulatorSource = payload['source'] == 'simulated_native_location';
    final sourceVerified =
        payload['source'] == 'native_location' ||
        payload['source'] == 'validated_native_location' ||
        (simulatorSource && allowExplicitSimulatorHarness);
    if (!sourceVerified) {
      return _rejected(
        simulatorSource
            ? TripLocationSampleIntakeReason.simulatorHarnessRequired
            : TripLocationSampleIntakeReason.sourceMismatch,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: false,
      );
    }
    if (_containsSensitivePayload(payload)) {
      return _rejected(
        TripLocationSampleIntakeReason.sensitivePayloadRejected,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
      );
    }
    if (_claimsRemoteAuthority(payload)) {
      return _rejected(
        TripLocationSampleIntakeReason.remoteAuthorityRejected,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
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
    final futureSkew = _safePositiveDuration(
      maximumFutureSkew,
      const Duration(minutes: 2),
    );
    final staleAge = _safePositiveDuration(
      maximumStaleAge,
      const Duration(hours: 18),
    );
    if (recordedAt.isAfter(received.add(futureSkew))) {
      return _rejected(
        TripLocationSampleIntakeReason.futureTimestamp,
        schemaVersion: schemaVersion,
        ownerVerified: true,
        sessionVerified: true,
        sourceVerified: true,
        acceptedClockSkew: recordedAt.difference(received),
      );
    }
    if (recordedAt.isBefore(received.subtract(staleAge))) {
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
      simulatorHarnessVerified:
          simulatorSource && allowExplicitSimulatorHarness,
      acceptedClockSkew: received.difference(recordedAt).abs(),
    );
  }
}
