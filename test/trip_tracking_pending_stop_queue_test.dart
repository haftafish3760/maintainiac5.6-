import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'every pending stop remains reviewable after the newest is reviewed',
    () async {
      final startedAt = DateTime.utc(2026, 7, 22, 12);
      TripTrackingAdvisoryEvent stop(String id, int minutes) =>
          TripTrackingAdvisoryEvent(
            id: id,
            type: TripTrackingAdvisoryType.probableStop,
            sessionId: 'multi_stop_queue',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.deliveryVehicle,
            detectedAt: startedAt.add(Duration(minutes: minutes)),
            evidenceStartedAt: startedAt.add(Duration(minutes: minutes - 1)),
            evidenceEndedAt: startedAt.add(Duration(minutes: minutes)),
            confidence: TripTrackingConfidence.high,
            suggestedAction: 'reviewStop',
          );
      final store = TripTrackingSessionStore.memory();
      await store.save(
        TripTrackingSessionRecord(
          id: 'multi_stop_queue',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.deliveryVehicle,
          profileId: 'profile_1',
          startedAt: startedAt,
          updatedAt: startedAt.add(const Duration(minutes: 20)),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 2500,
            walkingReviewSuggested: false,
          ),
          advisories: [stop('stop_1', 5), stop('stop_2', 15)],
        ),
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      expect(await controller.restore(), isTrue);
      expect(controller.pendingStopReviewCount, 2);
      expect(controller.needsWalkingReview, isTrue);
      expect(
        controller.latestPendingStopBoundaryCandidate?.sourceAdvisoryId,
        'stop_2',
      );

      await controller.reviewLatestStopAdvisory(
        TripTrackingAdvisoryDisposition.confirmed,
      );
      expect(controller.pendingStopReviewCount, 1);
      expect(controller.needsWalkingReview, isTrue);
      expect(
        controller.advisories
            .singleWhere((event) => event.id == 'stop_2')
            .disposition,
        TripTrackingAdvisoryDisposition.confirmed,
      );
      expect(
        controller.latestPendingStopBoundaryCandidate?.sourceAdvisoryId,
        'stop_1',
      );

      await controller.reviewLatestStopAdvisory(
        TripTrackingAdvisoryDisposition.dismissed,
      );
      expect(controller.pendingStopReviewCount, 0);
      expect(controller.needsWalkingReview, isFalse);
      expect(controller.latestPendingStopBoundaryCandidate, isNull);
      expect(
        controller.advisories
            .singleWhere((event) => event.id == 'stop_1')
            .disposition,
        TripTrackingAdvisoryDisposition.dismissed,
      );

      final recoveredOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: odometer.confirmedReading,
      );
      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: recoveredOdometer,
      );
      addTearDown(recovered.dispose);
      addTearDown(recoveredOdometer.dispose);
      expect(await recovered.restore(), isTrue);
      expect(recovered.pendingStopReviewCount, 0);
      expect(
        recovered.advisories.map((event) => event.disposition),
        containsAll([
          TripTrackingAdvisoryDisposition.dismissed,
          TripTrackingAdvisoryDisposition.confirmed,
        ]),
      );
    },
  );
}
