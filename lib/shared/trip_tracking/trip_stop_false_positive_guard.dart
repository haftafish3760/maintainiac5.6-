import 'trip_tracking_models.dart';

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
    required this.profile,
    required this.canAllowReviewOpen,
  });

  final TripStopFalsePositiveGuardStatus status;
  final String reasonCode;
  final TripTrackingProfile? profile;
  final bool canAllowReviewOpen;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'profile': profile?.name,
    'canAllowReviewOpen': canAllowReviewOpen,
    'driverProfileBoundaryValidated': profile != null,
    'rideshareVehicleOnlyStopRequiresManualFallback':
        profile == TripTrackingProfile.rideshareVehicle,
    'deliveryAndContractorWalkingStopsMayOpenReview':
        profile == TripTrackingProfile.deliveryVehicle ||
        profile == TripTrackingProfile.contractorVehicle,
    'genericRoadVehicleRequiresUserReview':
        profile == TripTrackingProfile.roadVehicle,
    'guardsLongTrafficLight': true,
    'guardsVehicleOnlyDwell': true,
    'guardsWalkingBeforeVehicleMovement': true,
    'guardsRemoteStopAuthority': true,
    'guardsSensitiveLocationPayloads': true,
    'mapsRequiredForFalsePositiveGuard': false,
    'mapboxCanOverrideFalsePositiveGuard': false,
    'mapboxCanInferOfficialStopAddress': false,
    'firestoreCanOverrideFalsePositiveGuard': false,
    'cloudFunctionCanOverrideFalsePositiveGuard': false,
    'activityRecognitionCanBypassUserReview': false,
    'authenticationAloneAuthorizesStopReview': false,
    'localTripLogRequiredForReview': true,
    'ownershipValidationRequiredForReview': true,
    'addressRequiresUserConfirmation': true,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'stopEvidenceCanCreateCalibration': false,
    'stopEvidenceCanApplyCalibration': false,
    'stopEvidenceCanSetGlobalTruth': false,
    'stopEvidenceCanConfirmOfficialMileage': false,
    'stopEvidenceCanChangeOfficialMileage': false,
    'walkingEvidenceCanConfirmOfficialMileage': false,
    'trafficControlCanConfirmOfficialMileage': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'officialStopRequiresUserAction': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripStopFalsePositiveGuardSummaryValidation {
  const TripStopFalsePositiveGuardSummaryValidation._({
    required this.isRenderable,
    required this.canAllowReviewOpen,
    required this.reasons,
  });

  factory TripStopFalsePositiveGuardSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeGuardStatus(summary['status']);
    final reasonCode = summary['reasonCode'];

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_guard_status');
    if (reasonCode is! String || _safeReason(reasonCode) != reasonCode) {
      reasons.add('invalid_guard_reason');
    }
    if (summary['profile'] != null && summary['profile'] is! String) {
      reasons.add('invalid_guard_profile');
    }
    if (summary['canAllowReviewOpen'] is! bool) {
      reasons.add('review_open_not_bool');
    }
    if (summary['driverProfileBoundaryValidated'] != true) {
      reasons.add('profile_boundary_missing');
    }
    for (final key in const [
      'guardsLongTrafficLight',
      'guardsVehicleOnlyDwell',
      'guardsWalkingBeforeVehicleMovement',
      'guardsRemoteStopAuthority',
      'guardsSensitiveLocationPayloads',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'officialStopRequiresUserAction',
      'localTripLogRequiredForReview',
      'ownershipValidationRequiredForReview',
      'addressRequiresUserConfirmation',
    ]) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in const [
      'mapsRequiredForFalsePositiveGuard',
      'mapboxCanOverrideFalsePositiveGuard',
      'mapboxCanInferOfficialStopAddress',
      'firestoreCanOverrideFalsePositiveGuard',
      'cloudFunctionCanOverrideFalsePositiveGuard',
      'activityRecognitionCanBypassUserReview',
      'authenticationAloneAuthorizesStopReview',
      'stopEvidenceCanCreateCalibration',
      'stopEvidenceCanApplyCalibration',
      'stopEvidenceCanSetGlobalTruth',
      'stopEvidenceCanConfirmOfficialMileage',
      'stopEvidenceCanChangeOfficialMileage',
      'walkingEvidenceCanConfirmOfficialMileage',
      'trafficControlCanConfirmOfficialMileage',
      'rawSamplesIncluded',
      'coordinatesIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    if (summary.values.any(_containsSensitivePayload)) {
      reasons.add('guard_summary_contains_sensitive_payload');
    }
    reasons.addAll(
      _validateGuardStatusAuthority(
        status: status,
        reasonCode: reasonCode,
        canAllowReviewOpen: summary['canAllowReviewOpen'],
      ),
    );

    return TripStopFalsePositiveGuardSummaryValidation._(
      isRenderable: reasons.isEmpty,
      canAllowReviewOpen: reasons.isEmpty
          ? summary['canAllowReviewOpen'] as bool
          : false,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final bool canAllowReviewOpen;
  final List<String> reasons;
}

List<String> _validateGuardStatusAuthority({
  required TripStopFalsePositiveGuardStatus? status,
  required Object? reasonCode,
  required Object? canAllowReviewOpen,
}) {
  if (status == null || reasonCode is! String || canAllowReviewOpen is! bool) {
    return const [];
  }
  if (canAllowReviewOpen &&
      (status != TripStopFalsePositiveGuardStatus.passed ||
          reasonCode != 'stop_false_positive_guard_passed')) {
    return const ['guard_open_review_authority_mismatch'];
  }
  if (status == TripStopFalsePositiveGuardStatus.passed &&
      reasonCode != 'stop_false_positive_guard_passed') {
    return const ['guard_passed_reason_mismatch'];
  }
  if (status != TripStopFalsePositiveGuardStatus.passed &&
      reasonCode == 'stop_false_positive_guard_passed') {
    return const ['guard_blocked_reason_mismatch'];
  }
  return const [];
}

class TripStopFalsePositiveGuard {
  const TripStopFalsePositiveGuard._();

  static TripStopFalsePositiveGuardDecision evaluate({
    required TripTrackingProfile profile,
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
        profile: profile,
      );
    }
    if (_containsSensitivePayload(classification) ||
        _containsSensitivePayload(vehicleOnlyDwell)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedSensitivePayload,
        'sensitive_stop_guard_payload',
        profile: profile,
      );
    }
    if (_claimsRemoteAuthority(classification) ||
        _claimsRemoteAuthority(vehicleOnlyDwell)) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedRemoteAuthority,
        'remote_stop_guard_authority',
        profile: profile,
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
        profile: profile,
      );
    }
    if (canOpenReview && profile == TripTrackingProfile.rideshareVehicle) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedVehicleOnlyAutoReview,
        'rideshare_manual_review_required',
        profile: profile,
      );
    }
    if (canOpenReview &&
        vehicleOnlyDwell?['status'] == 'manualFallbackRecommended') {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedVehicleOnlyAutoReview,
        'vehicle_only_auto_review_blocked',
        profile: profile,
      );
    }
    if (canOpenReview && !needsWalkingReview) {
      return _decision(
        TripStopFalsePositiveGuardStatus.blockedReviewWithoutWalkingEvidence,
        'review_without_walking_evidence_blocked',
        profile: profile,
      );
    }
    return TripStopFalsePositiveGuardDecision(
      status: TripStopFalsePositiveGuardStatus.passed,
      reasonCode: 'stop_false_positive_guard_passed',
      profile: profile,
      canAllowReviewOpen: canOpenReview,
    );
  }
}

