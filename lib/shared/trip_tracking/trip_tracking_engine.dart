import 'dart:math' as math;

import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_vehicle_only_dwell_policy.dart';

part 'trip_tracking_engine_analysis.dart';
part 'trip_tracking_engine_recovery.dart';

/// Deterministic, platform-neutral evidence filter. Native adapters provide
/// samples; this engine decides what is safe to count and what needs review.
class TripTrackingEngine {
  // Android elapsedRealtimeNanos resets after a device reboot. A large,
  // forward-wall-clock regression is therefore treated as a new monotonic
  // clock epoch rather than permanently rejecting a recovered active day.
  static const _minimumMonotonicClockResetRegressionNanos = 60000000000;

  TripTrackingEngine({
    this.policy = const TripTrackingPolicy(),
    this.profile = TripTrackingProfile.roadVehicle,
  });

  final TripTrackingPolicy policy;
  final TripTrackingProfile profile;
  TripLocationSample? _lastAccepted;
  DateTime? _lastObservedAt;
  DateTime? _lastContinuousAt;
  int? _lastObservedMonotonicElapsedNanos;
  int? _lastContinuousMonotonicElapsedNanos;
  final List<TripActivityObservation> _walkingEvidence = [];
  var _totalAcceptedMeters = 0.0;
  var _walkingReviewSuggested = false;
  var _motionState = TripMotionState.unknown;
  var _vehicleMovementObserved = false;
  DateTime? _stationaryStartedAt;
  DateTime? _lastStationaryEvidenceAt;
  final List<TripTrackingSignalGap> _signalGaps = [];
  TripInitialFixAssessment? _initialFixAssessment;
  final List<TripInitialFixAssessment> _initialFixHistory = [];
  var _diagnostics = const TripTrackingDiagnostics();

  double get totalAcceptedMeters => _totalAcceptedMeters;
  bool get needsWalkingReview => _walkingReviewSuggested;
  TripMotionState get motionState => _motionState;
  TripStopCandidate? get currentStopCandidate => snapshot.currentStopCandidate;
  List<TripTrackingSignalGap> get signalGaps => List.unmodifiable(_signalGaps);
  TripInitialFixAssessment? get initialFixAssessment => _initialFixAssessment;
  List<TripInitialFixAssessment> get initialFixHistory =>
      List.unmodifiable(_initialFixHistory);

  void recordInitialFixAssessment(TripInitialFixAssessment? assessment) {
    _initialFixAssessment = assessment;
    if (assessment == null) return;
    _initialFixHistory.add(assessment);
  }

  bool beginSignalGap(
    DateTime startedAt, {
    required TripTrackingSignalGapReason reason,
  }) {
    if (_signalGaps.isNotEmpty && _signalGaps.last.isOpen) return false;
    var safeStartedAt = startedAt.toUtc();
    final lastObservedAt = _lastObservedAt?.toUtc();
    if (lastObservedAt != null && safeStartedAt.isBefore(lastObservedAt)) {
      safeStartedAt = lastObservedAt;
    }
    _signalGaps.add(
      TripTrackingSignalGap(startedAt: safeStartedAt, reason: reason),
    );
    return true;
  }

  bool completeSignalGap(DateTime endedAt) {
    if (_signalGaps.isEmpty || !_signalGaps.last.isOpen) return false;
    final safeEndedAt = endedAt.toUtc();
    final openGap = _signalGaps.last;
    if (safeEndedAt.isBefore(openGap.startedAt)) return false;
    _signalGaps[_signalGaps.length - 1] = openGap.closeAt(safeEndedAt);
    return true;
  }

  bool get odometerIsGlobalTruth => true;
  bool get calibrationRequiresTrustedGpsWindow => true;
  bool get poorGpsDaysExcludedFromCalibration => true;
  bool get engineCanCreateCalibration => false;
  bool get engineCanApplyCalibration => false;
  bool get engineCanConfirmOdometer => false;

  /// Retains the public monotonic-clock contract for native adapters and
  /// controller ingestion while the implementation lives with the related
  /// evidence-analysis helpers.
  static bool isMonotonicClockReset({
    required int? candidate,
    required int? previous,
    required DateTime candidateWallClock,
    required DateTime? previousWallClock,
  }) => TripTrackingEngineAnalysis.isMonotonicClockReset(
    candidate: candidate,
    previous: previous,
    candidateWallClock: candidateWallClock,
    previousWallClock: previousWallClock,
  );

