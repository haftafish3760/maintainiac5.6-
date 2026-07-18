import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_profile_strategy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_walking_evidence_recency_guard.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 18, 15);

  TripWalkingEvidenceRecencyDecision evaluate({
    TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
    int walkingEvidenceCount = 4,
    Duration walkingEvidenceSpan = const Duration(seconds: 32),
    DateTime? latestWalkingEvidenceAt,
    DateTime? observed,
  }) {
    return TripWalkingEvidenceRecencyGuard.evaluate(
      strategy: TripTrackingProfileStrategy.forProfile(profile),
      walkingEvidenceCount: walkingEvidenceCount,
      walkingEvidenceSpan: walkingEvidenceSpan,
      observedAt: observed ?? observedAt,
      latestWalkingEvidenceAt:
          latestWalkingEvidenceAt ??
          observedAt.subtract(const Duration(seconds: 15)),
    );
  }

  test('current walking evidence remains usable but never authoritative', () {
    final decision = evaluate();
    final safe = decision.toSafeDashboardMap();

    expect(decision.usable, isTrue);
    expect(decision.walkingEvidenceCount, 4);
    expect(decision.reasonCode, 'walking_evidence_current');
    expect(safe['activityRecognitionCanCreateOfficialStop'], isFalse);
    expect(safe['firestoreCanRefreshWalkingEvidence'], isFalse);
    expect(safe['cloudFunctionCanRefreshWalkingEvidence'], isFalse);
    expect(safe['rawSensorPayloadIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('future walking evidence is rejected fail closed', () {
    final decision = evaluate(
      latestWalkingEvidenceAt: observedAt.add(const Duration(seconds: 1)),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.rejected, isTrue);
    expect(decision.walkingEvidenceCount, 0);
    expect(decision.reasonCode, 'future_walking_evidence_rejected');
    expect(safe['futureEvidenceRejected'], isTrue);
  });

  test('stale walking evidence cannot be replayed into a stop', () {
    final decision = evaluate(
      latestWalkingEvidenceAt: observedAt.subtract(const Duration(minutes: 9)),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.rejected, isTrue);
    expect(decision.walkingEvidenceSpan, Duration.zero);
    expect(decision.reasonCode, 'stale_walking_evidence_rejected');
    expect(safe['staleEvidenceRejected'], isTrue);
    expect(safe['latestEvidenceAgeSeconds'], 540);
  });

  test('rideshare gets the same stale-evidence guard', () {
    final decision = evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      latestWalkingEvidenceAt: observedAt.subtract(const Duration(minutes: 9)),
    );

    expect(decision.rejected, isTrue);
    expect(decision.reasonCode, 'stale_walking_evidence_rejected');
    expect(decision.maximumEvidenceAge, const Duration(seconds: 135));
  });

  test('undated walking evidence is rejected instead of guessed current', () {
    final decision = TripWalkingEvidenceRecencyGuard.evaluate(
      strategy: TripTrackingProfileStrategy.forProfile(
        TripTrackingProfile.contractorVehicle,
      ),
      walkingEvidenceCount: 3,
      walkingEvidenceSpan: const Duration(seconds: 35),
      observedAt: observedAt,
      latestWalkingEvidenceAt: null,
    );

    expect(decision.rejected, isTrue);
    expect(decision.reasonCode, 'undated_walking_evidence_rejected');
    expect(decision.walkingEvidenceCount, 0);
  });
}
