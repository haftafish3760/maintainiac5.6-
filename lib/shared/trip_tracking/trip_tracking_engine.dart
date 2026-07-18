import 'dart:math' as math;

import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_profile_strategy.dart';

/// Deterministic, platform-neutral evidence filter. Native adapters provide
/// samples; this engine decides what is safe to count and what needs review.
class TripTrackingEngine {
  TripTrackingEngine({
    this.policy = const TripTrackingPolicy(),
    this.profile = TripTrackingProfile.roadVehicle,
  });

  final TripTrackingPolicy policy;
  final TripTrackingProfile profile;
  TripLocationSample? _lastAccepted;
  DateTime? _lastObservedAt;
  final List<TripActivityObservation> _walkingEvidence = [];
  var _totalAcceptedMeters = 0.0;
  var _walkingReviewSuggested = false;
  var _motionState = TripMotionState.unknown;
  var _vehicleMovementObserved = false;
  var _diagnostics = const TripTrackingDiagnostics();

  double get totalAcceptedMeters => _totalAcceptedMeters;
  bool get needsWalkingReview => _walkingReviewSuggested;
  TripMotionState get motionState => _motionState;

  /// Clears a user-reviewed walking cue without changing trip distance.
  void acknowledgeWalkingReview() {
    _walkingReviewSuggested = false;
    _walkingEvidence.clear();
    if (_motionState == TripMotionState.stopCandidate ||
        _motionState == TripMotionState.stopped) {
      _motionState = TripMotionState.unknown;
    }
  }

  TripTrackingEngineSnapshot get snapshot => TripTrackingEngineSnapshot(
    lastAccepted: _lastAccepted,
    lastObservedAt: _lastObservedAt,
    totalAcceptedMeters: _totalAcceptedMeters,
    walkingEvidence: List.unmodifiable(_walkingEvidence),
    walkingReviewSuggested: _walkingReviewSuggested,
    motionState: _motionState,
    vehicleMovementObserved: _vehicleMovementObserved,
    diagnostics: _diagnostics,
  );

  factory TripTrackingEngine.fromSnapshot(
    TripTrackingEngineSnapshot snapshot, {
    TripTrackingPolicy policy = const TripTrackingPolicy(),
    TripTrackingProfile profile = TripTrackingProfile.roadVehicle,
  }) {
    final engine = TripTrackingEngine(policy: policy, profile: profile);
    engine._lastAccepted = snapshot.lastAccepted;
    engine._lastObservedAt = snapshot.lastObservedAt;
    engine._totalAcceptedMeters =
        snapshot.totalAcceptedMeters.isFinite &&
            snapshot.totalAcceptedMeters >= 0
        ? snapshot.totalAcceptedMeters
        : 0;
    if (TripTrackingProfileStrategy.forProfile(
      profile,
      policy: policy,
    ).usesWalkingStopEvidence) {
      engine._walkingEvidence.addAll(snapshot.walkingEvidence);
      engine._walkingReviewSuggested = snapshot.walkingReviewSuggested;
      engine._motionState = snapshot.motionState;
    } else {
      engine._walkingReviewSuggested = false;
      engine._motionState =
          snapshot.motionState == TripMotionState.stopCandidate ||
              snapshot.motionState == TripMotionState.stopped
          ? TripMotionState.unknown
          : snapshot.motionState;
    }
    engine._vehicleMovementObserved = snapshot.vehicleMovementObserved;
    engine._diagnostics = snapshot.diagnostics;
    return engine;
  }

  TripSamplingRecommendation samplingRecommendation({
    double? speedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingMode? currentMode,
    bool activeTrip = false,
  }) => policy.samplingFor(
    speedMetersPerSecond: speedMetersPerSecond,
    vehicleMovementConfirmed: vehicleMovementConfirmed,
    profile: profile,
    currentMode: currentMode,
    activeTrip: activeTrip,
  );

  TripSampleDecision ingest(
    TripLocationSample sample, {
    TripActivityObservation? activity,
  }) {
    final verifiedActivity = _freshActivityForSample(sample, activity);
    if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) {
      return _decision(TripSampleDisposition.rejectedInvalid);
    }
    if (sample.mockedLocation == true) {
      return _decision(TripSampleDisposition.rejectedMockLocation);
    }
    final lastObservedAt = _lastObservedAt;
    if (lastObservedAt != null && !sample.recordedAt.isAfter(lastObservedAt)) {
      return _decision(TripSampleDisposition.rejectedOutOfOrder);
    }
    _lastObservedAt = sample.recordedAt;
    if (sample.horizontalAccuracyMeters >
        _safePositiveDouble(
          policy.maximumHorizontalAccuracyMeters,
          fallback: 65,
        )) {
      return _decision(TripSampleDisposition.rejectedAccuracy);
    }

