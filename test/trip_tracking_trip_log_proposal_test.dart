import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_trip_log_proposal.dart';

void main() {
  test(
    'completion proposes to TripLog without confirmation authority',
    () async {
      final at = DateTime.utc(2026, 7, 21, 14);
      final sink = _ProposalSink();
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 12000,
        ),
        tripLogProposalSink: sink,
        clockNow: () => at.add(const Duration(minutes: 10)),
      );
      addTearDown(controller.dispose);
      expect(
        await controller.start(
          tripId: 'trip_log_proposal',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'work_profile_1',
          startedAt: at,
        ),
        isTrue,
      );

      final review = await controller.finishForReview(
        finishedAt: at.add(const Duration(minutes: 10)),
      );
      expect(review, isNotNull);
      expect(
        review!.transitionAudits.last.toState,
        TripTrackingSessionLifecycleState.stopping,
      );
      expect(sink.proposals, hasLength(1));
      final proposal = sink.proposals.single;
      expect(proposal.vehicleId, 'vehicle_1');
      expect(proposal.profileId, 'work_profile_1');
      expect(proposal.beginningOdometer, 12000);
      expect(proposal.requiresTripLogConfirmation, isTrue);
      expect(proposal.canFinalizeTripLog, isFalse);
      expect(proposal.canConfirmMileage, isFalse);
      expect(proposal.reviewRevision, review.revision);
      expect(proposal.toMap()['schemaVersion'], 2);
      expect(proposal.toMap()['reviewRevision'], review.revision);
      expect(proposal.toMap()['coordinatesIncluded'], isFalse);
      expect(review.confirmedEndingOdometer, isNull);
      final saved = store.reviewForTrip('trip_log_proposal')!;
      expect(
        saved.tripLogProposalState,
        TripTrackingTripLogProposalState.submitted,
      );
      expect(saved.tripLogProposalAttemptCount, 1);
    },
  );

  test('failed TripLog proposal remains locally retryable', () async {
    final at = DateTime.utc(2026, 7, 21, 15);
    final sink = _ProposalSink()..fail = true;
    final store = TripTrackingSessionStore.memory();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 13000,
      ),
      tripLogProposalSink: sink,
      clockNow: () => at.add(const Duration(minutes: 5)),
    );
    addTearDown(controller.dispose);
    await controller.start(
      tripId: 'trip_log_retry',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: at,
    );

    expect(
      await controller.finishForReview(
        finishedAt: at.add(const Duration(minutes: 5)),
      ),
      isNotNull,
    );
    expect(store.reviewForTrip('trip_log_retry'), isNotNull);
    expect(controller.tripLogProposalError, isNotNull);
    expect(
      store.reviewForTrip('trip_log_retry')!.tripLogProposalState,
      TripTrackingTripLogProposalState.pending,
    );
    expect(
      store.reviewForTrip('trip_log_retry')!.tripLogProposalAttemptCount,
      1,
    );

    sink.fail = false;
    expect(await controller.retryTripLogProposal('trip_log_retry'), isTrue);
    expect(controller.tripLogProposalError, isNull);
    expect(sink.proposals, hasLength(1));
    expect(
      sink.proposals.single.reviewRevision,
      store.reviewForTrip('trip_log_retry')!.revision - 1,
    );
    expect(
      store.reviewForTrip('trip_log_retry')!.tripLogProposalState,
      TripTrackingTripLogProposalState.submitted,
    );
    expect(
      store.reviewForTrip('trip_log_retry')!.tripLogProposalAttemptCount,
      2,
    );
  });

  test(
    'TripLog retry cannot overwrite a concurrent completion draft',
    () async {
      final at = DateTime.utc(2026, 7, 21, 16);
      final sink = _ProposalSink()..fail = true;
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 14000,
        ),
        tripLogProposalSink: sink,
        clockNow: () => at.add(const Duration(minutes: 5)),
      );
      addTearDown(controller.dispose);
      await controller.start(
        tripId: 'trip_log_retry_draft_race',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      );
      await controller.finishForReview(
        finishedAt: at.add(const Duration(minutes: 5)),
      );

      sink
        ..fail = false
        ..proposalStarted = Completer<void>()
        ..allowProposal = Completer<void>();
      final retry = controller.retryTripLogProposal(
        'trip_log_retry_draft_race',
      );
      await sink.proposalStarted!.future;

      expect(
        await controller.saveCompletionDraft(
          tripId: 'trip_log_retry_draft_race',
          endingOdometerDraft: 14010,
        ),
        isFalse,
      );
      expect(controller.platformStatus, 'session_operation_in_progress');

      sink.allowProposal!.complete();
      expect(await retry, isTrue);
      expect(
        await controller.saveCompletionDraft(
          tripId: 'trip_log_retry_draft_race',
          endingOdometerDraft: 14010,
        ),
        isTrue,
      );
      final saved = store.reviewForTrip('trip_log_retry_draft_race')!;
      expect(
        saved.tripLogProposalState,
        TripTrackingTripLogProposalState.submitted,
      );
      expect(saved.endingOdometerDraft, 14010);
    },
  );
}

class _ProposalSink implements TripTrackingTripLogProposalSink {
  bool fail = false;
  Completer<void>? proposalStarted;
  Completer<void>? allowProposal;
  final proposals = <TripTrackingTripLogProposal>[];

  @override
  Future<void> propose(TripTrackingTripLogProposal proposal) async {
    if (fail) throw StateError('proposal unavailable');
    proposalStarted?.complete();
    if (allowProposal != null) await allowProposal!.future;
    proposals.add(proposal);
  }
}
