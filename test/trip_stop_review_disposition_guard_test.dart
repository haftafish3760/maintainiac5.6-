import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_review_disposition_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final start = DateTime.utc(2026, 7, 18, 8);
  final now = DateTime.utc(2026, 7, 18, 9);

  test('owner can apply final pending stop disposition locally', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(
        nowUtc: now,
        reviewedAtUtc: now,
        disposition: TripTrackingAdvisoryDisposition.confirmed,
        tripLogReference: 'tripLog_123',
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopReviewDispositionStatus.ready);
    expect(decision.mayApplyDisposition, isTrue);
    expect(decision.reviewIndex, 0);
    expect(
      decision.updatedAdvisories.single.disposition,
      TripTrackingAdvisoryDisposition.confirmed,
    );
    expect(decision.updatedAdvisories.single.tripLogReference, 'tripLog_123');
    expect(
      decision.reviewPayload['schema'],
      'trip_stop_review_disposition_mirror_v1',
    );
    expect(decision.reviewPayload['firestoreRole'], 'mirror_after_local_write');
    expect(
      decision.reviewPayload['remoteCanOverrideLocalDisposition'],
      isFalse,
    );
    expect(safe['firestoreCanApplyDisposition'], isFalse);
    expect(safe['mapboxCanApplyDisposition'], isFalse);
    expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(safe['employerGodModeAllowed'], isFalse);
    expect(safe['dispositionPayloadCanExposeLiveLocation'], isFalse);
    expect(safe['canReplaceOdometer'], isFalse);
  });

  test(
    'pending disposition is blocked because it is not final user review',
    () {
      final decision = TripStopReviewDispositionGuard.evaluate(
        request(
          nowUtc: now,
          reviewedAtUtc: now,
          disposition: TripTrackingAdvisoryDisposition.pending,
        ),
      );

      expect(
        decision.status,
        TripStopReviewDispositionStatus.blockedDisposition,
      );
      expect(decision.mayApplyDisposition, isFalse);
      expect(
        decision.updatedAdvisories.single.disposition,
        TripTrackingAdvisoryDisposition.pending,
      );
      expect(decision.reviewPayload, isEmpty);
    },
  );

  test('authenticated user must own the session disposition', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(authenticatedUid: 'otherUser', nowUtc: now, reviewedAtUtc: now),
    );

    expect(decision.status, TripStopReviewDispositionStatus.blockedOwner);
    expect(decision.ownerValid, isFalse);
    expect(decision.mayApplyDisposition, isFalse);
  });

  test('bad local session metadata blocks disposition writes', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(
        nowUtc: now,
        reviewedAtUtc: now,
        session: sessionWith(id: 'sk.secret'),
      ),
    );

    expect(decision.status, TripStopReviewDispositionStatus.blockedSession);
    expect(decision.sessionValid, isFalse);
    expect(decision.reviewPayload, isEmpty);
  });

  test('unknown review id cannot mutate another advisory', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(nowUtc: now, reviewedAtUtc: now, reviewId: 'missing_review'),
    );

    expect(decision.status, TripStopReviewDispositionStatus.blockedReview);
    expect(decision.reviewIndex, -1);
    expect(decision.mayApplyDisposition, isFalse);
  });

  test('already finalized review cannot be overwritten by a second source', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(
        nowUtc: now,
        reviewedAtUtc: now,
        session: sessionWith(
          advisoryDisposition: TripTrackingAdvisoryDisposition.rejected,
        ),
        disposition: TripTrackingAdvisoryDisposition.confirmed,
      ),
    );

    expect(decision.status, TripStopReviewDispositionStatus.blockedFinalized);
    expect(decision.mayApplyDisposition, isFalse);
    expect(
      decision.updatedAdvisories.single.disposition,
      TripTrackingAdvisoryDisposition.rejected,
    );
  });

  test('review clock anomalies fail closed before disposition write', () {
    for (final reviewedAt in [
      now.add(const Duration(minutes: 6)),
      now.subtract(const Duration(days: 31)),
      start.subtract(const Duration(seconds: 1)),
    ]) {
      final decision = TripStopReviewDispositionGuard.evaluate(
        request(nowUtc: now, reviewedAtUtc: reviewedAt),
      );

      expect(decision.status, TripStopReviewDispositionStatus.blockedClock);
      expect(decision.clockValid, isFalse);
      expect(decision.mayApplyDisposition, isFalse);
    }
  });

  test('unsafe trip log references are dropped from safe mirror payload', () {
    final decision = TripStopReviewDispositionGuard.evaluate(
      request(
        nowUtc: now,
        reviewedAtUtc: now,
        disposition: TripTrackingAdvisoryDisposition.corrected,
        tripLogReference: 'sk.secret:raw',
      ),
    );

    expect(decision.status, TripStopReviewDispositionStatus.ready);
    expect(decision.updatedAdvisories.single.tripLogReference, isNull);
    expect(decision.reviewPayload['tripLogReference'], isNull);
    expect(decision.reviewPayload.toString(), isNot(contains('sk.secret')));
  });

  test('disposition mirror payload cannot expose live employee location', () {
    final payload = TripStopReviewDispositionGuard.evaluate(
      request(nowUtc: now, reviewedAtUtc: now),
    ).reviewPayload;

    expect(payload['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(payload['employerGodModeAllowed'], isFalse);
    expect(payload['dispositionPayloadCanExposeLiveLocation'], isFalse);
    expect(payload['coordinatesIncluded'], isFalse);
  });
}

TripStopReviewDispositionRequest request({
  String authenticatedUid = 'userA',
  String sessionOwnerUid = 'userA',
  TripTrackingSessionRecord? session,
  String reviewId = 'review_1',
  TripTrackingAdvisoryDisposition disposition =
      TripTrackingAdvisoryDisposition.rejected,
  DateTime? reviewedAtUtc,
  DateTime? nowUtc,
  String? tripLogReference,
}) {
  final activeSession = session ?? sessionWith();
  return TripStopReviewDispositionRequest(
    authenticatedUid: authenticatedUid,
    sessionOwnerUid: sessionOwnerUid,
    session: activeSession,
    reviewId: reviewId,
    disposition: disposition,
    reviewedAtUtc: reviewedAtUtc ?? DateTime.utc(2026, 7, 18, 9),
    nowUtc: nowUtc ?? DateTime.utc(2026, 7, 18, 9),
    tripLogReference: tripLogReference,
  );
}

TripTrackingSessionRecord sessionWith({
  String id = 'trip_1',
  String vehicleId = 'vehicle_1',
  TripTrackingAdvisoryDisposition advisoryDisposition =
      TripTrackingAdvisoryDisposition.pending,
}) {
  final start = DateTime.utc(2026, 7, 18, 8);
  return TripTrackingSessionRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: start,
    updatedAt: start.add(const Duration(minutes: 30)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 100,
      walkingReviewSuggested: false,
    ),
    advisories: [
      TripTrackingAdvisoryEvent(
        id: 'review_1',
        type: TripTrackingAdvisoryType.probableStop,
        sessionId: id,
        vehicleId: vehicleId,
        profile: TripTrackingProfile.deliveryVehicle,
        detectedAt: start.add(const Duration(minutes: 20)),
        evidenceStartedAt: start.add(const Duration(minutes: 18)),
        evidenceEndedAt: start.add(const Duration(minutes: 20)),
        confidence: TripTrackingConfidence.medium,
        suggestedAction: 'reviewStop',
        disposition: advisoryDisposition,
      ),
    ],
  );
}
