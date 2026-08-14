/// Regression coverage for the local GPS App Assistant candidate inbox.
///
/// Verifies idempotent, coordinate-free, review-only candidate persistence.
/// Does not test GPS collection, active sessions, odometer confirmation, or UI.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_candidate_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final startedAt = DateTime.utc(2026, 8, 4, 12);
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'trip-automatic-evidence-inbox-',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  TripAutomaticEvidenceCandidate candidate({
    int acceptedFreeUses = 0,
    int offsetMinutes = 0,
  }) {
    final candidateStartedAt = startedAt.add(Duration(minutes: offsetMinutes));
    final decision = const TripAutomaticStartDetector().evaluate(
      enabled: true,
      accessLevel: TripAutomaticStartAccessLevel.free,
      hasActiveOrRecoverableSession: false,
      acceptedFreeUsesInPeriod: acceptedFreeUses,
      evaluatedAt: candidateStartedAt.add(const Duration(seconds: 30)),
      observations: List.generate(
        3,
        (index) => TripAutomaticStartObservation(
          recordedAt: candidateStartedAt.add(Duration(seconds: index * 15)),
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
      detectedAt: candidateStartedAt.add(const Duration(seconds: 31)),
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

  test(
    'durably restores a review-only candidate after local restart',
    () async {
      final store = await TripAutomaticEvidenceCandidateStore.create();
      final proposed = candidate();
      await store.propose(proposed);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await TripAutomaticEvidenceCandidateStore.create();

      expect(restored.reviewNeeded, hasLength(1));
      final saved = restored.reviewNeeded.single;
      expect(saved.id, proposed.id);
      expect(saved.canCreateConfirmedRecord, isFalse);
      expect(saved.canConfirmMileage, isFalse);
      expect(saved.canAssignBusinessPurpose, isFalse);
      expect(saved.toMap()['coordinatesIncluded'], isFalse);
    },
  );

  test('isolates malformed local data without hiding a valid review', () async {
    final store = await TripAutomaticEvidenceCandidateStore.create();
    final proposed = candidate();
    await store.propose(proposed);
    final box = Hive.box<dynamic>(TripAutomaticEvidenceCandidateStore.boxName);
    await box.put('malformed', {'schemaVersion': 999, 'candidate': 'invalid'});

    expect(store.reviewNeeded, hasLength(1));
    expect(store.reviewNeeded.single.id, proposed.id);
    expect(store.reviewNeeded.single.requiresUserReview, isTrue);
  });

  test('rejects an unknown audit action instead of rewriting history', () {
    final serialized = candidate().toMap();
    final audits = (serialized['auditHistory'] as List).cast<Map>();
    audits.first['action'] = 'unexpected_action';

    expect(TripAutomaticEvidenceCandidate.fromMap(serialized), isNull);
  });

  test('durably enforces the free monthly acceptance limit', () async {
    final store = TripAutomaticEvidenceCandidateStore.memory();
    for (var index = 0; index < 4; index += 1) {
      final proposed = candidate(offsetMinutes: index);
      await store.propose(proposed);
      await store.decide(
        candidateId: proposed.id,
        expectedRevision: proposed.revision,
        approved: true,
        decidedAt: proposed.detectedAtUtc.add(const Duration(seconds: 1)),
      );
    }
    final fifth = candidate(offsetMinutes: 5);
    await store.propose(fifth);

    await expectLater(
      store.decide(
        candidateId: fifth.id,
        expectedRevision: fifth.revision,
        approved: true,
        decidedAt: fifth.detectedAtUtc.add(const Duration(seconds: 1)),
      ),
      throwsStateError,
    );
    expect(store.acceptedFreeUsesAt(startedAt), 4);
    expect(store.candidateForId(fifth.id)?.requiresUserReview, isTrue);
  });

  test('retention expires pending evidence before later pruning it', () async {
    final store = TripAutomaticEvidenceCandidateStore.memory();
    final proposed = candidate();
    await store.propose(proposed);

    await store.maintainRetention(
      nowUtc: proposed.detectedAtUtc.add(const Duration(days: 91)),
    );
    expect(
      store.candidateForId(proposed.id)?.state,
      TripAutomaticEvidenceCandidateState.expired,
    );
    expect(
      store.candidateForId(proposed.id)?.auditHistory.last.action,
      TripAutomaticEvidenceCandidateAction.expired,
    );

    await store.maintainRetention(
      nowUtc: proposed.detectedAtUtc.add(const Duration(days: 457)),
    );
    expect(store.candidateForId(proposed.id), isNull);
  });
}
