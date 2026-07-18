import 'trip_tracking_backup_scope_policy.dart';
import 'trip_tracking_session_store.dart';

enum TripReviewMirrorPayloadStatus {
  ready,
  blockedInvalidReview,
  blockedUnconfirmedOdometer,
  blockedScope,
  blockedOwner,
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
    _ => 'invalid_review_mirror_record',
  };
}
