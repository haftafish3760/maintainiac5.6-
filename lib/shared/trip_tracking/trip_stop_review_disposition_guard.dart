import 'trip_stop_advisory_reviewer.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

enum TripStopReviewDispositionStatus {
  ready,
  blockedDisposition,
  blockedOwner,
  blockedSession,
  blockedReview,
  blockedFinalized,
  blockedClock,
}

class TripStopReviewDispositionRequest {
  const TripStopReviewDispositionRequest({
    required this.authenticatedUid,
    required this.sessionOwnerUid,
    required this.session,
    required this.reviewId,
    required this.disposition,
    required this.reviewedAtUtc,
    required this.nowUtc,
    this.tripLogReference,
  });

  final String authenticatedUid;
  final String sessionOwnerUid;
  final TripTrackingSessionRecord session;
  final String reviewId;
  final TripTrackingAdvisoryDisposition disposition;
  final DateTime reviewedAtUtc;
  final DateTime nowUtc;
  final String? tripLogReference;
}

class TripStopReviewDispositionDecision {
  const TripStopReviewDispositionDecision({
    required this.status,
    required this.reviewIndex,
    required this.ownerValid,
    required this.sessionValid,
    required this.clockValid,
    required this.mayApplyDisposition,
    required this.updatedAdvisories,
    required this.reviewPayload,
  });

  final TripStopReviewDispositionStatus status;
  final int reviewIndex;
  final bool ownerValid;
  final bool sessionValid;
  final bool clockValid;
  final bool mayApplyDisposition;
  final List<TripTrackingAdvisoryEvent> updatedAdvisories;
  final Map<String, Object?> reviewPayload;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reviewIndex': reviewIndex < 0 ? null : reviewIndex,
    'ownerValid': ownerValid,
    'sessionValid': sessionValid,
    'clockValid': clockValid,
    'mayApplyDisposition': mayApplyDisposition,
    'requiresAuthenticatedOwner': true,
    'requiresLocalSessionRevision': true,
    'requiresPendingReview': true,
    'requiresFinalUserDisposition': true,
    'createsOfficialStop': false,
    'confirmedDispositionCanCreateStopAfterUserAcceptance': true,
    'rejectedOrDismissedCreatesStop': false,
    'correctedRequiresSeparateUserEditedTripLog': true,
    'officialStopSource': 'user_review_after_acceptance',
    'officialMileageSource': 'odometer',
    'remoteCanApplyDisposition': false,
    'firestoreCanApplyDisposition': false,
    'cloudFunctionCanApplyDisposition': false,
    'mapboxCanApplyDisposition': false,
    'activityRecognitionCanApplyDisposition': false,
    'canEndTripAutomatically': false,
    'canReplaceOdometer': false,
    'tokensIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'rawSamplesIncluded': false,
  };
}

class TripStopReviewDispositionGuard {
  const TripStopReviewDispositionGuard._();

  static TripStopReviewDispositionDecision evaluate(
    TripStopReviewDispositionRequest request,
  ) {
    final dispositionValid = TripStopAdvisoryReviewer.isFinalReviewDisposition(
      request.disposition,
    );
    final ownerValid =
        _safeIdentifier(request.authenticatedUid, maxLength: 96) &&
        request.authenticatedUid == request.sessionOwnerUid;
    final sessionValid = _sessionValid(request.session);
    final clockValid = _clockValid(
      reviewedAtUtc: request.reviewedAtUtc,
      nowUtc: request.nowUtc,
      session: request.session,
    );
    final reviewIndex = request.session.advisories.indexWhere(
      (event) =>
          event.id == request.reviewId &&
          event.type == TripTrackingAdvisoryType.probableStop &&
          event.sessionId == request.session.id &&
          event.vehicleId == request.session.vehicleId,
    );
    final review = reviewIndex < 0
        ? null
        : request.session.advisories[reviewIndex];
    final alreadyFinalized =
        review != null &&
        TripStopAdvisoryReviewer.isFinalReviewDisposition(review.disposition);
    final status = _statusFor(
      dispositionValid: dispositionValid,
      ownerValid: ownerValid,
      sessionValid: sessionValid,
      reviewIndex: reviewIndex,
      alreadyFinalized: alreadyFinalized,
      clockValid: clockValid,
    );
    final mayApply = status == TripStopReviewDispositionStatus.ready;
    final updated = mayApply
        ? _updatedAdvisories(
            request: request,
            reviewIndex: reviewIndex,
            tripLogReference: _safeOptionalReference(request.tripLogReference),
          )
        : request.session.advisories;

    return TripStopReviewDispositionDecision(
      status: status,
      reviewIndex: reviewIndex,
      ownerValid: ownerValid,
      sessionValid: sessionValid,
      clockValid: clockValid,
      mayApplyDisposition: mayApply,
      updatedAdvisories: List.unmodifiable(updated),
      reviewPayload: mayApply
          ? _payloadFor(
              request: request,
              tripLogReference: _safeOptionalReference(
                request.tripLogReference,
              ),
            )
          : const <String, Object?>{},
    );
  }
}

