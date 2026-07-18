import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_detection_readiness.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_summary_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  Map<String, Object?> safeReviewSummary() => TripStopClassifier.classify(
    profile: TripTrackingProfile.contractorVehicle,
    motionState: TripMotionState.stopped,
    needsWalkingReview: true,
    excludedWalkingCount: 5,
    rejectedDriftCount: 0,
    rejectedUnsafeCount: 0,
    acceptedDistanceCount: 6,
  ).toSafeSummary();

  test('safe stop summary declares all stop authority boundaries', () {
    final summary = safeReviewSummary();

    expect(summary['remoteDashboardCanOpenStopReview'], isFalse);
    expect(summary['importedStopSummaryCanOpenStopReview'], isFalse);
    expect(summary['localTripLogRequiredForReview'], isTrue);
    expect(summary['authenticatedUserStillNeedsAuthorization'], isTrue);
    expect(summary['fleetObserverCanCreateStop'], isFalse);
    expect(summary['mapboxDirectionsCanCreateStop'], isFalse);
    expect(summary['mapboxMatrixCanCreateStop'], isFalse);
    expect(summary['mapboxMapMatchingCanReplaceMileage'], isFalse);
    expect(summary['mapboxOptimizationCanReorderOfficialStops'], isFalse);
  });

  test('summary validation fails closed on remote review authority claims', () {
    final validation = TripStopSummaryValidation.fromSummary(
      safeReviewSummary()..addAll({
        'remoteDashboardCanOpenStopReview': true,
        'importedStopSummaryCanOpenStopReview': true,
        'localTripLogRequiredForReview': false,
        'authenticatedUserStillNeedsAuthorization': false,
        'fleetObserverCanCreateStop': true,
        'mapboxDirectionsCanCreateStop': true,
        'mapboxMatrixCanCreateStop': true,
        'mapboxMapMatchingCanReplaceMileage': true,
        'mapboxOptimizationCanReorderOfficialStops': true,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'remote_summary_can_open_stop_review',
        'local_trip_log_not_required_for_review',
        'authentication_treated_as_authorization',
        'fleet_observer_can_create_stop',
        'mapbox_can_control_stop_review',
      ]),
    );
  });

  test('readiness requires local owner or explicit shared trip access', () {
    final blocked = TripStopDetectionReadiness.fromSummary(
      safeReviewSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'employee-a',
        tripOwnerUserId: 'employee-b',
        source: TripStopReviewBoundarySource.localTripLog,
      ),
    );
    final shared = TripStopDetectionReadiness.fromSummary(
      safeReviewSummary(),
      activeTrip: true,
      localSessionAvailable: true,
      acceptedVehicleMovementObserved: true,
      authorization: TripStopReviewAuthorization.fromBoundary(
        currentUserId: 'manager-a',
        tripOwnerUserId: 'employee-b',
        source: TripStopReviewBoundarySource.localTripLog,
        explicitSharedTripAccess: true,
      ),
    );

    expect(
      blocked.status,
      TripStopDetectionReadinessStatus.unauthorizedBoundary,
    );
    expect(blocked.canOpenStopReview, isFalse);
    expect(blocked.reasons, contains('trip_owner_or_explicit_access_required'));
    expect(shared.status, TripStopDetectionReadinessStatus.readyForUserReview);
    expect(shared.canOpenStopReview, isTrue);
  });

  test('remote and fleet-observer boundaries cannot open stop review', () {
    for (final source in [
      TripStopReviewBoundarySource.firestoreMirror,
      TripStopReviewBoundarySource.cloudFunction,
      TripStopReviewBoundarySource.importedFile,
      TripStopReviewBoundarySource.mapbox,
      TripStopReviewBoundarySource.dashboardCache,
    ]) {
      final readiness = TripStopDetectionReadiness.fromSummary(
        safeReviewSummary(),
        activeTrip: true,
        localSessionAvailable: true,
        acceptedVehicleMovementObserved: true,
        authorization: TripStopReviewAuthorization.fromBoundary(
          currentUserId: 'driver-1',
          tripOwnerUserId: 'driver-1',
          source: source,
          fleetObserverMode: source == TripStopReviewBoundarySource.mapbox,
        ),
      );

      expect(
        readiness.status,
        TripStopDetectionReadinessStatus.unauthorizedBoundary,
      );
      expect(readiness.canOpenStopReview, isFalse);
      expect(readiness.reasons, contains('local_trip_log_boundary_required'));
    }
  });
}
