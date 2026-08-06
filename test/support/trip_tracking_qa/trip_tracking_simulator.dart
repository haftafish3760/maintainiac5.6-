import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_false_positive_guard.dart';

class SimulatedTripPoint {
  const SimulatedTripPoint(this.sample, {this.activity});

  final TripLocationSample sample;
  final TripActivityObservation? activity;
}

class SimulatedTripResult {
  const SimulatedTripResult({
    required this.acceptedMeters,
    required this.dispositions,
    required this.needsWalkingReview,
    required this.sawReviewableStopEvidence,
    required this.motionState,
  });

  final double acceptedMeters;
  final List<TripSampleDisposition> dispositions;
  final bool needsWalkingReview;
  final bool sawReviewableStopEvidence;
  final TripMotionState motionState;

  double get acceptedMiles => acceptedMeters / 1609.344;

  int get acceptedDistanceCount =>
      count(TripSampleDisposition.acceptedDistance);

  int get rejectedCount => dispositions
      .where(
        (value) =>
            value != TripSampleDisposition.acceptedAnchor &&
            value != TripSampleDisposition.acceptedDistance,
      )
      .length;

  int get excludedWalkingCount => count(TripSampleDisposition.excludedWalking);

  int get rejectedUnsafeCount =>
      count(TripSampleDisposition.rejectedInvalid) +
      count(TripSampleDisposition.rejectedMockLocation) +
      count(TripSampleDisposition.rejectedAccuracy) +
      count(TripSampleDisposition.rejectedOutOfOrder) +
      count(TripSampleDisposition.rejectedImplausibleSpeed) +
      count(TripSampleDisposition.rejectedSpeedConflict) +
      count(TripSampleDisposition.rejectedGap);

  int get rejectedGpsJumpCount =>
      count(TripSampleDisposition.rejectedImplausibleSpeed) +
      count(TripSampleDisposition.rejectedSpeedConflict);

  int count(TripSampleDisposition disposition) =>
      dispositions.where((value) => value == disposition).length;

  Map<String, Object?> toSafeSummary() => {
    'acceptedMiles': double.parse(acceptedMiles.toStringAsFixed(3)),
    'acceptedDistanceCount': acceptedDistanceCount,
    'excludedWalkingCount': excludedWalkingCount,
    'rejectedCount': rejectedCount,
    'rejectedUnsafeCount': rejectedUnsafeCount,
    'rejectedGpsJumpCount': rejectedGpsJumpCount,
    'needsWalkingReview': needsWalkingReview,
    'sawReviewableStopEvidence': sawReviewableStopEvidence,
    'motionState': motionState.name,
    'simulationCanCreateOfficialStop': false,
    'simulationCanReplaceOdometer': false,
    'officialMileageSource': 'odometer',
    'officialStopSource': 'user_review',
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
  };

  Map<String, Object?> toSafeDashboardSummary({
    required TripTrackingProfile profile,
  }) {
    final classification = TripStopClassifier.classify(
      profile: profile,
      motionState: motionState,
      needsWalkingReview: needsWalkingReview,
      excludedWalkingCount: count(TripSampleDisposition.excludedWalking),
      rejectedDriftCount: count(TripSampleDisposition.rejectedDrift),
      rejectedUnsafeCount: rejectedUnsafeCount,
      acceptedDistanceCount: acceptedDistanceCount,
    );
    final classificationSummary = classification.toSafeSummary();
    final stopCanOpenReview =
        classification.requiresUserReview && classification.canSuggestStop;
    final falsePositiveGuard = TripStopFalsePositiveGuard.evaluate(
      profile: profile,
      status: _dashboardDebounceStatus(classification.signal),
      classification: classificationSummary,
      vehicleOnlyDwell: null,
      needsWalkingReview: needsWalkingReview,
      protectedTrafficControl:
          classification.signal == TripStopSignal.likelyTrafficControl,
      canOpenReview: stopCanOpenReview,
    ).toSafeDashboardMap();
    return {
      ...toSafeSummary(),
      'profile': profile.name,
      'stopSignal': _dashboardStopSignal(classification.signal),
      'stopActionToken': classification.actionToken,
      'stopReviewConfidence': classification.reviewConfidence.name,
      'stopClassificationReason': classification.reasonCode,
      'stopClassification': classificationSummary,
      'stopRequiresUserReview': classification.requiresUserReview,
      'stopCanSuggestReview': classification.canSuggestStop,
      'stopShouldSurfaceManualFallback':
          classification.shouldSurfaceManualStopFallback,
      'stopCanCreateOfficialStop': false,
      'stopCanReplaceOdometer': false,
      'stopReviewConfidenceCanCreateOfficialStop': false,
      'stopReviewConfidenceCanReplaceOdometer': false,
      'stopReviewConfidenceCanEndTripAutomatically': false,
      'mapsRequiredForStopReview': false,
      'falsePositiveGuard': falsePositiveGuard,
    };
  }
}

