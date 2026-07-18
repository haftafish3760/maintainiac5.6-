import 'trip_stop_detection_readiness.dart';

enum TripStopReviewOpenStatus {
  ready,
  blockedReadiness,
  blockedOwner,
  blockedSession,
  blockedDuplicate,
  blockedClock,
}

class TripStopReviewOpenRequest {
  const TripStopReviewOpenRequest({
    required this.authenticatedUid,
    required this.sessionOwnerUid,
    required this.sessionId,
    required this.vehicleId,
    required this.localSessionRevision,
    required this.activeTrip,
    required this.localSessionAvailable,
    required this.acceptedVehicleMovementObserved,
    required this.detectedAtUtc,
    required this.nowUtc,
    required this.existingPendingReviewIds,
    required this.stopSummary,
  });

  final String authenticatedUid;
  final String sessionOwnerUid;
  final String sessionId;
  final String vehicleId;
  final int localSessionRevision;
  final bool activeTrip;
  final bool localSessionAvailable;
  final bool acceptedVehicleMovementObserved;
  final DateTime detectedAtUtc;
  final DateTime nowUtc;
  final List<String> existingPendingReviewIds;
  final Map<String, Object?> stopSummary;
}

class TripStopReviewOpenGuard {
  const TripStopReviewOpenGuard._();

  static TripStopReviewOpenDecision evaluate(
    TripStopReviewOpenRequest request,
  ) {
    final readiness = TripStopDetectionReadiness.fromSummary(
      request.stopSummary,
      activeTrip: request.activeTrip,
      localSessionAvailable: request.localSessionAvailable,
      acceptedVehicleMovementObserved: request.acceptedVehicleMovementObserved,
    );
    final ownerValid =
        _safeIdentifier(request.authenticatedUid, maxLength: 96) &&
        request.authenticatedUid == request.sessionOwnerUid;
    final sessionValid =
        _safeIdentifier(request.sessionId, maxLength: 96) &&
        _safeIdentifier(request.vehicleId, maxLength: 96) &&
        request.localSessionRevision > 0;
    final reviewId = _safeReviewId(
      sessionId: request.sessionId,
      detectedAtUtc: request.detectedAtUtc,
    );
    final duplicate = request.existingPendingReviewIds.any(
      (id) => id == reviewId,
    );
    final clockValid = _clockValid(
      detectedAtUtc: request.detectedAtUtc,
      nowUtc: request.nowUtc,
    );
    final status = _statusFor(
      readiness: readiness,
      ownerValid: ownerValid,
      sessionValid: sessionValid,
      duplicate: duplicate,
      clockValid: clockValid,
    );

    return TripStopReviewOpenDecision(
      status: status,
      readiness: readiness,
      ownerValid: ownerValid,
      sessionValid: sessionValid,
      duplicatePendingReview: duplicate,
      clockValid: clockValid,
      reviewId: reviewId,
      reviewPayload: status == TripStopReviewOpenStatus.ready
          ? _payloadFor(
              request: request,
              readiness: readiness,
              reviewId: reviewId,
            )
          : const <String, Object?>{},
    );
  }

  static TripStopReviewOpenStatus _statusFor({
    required TripStopDetectionReadiness readiness,
    required bool ownerValid,
    required bool sessionValid,
    required bool duplicate,
    required bool clockValid,
  }) {
    if (!readiness.canOpenStopReview) {
      return TripStopReviewOpenStatus.blockedReadiness;
    }
    if (!ownerValid) return TripStopReviewOpenStatus.blockedOwner;
    if (!sessionValid) return TripStopReviewOpenStatus.blockedSession;
    if (duplicate) return TripStopReviewOpenStatus.blockedDuplicate;
    if (!clockValid) return TripStopReviewOpenStatus.blockedClock;
    return TripStopReviewOpenStatus.ready;
  }
}

class TripStopReviewOpenDecision {
  const TripStopReviewOpenDecision({
    required this.status,
    required this.readiness,
    required this.ownerValid,
    required this.sessionValid,
    required this.duplicatePendingReview,
    required this.clockValid,
    required this.reviewId,
    required this.reviewPayload,
  });

  final TripStopReviewOpenStatus status;
  final TripStopDetectionReadiness readiness;
  final bool ownerValid;
  final bool sessionValid;
  final bool duplicatePendingReview;
  final bool clockValid;
  final String reviewId;
  final Map<String, Object?> reviewPayload;

  bool get mayOpenReview => status == TripStopReviewOpenStatus.ready;

  String get userFacingReason {
    return switch (status) {
      TripStopReviewOpenStatus.ready => 'Stop review is ready.',
      TripStopReviewOpenStatus.blockedReadiness => readiness.userFacingReason,
      TripStopReviewOpenStatus.blockedOwner =>
        'Stop review is waiting for account ownership verification.',
      TripStopReviewOpenStatus.blockedSession =>
        'Stop review is waiting for a valid local trip session.',
      TripStopReviewOpenStatus.blockedDuplicate =>
        'A stop review is already pending for this evidence.',
      TripStopReviewOpenStatus.blockedClock =>
        'Stop review is waiting for a reliable device clock.',
    };
  }

