/// Regression coverage for the local GPS App Assistant candidate inbox.
///
/// Verifies idempotent, coordinate-free, review-only candidate persistence.
/// Does not test GPS collection, active sessions, odometer confirmation, or UI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final startedAt = DateTime.utc(2026, 8, 4, 12);

  TripAutomaticEvidenceCandidate candidate({int acceptedFreeUses = 0}) {
    final decision = const TripAutomaticStartDetector().evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.free,
      hasActiveOrRecoverableSession: false,
      acceptedFreeUsesInPeriod: acceptedFreeUses,
      evaluatedAt: startedAt.add(const Duration(seconds: 30)),
      observations: List.generate(
        3,
        (index) => TripAutomaticStartObservation(
          recordedAt: startedAt.add(Duration(seconds: index * 15)),
          speedMetersPerSecond: 8,
          displacementMeters: 30,
          horizontalAccuracyMeters: 8,
          activity: TripActivity.automotive,
          activityConfidence: 90,
          bluetoothVehicleId: 'vehicle_1',
        ),
      ),
    );
    return TripAutomaticEvidenceCandidate.fromDecision(
      decision: decision,
      detectedAt: startedAt.add(const Duration(seconds: 31)),
    );
  }

  test(
    'proposal persists once without coordinates or confirmed-record authority',
    () async {
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final proposed = candidate();

      await store.propose(proposed);
      await store.propose(proposed);

      expect(store.candidates, hasLength(1));
      final saved = store.reviewNeeded.single;
      expect(saved.id, proposed.id);
      expect(saved.canCreateConfirmedRecord, isFalse);
      expect(saved.canConfirmMileage, isFalse);
      expect(saved.canAssignBusinessPurpose, isFalse);
      expect(saved.canClassifyMileage, isFalse);
      expect(saved.toMap()['coordinatesIncluded'], isFalse);
      expect(saved.toMap().containsKey('latitude'), isFalse);
      expect(saved.toMap().containsKey('longitude'), isFalse);
      expect(
        saved.auditHistory.single.action,
        TripAutomaticEvidenceCandidateAction.detected,
      );
    },
  );

  test(
    'approval opens only editable review and records one audit decision',
    () async {
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final proposed = candidate();
      await store.propose(proposed);

      final decided = await store.decide(
        candidateId: proposed.id,
        expectedRevision: proposed.revision,
        approved: true,
        decidedAt: startedAt.add(const Duration(minutes: 1)),
      );

      expect(
        decided.state,
        TripAutomaticEvidenceCandidateState.approvedForEditableReview,
      );
      expect(decided.requiresUserReview, isFalse);
      expect(decided.revision, 2);
      expect(decided.auditHistory.map((item) => item.action), [
        TripAutomaticEvidenceCandidateAction.detected,
        TripAutomaticEvidenceCandidateAction.approved,
      ]);
      expect(decided.expectedResultIfApproved, contains('No odometer'));
      expect(store.reviewNeeded, isEmpty);
    },
  );

  test(
    'stale or repeated decision is rejected without overwriting the first decision',
    () async {
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final proposed = candidate();
      await store.propose(proposed);
      await store.decide(
        candidateId: proposed.id,
        expectedRevision: proposed.revision,
        approved: false,
        decidedAt: startedAt.add(const Duration(minutes: 1)),
      );

      await expectLater(
        store.decide(
          candidateId: proposed.id,
          expectedRevision: proposed.revision,
          approved: true,
          decidedAt: startedAt.add(const Duration(minutes: 2)),
        ),
        throwsStateError,
      );
      expect(
        store.candidateForId(proposed.id)?.state,
        TripAutomaticEvidenceCandidateState.rejected,
      );
    },
  );

  test(
    'exhausted free allowance does not hide a candidate before user review',
    () async {
      final store = TripAutomaticEvidenceCandidateStore.memory();
      final proposed = candidate(acceptedFreeUses: 4);

      await store.propose(proposed);

      expect(
        store.reviewNeeded.single.requiresPaidEntitlementOnAcceptance,
        isTrue,
      );
      expect(store.reviewNeeded.single.requiresUserReview, isTrue);
    },
  );
}
