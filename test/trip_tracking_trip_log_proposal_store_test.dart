import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_trip_log_proposal.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_trip_log_proposal_store.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('trip-log-inbox-');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'durably de-duplicates proposals and preserves the newest revision',
    () async {
      final store = await TripTrackingTripLogProposalStore.create();
      final first = _proposal(revision: 2);
      final older = _proposal(revision: 1);
      final newer = _proposal(revision: 3);

      await Future.wait([store.propose(first), store.propose(older)]);
      expect(store.proposals, hasLength(1));
      expect(store.proposalForId('trip_1')!.reviewRevision, 2);

      await store.propose(newer);
      expect(store.proposalForId('trip_1')!.reviewRevision, 3);

      await Hive.close();
      Hive.init(directory.path);
      final restored = await TripTrackingTripLogProposalStore.create();
      expect(restored.proposals, hasLength(1));
      expect(restored.proposals.single.reviewRevision, 3);
      expect(restored.proposals.single.canConfirmMileage, isFalse);
      expect(restored.proposals.single.toMap()['coordinatesIncluded'], isFalse);
    },
  );

  test(
    'isolates malformed records and preserves confirmed review authority',
    () async {
      final store = await TripTrackingTripLogProposalStore.create();
      final box = Hive.box<dynamic>(TripTrackingTripLogProposalStore.boxName);
      await box.put('broken', {'schemaVersion': 99, 'review': 'invalid'});

      expect(store.proposals, isEmpty);
      final confirmed = _proposal(revision: 2, confirmedEndingOdometer: 1010);
      await store.propose(confirmed);
      expect(store.proposals.single.review.isOdometerConfirmed, isTrue);
      expect(store.proposals.single.canConfirmMileage, isFalse);
      expect(store.proposals.single.canFinalizeTripLog, isFalse);
    },
  );

  test('unavailable storage keeps the controller retry path honest', () async {
    final store = TripTrackingTripLogProposalStore.unavailable();
    await expectLater(store.propose(_proposal(revision: 1)), throwsStateError);
  });
}

TripTrackingTripLogProposal _proposal({
  required int revision,
  int? confirmedEndingOdometer,
}) {
  final startedAt = DateTime.utc(2026, 7, 24, 12);
  return TripTrackingTripLogProposal.fromReview(
    TripTrackingReviewRecord(
      id: 'trip_1',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      profileId: 'profile_1',
      startedAt: startedAt,
      finishedAt: startedAt.add(const Duration(minutes: 10)),
      startingOdometer: 1000,
      estimatedEndingOdometer: 1000,
      confirmedEndingOdometer: confirmedEndingOdometer,
      odometerConfirmedAt: confirmedEndingOdometer == null
          ? null
          : startedAt.add(const Duration(minutes: 11)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
      revision: revision,
    ),
  );
}
