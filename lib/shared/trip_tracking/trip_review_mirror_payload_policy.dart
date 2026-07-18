import 'trip_tracking_backup_scope_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

enum TripReviewMirrorPayloadStatus {
  ready,
  blockedInvalidReview,
  blockedUnconfirmedOdometer,
  blockedScope,
  blockedOwner,
  blockedInvalidPayload,
}

class TripReviewMirrorPayloadDecision {
  const TripReviewMirrorPayloadDecision({
    required this.status,
    required this.reasonCode,
    required this.payload,
    required this.scopeSummary,
  });

  final TripReviewMirrorPayloadStatus status;
  final String reasonCode;
  final Map<String, Object?> payload;
  final Map<String, Object?> scopeSummary;

  bool get mayMirror => status == TripReviewMirrorPayloadStatus.ready;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'mayMirror': mayMirror,
    'scope': scopeSummary,
    'requiresValidTimeline': true,
    'requiresConfirmedOdometer': true,
    'requiresOwnerBinding': true,
    'requiresScopeBinding': true,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'cloudFunctionMirrorOnly': true,
    'remoteDataCanOverrideLocalTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'mirrorCanDeleteLocalTripLog': false,
    'mirrorCanConfirmOdometer': false,
    'mirrorCanCreateStop': false,
    'mirrorCanEndTripAutomatically': false,
    'cloudFunctionCanOverrideLocalTripLog': false,
    'cloudFunctionCanConfirmOdometer': false,
    'cloudFunctionCanCreateStop': false,
    'cloudFunctionMustRevalidateOwner': true,
    'cloudFunctionMustRevalidateSchema': true,
    'cloudFunctionMustRevalidateScope': true,
    'firestoreRulesMustValidateOwner': true,
    'firestoreRulesMustValidateSchema': true,
    'firestoreRulesMustValidateScope': true,
    'payloadContainsRawGps': false,
    'payloadContainsRouteGeometry': false,
    'payloadContainsMapboxData': false,
    'payloadContainsPreciseCoordinates': false,
    'tokensIncluded': false,
    'rawReviewIncluded': false,
  };
}

class TripReviewMirrorPayloadPolicy {
  const TripReviewMirrorPayloadPolicy._();

  static TripReviewMirrorPayloadDecision build({
    required TripTrackingReviewRecord review,
    required String ownerUid,
    required bool personalBackup,
    required bool organizationSharingEnabled,
    String? organizationId,
  }) {
    final scopeDecision = TripTrackingBackupScopePolicy.bindForQueue(
      review: review,
      createdByUid: ownerUid,
      personalBackup: personalBackup,
      organizationSharingEnabled: organizationSharingEnabled,
      orgId: organizationId,
    );
    final scopeSummary = scopeDecision.toSafeSummary();
    final boundReview = scopeDecision.boundReview;
    if (!review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        review.vehicleId.trim().isEmpty ||
        review.estimatedEndingOdometer < review.startingOdometer ||
        review.finishedAt.isBefore(review.startedAt)) {
      return _decision(
        status: TripReviewMirrorPayloadStatus.blockedInvalidReview,
        reasonCode: 'invalid_review_mirror_record',
        scopeSummary: scopeSummary,
      );
    }
    if (!review.isOdometerConfirmed) {
      return _decision(
        status: TripReviewMirrorPayloadStatus.blockedUnconfirmedOdometer,
        reasonCode: 'unconfirmed_odometer_blocks_mirror',
        scopeSummary: scopeSummary,
      );
    }
    if (!scopeDecision.canQueue || boundReview == null) {
      return _decision(
        status: _scopeStatus(scopeDecision.failure),
        reasonCode: _scopeReason(scopeDecision.failure),
        scopeSummary: scopeSummary,
      );
    }
    return _decision(
      status: TripReviewMirrorPayloadStatus.ready,
      reasonCode: 'review_mirror_payload_ready',
      payload: _payloadFor(boundReview),
      scopeSummary: scopeSummary,
    );
  }