  /// Clears a user-reviewed walking cue without changing trip distance.
  void acknowledgeWalkingReview() {
    _walkingReviewSuggested = false;
    _walkingEvidence.clear();
    if (_motionState == TripMotionState.stopCandidate ||
        _motionState == TripMotionState.stopped) {
      _motionState = TripMotionState.unknown;
    }
  }

  /// Retains a validated native motion observation until the next location
  /// sample can evaluate it against stationary GPS evidence. Motion remains
  /// advisory-only: this never changes distance, odometer truth, or TripLog.
  bool recordActivityEvidence(
    TripActivityObservation activity, {
    required DateTime observedAt,
  }) {
    final eventAt = activity.recordedAt.toUtc();
    final referenceAt = observedAt.toUtc();
    final confirmationWindow = _safePositiveDuration(
      policy.walkingConfirmationWindow,
      _defaultWalkingConfirmationWindow,
    );
    if (activity.confidence < 0 ||
        activity.confidence > 100 ||
        eventAt.isAfter(referenceAt.add(policy.maximumFutureSampleSkew)) ||
        referenceAt.difference(eventAt) > confirmationWindow) {
      return false;
    }
    final priorCount = _walkingEvidence.length;
    final priorReview = _walkingReviewSuggested;
    _recordActivity(activity, observedAt: referenceAt);
    if (_hasWalkingStopEvidence(referenceAt)) {
      _motionState = TripMotionState.stopped;
    } else if (_isRecentVehicleToWalkingTransition(
      activity,
      observedAt: referenceAt,
    )) {
      _motionState = TripMotionState.stopCandidate;
    }
    return priorCount != _walkingEvidence.length ||
        priorReview != _walkingReviewSuggested;
  }

  bool _isRecentVehicleToWalkingTransition(
    TripActivityObservation activity, {
    required DateTime observedAt,
  }) {
    if (!_strategy.usesWalkingStopEvidence ||
        !_vehicleMovementObserved ||
        !activity.canSupportStopReview ||
        activity.confidence <
            policy.walkingTransitionCandidateMinimumConfidence) {
      return false;
    }
    final lastVehicleSample = _lastAccepted;
    if (lastVehicleSample == null) return false;
    final elapsed = observedAt.difference(lastVehicleSample.recordedAt);
    final minimumDelay = policy.walkingTransitionCandidateDelay;
    final maximumDelay = policy.walkingConfirmationWindow;
    return !elapsed.isNegative &&
        elapsed >= minimumDelay &&
        elapsed <= maximumDelay;
  }

