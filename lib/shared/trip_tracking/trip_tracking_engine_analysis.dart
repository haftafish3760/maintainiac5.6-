part of 'trip_tracking_engine.dart';

/// Motion, activity, and provider-evidence analysis for the shared engine.
/// It can advise the TripLog workflow but cannot confirm odometer mileage.
extension TripTrackingEngineAnalysis on TripTrackingEngine {
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

  static DateTime? _safeRecoveredStationaryStartedAt(
    DateTime? candidate, {
    required bool vehicleMovementObserved,
    required DateTime? lastObservedAt,
  }) {
    if (!vehicleMovementObserved ||
        candidate == null ||
        lastObservedAt == null) {
      return null;
    }
    // A directly constructed recovery snapshot is still an external boundary.
    // A future stationary start would otherwise suppress legitimate stop
    // detection until wall time catches up with corrupt state.
    return candidate.isAfter(lastObservedAt) ? null : candidate;
  }

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

  bool _reportedAccelerationExceedsLimit({
    required double? previousReportedSpeed,
    required double? reportedSpeed,
    required Duration elapsed,
  }) {
    if (previousReportedSpeed == null ||
        reportedSpeed == null ||
        !previousReportedSpeed.isFinite ||
        !reportedSpeed.isFinite ||
        previousReportedSpeed < 0 ||
        reportedSpeed < 0) {
      return false;
    }
    final seconds = elapsed.inMilliseconds / Duration.millisecondsPerSecond;
    if (!seconds.isFinite || seconds <= 0) return false;
    final maximumAcceleration = _safePositiveDouble(
      policy.maximumReportedAccelerationMetersPerSecondSquared,
      fallback: 25,
    );
    return (reportedSpeed - previousReportedSpeed).abs() / seconds >
        maximumAcceleration;
  }

  double? _trustedReportedSpeed(TripLocationSample sample) {
    final speed = sample.speedMetersPerSecond;
    final speedAccuracy = sample.speedAccuracyMetersPerSecond;
    if (speed == null ||
        speedAccuracy == null ||
        speedAccuracy <=
            _safePositiveDouble(
              policy.maximumTrustedReportedSpeedAccuracyMetersPerSecond,
              fallback: 20,
            )) {
      return speed;
    }
    return null;
  }

  static bool _isMonotonicElapsedNanosNewer(int? candidate, int? previous) =>
      candidate != null && previous != null && candidate > previous;

  static bool isMonotonicClockReset({
    required int? candidate,
    required int? previous,
    required DateTime candidateWallClock,
    required DateTime? previousWallClock,
  }) =>
      candidate != null &&
      previous != null &&
      previousWallClock != null &&
      candidate < previous &&
      candidateWallClock.isAfter(previousWallClock) &&
      previous - candidate >=
          TripTrackingEngine._minimumMonotonicClockResetRegressionNanos;

  static Duration? _elapsedBetween({
    required DateTime? earlierWallClock,
    required DateTime laterWallClock,
    required int? earlierMonotonicElapsedNanos,
    required int? laterMonotonicElapsedNanos,
  }) {
    if (earlierMonotonicElapsedNanos != null &&
        laterMonotonicElapsedNanos != null) {
      final nanos = laterMonotonicElapsedNanos - earlierMonotonicElapsedNanos;
      if (nanos <= 0) return null;
      return Duration(microseconds: nanos ~/ 1000);
    }
    return earlierWallClock == null
        ? null
        : laterWallClock.difference(earlierWallClock);
  }

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
        _isStationaryReportedSpeed(_trustedReportedSpeed(sample)) &&
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
    final speedMps = _trustedReportedSpeed(sample);
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
}
