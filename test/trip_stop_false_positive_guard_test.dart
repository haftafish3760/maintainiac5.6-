import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_debounce_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_false_positive_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 18, 14);

  test('delivery walking stop passes guard but still requires review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: _observation(
        observedAt: observedAt,
        latestWalkingEvidenceAt: observedAt.subtract(
          const Duration(seconds: 30),
        ),
      ),
    );
    final safe = decision.toSafeDashboardMap();
    final guard = safe['falsePositiveGuard'] as Map<String, Object?>;

    expect(decision.canOpenReview, isTrue);
    expect(decision.needsWalkingReview, isTrue);
    expect(guard['profile'], TripTrackingProfile.deliveryVehicle.name);
    expect(guard['driverProfileBoundaryValidated'], isTrue);
    expect(guard['deliveryAndContractorWalkingStopsMayOpenReview'], isTrue);
    expect(guard['rideshareVehicleOnlyStopRequiresManualFallback'], isFalse);
    expect(guard['status'], TripStopFalsePositiveGuardStatus.passed.name);
    expect(guard['canAllowReviewOpen'], isTrue);
    expect(guard['officialStopRequiresUserAction'], isTrue);
    expect(guard['odometerRemainsOfficialMileageTruth'], isTrue);
  });

  test('long traffic light cannot open review through forged summary', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: _observation(
        observedAt: observedAt,
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        rejectedDriftCount: 7,
        stationaryDuration: const Duration(minutes: 2),
      ),
    );
    final forged = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      status: decision.status.name,
      classification: decision.classification.toSafeSummary(),
      vehicleOnlyDwell: decision.vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: false,
      protectedTrafficControl: true,
      canOpenReview: true,
    );

    expect(decision.protectedTrafficControl, isTrue);
    expect(
      forged.status,
      TripStopFalsePositiveGuardStatus.blockedTrafficControlReview,
    );
    expect(forged.canAllowReviewOpen, isFalse);
  });

  test('rideshare vehicle-only dwell cannot become automatic stop review', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      observation: _observation(
        observedAt: observedAt,
        walkingEvidenceCount: 0,
        walkingEvidenceSpan: Duration.zero,
        stationaryDuration: const Duration(minutes: 9),
      ),
    );
    final forged = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      status: decision.status.name,
      classification: decision.classification.toSafeSummary(),
      vehicleOnlyDwell: decision.vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: false,
      protectedTrafficControl: false,
      canOpenReview: true,
    );

    expect(decision.reasonCode, 'vehicle_only_dwell_manual_fallback');
    expect(
      forged
          .toSafeDashboardMap()['rideshareVehicleOnlyStopRequiresManualFallback'],
      isTrue,
    );
    expect(
      forged.status,
      TripStopFalsePositiveGuardStatus.blockedVehicleOnlyAutoReview,
    );
  });

  test('guard rejects remote authority, tokens, and precise coordinates', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      observation: _observation(
        observedAt: observedAt,
        latestWalkingEvidenceAt: observedAt.subtract(
          const Duration(seconds: 35),
        ),
      ),
    );
    final base = decision.classification.toSafeSummary();

    final remote = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      status: decision.status.name,
      classification: {...base, 'firestoreCanCreateOfficialStop': true},
      vehicleOnlyDwell: decision.vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: true,
      protectedTrafficControl: false,
      canOpenReview: true,
    );
    final sensitive = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.contractorVehicle,
      status: decision.status.name,
      classification: {
        ...base,
        'supportNote': '35.123456,-80.123456',
        'tokenEcho': 'sk.redacted',
      },
      vehicleOnlyDwell: decision.vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: true,
      protectedTrafficControl: false,
      canOpenReview: true,
    );

    expect(
      remote.status,
      TripStopFalsePositiveGuardStatus.blockedRemoteAuthority,
    );
    expect(
      sensitive.status,
      TripStopFalsePositiveGuardStatus.blockedSensitivePayload,
    );
    expect(sensitive.toSafeDashboardMap().toString(), isNot(contains('35.')));
    expect(sensitive.toSafeDashboardMap().toString(), isNot(contains('sk.')));
  });

  test('guard pass does not authorize review when debounce kept it closed', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      observation: _observation(
        observedAt: observedAt,
        walkingEvidenceCount: 3,
        walkingEvidenceSpan: const Duration(seconds: 35),
        stationaryDuration: const Duration(seconds: 50),
      ),
    );
    final guard =
        decision.toSafeDashboardMap()['falsePositiveGuard']
            as Map<String, Object?>;

    expect(decision.canOpenReview, isFalse);
    expect(guard['status'], TripStopFalsePositiveGuardStatus.passed.name);
    expect(guard['canAllowReviewOpen'], isFalse);
  });

  test('guard treats missing trip authority fields as malformed', () {
    final decision = TripStopDebouncePolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      observation: _observation(observedAt: observedAt),
    );
    final malformed = TripStopFalsePositiveGuard.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      status: decision.status.name,
      classification: {
        ...decision.classification.toSafeSummary(),
        'localTripLogRequiredForReview': false,
        'stopRequiresAcceptedVehicleMovement': false,
      },
      vehicleOnlyDwell: decision.vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: true,
      protectedTrafficControl: false,
      canOpenReview: true,
    );

    expect(
      malformed.status,
      TripStopFalsePositiveGuardStatus.blockedMalformedSummary,
    );
    expect(malformed.canAllowReviewOpen, isFalse);
  });
}

TripStopDebounceObservation _observation({
  required DateTime observedAt,
  DateTime? latestWalkingEvidenceAt,
  Duration stationaryDuration = const Duration(seconds: 45),
  int walkingEvidenceCount = 4,
  Duration walkingEvidenceSpan = const Duration(seconds: 35),
  int rejectedDriftCount = 0,
}) {
  return TripStopDebounceObservation(
    motionState: TripMotionState.stopCandidate,
    stationaryDuration: stationaryDuration,
    walkingEvidenceCount: walkingEvidenceCount,
    walkingEvidenceSpan: walkingEvidenceSpan,
    rejectedDriftCount: rejectedDriftCount,
    rejectedUnsafeCount: 0,
    acceptedDistanceCount: 8,
    acceptedVehicleMovementObserved: true,
    speedMps: 0.1,
    horizontalAccuracyMeters: 12,
    latestWalkingEvidenceAt:
        latestWalkingEvidenceAt ??
        observedAt.subtract(const Duration(seconds: 30)),
    observedAt: observedAt,
  );
}