  static TripReviewMirrorPayloadDecision validateInbound({
    required Map<String, Object?> payload,
    required Map<String, Object?> scopeSummary,
  }) {
    final reasons = <String>[];
    if (payload['schemaVersion'] != 1 ||
        payload['schema'] != 'trip_review_mileage_mirror_v1') {
      reasons.add('invalid_payload_schema');
    }
    if (!_safeMirrorToken(payload['tripId']) ||
        !_safeMirrorToken(payload['vehicleId'])) {
      reasons.add('invalid_payload_identity');
    }
    if (!_safeProfile(payload['profile'])) {
      reasons.add('invalid_payload_profile');
    }
    final starting = _safeMileage(payload['startingOdometer']);
    final ending = _safeMileage(payload['confirmedEndingOdometer']);
    final miles = _safeMileage(payload['confirmedMiles']);
    final estimated = _safeMileage(payload['estimatedEndingOdometer']);
    if (starting == null ||
        ending == null ||
        miles == null ||
        estimated == null) {
      reasons.add('invalid_payload_mileage');
    } else if (ending < starting || miles < 0 || estimated < starting) {
      reasons.add('payload_mileage_regresses');
    }
    final startedAt = _safeTimestamp(payload['startedAtUtc']);
    final finishedAt = _safeTimestamp(payload['finishedAtUtc']);
    final confirmedAt = _safeTimestamp(payload['confirmedAtUtc']);
    if (startedAt == null || finishedAt == null || confirmedAt == null) {
      reasons.add('invalid_payload_timestamps');
    } else if (finishedAt.isBefore(startedAt) ||
        confirmedAt.isBefore(finishedAt)) {
      reasons.add('payload_timeline_regresses');
    }
    if (payload['source'] != 'validated_local_review' ||
        payload['hiveSourceOfTruth'] != true ||
        payload['firestoreRole'] != 'mirror_after_local_write') {
      reasons.add('payload_source_not_local_review');
    }
    if (payload['remoteCanOverrideLocalTripLog'] != false ||
        payload['remoteTotalsCanBecomeCanonical'] != false ||
        payload['mirrorCanDeleteLocalTripLog'] != false ||
        payload['cloudFunctionCanOverrideLocalTripLog'] != false ||
        payload['cloudFunctionCanConfirmOdometer'] != false ||
        payload['cloudFunctionCanCreateStop'] != false ||
        payload['officialMileageSource'] != 'odometer' ||
        payload['gpsDistanceAdvisoryOnly'] != true ||
        payload['mapboxDistanceAdvisoryOnly'] != true) {
      reasons.add('payload_claims_trip_authority');
    }
    if (payload['firestoreRulesMustValidateOwner'] != true ||
        payload['firestoreRulesMustValidateSchema'] != true ||
        payload['firestoreRulesMustValidateScope'] != true ||
        payload['cloudFunctionMustRevalidateOwner'] != true ||
        payload['cloudFunctionMustRevalidateSchema'] != true ||
        payload['cloudFunctionMustRevalidateScope'] != true) {
      reasons.add('payload_missing_backend_revalidation_contract');
    }
    if (scopeSummary['authenticationImpliesAuthorization'] != false ||
        scopeSummary['hiveRemainsSourceOfTruth'] != true ||
        scopeSummary['remoteDataCanOverrideLocalTripLog'] != false ||
        scopeSummary['remoteTotalsCanBecomeCanonical'] != false ||
        scopeSummary['cloudMirrorCanDeleteLocalTripLog'] != false) {
      reasons.add('scope_summary_claims_remote_authority');
    }
    if (payload['rawGpsIncluded'] != false ||
        payload['routeGeometryIncluded'] != false ||
        payload['mapboxGeometryIncluded'] != false ||
        payload['preciseCoordinatesIncluded'] != false ||
        payload['tokensIncluded'] != false ||
        _containsSensitivePayload(payload)) {
      reasons.add('payload_contains_sensitive_material');
    }
    if (reasons.isNotEmpty) {
      return _decision(
        status: TripReviewMirrorPayloadStatus.blockedInvalidPayload,
        reasonCode: 'invalid_review_mirror_payload',
        scopeSummary: scopeSummary,
      );
    }
    return _decision(
      status: TripReviewMirrorPayloadStatus.ready,
      reasonCode: 'review_mirror_payload_ready',
      payload: _redactedInboundPayload(payload),
      scopeSummary: scopeSummary,
    );
  }
}