TripStopReviewDispositionStatus _statusFor({
  required bool dispositionValid,
  required bool ownerValid,
  required bool sessionValid,
  required int reviewIndex,
  required bool alreadyFinalized,
  required bool clockValid,
}) {
  if (!dispositionValid) {
    return TripStopReviewDispositionStatus.blockedDisposition;
  }
  if (!ownerValid) return TripStopReviewDispositionStatus.blockedOwner;
  if (!sessionValid) return TripStopReviewDispositionStatus.blockedSession;
  if (reviewIndex < 0) return TripStopReviewDispositionStatus.blockedReview;
  if (alreadyFinalized) return TripStopReviewDispositionStatus.blockedFinalized;
  if (!clockValid) return TripStopReviewDispositionStatus.blockedClock;
  return TripStopReviewDispositionStatus.ready;
}

List<TripTrackingAdvisoryEvent> _updatedAdvisories({
  required TripStopReviewDispositionRequest request,
  required int reviewIndex,
  String? tripLogReference,
}) {
  final updated = [...request.session.advisories];
  updated[reviewIndex] = updated[reviewIndex].copyWith(
    disposition: request.disposition,
    tripLogReference: tripLogReference,
  );
  return updated;
}

Map<String, Object?> _payloadFor({
  required TripStopReviewDispositionRequest request,
  String? tripLogReference,
}) {
  return {
    'schemaVersion': 1,
    'schema': 'trip_stop_review_disposition_mirror_v1',
    'reviewId': request.reviewId,
    'sessionId': request.session.id,
    'vehicleId': request.session.vehicleId,
    'ownerUid': request.sessionOwnerUid,
    'updatedByUid': request.sessionOwnerUid,
    'disposition': request.disposition.name,
    'reviewedAtUtc': request.reviewedAtUtc.toUtc().toIso8601String(),
    'tripLogReference': tripLogReference,
    'source': 'validated_local_user_review_disposition',
    'firestoreRole': 'mirror_after_local_write',
    'remoteCanOverrideLocalDisposition': false,
    'createsOfficialStop': false,
    'officialStopRequiresUserAcceptance': true,
    'officialMileageSource': 'odometer',
    'canEndTripAutomatically': false,
    'canReplaceOdometer': false,
    'locationDataIncluded': false,
    'rawGpsIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

bool _sessionValid(TripTrackingSessionRecord session) {
  return session.hasValidTimeline &&
      _safeIdentifier(session.id, maxLength: 96) &&
      _safeIdentifier(session.vehicleId, maxLength: 96) &&
      session.schemaVersion >= 1 &&
      !session.updatedAt.isBefore(session.startedAt);
}

bool _clockValid({
  required DateTime reviewedAtUtc,
  required DateTime nowUtc,
  required TripTrackingSessionRecord session,
}) {
  final reviewed = reviewedAtUtc.toUtc();
  final now = nowUtc.toUtc();
  if (reviewed.isBefore(session.startedAt.toUtc())) return false;
  if (reviewed.isAfter(now.add(const Duration(minutes: 5)))) return false;
  if (reviewed.isBefore(now.subtract(const Duration(days: 30)))) return false;
  return true;
}

String? _safeOptionalReference(String? value) {
  if (value == null) return null;
  return _safeIdentifier(value, maxLength: 160) ? value : null;
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
