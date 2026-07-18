import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_advisory_reviewer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final start = DateTime.utc(2026, 7, 14, 12);

  TripTrackingAdvisoryEvent stop({
    required String id,
    required DateTime detectedAt,
    TripTrackingConfidence confidence = TripTrackingConfidence.medium,
    TripTrackingAdvisoryDisposition disposition =
        TripTrackingAdvisoryDisposition.pending,
  }) => TripTrackingAdvisoryEvent(
    id: id,
    type: TripTrackingAdvisoryType.probableStop,
    sessionId: 'trip_1',
    vehicleId: 'vehicle_1',
    profile: TripTrackingProfile.rideshareVehicle,
    detectedAt: detectedAt,
    evidenceStartedAt: detectedAt,
    evidenceEndedAt: detectedAt,
    confidence: confidence,
    suggestedAction: 'reviewStop',
    disposition: disposition,
  );

  TripTrackingSessionRecord sessionWith(
    List<TripTrackingAdvisoryEvent> advisories, {
    String id = 'trip_1',
    String vehicleId = 'vehicle_1',
  }) => TripTrackingSessionRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    profile: TripTrackingProfile.rideshareVehicle,
    startedAt: start,
    updatedAt: start,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 0,
      walkingReviewSuggested: false,
    ),
    advisories: advisories,
  );

  test('review dispositions are explicit final user choices only', () {
    expect(
      TripStopAdvisoryReviewer.isFinalReviewDisposition(
        TripTrackingAdvisoryDisposition.pending,
      ),
      isFalse,
    );
    for (final disposition in [
      TripTrackingAdvisoryDisposition.confirmed,
      TripTrackingAdvisoryDisposition.rejected,
      TripTrackingAdvisoryDisposition.corrected,
      TripTrackingAdvisoryDisposition.dismissed,
    ]) {
      expect(
        TripStopAdvisoryReviewer.isFinalReviewDisposition(disposition),
        isTrue,
      );
    }
  });

  test('walking review prefers the latest high-confidence pending stop', () {
    final session = sessionWith([
      stop(
        id: 'medium_latest',
        detectedAt: start.add(const Duration(minutes: 3)),
      ),
      stop(
        id: 'high_earlier',
        detectedAt: start.add(const Duration(minutes: 2)),
        confidence: TripTrackingConfidence.high,
      ),
      stop(
        id: 'medium_newest',
        detectedAt: start.add(const Duration(minutes: 4)),
      ),
    ]);

    expect(
      TripStopAdvisoryReviewer.latestPendingStopReviewIndex(
        session,
        preferHighConfidence: true,
      ),
      1,
    );
    expect(
      TripStopAdvisoryReviewer.latestPendingStopReviewIndex(
        session,
        preferHighConfidence: false,
      ),
      2,
    );
  });

  test('rejected and dismissed stops are not active resume anchors', () {
    for (final disposition in [
      TripTrackingAdvisoryDisposition.rejected,
      TripTrackingAdvisoryDisposition.dismissed,
    ]) {
      final session = sessionWith([
        stop(id: disposition.name, detectedAt: start, disposition: disposition),
      ]);

      expect(TripStopAdvisoryReviewer.hasActiveStopReview(session), isFalse);
    }
  });

  test(
    'vehicle-only stop uses stationary evidence start and upgrades in place',
    () {
      final stationaryStartedAt = start.add(const Duration(seconds: 30));
      final detectedAt = start.add(const Duration(seconds: 135));
      final session = sessionWith(const []);
      final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
        session,
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
          motionState: TripMotionState.stopCandidate,
          vehicleMovementObserved: true,
          stationaryStartedAt: stationaryStartedAt,
        ),
        previousMotionState: TripMotionState.moving,
        currentMotionState: TripMotionState.stopCandidate,
        detectedAt: detectedAt,
      );

      expect(advisories.single.evidenceStartedAt, stationaryStartedAt);
      expect(advisories.single.confidence, TripTrackingConfidence.medium);

      final upgraded = TripStopAdvisoryReviewer.afterMotionTransition(
        sessionWith(advisories),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: true,
          motionState: TripMotionState.stopped,
        ),
        previousMotionState: TripMotionState.stopCandidate,
        currentMotionState: TripMotionState.stopped,
        detectedAt: start.add(const Duration(seconds: 180)),
      );

      expect(upgraded, hasLength(1));
      expect(upgraded.single.evidenceStartedAt, stationaryStartedAt);
      expect(upgraded.single.confidence, TripTrackingConfidence.high);
    },
  );

  test('advisory transitions clamp evidence inside the trip boundary', () {
    final session = sessionWith(const []);
    final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
      session,
      engineSnapshot: TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: true,
        motionState: TripMotionState.stopped,
        vehicleMovementObserved: true,
        walkingEvidence: [
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 94,
            recordedAt: start.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      previousMotionState: TripMotionState.moving,
      currentMotionState: TripMotionState.stopped,
      detectedAt: start.subtract(const Duration(minutes: 2)),
    );

    expect(advisories, hasLength(1));
    expect(advisories.single.detectedAt, start);
    expect(advisories.single.evidenceStartedAt, start);
    expect(advisories.single.evidenceEndedAt, start);
    expect(advisories.single.confidence, TripTrackingConfidence.high);
  });

  test(
    'duplicate transition timestamps do not create duplicate advisories',
    () {
      final detectedAt = start.add(const Duration(minutes: 5));
      final first = TripStopAdvisoryReviewer.afterMotionTransition(
        sessionWith(const []),
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
          motionState: TripMotionState.stopCandidate,
          vehicleMovementObserved: true,
          stationaryStartedAt: start.add(const Duration(minutes: 3)),
        ),
        previousMotionState: TripMotionState.moving,
        currentMotionState: TripMotionState.stopCandidate,
        detectedAt: detectedAt,
      );
      final second = TripStopAdvisoryReviewer.afterMotionTransition(
        sessionWith(first),
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
          motionState: TripMotionState.stopCandidate,
          vehicleMovementObserved: true,
          stationaryStartedAt: start.add(const Duration(minutes: 3)),
        ),
        previousMotionState: TripMotionState.moving,
        currentMotionState: TripMotionState.stopCandidate,
        detectedAt: detectedAt,
      );

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(second.single.id, first.single.id);
    },
  );

  test(
    'far future advisory timestamps are capped instead of persisted raw',
    () {
      final cappedAt = start.add(const Duration(days: 30));
      final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
        sessionWith(const []),
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
          motionState: TripMotionState.stopCandidate,
          vehicleMovementObserved: true,
          stationaryStartedAt: start.add(const Duration(minutes: 1)),
        ),
        previousMotionState: TripMotionState.moving,
        currentMotionState: TripMotionState.stopCandidate,
        detectedAt: start.add(const Duration(days: 365)),
      );

      expect(advisories.single.detectedAt, cappedAt);
      expect(advisories.single.evidenceEndedAt, cappedAt);
      expect(
        advisories.single.id,
        contains('${cappedAt.microsecondsSinceEpoch}'),
      );
    },
  );

  test('unsafe session identifiers cannot create advisory records', () {
    for (final session in [
      sessionWith(const [], id: 'sk.secret'),
      sessionWith(const [], vehicleId: 'vehicle:raw'),
      sessionWith(const [], id: 'trip token leak'),
    ]) {
      final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
        session,
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
          motionState: TripMotionState.stopCandidate,
          vehicleMovementObserved: true,
          stationaryStartedAt: start.add(const Duration(minutes: 1)),
        ),
        previousMotionState: TripMotionState.moving,
        currentMotionState: TripMotionState.stopCandidate,
        detectedAt: start.add(const Duration(minutes: 5)),
      );

      expect(advisories, isEmpty);
    }
  });

  test('unsafe session identifiers cannot upgrade stop advisories', () {
    final pending = stop(
      id: 'review_1',
      detectedAt: start.add(const Duration(minutes: 1)),
    );
    final advisories = TripStopAdvisoryReviewer.upgradedStopCandidateAdvisories(
      sessionWith([pending], id: 'pk.public'),
      detectedAt: start.add(const Duration(minutes: 2)),
    );

    expect(advisories.single.confidence, TripTrackingConfidence.medium);
  });
}