    final lastAccepted = _lastAccepted;
    if (lastAccepted == null) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.acceptedAnchor,
      );
    }

    final elapsed = sample.recordedAt.difference(lastAccepted.recordedAt);
    if (elapsed > _safePositiveDuration(policy.maximumGap, _defaultGap)) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedGap,
      );
    }

    final distance = _distanceMeters(lastAccepted, sample);
    final seconds = elapsed.inMilliseconds / Duration.millisecondsPerSecond;
    final impliedSpeed = seconds <= 0 ? double.infinity : distance / seconds;
    if (impliedSpeed >
        _safePositiveDouble(
          policy.maximumPlausibleSpeedMetersPerSecond,
          fallback: 75,
        )) {
      // Re-anchor without awarding distance. This prevents a rejected stale
      // point from becoming a delayed, large false odometer bridge.
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedImplausibleSpeed,
      );
    }

    final reportedSpeed = sample.speedMetersPerSecond;
    if (reportedSpeed != null &&
        reportedSpeed.isFinite &&
        reportedSpeed >= 0 &&
        (reportedSpeed - impliedSpeed).abs() >
            _safePositiveDouble(
              policy.maximumReportedSpeedDisagreementMetersPerSecond,
              fallback: 25,
            )) {
      // Preserve the newer anchor but refuse to bridge two mutually
      // contradictory provider measurements into mileage.
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedSpeedConflict,
      );
    }

    _recordActivity(verifiedActivity, observedAt: sample.recordedAt);

    final strongWalking = _isStrongWalking(verifiedActivity);
    final precisionExitSpeed = _safePositiveDouble(
      policy.precisionExitSpeedMetersPerSecond,
      fallback: 5.6,
    );
    final vehicleSpeedEvidence =
        impliedSpeed >= precisionExitSpeed ||
        (reportedSpeed != null &&
            reportedSpeed.isFinite &&
            reportedSpeed >= precisionExitSpeed);
    final walkingLooksLikeVehicleMisclassification =
        strongWalking && vehicleSpeedEvidence;
    if (walkingLooksLikeVehicleMisclassification) {
      _walkingEvidence.clear();
      _walkingReviewSuggested = false;
    }
    final activityForMileage = walkingLooksLikeVehicleMisclassification
        ? null
        : verifiedActivity;

    // A strong fitness-motion walking signal is never road-vehicle mileage
    // unless the same sample also has credible vehicle-speed evidence. That
    // protects drivers from phone sensor misclassification while keeping true
    // stop-and-walk delivery evidence out of odometer mileage.
    // We retain it as advisory evidence, but exclude it immediately instead
    // of allowing the first few on-foot points to inflate the live estimate.
    if (_strategy.walkingMayExcludeRoadMileage && strongWalking) {
      _lastAccepted = sample;
      if (!walkingLooksLikeVehicleMisclassification) {
        return _finish(
          sample,
          verifiedActivity,
          TripSampleDisposition.excludedWalking,
        );
      }
    }

    final accuracyEnvelope = math.max(
      _safePositiveDouble(policy.minimumMovementMeters, fallback: 5),
      ((lastAccepted.horizontalAccuracyMeters +
                  sample.horizontalAccuracyMeters) /
              2) *
          _safePositiveDouble(
            policy.accuracyEnvelopeMultiplier,
            fallback: 1.25,
          ),
    );
    if (distance <= accuracyEnvelope) {
      return _finish(
        sample,
        activityForMileage,
        TripSampleDisposition.rejectedDrift,
      );
    }

    _lastAccepted = sample;
    _totalAcceptedMeters += distance;
    return _finish(
      sample,
      activityForMileage,
      TripSampleDisposition.acceptedDistance,
      addedMeters: distance,
    );
  }

  /// Records a native-source rejection without changing anchors, distance, or
  /// motion state. The controller uses this for wall-clock timestamp guards
  /// that must remain outside deterministic replay behavior.
  TripSampleDecision reject(TripSampleDisposition disposition) {
    return _decision(disposition);
  }

  TripActivityObservation? _freshActivityForSample(
    TripLocationSample sample,
    TripActivityObservation? activity,
  ) {
    if (activity == null || activity.recordedAt.isAfter(sample.recordedAt)) {
      return null;
    }
    return sample.recordedAt.difference(activity.recordedAt) <=
            _safePositiveDuration(
              policy.walkingConfirmationWindow,
              _defaultWalkingConfirmationWindow,
            )
        ? activity
        : null;
  }

  void _recordActivity(
    TripActivityObservation? activity, {
    required DateTime observedAt,
  }) {
    if (activity == null) return;
    if (activity.activity == TripActivity.automotive) {
      _walkingEvidence.clear();
      return;
    }
    if (!_strategy.usesWalkingStopEvidence || !_isStrongWalking(activity)) {
      return;
    }
    if (!_walkingEvidence.any(
      (item) => item.recordedAt == activity.recordedAt,
    )) {
      _walkingEvidence.add(activity);
    }
    final cutoff = observedAt.subtract(
      _safePositiveDuration(
        policy.walkingConfirmationWindow,
        _defaultWalkingConfirmationWindow,
      ),
    );
    _walkingEvidence.removeWhere((item) => item.recordedAt.isBefore(cutoff));
    if (_hasWalkingStopEvidence(observedAt)) {
      _walkingReviewSuggested = true;
    }
  }

  bool _isStrongWalking(TripActivityObservation? activity) =>
      activity?.canSupportStopReview ?? false;

  TripSampleDecision _finish(
    TripLocationSample sample,
    TripActivityObservation? activity,
    TripSampleDisposition disposition, {
    double addedMeters = 0,
  }) {
    _updateMotionState(sample, activity, disposition);
    return _decision(disposition, addedMeters: addedMeters);
  }

  void _updateMotionState(
    TripLocationSample sample,
    TripActivityObservation? activity,
    TripSampleDisposition disposition,
  ) {
    final automotive = activity?.activity == TripActivity.automotive;
    final walking = _isStrongWalking(activity);
    final credibleMovement =
        disposition == TripSampleDisposition.acceptedDistance && !walking;
    if (automotive || credibleMovement) {
      if (credibleMovement && !_vehicleMovementObserved) {
        _walkingEvidence.clear();
      }
      _vehicleMovementObserved = true;
      _motionState = TripMotionState.moving;
      return;
    }

    // Walking is a corroborating clue only. A traffic light has no walking
    // evidence, and walking before any observed vehicle movement cannot become
    // a vehicle-stop suggestion.
    if (!_strategy.usesWalkingStopEvidence ||
        !_vehicleMovementObserved ||
        !walking) {
      return;
    }
    if (!_hasWalkingStopEvidence(sample.recordedAt)) {
      _motionState = TripMotionState.stopCandidate;
      return;
    }
    _motionState = TripMotionState.stopped;
  }

  bool _hasWalkingStopEvidence(DateTime observedAt) {
    return _strategy.hasWalkingStopEvidence(
      walkingEvidenceCount: _walkingEvidence.length,
      observedAt: observedAt,
      latestWalkingEvidenceAt: _walkingEvidence.isEmpty
          ? null
          : _walkingEvidence.last.recordedAt,
    );
  }

  TripSampleDecision _decision(
    TripSampleDisposition disposition, {
    double addedMeters = 0,
  }) {
    _diagnostics = _diagnostics.record(disposition);
    return TripSampleDecision(
      disposition: disposition,
      totalAcceptedMeters: _totalAcceptedMeters,
      addedMeters: addedMeters,
      walkingReviewSuggested: _walkingReviewSuggested,
      motionState: _motionState,
    );
  }
}

extension on TripTrackingEngine {
  TripTrackingProfileStrategy get _strategy =>
      TripTrackingProfileStrategy.forProfile(profile, policy: policy);
}

const _defaultGap = Duration(minutes: 2);
const _defaultWalkingConfirmationWindow = Duration(seconds: 45);

double _safePositiveDouble(double value, {required double fallback}) =>
    value.isFinite && value > 0 ? value : fallback;

Duration _safePositiveDuration(Duration value, Duration fallback) =>
    value > Duration.zero ? value : fallback;

double _distanceMeters(TripLocationSample left, TripLocationSample right) {
  const earthRadiusMeters = 6371008.8;
  final latitudeDelta = _radians(right.latitude - left.latitude);
  final longitudeDelta = _radians(right.longitude - left.longitude);
  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(_radians(left.latitude)) *
          math.cos(_radians(right.latitude)) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final boundedA = a.clamp(0.0, 1.0).toDouble();
  return earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA));
}

double _radians(double degrees) => degrees * math.pi / 180;
