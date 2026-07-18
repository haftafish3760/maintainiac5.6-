import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_review_open_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('validated local stop evidence may open a pending user review', () {
    final decision = TripStopReviewOpenGuard.evaluate(request());
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopReviewOpenStatus.ready);
    expect(decision.mayOpenReview, isTrue);
    expect(decision.reviewPayload['schema'], 'trip_stop_review_mirror_v1');
    expect(decision.reviewPayload['ownerUid'], 'userA');
    expect(decision.reviewPayload['createdByUid'], 'userA');
    expect(decision.reviewPayload['updatedByUid'], 'userA');
    expect(decision.reviewPayload['disposition'], 'pending_user_review');
    expect(
      decision.reviewPayload['source'],
      'validated_local_trip_stop_evidence',
    );
    expect(decision.reviewPayload['createsOfficialStop'], isFalse);
    expect(
      decision.reviewPayload['officialStopRequiresUserAcceptance'],
      isTrue,
    );
    expect(decision.reviewPayload['firestoreRole'], 'mirror_after_local_write');
    expect(decision.reviewPayload['locationDataIncluded'], isFalse);
    expect(decision.reviewPayload['rawGpsIncluded'], isFalse);
    expect(decision.reviewPayload['coordinatesIncluded'], isFalse);
    expect(decision.reviewPayload['routeGeometryIncluded'], isFalse);
    expect(decision.reviewPayload['tokensIncluded'], isFalse);
    expect(safe['remoteCanOpenStopReview'], isFalse);
    expect(safe['firestoreCanOpenStopReview'], isFalse);
    expect(safe['mapboxCanOpenStopReview'], isFalse);
    expect(safe['canEndTripAutomatically'], isFalse);
    expect(safe['canReplaceOdometer'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
  });

  test('readiness boundary blocks traffic control and unsafe summaries', () {
    for (final summary in [
      TripStopClassifier.classify(
        profile: TripTrackingProfile.deliveryVehicle,
        motionState: TripMotionState.moving,
        needsWalkingReview: false,
        excludedWalkingCount: 0,
        rejectedDriftCount: 8,
        rejectedUnsafeCount: 0,
        acceptedDistanceCount: 4,
      ).toSafeSummary(),
      reviewStopSummary()
        ..addAll({'mapboxCanCreateStop': true, 'coordinatesIncluded': true}),
    ]) {
      final decision = TripStopReviewOpenGuard.evaluate(
        request(stopSummary: summary),
      );

      expect(decision.status, TripStopReviewOpenStatus.blockedReadiness);
      expect(decision.mayOpenReview, isFalse);
      expect(decision.reviewPayload, isEmpty);
      expect(decision.toSafeDashboardMap()['createsOfficialStop'], isFalse);
    }
  });

  test('authenticated user must own the local trip session', () {
    final decision = TripStopReviewOpenGuard.evaluate(
      request(authenticatedUid: 'otherUser'),
    );

    expect(decision.status, TripStopReviewOpenStatus.blockedOwner);
    expect(decision.ownerValid, isFalse);
    expect(decision.mayOpenReview, isFalse);
    expect(decision.reviewPayload, isEmpty);
    expect(decision.toSafeDashboardMap()['requiresAuthenticatedOwner'], isTrue);
  });

  test('invalid session metadata blocks stop review creation', () {
    final invalidRequests = [
      request(sessionId: 'bad:id'),
      request(vehicleId: 'sk.secret'),
      request(localSessionRevision: 0),
    ];

    for (final invalid in invalidRequests) {
      final decision = TripStopReviewOpenGuard.evaluate(invalid);

      expect(decision.status, TripStopReviewOpenStatus.blockedSession);
      expect(decision.sessionValid, isFalse);
      expect(decision.mayOpenReview, isFalse);
      expect(decision.reviewPayload, isEmpty);
    }
  });

  test('duplicate pending review id blocks repeated review popups', () {
    final detectedAt = DateTime.utc(2026, 7, 18, 12);
    final duplicateId =
        'sessionA.stop.${detectedAt.toUtc().microsecondsSinceEpoch}';
    final decision = TripStopReviewOpenGuard.evaluate(
      request(
        detectedAtUtc: detectedAt,
        existingPendingReviewIds: [duplicateId],
      ),
    );

    expect(decision.status, TripStopReviewOpenStatus.blockedDuplicate);
    expect(decision.duplicatePendingReview, isTrue);
    expect(decision.mayOpenReview, isFalse);
    expect(decision.reviewPayload, isEmpty);
  });

  test('device clock anomalies fail closed before opening a stop review', () {
    final now = DateTime.utc(2026, 7, 18, 12);
    for (final detectedAt in [
      now.add(const Duration(minutes: 6)),
      now.subtract(const Duration(days: 31)),
    ]) {
      final decision = TripStopReviewOpenGuard.evaluate(
        request(nowUtc: now, detectedAtUtc: detectedAt),
      );

      expect(decision.status, TripStopReviewOpenStatus.blockedClock);
      expect(decision.clockValid, isFalse);
      expect(decision.mayOpenReview, isFalse);
      expect(decision.reviewPayload, isEmpty);
    }
  });

  test(
    'no active local session cannot open review from remote mirror alone',
    () {
      final decision = TripStopReviewOpenGuard.evaluate(
        request(activeTrip: false, localSessionAvailable: false),
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripStopReviewOpenStatus.blockedReadiness);
      expect(decision.mayOpenReview, isFalse);
      expect(safe['requiresLocalTripLog'], isTrue);
      expect(safe['remoteCanOpenStopReview'], isFalse);
      expect(safe['firestoreCanOpenStopReview'], isFalse);
      expect(safe['cloudFunctionCanOpenStopReview'], isFalse);
    },
  );

  test('safe dashboard map never exposes tokens, coordinates, or samples', () {
    final decision = TripStopReviewOpenGuard.evaluate(request());
    final safe = decision.toSafeDashboardMap();

    expect(safe['tokensIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
    expect(safe.toString(), isNot(contains('35.')));
  });
}

TripStopReviewOpenRequest request({
  String authenticatedUid = 'userA',
  String sessionOwnerUid = 'userA',
  String sessionId = 'sessionA',
  String vehicleId = 'vehicleA',
  int localSessionRevision = 1,
  bool activeTrip = true,
  bool localSessionAvailable = true,
  bool acceptedVehicleMovementObserved = true,
  DateTime? detectedAtUtc,
  DateTime? nowUtc,
  List<String> existingPendingReviewIds = const [],
  Map<String, Object?>? stopSummary,
}) {
  final now = nowUtc ?? DateTime.utc(2026, 7, 18, 12, 5);
  return TripStopReviewOpenRequest(
    authenticatedUid: authenticatedUid,
    sessionOwnerUid: sessionOwnerUid,
    sessionId: sessionId,
    vehicleId: vehicleId,
    localSessionRevision: localSessionRevision,
    activeTrip: activeTrip,
    localSessionAvailable: localSessionAvailable,
    acceptedVehicleMovementObserved: acceptedVehicleMovementObserved,
    detectedAtUtc: detectedAtUtc ?? DateTime.utc(2026, 7, 18, 12),
    nowUtc: now,
    existingPendingReviewIds: existingPendingReviewIds,
    stopSummary: stopSummary ?? reviewStopSummary(),
  );
}

Map<String, Object?> reviewStopSummary() => TripStopClassifier.classify(
  profile: TripTrackingProfile.deliveryVehicle,
  motionState: TripMotionState.stopped,
  needsWalkingReview: true,
  excludedWalkingCount: 4,
  rejectedDriftCount: 0,
  rejectedUnsafeCount: 0,
  acceptedDistanceCount: 5,
).toSafeSummary();