TripReviewMirrorPayloadDecision _decision({
  required TripReviewMirrorPayloadStatus status,
  required String reasonCode,
  required Map<String, Object?> scopeSummary,
  Map<String, Object?> payload = const <String, Object?>{},
}) {
  return TripReviewMirrorPayloadDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    payload: Map.unmodifiable(payload),
    scopeSummary: Map.unmodifiable(scopeSummary),
  );
}

Map<String, Object?> _payloadFor(TripTrackingReviewRecord review) {
  final confirmedEnding = review.confirmedEndingOdometer!;
  final confirmedMiles = confirmedEnding - review.startingOdometer;
  return {
    'schemaVersion': 1,
    'schema': 'trip_review_mileage_mirror_v1',
    'tripId': review.id,
    'vehicleId': review.vehicleId,
    'profile': review.profile.name,
    'startedAtUtc': review.startedAt.toUtc().toIso8601String(),
    'finishedAtUtc': review.finishedAt.toUtc().toIso8601String(),
    'confirmedAtUtc': review.odometerConfirmedAt!.toUtc().toIso8601String(),
    'startingOdometer': review.startingOdometer,
    'confirmedEndingOdometer': confirmedEnding,
    'confirmedMiles': confirmedMiles < 0 ? 0 : confirmedMiles,
    'estimatedEndingOdometer': review.estimatedEndingOdometer,
    'gpsAcceptedMetersRounded': _roundedMeters(
      review.engineSnapshot.totalAcceptedMeters,
    ),
    'cloudBackupScope': review.cloudBackupScope?.name,
    'cloudOrganizationBound':
        review.cloudBackupScope == TripTrackingCloudBackupScope.organization,
    'source': 'validated_local_review',
    'hiveSourceOfTruth': true,
    'firestoreRole': 'mirror_after_local_write',
    'remoteCanOverrideLocalTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'mirrorCanDeleteLocalTripLog': false,
    'cloudFunctionCanOverrideLocalTripLog': false,
    'cloudFunctionCanConfirmOdometer': false,
    'cloudFunctionCanCreateStop': false,
    'cloudFunctionMustRevalidateOwner': true,
    'cloudFunctionMustRevalidateSchema': true,
    'cloudFunctionMustRevalidateScope': true,
    'firestoreRulesMustValidateOwner': true,
    'firestoreRulesMustValidateSchema': true,
    'firestoreRulesMustValidateScope': true,
    'officialMileageSource': 'odometer',
    'gpsDistanceAdvisoryOnly': true,
    'mapboxDistanceAdvisoryOnly': true,
    'rawGpsIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
    'preciseCoordinatesIncluded': false,
    'tokensIncluded': false,
  };
}

TripReviewMirrorPayloadStatus _scopeStatus(
  TripTrackingBackupScopeFailure? failure,
) {
  return switch (failure) {
    TripTrackingBackupScopeFailure.unsafeAccount ||
    TripTrackingBackupScopeFailure.accountMismatch =>
      TripReviewMirrorPayloadStatus.blockedOwner,
    TripTrackingBackupScopeFailure.missingOrganization ||
    TripTrackingBackupScopeFailure.scopeMismatch ||
    null => TripReviewMirrorPayloadStatus.blockedScope,
  };
}

String _scopeReason(TripTrackingBackupScopeFailure? failure) {
  return switch (failure) {
    TripTrackingBackupScopeFailure.unsafeAccount => 'unsafe_mirror_owner',
    TripTrackingBackupScopeFailure.accountMismatch => 'mirror_owner_mismatch',
    TripTrackingBackupScopeFailure.missingOrganization =>
      'mirror_organization_missing',
    TripTrackingBackupScopeFailure.scopeMismatch => 'mirror_scope_mismatch',
    null => 'mirror_scope_mismatch',
  };
}