String _dashboardStopSignal(TripStopSignal signal) {
  return switch (signal) {
    TripStopSignal.noStop => 'no_stop',
    TripStopSignal.stopCandidate => 'stop_candidate',
    TripStopSignal.reviewOnlyStop => 'review_only_stop',
    TripStopSignal.likelyTrafficControl => 'likely_traffic_control',
    TripStopSignal.equipmentIgnored => 'equipment_ignored',
    TripStopSignal.unsafeEvidence => 'unsafe_evidence',
  };
}

String _dashboardDebounceStatus(TripStopSignal signal) {
  return switch (signal) {
    TripStopSignal.reviewOnlyStop => 'readyForReview',
    TripStopSignal.likelyTrafficControl => 'trafficControlProtected',
    TripStopSignal.unsafeEvidence => 'unsafeEvidence',
    TripStopSignal.stopCandidate => 'waitingForEvidence',
    TripStopSignal.equipmentIgnored => 'waitingForEvidence',
    TripStopSignal.noStop => 'keepTracking',
  };
}

/// Deterministic replay harness for GPS QA. Scenario tests use this instead of
/// duplicating ingest loops, so each newly discovered field trace can become a
/// durable regression fixture.
SimulatedTripResult replayTrip(
  Iterable<SimulatedTripPoint> points, {
  TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
  TripTrackingPolicy policy = const TripTrackingPolicy(),
}) {
  final engine = TripTrackingEngine(profile: profile, policy: policy);
  final dispositions = <TripSampleDisposition>[];
  var sawReviewableStopEvidence = false;
  for (final point in points) {
    dispositions.add(
      engine.ingest(point.sample, activity: point.activity).disposition,
    );
    sawReviewableStopEvidence |=
        engine.needsWalkingReview ||
        engine.motionState == TripMotionState.stopCandidate ||
        engine.motionState == TripMotionState.stopped;
  }
  return SimulatedTripResult(
    acceptedMeters: engine.totalAcceptedMeters,
    dispositions: List.unmodifiable(dispositions),
    needsWalkingReview: engine.needsWalkingReview,
    sawReviewableStopEvidence: sawReviewableStopEvidence,
    motionState: engine.motionState,
  );
}

/// Replays independently delivered native location and activity callbacks.
///
/// Owns deterministic callback ordering for field-trace regressions. It does
/// not create TripLog records, approve a stop, or replace odometer truth.
SimulatedTripResult replayNativeEvidence(
  Iterable<SimulatedTripPoint> points, {
  TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
  TripTrackingPolicy policy = const TripTrackingPolicy(),
}) {
  final engine = TripTrackingEngine(profile: profile, policy: policy);
  final dispositions = <TripSampleDisposition>[];
  var sawReviewableStopEvidence = false;
  for (final point in points) {
    dispositions.add(engine.ingest(point.sample).disposition);
    final activity = point.activity;
    if (activity != null) {
      engine.recordActivityEvidence(
        activity,
        observedAt: point.sample.recordedAt,
      );
    }
    sawReviewableStopEvidence |=
        engine.needsWalkingReview ||
        engine.motionState == TripMotionState.stopCandidate ||
        engine.motionState == TripMotionState.stopped;
  }
  return SimulatedTripResult(
    acceptedMeters: engine.totalAcceptedMeters,
    dispositions: List.unmodifiable(dispositions),
    needsWalkingReview: engine.needsWalkingReview,
    sawReviewableStopEvidence: sawReviewableStopEvidence,
    motionState: engine.motionState,
  );
}