  TripTrackingEngineSnapshot get snapshot => TripTrackingEngineSnapshot(
    lastAccepted: _lastAccepted,
    lastObservedAt: _lastObservedAt,
    lastContinuousAt: _lastContinuousAt,
    lastObservedMonotonicElapsedNanos: _lastObservedMonotonicElapsedNanos,
    lastContinuousMonotonicElapsedNanos: _lastContinuousMonotonicElapsedNanos,
    totalAcceptedMeters: _totalAcceptedMeters,
    walkingEvidence: List.unmodifiable(_walkingEvidence),
    signalGaps: List.unmodifiable(_signalGaps),
    initialFixAssessment: _initialFixAssessment,
    initialFixHistory: List.unmodifiable(_initialFixHistory),
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
  }) => restoreTripTrackingEngineSnapshot(
    snapshot,
    policy: policy,
    profile: profile,
  );

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
    if (!sample.hasValidReportedSpeed ||
        !sample.hasValidReportedSpeedAccuracy) {
      return _decision(TripSampleDisposition.rejectedInvalid);
    }
    if (sample.mockedLocation == true) {
      return _decision(TripSampleDisposition.rejectedMockLocation);
    }
    final lastObservedAt = _lastObservedAt;
    final lastObservedMonotonicElapsedNanos =
        _lastObservedMonotonicElapsedNanos;
    final lastContinuousAt = _lastContinuousAt;
    final lastContinuousMonotonicElapsedNanos =
        _lastContinuousMonotonicElapsedNanos;
    final sampleMonotonicElapsedNanos = sample.monotonicElapsedNanos;
    final monotonicIsNewer =
        TripTrackingEngineAnalysis._isMonotonicElapsedNanosNewer(
          sampleMonotonicElapsedNanos,
          lastObservedMonotonicElapsedNanos,
        );
    final monotonicClockReset =
        TripTrackingEngineAnalysis.isMonotonicClockReset(
          candidate: sampleMonotonicElapsedNanos,
          previous: lastObservedMonotonicElapsedNanos,
          candidateWallClock: sample.recordedAt,
          previousWallClock: lastObservedAt,
        );
    if (lastObservedAt != null &&
        !sample.recordedAt.isAfter(lastObservedAt) &&
        !monotonicIsNewer) {
      return _decision(TripSampleDisposition.rejectedOutOfOrder);
    }
    if (lastObservedMonotonicElapsedNanos != null &&
        sampleMonotonicElapsedNanos != null &&
        !monotonicIsNewer &&
        !monotonicClockReset) {
      return _decision(TripSampleDisposition.rejectedOutOfOrder);
    }
    _lastObservedAt = sample.recordedAt;
    _lastObservedMonotonicElapsedNanos = sampleMonotonicElapsedNanos;
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
    _lastContinuousMonotonicElapsedNanos = sampleMonotonicElapsedNanos;

    final lastAccepted = _lastAccepted;
    if (lastAccepted == null) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.acceptedAnchor,
      );
    }

    final distance = _distanceMeters(lastAccepted, sample);

    final continuityElapsed = TripTrackingEngineAnalysis._elapsedBetween(
      earlierWallClock: lastContinuousAt,
      laterWallClock: sample.recordedAt,
      earlierMonotonicElapsedNanos: lastContinuousMonotonicElapsedNanos,
      laterMonotonicElapsedNanos: monotonicClockReset
          ? null
          : sampleMonotonicElapsedNanos,
    );
    if (continuityElapsed != null &&
        continuityElapsed >
            _safePositiveDuration(policy.maximumGap, _defaultGap)) {
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedGap,
        estimatedGapMeters: distance,
      );
    }

    final elapsed = TripTrackingEngineAnalysis._elapsedBetween(
      earlierWallClock: lastAccepted.recordedAt,
      laterWallClock: sample.recordedAt,
      earlierMonotonicElapsedNanos: lastAccepted.monotonicElapsedNanos,
      laterMonotonicElapsedNanos: monotonicClockReset
          ? null
          : sampleMonotonicElapsedNanos,
    );
    final seconds =
        (elapsed?.inMilliseconds ?? 0) / Duration.millisecondsPerSecond;
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
        rejectedMeters: distance,
      );
    }

    final reportedSpeed = _trustedReportedSpeed(sample);
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
        rejectedMeters: distance,
      );
    }
    if (_reportedAccelerationExceedsLimit(
      previousReportedSpeed: _trustedReportedSpeed(lastAccepted),
      reportedSpeed: reportedSpeed,
      elapsed: elapsed ?? Duration.zero,
    )) {
      // Preserve the fresh anchor so a rejected acceleration spike cannot
      // later bridge into a large false mileage segment.
      _lastAccepted = sample;
      return _finish(
        sample,
        verifiedActivity,
        TripSampleDisposition.rejectedSpeedConflict,
        rejectedMeters: distance,
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
        rejectedMeters: distance,
      );
    }
    if (distance <= accuracyEnvelope) {
      return _finish(
        sample,
        activityForMileage,
        TripSampleDisposition.rejectedDrift,
        rejectedMeters: distance,
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
  TripSampleDecision _decision(
    TripSampleDisposition disposition, {
    double addedMeters = 0,
    double rejectedMeters = 0,
    double estimatedGapMeters = 0,
  }) {
    _diagnostics = _diagnostics.record(
      disposition,
      rejectedMeters: rejectedMeters,
      estimatedGapMeters: estimatedGapMeters,
    );
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
const _maximumContinuousStationaryEvidenceGap = Duration(seconds: 45);

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
