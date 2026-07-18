enum TripStopFalsePositiveGuardStatus {
  passed,
  blockedTrafficControlReview,
  blockedVehicleOnlyAutoReview,
  blockedRemoteAuthority,
  blockedSensitivePayload,
  blockedReviewWithoutWalkingEvidence,
  blockedMalformedSummary,
}

class TripStopFalsePositiveGuardDecision {
  const TripStopFalsePositiveGuardDecision({
    required this.status,
    required this.reasonCode,
    required this.canAllowReviewOpen,
  });

  final TripStopFalsePositiveGuardStatus status;
  final String reasonCode;
  final bool canAllowReviewOpen;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'canAllowReviewOpen': canAllowReviewOpen,
    'guardsLongTrafficLight': true,
    'guardsVehicleOnlyDwell': true,
    'guardsWalkingBeforeVehicleMovement': true,
    'guardsRemoteStopAuthority': true,
    'guardsSensitiveLocationPayloads': true,
    'mapsRequiredForFalsePositiveGuard': false,
    'mapboxCanOverrideFalsePositiveGuard': false,
    'firestoreCanOverrideFalsePositiveGuard': false,
    'cloudFunctionCanOverrideFalsePositiveGuard': false,
    'activityRecognitionCanBypassUserReview': false,
    'odometerRemainsOfficialMileageTruth': true,
    'officialStopRequiresUserAction': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripStopFalsePositiveGuard {
  const TripStopFalsePositiveGuard._();

  static TripStopFalsePositiveGuardDecision evaluate({
    required String status,
    required Map<String, Object?> classification,
    required Map<String, Object?>? vehicleOnlyDwell,
    required bool needsWalkingReview,
    required bool protectedTrafficControl,
    required bool canOpenReview,
  }) {
    if (!_safeStatus(status) || !_safeClassification(classification)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedMalformedSummary,
        'malformed_stop_guard_summary',
      );
    }
    if (_containsSensitivePayload(classification) ||
        _containsSensitivePayload(vehicleOnlyDwell)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedSensitivePayload,
        'sensitive_stop_guard_payload',
      );
    }
    if (_claimsRemoteAuthority(classification) ||
        _claimsRemoteAuthority(vehicleOnlyDwell)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedRemoteAuthority,
        'remote_stop_guard_authority',
      );
    }
    if (canOpenReview &&
        (protectedTrafficControl ||
            status == 'trafficControlProtected' ||
            classification['signal'] == 'likelyTrafficControl' ||
            vehicleOnlyDwell?['longTrafficLightProtected'] == true)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedTrafficControlReview,
        'traffic_control_review_blocked',
      );
    }
    if (canOpenReview &&
        vehicleOnlyDwell?['status'] == 'manualFallbackRecommended') {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedVehicleOnlyAutoReview,
        'vehicle_only_auto_review_blocked',
      );
    }
    if (canOpenReview && !needsWalkingReview) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedReviewWithoutWalkingEvidence,
        'review_without_walking_evidence_blocked',
      );
    }
    return const TripStopFalsePositiveGuardDecision(
      status: TripStopFalsePositiveGuardStatus.passed,
      reasonCode: 'stop_false_positive_guard_passed',
      canAllowReviewOpen: true,
    );
  }
}

TripStopFalsePositiveGuardDecision _decision(
  TripStopFalsePositiveGuardStatus status,
  String reasonCode,
) {
  return TripStopFalsePositiveGuardDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    canAllowReviewOpen: false,
  );
}

bool _safeStatus(String value) {
  return const {
    'keepTracking',
    'waitingForEvidence',
    'readyForReview',
    'trafficControlProtected',
    'unsafeEvidence',
  }.contains(value.trim());
}

bool _safeClassification(Map<String, Object?> value) {
  return value['schemaVersion'] == 1 &&
      value['canCreateOfficialStop'] == false &&
      value['canEndTripAutomatically'] == false &&
      value['officialStopSource'] == 'user_review' &&
      value['officialMileageSource'] == 'odometer';
}

bool _claimsRemoteAuthority(Object? value) {
  if (value is! Map) return false;
  for (final entry in value.entries) {
    final key = entry.key.toString();
    if ((key.startsWith('remote') ||
            key.startsWith('firestore') ||
            key.startsWith('cloudFunction') ||
            key.startsWith('mapbox') ||
            key.startsWith('activityRecognition')) &&
        entry.value == true) {
      return true;
    }
  }
  return false;
}

bool _containsSensitivePayload(Object? value) {
  if (value is String) {
    return value.startsWith('pk.') ||
        value.startsWith('sk.') ||
        RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(value);
  }
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

String _safeReason(String value) {
  return switch (value.trim()) {
    'stop_false_positive_guard_passed' => 'stop_false_positive_guard_passed',
    'malformed_stop_guard_summary' => 'malformed_stop_guard_summary',
    'sensitive_stop_guard_payload' => 'sensitive_stop_guard_payload',
    'remote_stop_guard_authority' => 'remote_stop_guard_authority',
    'traffic_control_review_blocked' => 'traffic_control_review_blocked',
    'vehicle_only_auto_review_blocked' => 'vehicle_only_auto_review_blocked',
    'review_without_walking_evidence_blocked' =>
      'review_without_walking_evidence_blocked',
    _ => 'malformed_stop_guard_summary',
  };
}
