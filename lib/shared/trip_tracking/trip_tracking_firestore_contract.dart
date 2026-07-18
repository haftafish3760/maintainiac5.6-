/// The stable, coordinate-free shape shared by trip-summary builders and the
/// local upload guard. Firestore rules repeat this allowlist independently at
/// the server boundary.
abstract final class TripTrackingFirestoreContract {
  static const reviewedSummarySchema = 'trip_tracking_review_v1';
  static const visibilityScopeMileageOnly = 'mileage_only';
  static const mileageRecordPathUser = 'users/{uid}/mileageRecords/{tripId}';
  static const mileageRecordPathOrganization =
      'orgs/{orgId}/mileageRecords/{tripId}';

  static const reviewedSummaryFields = <String>{
    'schema',
    'tripId',
    'orgId',
    'organizationSharingConsent',
    'createdByUid',
    'updatedByUid',
    'vehicleId',
    'profile',
    'startedAt',
    'finishedAt',
    'createdAt',
    'updatedAt',
    'startingOdometer',
    'estimatedEndingOdometer',
    'confirmedEndingOdometer',
    'odometerConfirmedAt',
    'acceptedMeters',
    'acceptedMiles',
    'walkingReviewSuggested',
    'motionState',
    'receivedSampleCount',
    'acceptedSampleCount',
    'locationDataIncluded',
    'visibilityScope',
  };

  static const requiredReviewedSummaryFields = <String>{
    'schema',
    'tripId',
    'createdByUid',
    'updatedByUid',
    'vehicleId',
    'profile',
    'startedAt',
    'finishedAt',
    'createdAt',
    'updatedAt',
    'startingOdometer',
    'estimatedEndingOdometer',
    'confirmedEndingOdometer',
    'odometerConfirmedAt',
    'acceptedMeters',
    'acceptedMiles',
    'walkingReviewSuggested',
    'motionState',
    'receivedSampleCount',
    'acceptedSampleCount',
    'locationDataIncluded',
    'visibilityScope',
  };

  static List<String> reviewedSummaryFindings(Map<String, Object?> data) {
    final findings = <String>[];
    if (data['schema'] != reviewedSummarySchema) {
      findings.add('invalid_schema');
    }
    final keys = data.keys.toSet();
    final extra = keys.difference(reviewedSummaryFields);
    if (extra.isNotEmpty) findings.add('unknown_fields');
    final missing = requiredReviewedSummaryFields.difference(keys);
    if (missing.isNotEmpty) findings.add('missing_required_fields');
    if (data['locationDataIncluded'] != false ||
        data['visibilityScope'] != visibilityScopeMileageOnly) {
      findings.add('not_mileage_only');
    }
    if (!_isSafeToken(data['tripId']) ||
        !_isSafeToken(data['vehicleId']) ||
        !_isSafeUid(data['createdByUid']) ||
        !_isSafeUid(data['updatedByUid'])) {
      findings.add('unsafe_identity');
    }
    if (data['createdByUid'] != data['updatedByUid']) {
      findings.add('owner_mismatch');
    }
    if (!_isKnownTripProfile(data['profile'])) {
      findings.add('invalid_profile');
    }
    if (!_isKnownMotionState(data['motionState'])) {
      findings.add('invalid_motion_state');
    }
    if (!_isIsoTimestamp(data['startedAt']) ||
        !_isIsoTimestamp(data['finishedAt']) ||
        !_isIsoTimestamp(data['createdAt']) ||
        !_isIsoTimestamp(data['updatedAt']) ||
        !_isIsoTimestamp(data['odometerConfirmedAt'])) {
      findings.add('invalid_timestamp');
    }
    final starting = data['startingOdometer'];
    final estimated = data['estimatedEndingOdometer'];
    final confirmed = data['confirmedEndingOdometer'];
    if (!_isNonNegativeInt(starting) ||
        !_isNonNegativeInt(estimated) ||
        !_isNonNegativeInt(confirmed) ||
        (estimated is int && starting is int && estimated < starting) ||
        (confirmed is int && starting is int && confirmed < starting)) {
      findings.add('invalid_odometer');
    }
    final acceptedMeters = data['acceptedMeters'];
    final acceptedMiles = data['acceptedMiles'];
    if (!_isNonNegativeFiniteNumber(acceptedMeters) ||
        !_isNonNegativeFiniteNumber(acceptedMiles)) {
      findings.add('invalid_distance');
    }
    final received = data['receivedSampleCount'];
    final accepted = data['acceptedSampleCount'];
    if (!_isBoundedSampleCount(received) ||
        !_isBoundedSampleCount(accepted) ||
        (received is int && accepted is int && accepted > received)) {
      findings.add('invalid_sample_counts');
    }
    if (data['walkingReviewSuggested'] is! bool) {
      findings.add('invalid_walking_review_flag');
    }
    if (data.containsKey('orgId')) {
      if (!_isSafeToken(data['orgId']) ||
          data['organizationSharingConsent'] != true) {
        findings.add('invalid_organization_scope');
      }
    } else if (data.containsKey('organizationSharingConsent')) {
      findings.add('invalid_organization_scope');
    }
    return List.unmodifiable(findings);
  }

  static bool isReviewedSummaryShape(Map<String, Object?> data) =>
      reviewedSummaryFindings(data).isEmpty;