double _roundedMeters(double value) {
  if (!value.isFinite || value < 0) return 0;
  return (value * 10).round() / 10;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'invalid_review_mirror_record' => 'invalid_review_mirror_record',
    'unconfirmed_odometer_blocks_mirror' =>
      'unconfirmed_odometer_blocks_mirror',
    'unsafe_mirror_owner' => 'unsafe_mirror_owner',
    'mirror_owner_mismatch' => 'mirror_owner_mismatch',
    'mirror_organization_missing' => 'mirror_organization_missing',
    'mirror_scope_mismatch' => 'mirror_scope_mismatch',
    'review_mirror_payload_ready' => 'review_mirror_payload_ready',
    'invalid_review_mirror_payload' => 'invalid_review_mirror_payload',
    _ => 'invalid_review_mirror_record',
  };
}

bool _safeMirrorToken(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 160 &&
      !clean.contains(RegExp(r'[\x00-\x1F\x7F]')) &&
      !clean.startsWith('pk.') &&
      !clean.startsWith('sk.');
}

bool _safeProfile(Object? value) {
  if (value is! String) return false;
  for (final profile in TripTrackingProfile.values) {
    if (profile.name == value) return true;
  }
  return false;
}

double? _safeMileage(Object? value) {
  if (value is! num || !value.isFinite || value < 0 || value > 9999999) {
    return null;
  }
  return value.toDouble();
}

DateTime? _safeTimestamp(Object? value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed?.toUtc();
}

Map<String, Object?> _redactedInboundPayload(Map<String, Object?> payload) {
  return Map.unmodifiable({
    'schemaVersion': 1,
    'schema': 'trip_review_mileage_mirror_v1',
    'tripId': payload['tripId'],
    'vehicleId': payload['vehicleId'],
    'profile': payload['profile'],
    'startedAtUtc': payload['startedAtUtc'],
    'finishedAtUtc': payload['finishedAtUtc'],
    'confirmedAtUtc': payload['confirmedAtUtc'],
    'startingOdometer': payload['startingOdometer'],
    'confirmedEndingOdometer': payload['confirmedEndingOdometer'],
    'confirmedMiles': payload['confirmedMiles'],
    'estimatedEndingOdometer': payload['estimatedEndingOdometer'],
    'gpsAcceptedMetersRounded': _roundedMeters(
      payload['gpsAcceptedMetersRounded'] is num
          ? (payload['gpsAcceptedMetersRounded'] as num).toDouble()
          : 0,
    ),
    'cloudBackupScope': payload['cloudBackupScope'],
    'cloudOrganizationBound': payload['cloudOrganizationBound'] == true,
    'source': 'validated_local_review',
    'hiveSourceOfTruth': true,
    'firestoreRole': 'mirror_after_local_write',
    'remoteCanOverrideLocalTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'mirrorCanDeleteLocalTripLog': false,
    'cloudFunctionCanOverrideLocalTripLog': false,
    'cloudFunctionCanConfirmOdometer': false,
    'cloudFunctionCanCreateStop': false,
    'cloudFunctionMustRevalidateOwner': true,
    'cloudFunctionMustRevalidateSchema': true,
    'cloudFunctionMustRevalidateScope': true,
    'firestoreRulesMustValidateOwner': true,
    'firestoreRulesMustValidateSchema': true,
    'firestoreRulesMustValidateScope': true,
    'officialMileageSource': 'odometer',
    'gpsDistanceAdvisoryOnly': true,
    'mapboxDistanceAdvisoryOnly': true,
    'rawGpsIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
    'preciseCoordinatesIncluded': false,
    'tokensIncluded': false,
  });
}

bool _containsSensitivePayload(Object? value) {
  if (value is String) {
    final lower = value.toLowerCase();
    return value.startsWith('pk.') ||
        value.startsWith('sk.') ||
        lower.contains('mapbox') ||
        RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(value);
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (_containsSensitiveKey(entry.key) ||
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

bool _containsSensitiveKey(Object? value) {
  if (value is! String) return false;
  return value.startsWith('pk.') ||
      value.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(value);
}