  Map<String, Object?> toSafeDashboardMap() {
    return {
      'schemaVersion': 1,
      'status': status.name,
      'mayOpenReview': mayOpenReview,
      'reviewId': mayOpenReview ? reviewId : null,
      'readiness': readiness.toSafeDashboardMap(),
      'ownerValid': ownerValid,
      'sessionValid': sessionValid,
      'duplicatePendingReview': duplicatePendingReview,
      'clockValid': clockValid,
      'requiresAuthenticatedOwner': true,
      'requiresLocalSessionRevision': true,
      'requiresLocalTripLog': true,
      'requiresAcceptedVehicleMovement': true,
      'createsOfficialStop': false,
      'officialStopSource': 'user_review_after_acceptance',
      'officialMileageSource': 'odometer',
      'odometerIsGlobalTruth': true,
      'addressRequiresUserConfirmation': true,
      'remoteCanOpenStopReview': false,
      'firestoreCanOpenStopReview': false,
      'cloudFunctionCanOpenStopReview': false,
      'mapboxCanOpenStopReview': false,
      'mapboxCanInferOfficialStopAddress': false,
      'activityRecognitionCanOpenStopReviewWithoutValidation': false,
      'employeeTrackingRequiresMutualConsent': true,
      'employerGodModeAllowed': false,
      'stopReviewPayloadCanExposeLiveLocation': false,
      'canEndTripAutomatically': false,
      'canReplaceOdometer': false,
      'tokensIncluded': false,
      'coordinatesIncluded': false,
      'routeGeometryIncluded': false,
      'rawSamplesIncluded': false,
    };
  }
}

extension on TripStopDetectionReadiness {
  String get userFacingReason {
    return switch (status) {
      TripStopDetectionReadinessStatus.readyForUserReview =>
        'Stop review is ready.',
      TripStopDetectionReadinessStatus.keepTracking =>
        'Maintainiac should keep tracking.',
      TripStopDetectionReadinessStatus.waitForMoreEvidence =>
        'Maintainiac is waiting for stronger stop evidence.',
      TripStopDetectionReadinessStatus.unsafeBoundary =>
        'Stop evidence could not be safely verified.',
      TripStopDetectionReadinessStatus.unauthorizedBoundary =>
        'Stop review is waiting for trip access verification.',
    };
  }
}

Map<String, Object?> _payloadFor({
  required TripStopReviewOpenRequest request,
  required TripStopDetectionReadiness readiness,
  required String reviewId,
}) {
  return {
    'schemaVersion': 1,
    'schema': 'trip_stop_review_mirror_v1',
    'reviewId': reviewId,
    'sessionId': request.sessionId,
    'vehicleId': request.vehicleId,
    'ownerUid': request.sessionOwnerUid,
    'createdByUid': request.sessionOwnerUid,
    'updatedByUid': request.sessionOwnerUid,
    'localSessionRevision': request.localSessionRevision,
    'detectedAtUtc': request.detectedAtUtc.toUtc().toIso8601String(),
    'actionToken': readiness.actionToken,
    'reasonCode': readiness.reasonCode,
    'disposition': 'pending_user_review',
    'source': 'validated_local_trip_stop_evidence',
    'createsOfficialStop': false,
    'officialStopRequiresUserAcceptance': true,
    'officialMileageSource': 'odometer',
    'odometerIsGlobalTruth': true,
    'addressRequiresUserConfirmation': true,
    'firestoreRole': 'mirror_after_local_write',
    'remoteCanOverrideLocalDisposition': false,
    'mapboxCanInferOfficialStopAddress': false,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'stopReviewPayloadCanExposeLiveLocation': false,
    'canEndTripAutomatically': false,
    'locationDataIncluded': false,
    'rawGpsIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

String _safeReviewId({
  required String sessionId,
  required DateTime detectedAtUtc,
}) {
  final cleanSession = _safeIdentifier(sessionId, maxLength: 96)
      ? sessionId
      : 'invalid_session';
  return '$cleanSession.stop.${detectedAtUtc.toUtc().microsecondsSinceEpoch}';
}

bool _clockValid({required DateTime detectedAtUtc, required DateTime nowUtc}) {
  final detected = detectedAtUtc.toUtc();
  final now = nowUtc.toUtc();
  if (detected.isAfter(now.add(const Duration(minutes: 5)))) return false;
  if (detected.isBefore(now.subtract(const Duration(days: 30)))) return false;
  return true;
}

final RegExp _safeIdPattern = RegExp(r'^[A-Za-z0-9_.-]+$');

bool _safeIdentifier(String value, {required int maxLength}) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean != value ||
      clean.length > maxLength ||
      clean.contains(':') ||
      !_safeIdPattern.hasMatch(clean)) {
    return false;
  }
  final lower = clean.toLowerCase();
  return !lower.contains('token') &&
      !lower.contains('secret') &&
      !lower.startsWith('pk.') &&
      !lower.startsWith('sk.');
}