  static Map<String, Object?> trustBoundarySummary({
    required bool organizationScoped,
  }) {
    return Map.unmodifiable({
      'schemaVersion': 1,
      'boundary': 'firestore_mileage_mirror',
      'documentPath': organizationScoped
          ? mileageRecordPathOrganization
          : mileageRecordPathUser,
      'authenticationImpliesAuthorization': false,
      'rulesMustValidateOwnerUid': true,
      'rulesMustValidateTripIdMatchesRecordId': true,
      'rulesMustValidateAllowedFields': true,
      'rulesMustValidateRequiredFields': true,
      'rulesMustValidateValueTypes': true,
      'rulesMustValidateOdometerDoesNotRegress': true,
      'rulesMustValidateDistanceMatchesOdometerWindow': true,
      'rulesMustRejectRawGps': true,
      'rulesMustRejectMapboxGeometry': true,
      'rulesMustRejectTokens': true,
      'rulesMustRejectServerManagedSpoofing': true,
      'rulesMustRejectDeletes': true,
      'rulesAllowOnlyIdempotentCreatorReplay': true,
      'hiveRemainsSourceOfTruth': true,
      'firestoreMirrorOnly': true,
      'remoteCanOverrideLocalTripLog': false,
      'remoteCanConfirmOdometer': false,
      'remoteCanCreateOfficialStop': false,
      'remoteCanPurgeLocalTripData': false,
      'remoteTotalsCanBecomeCanonical': false,
      'mapboxCanReplaceOdometer': false,
      'organizationMembershipRequired': organizationScoped,
      'organizationSharingConsentRequired': organizationScoped,
      'fleetReadRequiresConsent': organizationScoped,
      'employeeTrackingRequiresMutualConsent': organizationScoped,
      'publicTokenAllowedInPayload': false,
      'secretTokenAllowedInPayload': false,
      'preciseCoordinatesAllowedInPayload': false,
      'routeGeometryAllowedInPayload': false,
    });
  }

  static List<String> trustBoundaryFindings(Map<String, Object?> summary) {
    final findings = <String>[];
    if (summary['schemaVersion'] != 1 ||
        summary['boundary'] != 'firestore_mileage_mirror') {
      findings.add('invalid_boundary_schema');
    }
    if (summary['authenticationImpliesAuthorization'] != false ||
        summary['rulesMustValidateOwnerUid'] != true ||
        summary['rulesMustValidateTripIdMatchesRecordId'] != true ||
        summary['rulesMustValidateAllowedFields'] != true ||
        summary['rulesMustValidateRequiredFields'] != true ||
        summary['rulesMustValidateValueTypes'] != true ||
        summary['rulesMustRejectDeletes'] != true) {
      findings.add('authorization_boundary_not_closed');
    }
    if (summary['hiveRemainsSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteCanOverrideLocalTripLog'] != false ||
        summary['remoteCanConfirmOdometer'] != false ||
        summary['remoteCanCreateOfficialStop'] != false ||
        summary['remoteCanPurgeLocalTripData'] != false ||
        summary['remoteTotalsCanBecomeCanonical'] != false ||
        summary['mapboxCanReplaceOdometer'] != false) {
      findings.add('remote_authority_too_high');
    }
    if (summary['rulesMustRejectRawGps'] != true ||
        summary['rulesMustRejectMapboxGeometry'] != true ||
        summary['rulesMustRejectTokens'] != true ||
        summary['publicTokenAllowedInPayload'] != false ||
        summary['secretTokenAllowedInPayload'] != false ||
        summary['preciseCoordinatesAllowedInPayload'] != false ||
        summary['routeGeometryAllowedInPayload'] != false) {
      findings.add('sensitive_payload_boundary_open');
    }
    final organizationScoped =
        summary['documentPath'] == mileageRecordPathOrganization;
    if (organizationScoped &&
        (summary['organizationMembershipRequired'] != true ||
            summary['organizationSharingConsentRequired'] != true ||
            summary['fleetReadRequiresConsent'] != true ||
            summary['employeeTrackingRequiresMutualConsent'] != true)) {
      findings.add('organization_consent_boundary_open');
    }
    if (!organizationScoped &&
        summary['documentPath'] != mileageRecordPathUser) {
      findings.add('unknown_document_path');
    }
    return List.unmodifiable(findings);
  }

  static bool isTrustBoundaryClosed(Map<String, Object?> summary) =>
      trustBoundaryFindings(summary).isEmpty;
}

bool _isSafeToken(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 120 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean);
}

bool _isSafeUid(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 128 &&
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean);
}

bool _isKnownTripProfile(Object? value) {
  return switch (value) {
    'roadVehicle' ||
    'rideshareVehicle' ||
    'deliveryVehicle' ||
    'contractorVehicle' ||
    'lowSpeedEquipment' => true,
    _ => false,
  };
}

bool _isKnownMotionState(Object? value) {
  return switch (value) {
    'unknown' || 'moving' || 'stopCandidate' || 'stopped' => true,
    _ => false,
  };
}

bool _isIsoTimestamp(Object? value) =>
    value is String &&
    value.trim().isNotEmpty &&
    DateTime.tryParse(value) != null;

bool _isNonNegativeInt(Object? value) => value is int && value >= 0;

bool _isNonNegativeFiniteNumber(Object? value) =>
    value is num && value.isFinite && value >= 0;

bool _isBoundedSampleCount(Object? value) =>
    value is int && value >= 0 && value <= 1000000;
