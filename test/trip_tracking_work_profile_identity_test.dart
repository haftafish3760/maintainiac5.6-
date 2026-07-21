import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'work profile identity survives session transitions and review',
    () async {
      var now = DateTime.utc(2026, 7, 21, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        clockNow: () => now,
      );

      expect(
        await controller.start(
          tripId: 'profile_identity_trip',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.contractorVehicle,
          profileId: 'electrical_job_profile',
          startedAt: now,
        ),
        isTrue,
      );
      expect(
        controller.activeSession!.effectiveProfileId,
        'electrical_job_profile',
      );
      expect(
        await controller.tryTransitionForTest(
          TripTrackingSessionLifecycleState.starting,
          reasonCode: 'test_starting',
        ),
        isTrue,
      );
      expect(
        controller.transitionAudits.single.profileId,
        'electrical_job_profile',
      );
      expect(
        await controller.tryTransitionForTest(
          TripTrackingSessionLifecycleState.active,
          reasonCode: 'test_active',
        ),
        isTrue,
      );

      now = now.add(const Duration(hours: 1));
      final review = await controller.finishForReview(finishedAt: now);
      expect(review?.effectiveProfileId, 'electrical_job_profile');
      expect(
        TripTrackingReviewRecord.fromMap(review!.toMap()).effectiveProfileId,
        'electrical_job_profile',
      );
    },
  );
}