TripStopFalsePositiveGuardDecision _decision(
  TripStopFalsePositiveGuardStatus status,
  String reasonCode, {
  required TripTrackingProfile profile,
}) {
  return TripStopFalsePositiveGuardDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    profile: profile,
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

TripStopFalsePositiveGuardStatus? _safeGuardStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripStopFalsePositiveGuardStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _safeClassification(Map<String, Object?> value) {
  return value['schemaVersion'] == 1 &&
      value['reviewOnly'] == true &&
      value['advisoryOnly'] == true &&
      value['gpsAssistedOnly'] == true &&
      value['canCreateOfficialStop'] == false &&
      value['canEndTripAutomatically'] == false &&
      value['canReplaceOdometer'] == false &&
      value['stopEvidenceCanSetGlobalTruth'] == false &&
      value['stopEvidenceCanConfirmOfficialMileage'] == false &&
      value['stopEvidenceCanChangeOfficialMileage'] == false &&
      value['stopRequiresAcceptedVehicleMovement'] == true &&
      value['localTripLogRequiredForReview'] == true &&
      value['authenticatedUserStillNeedsAuthorization'] == true &&
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
    'rideshare_manual_review_required' => 'rideshare_manual_review_required',
    'review_without_walking_evidence_blocked' =>
      'review_without_walking_evidence_blocked',
    _ => 'malformed_stop_guard_summary',
  };
}
