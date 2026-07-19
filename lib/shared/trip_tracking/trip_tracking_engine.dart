import 'dart:math' as math;

import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_vehicle_only_dwell_policy.dart';

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
  DateTime? _lastContinuousAt;
  final List<TripActivityObservation> _walkingEvidence = [];
  var _totalAcceptedMeters = 0.0;
  var _walkingReviewSuggested = false;
  var _motionState = TripMotionState.unknown;
  var _vehicleMovementObserved = false;
  DateTime? _stationaryStartedAt;
  var _diagnostics = const TripTrackingDiagnostics();

  double get totalAcceptedMeters => _totalAcceptedMeters;
  bool get needsWalkingReview => _walkingReviewSuggested;
  TripMotionState get motionState => _motionState;
  bool get odometerIsGlobalTruth => true;
  bool get calibrationRequiresTrustedGpsWindow => true;
  bool get poorGpsDaysExcludedFromCalibration => true;
  bool get engineCanCreateCalibration => false;
  bool get engineCanApplyCalibration => false;
  bool get engineCanConfirmOdometer => false;

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
    lastContinuousAt: _lastContinuousAt,
    totalAcceptedMeters: _totalAcceptedMeters,
    walkingEvidence: List.unmodifiable(_walkingEvidence),
    walkingReviewSuggested: _walkingReviewSuggested,
    motionState: _motionState,
    vehicleMovementObserved: _vehicleMovementObserved,
    stationaryStartedAt: _stationaryStartedAt,
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
    engine._lastContinuousAt =
        snapshot.lastContinuousAt ?? snapshot.lastAccepted?.recordedAt;
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
    engine._stationaryStartedAt = snapshot.stationaryStartedAt;
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
    if (!sample.hasValidReportedSpeed) {
      return _decision(TripSampleDisposition.rejectedInvalid);
    }
    if (sample.mockedLocation == true) {
      return _decision(TripSampleDisposition.rejectedMockLocation);
    }
    final lastObservedAt = _lastObservedAt;
    final lastContinuousAt = _lastContinuousAt;
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
    // Continuity is based on the last structurally sound, accurate observation,
    // not the last point that contributed mileage. Otherwise a legitimate
    // stationary period looks like a GPS outage merely because drift points did
    // not move the vehicle-distance anchor. Keep ordering separate so rejected
    // poor-accuracy samples cannot make later stale data appear fresh.
    _lastContinuousAt = sample.recordedAt;

    final lastAccepted = _lastAccepted;
    if (lastAccepted == null) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.acceptedAnchor,
      );
    }

    final continuityElapsed = lastContinuousAt == null
        ? null
        : sample.recordedAt.difference(lastContinuousAt);
    if (continuityElapsed != null &&
        continuityElapsed >
            _safePositiveDuration(policy.maximumGap, _defaultGap)) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedGap,
      );
    }

    final elapsed = sample.recordedAt.difference(lastAccepted.recordedAt);
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
      if (!walkingLooksLikeVehicleMisclassification) {
        // Keep the last verified vehicle anchor. Re-anchoring to a walking
        // point can turn an unclassified return-to-vehicle sample into false
        // road mileage after a delivery or jobsite walk.
        return _finish(
          sample,
          verifiedActivity,
          TripSampleDisposition.excludedWalking,
        );
      }
      _lastAccepted = sample;
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
    if (_stationaryProviderContradictsDistance(
      reportedSpeed: reportedSpeed,
      distance: distance,
      accuracyEnvelope: accuracyEnvelope,
    )) {
      // Some providers briefly jump coordinates while still reporting
      // near-zero speed after a vehicle stops. Re-anchor to prevent repeat
      // bridges, but never add that contradiction to odometer mileage.
      _lastAccepted = sample;
      return _finish(
        sample,
        activityForMileage,
        TripSampleDisposition.rejectedSpeedConflict,
      );
    }
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
    final latest = _walkingEvidence.isEmpty ? null : _walkingEvidence.last;
    if (latest != null &&
        activity.recordedAt.difference(latest.recordedAt) <
            _strategy.minimumWalkingEvidenceSpacing) {
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

  bool _stationaryProviderContradictsDistance({
    required double? reportedSpeed,
    required double distance,
    required double accuracyEnvelope,
  }) {
    if (!_isStationaryReportedSpeed(reportedSpeed)) return false;
    final minimumContradictoryDistance = math.max(75.0, accuracyEnvelope * 2);
    return distance >= minimumContradictoryDistance;
  }

  bool _isStationaryReportedSpeed(double? reportedSpeed) =>
      reportedSpeed != null &&
      reportedSpeed.isFinite &&
      reportedSpeed >= 0 &&
      reportedSpeed <= 0.5;

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
    final stationaryConflict =
        disposition == TripSampleDisposition.rejectedSpeedConflict &&
        _isStationaryReportedSpeed(sample.speedMetersPerSecond) &&
        !walking;
    if (automotive || credibleMovement) {
      if (credibleMovement && !_vehicleMovementObserved) {
        _walkingEvidence.clear();
      }
      _vehicleMovementObserved = true;
      _stationaryStartedAt = null;
      _motionState = TripMotionState.moving;
      return;
    }

    // A provider outage breaks the continuity required for automatic stop
    // assistance. Keep recorded distance intact, but discard any in-progress
    // stationary or walking window so a later fix cannot bridge the outage
    // into a fabricated stop.
    if (disposition == TripSampleDisposition.rejectedGap) {
      _stationaryStartedAt = null;
      _walkingEvidence.clear();
      // A gap invalidates only incomplete evidence. Once a stop has already
      // earned a review, it remains a user-visible advisory until reviewed.
      _motionState = TripMotionState.unknown;
      return;
    }

    if ((disposition == TripSampleDisposition.rejectedDrift ||
            stationaryConflict) &&
        _vehicleMovementObserved) {
      _stationaryStartedAt ??= sample.recordedAt;
      final stationaryStartedAt = _stationaryStartedAt;
      if (_walkingEvidence.isEmpty &&
          stationaryStartedAt != null &&
          sample.recordedAt.difference(stationaryStartedAt) >
              _safePositiveDuration(policy.maximumGap, _defaultGap)) {
        // Continuous stationary vehicle-only fixes can be a traffic queue,
        // gridlock, or a phone left in a parked vehicle. Age that evidence out
        // instead of turning a long wait into a stop candidate. Walking may
        // still establish a fresh, review-only stop cue afterward.
        _stationaryStartedAt = sample.recordedAt;
        _motionState = TripMotionState.unknown;
        return;
      }
      if (_hasVehicleOnlyStopCandidate(sample)) {
        _motionState = TripMotionState.stopCandidate;
      }
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
      walkingEvidenceSpan: _walkingEvidenceSpan,
    );
  }

  Duration get _walkingEvidenceSpan {
    if (_walkingEvidence.length < 2) return Duration.zero;
    return _walkingEvidence.last.recordedAt.difference(
      _walkingEvidence.first.recordedAt,
    );
  }

  bool _hasVehicleOnlyStopCandidate(TripLocationSample sample) {
    final startedAt = _stationaryStartedAt;
    final speedMps = sample.speedMetersPerSecond;
    if (startedAt == null ||
        speedMps == null ||
        sample.recordedAt.isBefore(startedAt)) {
      return false;
    }

    // Vehicle-only pauses are intentionally much more conservative than
    // walking-confirmed stops. A long traffic signal must not become a stop
    // review just because a few stationary fixes arrived. This policy only
    // permits a manual fallback after profile-specific dwell time plus a
    // meaningful, clean driving history; it never auto-confirms a stop.
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: profile,
      stationaryDuration: sample.recordedAt.difference(startedAt),
      walkingEvidenceCount: _walkingEvidence.length,
      rejectedDriftCount:
          _diagnostics.dispositionCounts[TripSampleDisposition.rejectedDrift] ??
          0,
      acceptedDistanceCount:
          _diagnostics.dispositionCounts[TripSampleDisposition
              .acceptedDistance] ??
          0,
      acceptedVehicleMovementObserved: _vehicleMovementObserved,
      speedMps: speedMps,
      horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
    );
    return decision.status ==
        TripVehicleOnlyDwellStatus.manualFallbackRecommended;
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
