import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_detection_readiness.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  Map<String, Object?> reviewOnlyStopSummary() => TripStopClassifier.classify(
    profile: TripTrackingProfile.deliveryVehicle,
    motionState: TripMotionState.stopped,
    needsWalkingReview: true,
    excludedWalkingCount: 4,
    rejectedDriftCount: 0,
    rejectedUnsafeCount: 0,
    acceptedDistanceCount: 5,
  ).toSafeSummary();

  test(
    'delivery walking stop is ready only with active local trip evidence',
    () {
      final readiness = TripStopDetectionReadiness.fromSummary(
        reviewOnlyStopSummary(),
        activeTrip: true,
        localSessionAvailable: true,
        acceptedVehicleMovementObserved: true,
      );
      final safe = readiness.toSafeDashboardMap();

      expect(
        readiness.status,
        TripStopDetectionReadinessStatus.readyForUserReview,
      );
      expect(readiness.canOpenStopReview, isTrue);
      expect(readiness.actionToken, 'review_delivery_stop');
      expect(safe['dashboardMaySuggestStop'], isTrue);
      expect(safe['officialStopCreated'], isFalse);
      expect(safe['officialMileageSource'], 'odometer');
      expect(safe['mapboxCanOpenStopReview'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
    },
  );

  test('ready stop summary cannot open review without active trip', () {
    final readiness = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: false,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
    );

    expect(readiness.status, TripStopDetectionReadinessStatus.keepTracking);
    expect(readiness.canOpenStopReview, isFalse);
    expect(readiness.reasonCode, 'no_active_trip_for_stop_review');
    expect(readiness.toSafeDashboardMap()['requiresActiveTrip'], isTrue);
  });

  test('ready stop summary fails closed without local session', () {
    final readiness = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: false,
      acceptedVehicleMovementObserved: true,
    );

    expect(readiness.status, TripStopDetectionReadinessStatus.unsafeBoundary);
    expect(readiness.canOpenStopReview, isFalse);
    expect(readiness.reasonCode, 'local_session_required_for_stop_review');
    expect(readiness.reasons, contains('local_trip_log_required'));
  });

  test('walking stop waits when no accepted vehicle movement exists', () {
    final readiness = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: false,
    );

    expect(
      readiness.status,
      TripStopDetectionReadinessStatus.waitForMoreEvidence,
    );
    expect(readiness.actionToken, 'continue_monitoring');
    expect(readiness.reasonCode, 'vehicle_movement_required_for_stop_review');
    expect(readiness.canOpenStopReview, isFalse);
  });

  test('traffic-control summaries keep tracking and do not open review', () {
    final traffic = TripStopClassifier.classify(
      profile: TripTrackingProfile.deliveryVehicle,
      motionState: TripMotionState.moving,
      needsWalkingReview: false,
      excludedWalkingCount: 0,
      rejectedDriftCount: 8,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 5,
    ).toSafeSummary();
    final readiness = TripStopDetectionReadiness.fromSummary(
      traffic,
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
    );

    expect(readiness.status, TripStopDetectionReadinessStatus.keepTracking);
    expect(readiness.actionToken, 'keep_tracking');
    expect(readiness.canOpenStopReview, isFalse);
  });

  test('vehicle-only stop candidate may surface manual fallback only', () {
    final candidate = TripStopClassifier.classify(
      profile: TripTrackingProfile.rideshareVehicle,
      motionState: TripMotionState.stopCandidate,
      needsWalkingReview: false,
      excludedWalkingCount: 0,
      rejectedDriftCount: 0,
      rejectedUnsafeCount: 0,
      acceptedDistanceCount: 5,
    ).toSafeSummary();
    final readiness = TripStopDetectionReadiness.fromSummary(
      candidate,
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
    );
    final safe = readiness.toSafeDashboardMap();

    expect(
      readiness.status,
      TripStopDetectionReadinessStatus.waitForMoreEvidence,
    );
    expect(readiness.canOpenStopReview, isFalse);
    expect(readiness.reasons, contains('manual_stop_fallback_available'));
    expect(safe['dashboardMaySuggestStop'], isFalse);
    expect(safe['dashboardMaySuggestManualFallback'], isTrue);
    expect(safe['manualFallbackCanCreateOfficialStop'], isFalse);
    expect(safe['manualFallbackRequiresUserAction'], isTrue);
  });

  test('forged mapbox or firestore stop readiness is blocked', () {
    final forged = reviewOnlyStopSummary()
      ..addAll({
        'firestoreCanCreateOfficialStop': true,
        'mapboxCanCreateStop': true,
        'mapboxCanEndTrip': true,
        'coordinatesIncluded': true,
      });
    final readiness = TripStopDetectionReadiness.fromSummary(
      forged,
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
    );
    final safe = readiness.toSafeDashboardMap();

    expect(readiness.status, TripStopDetectionReadinessStatus.unsafeBoundary);
    expect(readiness.canOpenStopReview, isFalse);
    expect(readiness.reasons, contains('firestore_can_create_stop'));
    expect(readiness.reasons, contains('mapbox_can_control_stop_review'));
    expect(
      readiness.reasons,
      contains('summary_contains_sensitive_route_material'),
    );
    expect(safe['firestoreCanOpenStopReview'], isFalse);
    expect(safe['mapboxCanOpenStopReview'], isFalse);
  });
}
