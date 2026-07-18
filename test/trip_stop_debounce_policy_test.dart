import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 18, 14);
  final latestWalking = observedAt.subtract(const Duration(seconds: 30));

  TripStopDebounceObservation observation({
    TripMotionState motionState = TripMotionState.stopCandidate,
    Duration stationaryDuration = const Duration(seconds: 45),
    int walkingEvidenceCount = 3,
    Duration walkingEvidenceSpan = const Duration(seconds: 24),
    int rejectedDriftCount = 0,
    int rejectedUnsafeCount = 0,
    int acceptedDistanceCount = 8,
    bool acceptedVehicleMovementObserved = true,
    double speedMps = 0.2,
    double horizontalAccuracyMeters = 12,
  }) {
    return TripStopDebounceObservation(
      motionState: motionState,
      stationaryDuration: stationaryDuration,
      walkingEvidenceCount: walkingEvidenceCount,
      walkingEvidenceSpan: walkingEvidenceSpan,
      rejectedDriftCount: rejectedDriftCount,
      rejectedUnsafeCount: rejectedUnsafeCount,
      acceptedDistanceCount: acceptedDistanceCount,
      acceptedVehicleMovementObserved: acceptedVehicleMovementObserved,
      speedMps: speedMps,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      latestWalkingEvidenceAt: latestWalking,
      observedAt: observedAt,
    );
  }

  test('delivery stops can open review after vehicle movement and walking', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(),
    );

    expect(decision.status, TripStopDebounceStatus.readyForReview);
    expect(decision.canOpenReview, isTrue);
    expect(decision.classification.signal, TripStopSignal.reviewOnlyStop);
    expect(decision.classification.reasonCode, 'delivery_stop_walk_review');
    expect(
      decision.classification.toSafeSummary()['canCreateOfficialStop'],
      isFalse,
    );
  });

  test('contractor jobsite stops are review-only and map independent', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: observation(
        walkingEvidenceCount: 4,
        walkingEvidenceSpan: const Duration(seconds: 35),
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.readyForReview);
    expect(decision.classification.reasonCode, 'contractor_stop_walk_review');
    expect(safe['mapsRequiredForStopDebounce'], isFalse);
    expect(safe['mapboxCanCreateStop'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
  });

  test(
    'rideshare waits for stronger evidence because phone may stay in car',
    () {
      final decision = TripStopDebouncePolicy.evaluate(
        profile: TripTrackingProfile.rideshareVehicle,
        observation: observation(
          stationaryDuration: const Duration(seconds: 40),
          walkingEvidenceCount: 3,
          walkingEvidenceSpan: const Duration(seconds: 30),
        ),
      );

      expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
      expect(decision.canOpenReview, isFalse);
      expect(
        decision.classification.reasonCode,
        'stop_candidate_waiting_for_stronger_evidence',
      );
      expect(decision.shouldContinueSampling, isTrue);
    },
  );

  test(
    'walking sensor burst is protected even during stationary vehicle dwell',
    () {
      final decision = TripStopDebouncePolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        observation: observation(
          stationaryDuration: const Duration(minutes: 2),
          walkingEvidenceCount: 5,
          walkingEvidenceSpan: const Duration(seconds: 2),
          rejectedDriftCount: 0,
          speedMps: 0.1,
        ),
      );
      final safe = decision.toSafeDashboardMap();
      final evidenceDigest = safe['evidenceDigest'] as Map<String, Object?>;

      expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
      expect(decision.reasonCode, 'walking_burst_debounce_protected');
      expect(decision.canOpenReview, isFalse);
      expect(decision.classification.signal, TripStopSignal.stopCandidate);
      expect(evidenceDigest['walkingBurstProtected'], isTrue);
      expect(evidenceDigest['coordinatesIncluded'], isFalse);
      expect(evidenceDigest['rawSamplesIncluded'], isFalse);
    },
  );

  test('well-spaced walking evidence keeps delivery review available', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        stationaryDuration: const Duration(minutes: 2),
        walkingEvidenceCount: 5,
        walkingEvidenceSpan: const Duration(seconds: 30),
        rejectedDriftCount: 0,
        speedMps: 0.1,
      ),
    );
    final evidenceDigest =
        decision.toSafeDashboardMap()['evidenceDigest'] as Map<String, Object?>;

    expect(decision.status, TripStopDebounceStatus.readyForReview);
    expect(decision.canOpenReview, isTrue);
    expect(decision.classification.signal, TripStopSignal.reviewOnlyStop);
    expect(evidenceDigest['walkingBurstProtected'], isFalse);
    expect(evidenceDigest['hasAcceptedVehicleMovement'], isTrue);
  });

  test('future walking evidence cannot open a stop review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: TripStopDebounceObservation(
        motionState: TripMotionState.stopped,
        stationaryDuration: const Duration(minutes: 2),
        walkingEvidenceCount: 5,
        walkingEvidenceSpan: const Duration(seconds: 35),
        rejectedDriftCount: 0,
        rejectedUnsafeCount: 0,
        acceptedDistanceCount: 9,
        acceptedVehicleMovementObserved: true,
        speedMps: 0.1,
        horizontalAccuracyMeters: 10,
        latestWalkingEvidenceAt: observedAt.add(const Duration(seconds: 2)),
        observedAt: observedAt,
      ),
    );
    final safe = decision.toSafeDashboardMap();
    final digest = safe['evidenceDigest'] as Map<String, Object?>;
    final recency = digest['walkingEvidenceRecency'] as Map<String, Object?>;

    expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(decision.reasonCode, 'future_walking_evidence_rejected');
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.canSuggestStop, isFalse);
    expect(digest['walkingEvidenceCurrent'], isFalse);
    expect(recency['futureEvidenceRejected'], isTrue);
  });

  test('stale walking evidence cannot be replayed into a stop review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: observation(
        motionState: TripMotionState.stopped,
        stationaryDuration: const Duration(minutes: 4),
        walkingEvidenceCount: 6,
        walkingEvidenceSpan: const Duration(minutes: 2),
        speedMps: 0.1,
      ),
    );
    final staleDecision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: TripStopDebounceObservation(
        motionState: TripMotionState.stopped,
        stationaryDuration: const Duration(minutes: 4),
        walkingEvidenceCount: 6,
        walkingEvidenceSpan: const Duration(minutes: 2),
        rejectedDriftCount: 0,
        rejectedUnsafeCount: 0,
        acceptedDistanceCount: 8,
        acceptedVehicleMovementObserved: true,
        speedMps: 0.1,
        horizontalAccuracyMeters: 12,
        latestWalkingEvidenceAt: observedAt.subtract(
          const Duration(minutes: 9),
        ),
        observedAt: observedAt,
      ),
    );
    final digest =
        staleDecision.toSafeDashboardMap()['evidenceDigest']
            as Map<String, Object?>;

    expect(decision.status, TripStopDebounceStatus.readyForReview);
    expect(staleDecision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(staleDecision.reasonCode, 'stale_walking_evidence_rejected');
    expect(staleDecision.canOpenReview, isFalse);
    expect(digest['walkingEvidenceCurrent'], isFalse);
  });

  test('profile thresholds are visible without raw GPS samples', () {
    final delivery = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        walkingEvidenceCount: 3,
        walkingEvidenceSpan: const Duration(seconds: 24),
      ),
    ).evidenceDigest.toSafeDashboardMap();
    final rideshare = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      observation: observation(
        walkingEvidenceCount: 4,
        walkingEvidenceSpan: const Duration(seconds: 46),
        stationaryDuration: const Duration(seconds: 50),
      ),
    ).evidenceDigest.toSafeDashboardMap();

    expect(delivery['minimumStationarySeconds'], 20);
    expect(rideshare['minimumStationarySeconds'], 45);
    expect(delivery['coordinatesIncluded'], isFalse);
    expect(rideshare['routeGeometryIncluded'], isFalse);
    expect(delivery['tokensIncluded'], isFalse);
  });

  test('long traffic light jitter is protected from false stop creation', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        motionState: TripMotionState.stopCandidate,
        stationaryDuration: const Duration(minutes: 2),
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        rejectedDriftCount: 6,
        speedMps: 0.1,
      ),
    );
    final summary = decision.classification.toSafeSummary();

    expect(decision.status, TripStopDebounceStatus.trafficControlProtected);
    expect(decision.protectedTrafficControl, isTrue);
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.signal, TripStopSignal.likelyTrafficControl);
    expect(summary['longTrafficLightProtected'], isTrue);
  });

  test('long rideshare vehicle-only dwell surfaces manual fallback only', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      observation: observation(
        stationaryDuration: const Duration(minutes: 9),
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        rejectedDriftCount: 0,
        speedMps: 0.1,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(decision.reasonCode, 'vehicle_only_dwell_manual_fallback');
    expect(decision.canOpenReview, isFalse);
    expect(decision.shouldContinueSampling, isTrue);
    expect(decision.classification.signal, TripStopSignal.stopCandidate);
    expect(decision.classification.shouldSurfaceManualStopFallback, isTrue);
    expect(safe['vehicleOnlyDwellCanCreateOfficialStop'], isFalse);
    expect(
      (safe['vehicleOnlyDwell']
          as Map<String, Object?>)['mapboxCanConfirmVehicleOnlyStop'],
      isFalse,
    );
  });

  test('walking evidence before accepted vehicle movement fails closed', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        acceptedVehicleMovementObserved: false,
        acceptedDistanceCount: 0,
        walkingEvidenceCount: 6,
      ),
    );

    expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.signal, TripStopSignal.unsafeEvidence);
    expect(
      decision.classification.reasonCode,
      'walking_stop_without_vehicle_movement',
    );
  });

  test('unsafe coordinates or provider values cannot surface stop review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: observation(
        horizontalAccuracyMeters: 500,
        speedMps: double.nan,
        rejectedUnsafeCount: 1,
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripStopDebounceStatus.unsafeEvidence);
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.signal, TripStopSignal.unsafeEvidence);
    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('malformed observation fails closed without opening review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(
        stationaryDuration: const Duration(seconds: -5),
        walkingEvidenceSpan: const Duration(seconds: -2),
        walkingEvidenceCount: 500000,
        acceptedDistanceCount: 500000,
        rejectedUnsafeCount: 500000,
        speedMps: double.infinity,
        horizontalAccuracyMeters: -1,
      ),
    );
    final safe = decision.toSafeDashboardMap();
    final evidenceDigest = safe['evidenceDigest'] as Map<String, Object?>;

    expect(decision.status, TripStopDebounceStatus.unsafeEvidence);
    expect(decision.canOpenReview, isFalse);
    expect(decision.needsWalkingReview, isFalse);
    expect(decision.classification.signal, TripStopSignal.unsafeEvidence);
    expect(safe['malformedStopDebounceObservationFailsClosed'], isTrue);
    expect(safe['remoteDebounceCanOpenReview'], isFalse);
    expect(safe['remoteDebounceCanEndTrip'], isFalse);
    expect(evidenceDigest['providerValuesUsable'], isFalse);
  });

  test('equipment profile ignores walking-style stops', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.lowSpeedEquipment,
      observation: observation(
        walkingEvidenceCount: 8,
        walkingEvidenceSpan: const Duration(minutes: 2),
      ),
    );

    expect(decision.status, TripStopDebounceStatus.waitingForEvidence);
    expect(decision.canOpenReview, isFalse);
    expect(decision.classification.signal, TripStopSignal.equipmentIgnored);
    expect(
      decision.classification.reasonCode,
      'equipment_walking_evidence_ignored',
    );
  });

  test('safe summary denies remote stop, maps, and mileage authority', () {
    final safe = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: observation(),
    ).toSafeDashboardMap();

    expect(safe['gpsAssistedOnly'], isTrue);
    expect(safe['firestoreCanCreateStop'], isFalse);
    expect(safe['cloudFunctionCanCreateStop'], isFalse);
    expect(safe['remoteDebounceCanOverrideLocalTrip'], isFalse);
    expect(safe['remoteDebounceCanOpenReview'], isFalse);
    expect(safe['remoteDebounceCanEndTrip'], isFalse);
    expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(safe['stopReviewRequiredForOfficialStop'], isTrue);
    expect(safe['stopReviewCannotCommitWithoutUserAction'], isTrue);
    expect(safe['vehicleOnlyDwellCanOnlySuggestManualFallback'], isTrue);
  });

  test('safe summary carries counts but never remote stop authority', () {
    final safe = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: observation(
        walkingEvidenceCount: 4,
        walkingEvidenceSpan: const Duration(seconds: 40),
        acceptedDistanceCount: 12,
        rejectedDriftCount: 2,
      ),
    ).toSafeDashboardMap();
    final evidenceDigest = safe['evidenceDigest'] as Map<String, Object?>;

    expect(evidenceDigest['acceptedDistanceCount'], 12);
    expect(evidenceDigest['rejectedDriftCount'], 2);
    expect(evidenceDigest['providerValuesUsable'], isTrue);
    expect(safe['firestoreCanCreateStop'], isFalse);
    expect(safe['cloudFunctionCanCreateStop'], isFalse);
    expect(safe['mapboxCanConfirmStop'], isFalse);
    expect(safe['remoteDebounceCanOverrideLocalTrip'], isFalse);
  });
}
