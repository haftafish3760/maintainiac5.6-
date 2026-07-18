import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

import 'support/trip_tracking_qa/trip_tracking_scenarios.dart';
import 'support/trip_tracking_qa/trip_tracking_simulator.dart';

void main() {
  final scenarios = TripTrackingScenarioLibrary();

  test('delivery driver walking stop becomes review-only stop evidence', () {
    final result = replayTrip(
      scenarios.deliveryDriverLeavesVehicle(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.motionState, TripMotionState.moving);
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      )['stopReviewConfidence'],
      'high',
    );
    expect(
      result.count(TripSampleDisposition.excludedWalking),
      greaterThanOrEqualTo(4),
    );
    expect(result.acceptedMeters, greaterThan(250));
    expect(result.acceptedMeters, lessThan(450));
  });

  test('rideshare passenger stop without walking stays vehicle-only', () {
    final result = replayTrip(
      scenarios.rideshareDriverStaysInVehicle(),
      profile: TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.motionState, TripMotionState.moving);
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.rideshareVehicle,
      )['stopCanSuggestReview'],
      isFalse,
    );
    expect(result.count(TripSampleDisposition.excludedWalking), isZero);
    expect(
      result.count(TripSampleDisposition.rejectedDrift),
      greaterThanOrEqualTo(6),
    );
    expect(result.acceptedMeters, greaterThan(250));
    expect(result.acceptedMeters, lessThan(500));
  });

  test('rideshare stop requires stronger sustained walking evidence', () {
    final result = replayTrip(
      scenarios.rideshareDriverWalksAfterShiftStop(),
      profile: TripTrackingProfile.rideshareVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.motionState, TripMotionState.stopped);
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.rideshareVehicle,
      )['stopReviewConfidence'],
      'medium',
    );
    expect(
      result.count(TripSampleDisposition.excludedWalking),
      greaterThanOrEqualTo(2),
    );
    expect(result.acceptedMeters, greaterThan(150));
    expect(result.acceptedMeters, lessThan(300));
  });

  test('contractor jobsite walking is excluded before the next drive', () {
    final result = replayTrip(
      scenarios.contractorJobsiteWalkAround(),
      profile: TripTrackingProfile.contractorVehicle,
    );

    expect(result.needsWalkingReview, isTrue);
    expect(result.motionState, TripMotionState.moving);
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.contractorVehicle,
      )['stopReviewConfidence'],
      'high',
    );
    expect(
      result.count(TripSampleDisposition.excludedWalking),
      greaterThanOrEqualTo(4),
    );
    expect(
      result.count(TripSampleDisposition.acceptedDistance),
      greaterThanOrEqualTo(3),
    );
    expect(result.acceptedMeters, greaterThan(250));
    expect(result.acceptedMeters, lessThan(450));
  });

  test('long traffic light jitter never creates a false walking stop', () {
    final result = replayTrip(
      scenarios.longTrafficLightWithUrbanJitter(),
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.motionState, TripMotionState.moving);
    expect(
      result.toSafeDashboardSummary(
        profile: TripTrackingProfile.deliveryVehicle,
      )['stopReviewConfidence'],
      'low',
    );
    expect(result.count(TripSampleDisposition.excludedWalking), isZero);
    expect(
      result.count(TripSampleDisposition.rejectedDrift),
      greaterThanOrEqualTo(10),
    );
    expect(result.acceptedMeters, greaterThan(250));
    expect(result.acceptedMeters, lessThan(500));
  });

  test('hostile provider replay rejects invalid unsafe mileage sources', () {
    final result = replayTrip(scenarios.hostileProviderReplay());

    expect(result.acceptedMeters.isFinite, isTrue);
    expect(result.acceptedMeters, greaterThan(50));
    expect(result.acceptedMeters, lessThan(160));
    expect(result.count(TripSampleDisposition.rejectedAccuracy), 2);
    expect(result.count(TripSampleDisposition.rejectedOutOfOrder), 3);
    expect(result.count(TripSampleDisposition.rejectedGap), 1);
    expect(result.count(TripSampleDisposition.rejectedInvalid), 1);
    expect(result.count(TripSampleDisposition.rejectedMockLocation), 1);
  });

  test('high-confidence walking at vehicle speed remains vehicle mileage', () {
    final result = replayTrip(
      scenarios.walkingSensorMisclassifiedAtVehicleSpeed(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.count(TripSampleDisposition.excludedWalking), 0);
    expect(result.acceptedDistanceCount, greaterThanOrEqualTo(3));
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
  });

  test('implausible GPS jump and gap cannot masquerade as a stop', () {
    final result = replayTrip(
      scenarios.gpsJumpAndGapMasqueradingAsStop(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.rejectedUnsafeCount, greaterThanOrEqualTo(3));
    expect(summary['stopSignal'], 'unsafe_evidence');
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopRequiresUserReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
  });

  test('partner delivery with phone in vehicle stays manual vehicle-only', () {
    final result = replayTrip(
      scenarios.deliveryPartnerWalksWhilePhoneStaysInVehicle(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.count(TripSampleDisposition.excludedWalking), isZero);
    expect(result.count(TripSampleDisposition.rejectedDrift), greaterThan(6));
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['stopShouldSurfaceManualFallback'], isTrue);
    expect(summary['mapsRequiredForStopReview'], isFalse);
  });

  test('fast door drop waits for stronger walking evidence', () {
    final result = replayTrip(
      scenarios.fastDoorDropWithTooLittleWalkingEvidence(),
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final summary = result.toSafeDashboardSummary(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    expect(result.needsWalkingReview, isFalse);
    expect(result.count(TripSampleDisposition.excludedWalking), lessThan(3));
    expect(summary['stopCanSuggestReview'], isFalse);
    expect(summary['stopCanCreateOfficialStop'], isFalse);
    expect(summary['officialMileageSource'], 'odometer');
  });

  test(
    'contractor long jobsite walk remains review-only and odometer-safe',
    () {
      final result = replayTrip(
        scenarios.contractorLongJobsiteWalkThenDriveAway(),
        profile: TripTrackingProfile.contractorVehicle,
      );
      final summary = result.toSafeDashboardSummary(
        profile: TripTrackingProfile.contractorVehicle,
      );

      expect(result.needsWalkingReview, isTrue);
      expect(
        result.count(TripSampleDisposition.excludedWalking),
        greaterThan(3),
      );
      expect(summary['stopSignal'], 'review_only_stop');
      expect(summary['stopCanSuggestReview'], isTrue);
      expect(summary['stopRequiresUserReview'], isTrue);
      expect(summary['stopCanCreateOfficialStop'], isFalse);
      expect(summary['officialStopSource'], 'user_review');
      expect(summary['officialMileageSource'], 'odometer');
      expect(summary['mapsRequiredForStopReview'], isFalse);
    },
  );
}
