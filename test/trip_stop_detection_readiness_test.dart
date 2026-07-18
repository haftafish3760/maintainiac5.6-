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
      expect(safe['odometerIsGlobalTruth'], isTrue);
      expect(safe['readinessCanCreateCalibration'], isFalse);
      expect(safe['readinessCanApplyCalibration'], isFalse);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['validatedStopSummaryRequired'], isTrue);
      expect(safe['localTripLogMustOwnStopReview'], isTrue);
      expect(safe['requiresOwnershipOrExplicitAccess'], isTrue);
      expect(safe['requiresFreshLocalStopSummary'], isTrue);
      expect(safe['stopReviewCanEditOdometer'], isFalse);
      expect(safe['mapboxCanOpenStopReview'], isFalse);
      expect(safe['routeGeometryIncluded'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      final validation =
          TripStopDetectionReadinessSummaryValidation.fromSummary(safe);
      expect(validation.isRenderable, isTrue);
      expect(validation.canOpenStopReview, isTrue);
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
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary(
        readiness.toSafeDashboardMap(),
      ).canOpenStopReview,
      isFalse,
    );
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
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary(
        readiness.toSafeDashboardMap(),
      ).isRenderable,
      isTrue,
    );
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
    expect(
      readiness.toSafeDashboardMap()['requiresAcceptedVehicleMovement'],
      isTrue,
    );
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
    expect(safe['readinessCanCreateCalibration'], isFalse);
    expect(safe['readinessCanApplyCalibration'], isFalse);
    expect(safe['manualFallbackRequiresUserAction'], isTrue);
    expect(safe['requiresReviewBeforeCommit'], isTrue);
    expect(safe['stopReviewCanBackdateWithoutReview'], isFalse);
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
    expect(safe['malformedStopSummaryFailsClosed'], isTrue);
    expect(safe['authenticationDoesNotGrantStopAuthority'], isTrue);
  });

  test('firestore mirror cannot open stop review even for same user', () {
    final readiness = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'driver-1',
        tripOwnerUserId: 'driver-1',
        source: TripStopReviewBoundarySource.firestoreMirror,
      ),
    );
    final safe = readiness.toSafeDashboardMap();

    expect(
      readiness.status,
      TripStopDetectionReadinessStatus.unauthorizedBoundary,
    );
    expect(readiness.canOpenStopReview, isFalse);
    expect(readiness.reasons, contains('local_trip_log_boundary_required'));
    expect(safe['firestoreCanOpenStopReview'], isFalse);
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('shared access still requires local trip-log source', () {
    final localShared = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'dispatcher-1',
        tripOwnerUserId: 'driver-1',
        source: TripStopReviewBoundarySource.localTripLog,
        explicitSharedTripAccess: true,
      ),
    );
    final mapboxShared = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'dispatcher-1',
        tripOwnerUserId: 'driver-1',
        source: TripStopReviewBoundarySource.mapbox,
        explicitSharedTripAccess: true,
      ),
    );

    expect(
      localShared.status,
      TripStopDetectionReadinessStatus.readyForUserReview,
    );
    expect(mapboxShared.canOpenStopReview, isFalse);
    expect(mapboxShared.reasons, contains('local_trip_log_boundary_required'));
  });

  test('fleet observer and malformed user ids fail closed', () {
    final observer = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'manager-1',
        tripOwnerUserId: 'driver-1',
        source: TripStopReviewBoundarySource.localTripLog,
        explicitSharedTripAccess: true,
        fleetObserverMode: true,
      ),
    );
    final badUser = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'pk.public-token',
        tripOwnerUserId: 'driver-1',
        source: TripStopReviewBoundarySource.localTripLog,
      ),
    );

    expect(
      observer.status,
      TripStopDetectionReadinessStatus.unauthorizedBoundary,
    );
    expect(observer.reasons, contains('fleet_observer_read_only'));
    expect(badUser.canOpenStopReview, isFalse);
    expect(badUser.reasons, contains('current_user_required'));
  });

  test('readiness summary validation rejects forged authority or secrets', () {
    final safe = TripStopDetectionReadiness.fromSummary(
      reviewOnlyStopSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
    ).toSafeDashboardMap();

    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary({
        ...safe,
        'mapboxCanOpenStopReview': true,
      }).isRenderable,
      isFalse,
    );
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary({
        ...safe,
        'stopReviewCanEditOdometer': true,
      }).isRenderable,
      isFalse,
    );
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary({
        ...safe,
        'odometerIsGlobalTruth': false,
        'readinessCanCreateCalibration': true,
        'readinessCanApplyCalibration': true,
        'calibrationRequiresTrustedGpsWindow': false,
        'poorGpsDaysExcludedFromCalibration': false,
      }).isRenderable,
      isFalse,
    );
    expect(
      TripStopDetectionReadinessSummaryValidation.fromSummary({
        ...safe,
        'supportNote': '35.123456,-80.123456 token=sk.secret',
      }).isRenderable,
      isFalse,
    );
  });
}
