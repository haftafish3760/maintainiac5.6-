import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';

import '../odometer/odometer_mileage_review.dart';
import '../state/global_odometer.dart';
import 'trip_initial_fix_classifier.dart';
import 'trip_live_odometer_projection.dart';
import 'trip_route_history_models.dart';
import 'trip_route_history_store.dart';
import 'trip_start_detection_assistant.dart';
import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_calibration_apply_guard.dart';
import 'trip_tracking_backup_port.dart';
import 'trip_tracking_cancelled_session.dart';
import 'trip_tracking_durable_record_bridge.dart';
import 'trip_tracking_engine.dart';
import 'trip_tracking_heartbeat_watchdog_policy.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_native_error_policy.dart';
import 'trip_tracking_native_sampling_policy.dart';
import 'trip_tracking_odometer_calibration.dart';
import 'trip_tracking_odometer_reconciliation.dart';
import 'trip_tracking_odometer_usage_anomaly.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_recovery_policy.dart';
import 'trip_tracking_sampling_preset_policy.dart';
import 'trip_tracking_session_store.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_state_machine.dart';
import 'trip_stop_advisory_reviewer.dart';

/// Owns one active GPS-assisted trip. Platform adapters feed it samples; this
/// controller keeps the UI, local recovery record, and live odometer aligned.
class TripTrackingController extends ChangeNotifier {
  TripTrackingController({
    required TripTrackingSessionStore sessionStore,
    required GlobalOdometerController odometer,
    TripTrackingNativeGateway? platform,
    TripTrackingPolicy policy = const TripTrackingPolicy(),
    TripTrackingBackupPort cloudMirror = const NoopTripTrackingBackupPort(),
    TripTrackingDurableRecordBridge? durableRecordBridge,
    double gpsAssistanceCalibrationMultiplier = 1,
    DateTime Function()? clockNow,
    DateTime Function()? heartbeatNow,
    String Function()? activeProfileId,
    TripRouteHistoryStore? routeHistoryStore,
    TripTrackingSettings Function()? trackingSettings,
  }) : _sessionStore = sessionStore,
       _odometer = odometer,
       _platform = platform,
       _policy = policy,
       _cloudMirror = cloudMirror,
       _durableRecordBridge = durableRecordBridge,
       _calibrationState = TripTrackingCalibrationState.initial(
         gpsAssistanceCalibrationMultiplier,
       ),
       _activeProfileId = activeProfileId,
       _routeHistoryStore = routeHistoryStore,
       _trackingSettings = trackingSettings,
       _clockNow = clockNow ?? heartbeatNow ?? DateTime.now;

  final TripTrackingSessionStore _sessionStore;
  final GlobalOdometerController _odometer;
  final TripTrackingNativeGateway? _platform;
  final TripTrackingPolicy _policy;
  final TripTrackingBackupPort _cloudMirror;
  final TripTrackingDurableRecordBridge? _durableRecordBridge;
  final String Function()? _activeProfileId;
  final TripRouteHistoryStore? _routeHistoryStore;
  final TripTrackingSettings Function()? _trackingSettings;

  /// One wall-clock authority for native timestamps, recovery, and review
  /// validation. Keeping these checks on the same clock prevents a delayed or
  /// future-dated provider sample from entering a restored trip merely because
  /// a different code path happened to omit its received-time reference.
  final DateTime Function() _clockNow;
  TripTrackingCalibrationState _calibrationState;
  TripTrackingSessionRecord? _session;
  TripTrackingEngine? _engine;
  TripLiveOdometerProjection? _projection;
  double _activeTripCalibrationMultiplier = 1;
  StreamSubscription<TripTrackingPlatformEvent>? _platformSubscription;
  Future<void> _platformEventQueue = Future<void>.value();
  Future<void> _ingestionQueue = Future<void>.value();
  Future<void> _nativeLifecycleQueue = Future<void>.value();
  bool _isDisposed = false;
  // Starting, restoring, discarding, and finishing all replace the same
  // durable active-trip checkpoint. A second tap must fail closed instead of
  // interleaving with the first operation and producing a duplicate review or
  // releasing the live odometer projection mid-write.
  bool _sessionOperationInProgress = false;
  bool _nativeTracking = false;
  // Distinguishes a driver/app-requested shutdown from a collector that
  // stopped on its own. An unexpected stop must remain recoverable evidence,
  // not be silently presented as a normal paused trip.
  bool _nativeStopRequested = false;
  bool _nativeInterruptionPending = false;
  bool _nativeCriticalBatteryStopPending = false;
  TripTrackingNativeRequest? _pendingNativeStartRequest;
  bool _pendingNativeStartActivityUnavailable = false;
  bool _pendingNativeStartPreferenceSaveFailed = false;
  bool _pendingNativeStartStopped = false;
  bool _pendingNativeStartAuthorizationRevoked = false;
  TripSamplingRecommendation? _nativeSampling;
  TripTrackingSamplingPlan? _nativeSamplingPlan;
  DateTime? _lastNativeHeartbeatUtc;
  DateTime? _nativeTrackingStartedAtUtc;
  DateTime? _lastNativeLocationReceivedUtc;
  bool _backgroundTrackingAllowed = false;
  bool _activityRecognitionEnabled = false;
  bool _adaptiveSamplingEnabled = true;
  String? _platformStatus;
  String? _platformError;
  String? _cloudMirrorError;
  String? _durableRecordError;
  TripActivityObservation? _latestActivity;
  TripTrackingPlatformCapabilities? _lastKnownCapabilities;
  DateTime? _lastBatterySafetyCheckUtc;
  bool _lowBatteryProtectionEnabled = true;
  bool _lowBatteryOverrideEnabled = false;
  bool _lowBatteryWarningDismissed = false;
  String? _acceptedCalibrationEvidenceSignature;
  String? _routeStorageStatus;
  TripInitialFixDecision _initialFixDecision =
      TripInitialFixClassifier.evaluate(
        sample: null,
        sessionStartedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        receivedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        preciseLocationAuthorized: false,
      );

  TripTrackingSessionRecord? get activeSession => _session;
  bool get isTracking =>
      _session != null &&
      _session!.lifecycleState !=
          TripTrackingSessionLifecycleState.completionPending &&
      _session!.lifecycleState != TripTrackingSessionLifecycleState.completed &&
      _session!.lifecycleState != TripTrackingSessionLifecycleState.cancelled;
  double get acceptedMeters => _engine?.totalAcceptedMeters ?? 0;
  bool get needsWalkingReview => _engine?.needsWalkingReview ?? false;
  TripMotionState get motionState =>
      _engine?.motionState ?? TripMotionState.unknown;
  TripTrackingDiagnostics get diagnostics =>
      _engine?.snapshot.diagnostics ?? const TripTrackingDiagnostics();
  List<TripTrackingAdvisoryEvent> get advisories =>
      List.unmodifiable(_session?.advisories ?? const []);
  TripTrackingSessionLifecycleState? get lifecycleState =>
      _session?.lifecycleState;
  TripTrackingHealthState? get healthState => _session?.healthState;
  TripTrackingRecoveryDecision get recoveryDecision =>
      TripTrackingRecoveryPolicy.evaluate(
        session: _session,
        currentVehicleId: _odometer.vehicleId,
        currentConfirmedOdometer: _odometer.confirmedReading,
      );
  bool get nativeTracking => _nativeTracking;
  String? get platformStatus => _platformStatus;
  String? get platformError => _platformError;
  String? get cloudMirrorError => _cloudMirrorError;
  String? get durableRecordError => _durableRecordError;
  String? get routeStorageStatus => _routeStorageStatus;
  TripInitialFixDecision get initialFixDecision => _initialFixDecision;
  TripRouteHistorySummary? routeSummaryFor(String tripId) =>
      _routeHistoryStore?.summary(tripId);
  bool get hasDurableRecordBridge => _durableRecordBridge != null;
  bool get odometerIsGlobalTruth => true;
  bool get calibrationRequiresTrustedGpsWindow => true;
  bool get poorGpsDaysExcludedFromCalibration => true;
  bool get controllerCanCreateCalibrationWithoutReview => false;
  bool get controllerCanApplyCalibrationWithoutOptIn => false;
  bool get calibrationReviewAcceptedForCurrentEvidence =>
      _acceptedCalibrationEvidenceSignature == _calibrationEvidenceSignature();
  TripTrackingCalibrationApplyGuard get gpsAssistanceCalibrationApplyGuard =>
      _calibrationApplyGuard(
        signal: odometerCalibrationSignal(),
        userOptedIn: _calibrationState.enabled,
        userAcceptedLatestReview: calibrationReviewAcceptedForCurrentEvidence,
      );
  double get gpsAssistanceCalibrationMultiplier => _calibrationState.multiplier;
  TripTrackingPlatformCapabilities? get lastKnownCapabilities =>
      _lastKnownCapabilities;
  TripTrackingReviewRecord? get latestReview =>
      _sessionStore.pendingReviews.isEmpty
      ? null
      : _sessionStore.pendingReviews.first;
  TripTrackingReviewRecord? get latestUnconfirmedReview => _sessionStore
      .pendingReviews
      .where((review) => !review.isOdometerConfirmed)
      .firstOrNull;

  TripOdometerCalibrationSignal odometerCalibrationSignal({
    String? vehicleId,
    DateTime? nowUtc,
  }) => TripOdometerCalibrationSignal.evaluateConfirmedReviews(
    reviews: _sessionStore.pendingReviews,
    vehicleId: vehicleId ?? _odometer.vehicleId,
    // Persisted reviews are an external trust boundary. A caller that does
    // not supply a reference clock must still not let future-dated records
    // influence advisory GPS calibration.
    nowUtc: nowUtc ?? _clockNow(),
    requireTrustedSignalDiagnostics: true,
  );

  void refreshGpsAssistanceCalibration({required bool enabled}) {
    final signal = odometerCalibrationSignal();
    final guard = _calibrationApplyGuard(
      signal: signal,
      userOptedIn: enabled,
      userAcceptedLatestReview: calibrationReviewAcceptedForCurrentEvidence,
    );
    final next = _calibrationState.refresh(
      enabled: enabled,
      signal: signal,
      canApplyToFutureGpsProjection: guard.canApplyToFutureGpsProjection,
    );
    if (identical(next, _calibrationState)) return;
    _calibrationState = next;
    notifyListeners();
  }

  /// Records an explicit, in-session acceptance for the exact reviewed local
  /// evidence currently shown to the driver. A later confirmed review, a
  /// vehicle change, or a process restart fails neutral and requires a fresh
  /// acceptance before GPS projections can be scaled.
  bool acceptGpsAssistanceCalibrationReview() {
    final signal = odometerCalibrationSignal();
    final guard = _calibrationApplyGuard(
      signal: signal,
      userOptedIn: true,
      userAcceptedLatestReview: true,
    );
    if (!guard.canApplyToFutureGpsProjection) return false;
    _acceptedCalibrationEvidenceSignature = _calibrationEvidenceSignature(
      signal,
    );
    refreshGpsAssistanceCalibration(enabled: true);
    return _calibrationState.multiplier != 1;
  }

  TripTrackingCalibrationApplyGuard _calibrationApplyGuard({
    required TripOdometerCalibrationSignal signal,
    required bool userOptedIn,
    required bool userAcceptedLatestReview,
  }) => TripTrackingCalibrationApplyGuard.evaluate(
    signal: signal,
    userOptedIn: userOptedIn,
    userAcceptedLatestReview: userAcceptedLatestReview,
    minimumReviewedDays: 7,
    latestReviewedAtUtc: _latestConfirmedOdometerReviewAt(),
    nowUtc: _clockNow(),
    activeVehicleId: _odometer.vehicleId,
    reviewedVehicleId: _odometer.vehicleId,
    reviewedVehicleIds: [_odometer.vehicleId],
  );

  DateTime? _latestConfirmedOdometerReviewAt() {
    DateTime? latest;
    final latestAllowed = _clockNow().toUtc().add(
      _policy.maximumFutureSampleSkew,
    );
    for (final review in _sessionStore.pendingReviews) {
      final confirmedAt = review.odometerConfirmedAt;
      if (review.vehicleId != _odometer.vehicleId || confirmedAt == null) {
        continue;
      }
      if (confirmedAt.toUtc().isAfter(latestAllowed) ||
          review.finishedAt.toUtc().isAfter(latestAllowed)) {
        continue;
      }
      if (latest == null || confirmedAt.isAfter(latest)) latest = confirmedAt;
    }
    return latest;
  }

  String _calibrationEvidenceSignature([
    TripOdometerCalibrationSignal? suppliedSignal,
  ]) {
    final signal = suppliedSignal ?? odometerCalibrationSignal();
    final latest =
        _latestConfirmedOdometerReviewAt()?.toUtc().millisecondsSinceEpoch ??
        -1;
    final ratio = signal.averageGpsToOdometerRatio;
    final stableRatio = ratio.isFinite ? ratio.toStringAsFixed(8) : 'invalid';
    return '${_odometer.vehicleId}|${signal.status.name}|${signal.eligibleSampleCount}|$stableRatio|$latest';
  }

  TripOdometerUsageAnomalySignal odometerUsageAnomalySignal({
    required double currentOdometerMiles,
    String? vehicleId,
    DateTime? nowUtc,
  }) => TripOdometerUsageAnomalySignal.evaluate(
    currentOdometerMiles: currentOdometerMiles,
    history: _sessionStore.pendingReviews,
    vehicleId: vehicleId ?? _odometer.vehicleId,
    nowUtc: nowUtc,
  );

  TripOdometerUsageAnomalySignal odometerUsageAnomalySignalForCurrentDay({
    int? startingOdometer,
    DateTime? nowUtc,
  }) {
    final baseline =
        startingOdometer ??
        _session?.startingOdometer ??
        _odometer.confirmedReading;
    final miles = (_odometer.reading - baseline).clamp(0, 999999).toDouble();
    final referenceTime = (nowUtc ?? _clockNow()).toUtc();
    // A recurring route is best compared with the same weekday. Three
    // confirmed occurrences are enough to provide a useful early warning;
    // until then, fall back to the broader seven-day baseline instead of
    // hiding a genuinely unusual odometer entry for a new user.
    final weekdaySignal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: miles,
      history: _sessionStore.pendingReviews,
      vehicleId: _odometer.vehicleId,
      nowUtc: referenceTime,
      weekday: referenceTime.weekday,
      minimumReviewedDays: 3,
    );
    if (weekdaySignal.status !=
        TripOdometerUsageAnomalyStatus.insufficientHistory) {
      return weekdaySignal;
    }
    return odometerUsageAnomalySignal(
      currentOdometerMiles: miles,
      nowUtc: referenceTime,
    );
  }

  Future<bool> confirmOdometerReview({
    required String reviewId,
    required int confirmedEndingOdometer,
    DateTime? confirmedAt,
  }) => _runExclusiveSessionOperation(
    false,
    () => _confirmOdometerReview(
      reviewId: reviewId,
      confirmedEndingOdometer: confirmedEndingOdometer,
      confirmedAt: confirmedAt,
    ),
  );

  Future<bool> _confirmOdometerReview({
    required String reviewId,
    required int confirmedEndingOdometer,
    DateTime? confirmedAt,
  }) async {
    final review = _sessionStore.reviewForTrip(reviewId);
    if (review == null ||
        !review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        review.vehicleId.trim().isEmpty ||
        review.vehicleId != _odometer.vehicleId ||
        review.estimatedEndingOdometer < review.startingOdometer ||
        confirmedEndingOdometer < review.startingOdometer) {
      return false;
    }
    if (review.isOdometerConfirmed) {
      if (review.confirmedEndingOdometer != confirmedEndingOdometer) {
        return false;
      }
      return _finalizeCompletedSession(review, confirmedAt: confirmedAt);
    }
    final confirmationTime = confirmedAt ?? _clockNow();
    if (confirmationTime.isBefore(review.finishedAt)) return false;
    if (confirmationTime.toUtc().isAfter(
      _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'odometer_confirmation_time_invalid';
      _platformError =
          'Trip odometer confirmation time cannot be in the future.';
      notifyListeners();
      return false;
    }
    final continuity = _continuityAgainstPreviousConfirmedReview(review);
    if (continuity.shouldBlockConfirmation) {
      _platformStatus = 'odometer_continuity_invalid';
      _platformError =
          'This trip starts below the previous confirmed odometer for this vehicle. Review the starting and ending odometer readings before confirming.';
      notifyListeners();
      return false;
    }
    final entryValidation = TripOdometerEntryValidation.validate(
      startingOdometer: review.startingOdometer,
      endingOdometer: confirmedEndingOdometer,
      previousConfirmedEndingOdometer: _previousConfirmedReviewFor(
        review,
      )?.confirmedEndingOdometer,
    );
    if (entryValidation.shouldBlockConfirmation) {
      _platformStatus = 'odometer_entry_invalid';
      _platformError =
          'Review the starting and ending odometer readings before confirming this trip.';
      notifyListeners();
      return false;
    }
    final odometerMileageReview = const OdometerMileageReview(
      use: OdometerMileageUse.unresolved,
    );
    final odometerPreflight = _odometer.updateFromText(
      confirmedEndingOdometer.toString(),
      enteredAt: confirmationTime,
      confirmSuspicious: true,
      commit: false,
      mileageReview: odometerMileageReview,
      sourceType: 'gps_trip_review',
      sourceId: review.id,
    );
    if (!odometerPreflight.ok) return false;

    final confirmedReview = review.copyWith(
      confirmedEndingOdometer: confirmedEndingOdometer,
      odometerConfirmedAt: confirmationTime,
    );
    final odometerCommit = _odometer.updateFromText(
      confirmedEndingOdometer.toString(),
      enteredAt: confirmationTime,
      confirmSuspicious: true,
      mileageReview: odometerPreflight.mileageReview ?? odometerMileageReview,
      sourceType: 'gps_trip_review',
      sourceId: review.id,
    );
    if (!odometerCommit.ok) return false;
    try {
      await _sessionStore.saveReview(confirmedReview);
    } catch (error) {
      // The odometer event is already source-idempotent, so a later retry can
      // safely mark the review confirmed without duplicating mileage history.
      _platformStatus = 'review_confirmation_save_failed';
      _platformError =
          'Could not save the confirmed trip review locally. Retry review confirmation.';
      notifyListeners();
      return false;
    }
    if (!await _finalizeCompletedSession(
      confirmedReview,
      confirmedAt: confirmationTime,
    )) {
      return false;
    }
    if (_platformStatus == 'review_confirmation_save_failed') {
      _platformStatus = null;
      _platformError = null;
    }
    await _saveDurableReviewedTrip(confirmedReview);
    _acceptedCalibrationEvidenceSignature = null;
    _calibrationState = _calibrationState.refreshEnabled(
      signal: odometerCalibrationSignal(),
      canApplyToFutureGpsProjection: false,
    );
    final reconciliation = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: confirmedEndingOdometer,
    );
    if (reconciliation.status ==
        TripOdometerReconciliationStatus.reviewRecommended) {
      _platformStatus = 'odometer_reconciliation_review';
      _platformError =
          'GPS and odometer mileage differ enough to review. The physical odometer remains the official mileage.';
    } else if (entryValidation.shouldPromptUser) {
      _platformStatus = 'odometer_entry_review';
      _platformError =
          'This odometer entry looks unusual compared with recent confirmed mileage. The physical odometer remains the official mileage.';
    } else if (_platformStatus == 'odometer_reconciliation_review') {
      _platformStatus = null;
      _platformError = null;
    } else if (_platformStatus == 'odometer_entry_review') {
      _platformStatus = null;
      _platformError = null;
    }
    try {
      await _cloudMirror.queueReview(confirmedReview);
      unawaited(_flushCloudMirror());
      _cloudMirrorError = null;
    } catch (error) {
      // Physical confirmation is durable locally even when a cloud queue is
      // unavailable. The user can retry backup without reopening the trip.
      _cloudMirrorError = 'Cloud mileage backup is pending.';
    }
    notifyListeners();
    return true;
  }

  Future<bool> _finalizeCompletedSession(
    TripTrackingReviewRecord review, {
    DateTime? confirmedAt,
  }) async {
    final active = _session?.id == review.id
        ? _session
        : _sessionStore.activeSession;
    if (active == null) return true;
    if (active.id != review.id ||
        active.lifecycleState !=
            TripTrackingSessionLifecycleState.completionPending) {
      return false;
    }
    final result = await _sessionStore.commitTransition(
      sessionId: active.id,
      expectedRevision: active.revision,
      nextState: TripTrackingSessionLifecycleState.completed,
      eventTimestamp: confirmedAt ?? review.odometerConfirmedAt ?? _clockNow(),
      reasonCode: 'odometer_review_confirmed',
      initiatingSource: 'trip_log_review',
      confidenceState: 'user_confirmed',
      permissionState: 'not_required',
      trackingQualityMode: 'completed',
    );
    if (!result.accepted) return false;
    if (!await _sessionStore.clearIfSession(active.id)) return false;
    if (_session?.id == active.id) _session = null;
    return true;
  }

  TripOdometerContinuityCheck _continuityAgainstPreviousConfirmedReview(
    TripTrackingReviewRecord review,
  ) {
    final previous = _previousConfirmedReviewFor(review);
    if (previous == null) {
      return const TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.insufficientData,
        odometerGapMiles: 0,
        reasonCode: 'missing_same_vehicle_confirmed_history',
      );
    }
    return TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: review,
    );
  }

  TripTrackingReviewRecord? _previousConfirmedReviewFor(
    TripTrackingReviewRecord review,
  ) => _sessionStore.pendingReviews
      .where(
        (candidate) =>
            candidate.id != review.id &&
            candidate.vehicleId == review.vehicleId &&
            candidate.isOdometerConfirmed &&
            candidate.finishedAt.isBefore(review.startedAt),
      )
      .firstOrNull;

  /// Retries locally durable mileage backups without touching the active trip
  /// or confirmed odometer. A successful retry clears any stale dashboard
  /// warning; failures remain visible and retryable.
  Future<void> retryCloudBackup() async {
    if (_isDisposed) return;
    await _retryDurableReviewedTrips();
    await _flushCloudMirror();
  }

  Future<void> _saveDurableReviewedTrip(TripTrackingReviewRecord review) async {
    final bridge = _durableRecordBridge;
    if (bridge == null || !review.isOdometerConfirmed) return;
    try {
      await bridge.saveReviewedTrip(
        review,
        routeSummary: _routeHistoryStore?.summary(review.id),
      );
      if (_durableRecordError != null) _durableRecordError = null;
    } catch (_) {
      _durableRecordError =
          'Reviewed trip is saved locally; durable backup is pending retry.';
    }
  }

  Future<void> _retryDurableReviewedTrips() async {
    final bridge = _durableRecordBridge;
    if (bridge == null) return;
    try {
      for (final review in _sessionStore.pendingReviews) {
        if (review.isOdometerConfirmed) {
          await bridge.saveReviewedTrip(
            review,
            routeSummary: _routeHistoryStore?.summary(review.id),
          );
        }
      }
      if (_durableRecordError != null) {
        _durableRecordError = null;
        notifyListeners();
      }
    } catch (_) {
      _durableRecordError =
          'Reviewed trip is saved locally; durable backup is pending retry.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // A detached Dart controller has no safe path to persist native events.
    // Stop collection rather than leaving a foreground service running with
    // no local consumer. Normal background tracking keeps this controller
    // alive; a later restore can resume from the durable local checkpoint.
    if (_nativeTracking) {
      unawaited(_stopNativeTracking());
    } else {
      unawaited(_platformSubscription?.cancel());
      _platformSubscription = null;
    }
    _isDisposed = true;
    _cloudMirror.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<T> _runExclusiveSessionOperation<T>(
    T busyValue,
    Future<T> Function() operation,
  ) async {
    if (_isDisposed || _sessionOperationInProgress) return busyValue;
    _sessionOperationInProgress = true;
    try {
      return await operation();
    } finally {
      _sessionOperationInProgress = false;
    }
  }

  Future<bool> start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    DateTime? startedAt,
  }) => _runExclusiveSessionOperation(
    false,
    () => _start(
      tripId: tripId,
      vehicleId: vehicleId,
      profile: profile,
      startedAt: startedAt,
    ),
  );

  Future<bool> beginAssistedSessionIfEligible({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    required TripTrackingSettings settings,
    required List<TripStartEvidenceObservation> observations,
    DateTime? startedAt,
  }) => _runExclusiveSessionOperation(false, () async {
    final decision = TripStartDetectionAssistant.evaluate(
      settings: settings,
      observations: observations,
      hasActiveOrRecoverableSession:
          _session != null || _sessionStore.activeSession != null,
    );
    if (!decision.shouldBeginAssistedSession) return false;
    return _start(
      tripId: tripId,
      vehicleId: vehicleId,
      profile: profile,
      startedAt: startedAt,
      initialLifecycleState:
          TripTrackingSessionLifecycleState.candidateMovement,
      startReasonCode: decision.reasonCode,
      initiatingSource: 'assisted_start_detector',
    );
  });

  Future<bool> _start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    DateTime? startedAt,
    TripTrackingSessionLifecycleState initialLifecycleState =
        TripTrackingSessionLifecycleState.preparing,
    String startReasonCode = 'manual_start_requested',
    String initiatingSource = 'user',
  }) async {
    if (_isDisposed ||
        isTracking ||
        !_isSafeTripTrackingIdentity(tripId) ||
        !_isSafeTripTrackingIdentity(vehicleId)) {
      return false;
    }
    if (vehicleId != _odometer.vehicleId) {
      // The live odometer is vehicle-scoped. Never create a session whose
      // later GPS miles could be projected onto a different active vehicle.
      _platformStatus = 'vehicle_mismatch';
      _platformError =
          'Select the vehicle used for this GPS trip before starting tracking.';
      notifyListeners();
      return false;
    }
    final boundProfileId = _activeProfileId?.call() ?? 'legacy-local-profile';
    if (!_isSafeTripTrackingIdentity(boundProfileId)) {
      _platformStatus = 'profile_missing';
      _platformError = 'Select a valid profile before starting GPS assistance.';
      notifyListeners();
      return false;
    }
    try {
      // Reviews are stored by trip id. Reusing an id would otherwise replace
      // an existing locally durable audit record when the new trip finishes.
      if (_sessionStore.recoveryReviewForTrip(tripId) != null) return false;
      final existing = _sessionStore.activeSession;
      if (existing != null) {
        _platformStatus = 'active_session_exists';
        _platformError =
            existing.vehicleId == vehicleId &&
                existing.profileId == boundProfileId
            ? 'A GPS trip is already available to resume or review.'
            : 'Another vehicle or profile has an unfinished GPS trip.';
        notifyListeners();
        return false;
      }
    } catch (error) {
      // Do not start GPS or alter the live odometer when we cannot establish
      // that the immutable local review history is available.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip locally.';
      notifyListeners();
      return false;
    }
    final platform = _platform;
    if (platform != null) {
      try {
        if (await platform.isTracking) {
          _platformStatus = 'native_session_recovery_required';
          _platformError =
              'The device GPS service is already tracking. Recover it before starting another trip.';
          notifyListeners();
          return false;
        }
      } catch (_) {
        _platformStatus = 'native_state_unavailable';
        _platformError =
            'The device GPS service state could not be verified safely.';
        notifyListeners();
        return false;
      }
    }
    final recoveredState = _session?.lifecycleState;
    if (!_nativeTracking &&
        recoveredState != null &&
        recoveredState != TripTrackingSessionLifecycleState.pausedByUser &&
        recoveredState != TripTrackingSessionLifecycleState.pausedBySystem &&
        TripTrackingSessionStateMachine.canTransition(
          recoveredState,
          TripTrackingSessionLifecycleState.pausedBySystem,
        )) {
      await _transitionSession(
        TripTrackingSessionLifecycleState.pausedBySystem,
        health: TripTrackingHealthState.interrupted,
        reasonCode: 'recovery_native_collector_not_running',
        initiatingSource: 'application_recovery',
      );
      _platformStatus ??= 'recovery_paused';
      _platformError ??=
          'The trip was restored safely, but GPS assistance is paused until you resume it.';
    }
    final now = _clockNow();
    final started = startedAt ?? now;
    if (started.toUtc().isAfter(
      now.toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'trip_start_time_invalid';
      _platformError =
          'GPS trip tracking could not start because the start time is in the future.';
      notifyListeners();
      return false;
    }
    final startingOdometer = _odometer.confirmedReading;
    _engine = TripTrackingEngine(policy: _policy, profile: profile);
    _projection = TripLiveOdometerProjection(
      startingOdometer: startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    _activeTripCalibrationMultiplier = gpsAssistanceCalibrationMultiplier;
    final candidate = TripTrackingSessionRecord(
      id: tripId,
      vehicleId: vehicleId,
      profileId: boundProfileId,
      startingOdometer: startingOdometer,
      profile: profile,
      startedAt: started,
      updatedAt: started,
      engineSnapshot: _engine!.snapshot,
      lifecycleState: initialLifecycleState,
    );
    try {
      final claim = await _sessionStore.claimActive(
        candidate,
        reasonCode: startReasonCode,
        initiatingSource: initiatingSource,
        confidenceState:
            initialLifecycleState ==
                TripTrackingSessionLifecycleState.candidateMovement
            ? 'high'
            : 'unknown',
        trackingQualityMode: initialLifecycleState.name,
      );
      if (claim.status != TripTrackingSessionClaimStatus.claimed ||
          claim.session == null) {
        _engine = null;
        _projection = null;
        _activeTripCalibrationMultiplier = 1;
        _platformStatus = claim.status == TripTrackingSessionClaimStatus.corrupt
            ? 'recovery_data_corrupt'
            : 'active_session_exists';
        _platformError = claim.status == TripTrackingSessionClaimStatus.corrupt
            ? 'Existing GPS recovery data needs review before another trip can start.'
            : 'A GPS trip is already available to resume or review.';
        notifyListeners();
        return false;
      }
      _session = claim.session;
      if (!_odometer.beginLiveTripProjection(
        tripId: tripId,
        startingOdometer: startingOdometer,
        observedAtUtc: started,
      )) {
        await _sessionStore.clearIfSession(tripId);
        _session = null;
        _engine = null;
        _projection = null;
        _activeTripCalibrationMultiplier = 1;
        return false;
      }
    } catch (error) {
      // An active trip is only recoverable after its initial local checkpoint
      // succeeds. Do not leave a phantom trip holding the live odometer when
      // storage is unavailable (for example, a full or closed local store).
      try {
        await _sessionStore.clearIfSession(tripId);
      } catch (_) {
        // The original storage failure is the useful error to surface. A
        // later restore still validates any residual record defensively.
      }
      _odometer.clearLiveTripProjection(tripId: tripId);
      _session = null;
      _engine = null;
      _projection = null;
      _activeTripCalibrationMultiplier = 1;
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip locally.';
      notifyListeners();
      return false;
    }
    _platformStatus = null;
    _platformError = null;
    _initialFixDecision = TripInitialFixClassifier.evaluate(
      sample: null,
      sessionStartedAt: _session!.startedAt,
      receivedAt: _clockNow(),
      preciseLocationAuthorized: false,
    );
    notifyListeners();
    return true;
  }

  Future<bool> restore() => _runExclusiveSessionOperation(false, _restore);

  Future<bool> _restore() async {
    if (_isDisposed || isTracking) return false;
    TripTrackingSessionRecord? session;
    try {
      final recovery = await _sessionStore.recoverActive();
      session = recovery.session;
      if (recovery.usedFallback) {
        _platformStatus = 'snapshot_recovered';
        _platformError =
            'The newest trip checkpoint was damaged. An earlier safe checkpoint was restored for review.';
      }
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip recovery data.';
      notifyListeners();
      return false;
    }
    if (session == null) return false;
    if (!_isRecoverableSession(session)) {
      try {
        final quarantined = await _sessionStore.quarantineActiveSession(
          sessionId: session.id,
          reasonCode: 'unsafe_session_recovery_boundary',
          quarantinedAtUtc: _clockNow(),
        );
        _platformStatus = quarantined
            ? 'session_quarantined'
            : 'session_quarantine_pending';
        _platformError = quarantined
            ? 'An unsafe trip checkpoint was isolated without deleting its evidence.'
            : 'An unsafe trip checkpoint still needs recovery review.';
        notifyListeners();
      } catch (error) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not isolate invalid local trip data safely.';
        notifyListeners();
      }
      return false;
    }
    // A review record was durably written before the process died. Do not
    // resume tracking or risk adding distance to a trip the user ended.
    TripTrackingReviewRecord? review;
    try {
      review = _sessionStore.recoveryReviewForTrip(session.id);
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip review data.';
      notifyListeners();
      return false;
    }
    if (review != null) {
      if (!_isAuthoritativeReview(review, session)) {
        // A malformed review must not make us discard the only recoverable
        // active-trip checkpoint. Fail closed until the local record can be
        // repaired instead of risking mileage loss or duplicate tracking.
        _platformStatus = 'review_invalid';
        _platformError =
            'A saved trip review is incomplete. GPS recovery is paused to protect your mileage.';
        notifyListeners();
        return false;
      }
      if (session.lifecycleState ==
          TripTrackingSessionLifecycleState.completionPending) {
        if (session.vehicleId != _odometer.vehicleId) {
          _platformStatus = 'vehicle_mismatch';
          _platformError =
              'This completed GPS trip belongs to another vehicle. Switch vehicles to review it.';
          notifyListeners();
          return false;
        }
        final currentProfileId = _activeProfileId?.call();
        if (currentProfileId != null && session.profileId != currentProfileId) {
          _platformStatus = 'profile_mismatch';
          _platformError =
              'This completed GPS trip belongs to another profile. Switch profiles to review it.';
          notifyListeners();
          return false;
        }
        _session = session;
        _engine = null;
        _projection = null;
        _platformStatus = 'completion_pending';
        _platformError =
            'GPS assistance stopped. Confirm the ending odometer to complete this trip.';
        notifyListeners();
        return true;
      }
      try {
        await _sessionStore.clearIfSession(session.id);
        await _sessionStore.clearPending(session.id);
      } catch (error) {
        // The durable review remains authoritative even if a stale recovery
        // checkpoint cannot be removed right now. Never resume it as a trip.
        _platformStatus = 'review_cleanup_failed';
        _platformError =
            'Could not clear stale trip recovery data or transient GPS sample.';
        notifyListeners();
      }
      return false;
    }
    if (session.vehicleId != _odometer.vehicleId) {
      // Never project a recovered trip onto whichever vehicle happens to be
      // active after a restart. Keep the durable session intact until the
      // driver selects its original vehicle and can review it safely.
      _platformStatus = 'vehicle_mismatch';
      _platformError =
          'This GPS trip belongs to another vehicle. Switch vehicles before recovering it.';
      notifyListeners();
      return false;
    }
    final currentProfileId = _activeProfileId?.call();
    if (currentProfileId != null && session.profileId != currentProfileId) {
      _platformStatus = 'profile_mismatch';
      _platformError =
          'This GPS trip belongs to another profile. Switch profiles before recovering it.';
      notifyListeners();
      return false;
    }
    final projection = TripLiveOdometerProjection(
      startingOdometer: session.startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    _activeTripCalibrationMultiplier = gpsAssistanceCalibrationMultiplier;
    final estimatedOdometer = projection.updateAcceptedMeters(
      session.engineSnapshot.totalAcceptedMeters,
      gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
    );
    if (!_odometer.beginLiveTripProjection(
      tripId: session.id,
      startingOdometer: session.startingOdometer,
      observedAtUtc: session.startedAt,
    )) {
      return false;
    }
    if (projection.lastUpdateExceededMax ||
        !_odometer.updateLiveTripProjection(
          tripId: session.id,
          estimatedOdometer: estimatedOdometer,
          observedAtUtc: session.updatedAt,
          receivedAtUtc: session.updatedAt,
        )) {
      _odometer.clearLiveTripProjection(tripId: session.id);
      _platformStatus = 'odometer_projection_invalid';
      _platformError =
          'Saved GPS trip distance is outside the supported odometer range.';
      notifyListeners();
      return false;
    }
    _session = session;
    _engine = TripTrackingEngine.fromSnapshot(
      session.engineSnapshot,
      policy: _policy,
      profile: session.profile,
    );
    _projection = projection;
    TripTrackingPendingSample? pending;
    try {
      pending = _sessionStore.pendingSampleFor(session.id);
    } catch (error) {
      // The active checkpoint is already recoverable. Keep it and its live
      // odometer projection rather than crashing or discarding mileage just
      // because the optional final in-flight sample cannot be read.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read pending GPS recovery data.';
      notifyListeners();
      return true;
    }
    final pendingRecovery = TripTrackingRecoveryPolicy.evaluate(
      session: session,
      currentVehicleId: _odometer.vehicleId,
      currentConfirmedOdometer: session.startingOdometer,
      pendingSample: pending,
    );
    if (pendingRecovery.status ==
            TripTrackingRecoveryStatus.pendingReplayReady &&
        pending != null) {
      try {
        await ingest(pending.sample, activity: pending.activity);
        await _sessionStore.clearPending(session.id);
      } catch (error) {
        // The active checkpoint and live odometer projection are already
        // restored. If replaying the optional in-flight sample cannot be
        // persisted, keep the trip recoverable and let the next sample move it
        // forward instead of failing the whole restore.
        _platformStatus = 'pending_replay_failed';
        _platformError = 'Could not replay the last pending GPS sample.';
        notifyListeners();
        return true;
      }
    } else if (pending != null && pending.sessionId == session.id) {
      try {
        await _sessionStore.clearPending(session.id);
      } catch (_) {
        _platformStatus = 'pending_cleanup_failed';
        _platformError = 'Could not clear stale GPS recovery data.';
        notifyListeners();
        return true;
      }
    }
    final platform = _platform;
    if (platform != null) {
      try {
        if (await platform.isTracking) {
          if (!session.backgroundTrackingAllowed) {
            // A collector that outlives this process cannot continue from
            // missing or foreground-only consent. Keep the local trip for an
            // explicit driver restart instead of silently tracking.
            try {
              await platform.stop();
              _platformStatus = 'background_consent_required';
              _platformError =
                  'GPS recovery was paused because background tracking was not previously authorized.';
            } catch (_) {
              _platformStatus = 'recoverable';
              _platformError =
                  'Could not stop GPS recovery without confirmed background permission.';
            }
          } else {
            _nativeTracking = true;
            _backgroundTrackingAllowed = true;
            _activityRecognitionEnabled = session.activityRecognitionEnabled;
            _nativeSampling = session.nativeSampling;
            _nativeSamplingPlan = session.samplingCeiling == null
                ? null
                : TripTrackingSamplingPlan(
                    sampling: session.samplingCeiling!,
                    deviceTier: TripTrackingDeviceCapabilityTier.locationOnly,
                    walkingEvidenceAvailable: false,
                    batteryProtectionEvidenceAvailable: false,
                  );
            _adaptiveSamplingEnabled = session.adaptiveSamplingEnabled;
            _lowBatteryProtectionEnabled = session.lowBatteryProtectionEnabled;
            _lowBatteryOverrideEnabled = session.lowBatteryOverrideEnabled;
            _lowBatteryWarningDismissed = session.lowBatteryWarningDismissed;
            _lastNativeHeartbeatUtc = _clockNow().toUtc();
            _nativeTrackingStartedAtUtc = _lastNativeHeartbeatUtc;
            _lastNativeLocationReceivedUtc = null;
            _platformStatus = 'tracking';
            final sampling = _nativeSampling;
            if (sampling == null) {
              _platformError =
                  'GPS recovery was paused because its saved sampling state is unavailable.';
              await _stopNativeTracking();
              _platformStatus = 'sampling_recovery_required';
            } else {
              bool reapplied;
              try {
                reapplied = await platform.update(
                  TripTrackingNativeRequest(
                    profile: session.profile,
                    sampling: sampling,
                    allowBackground: true,
                    activityRecognitionEnabled:
                        session.activityRecognitionEnabled,
                  ),
                );
              } catch (_) {
                reapplied = false;
              }
              if (!reapplied) {
                _platformError =
                    'GPS recovery was paused because the device could not reapply its saved tracking settings.';
                await _stopNativeTracking();
                _platformStatus = 'native_reconfiguration_failed';
              } else {
                _platformSubscription = _listenToPlatformEvents(platform);
                try {
                  _lastKnownCapabilities = await platform.readCapabilities();
                  _lastBatterySafetyCheckUtc = _clockNow().toUtc();
                  await _enforceRuntimeBatterySafety();
                } catch (_) {
                  // The surviving native collector remains authoritative for
                  // immediate OS-level safety. Do not fabricate a battery
                  // state or abandon recoverable local TripLog state when the
                  // optional runtime capability probe is temporarily
                  // unavailable.
                }
              }
            }
          }
        }
      } catch (error) {
        _platformError = 'Could not restore the GPS connection.';
        _platformStatus = 'recoverable';
      }
    }
    notifyListeners();
    return true;
  }

  bool _isRecoverableSession(TripTrackingSessionRecord session) =>
      session.hasValidTimeline &&
      _isSafeTripTrackingIdentity(session.id) &&
      _isSafeTripTrackingIdentity(session.vehicleId) &&
      session.startingOdometer >= 0 &&
      !session.updatedAt.isBefore(session.startedAt) &&
      _isRecoverableLifecycleState(session.lifecycleState);

  bool _isRecoverableLifecycleState(TripTrackingSessionLifecycleState state) =>
      switch (state) {
        TripTrackingSessionLifecycleState.preparing ||
        TripTrackingSessionLifecycleState.awaitingPermission ||
        TripTrackingSessionLifecycleState.awaitingLocationServices ||
        TripTrackingSessionLifecycleState.awaitingInitialFix ||
        TripTrackingSessionLifecycleState.candidateMovement ||
        TripTrackingSessionLifecycleState.activeTracking ||
        TripTrackingSessionLifecycleState.temporarilyStopped ||
        TripTrackingSessionLifecycleState.pausedByUser ||
        TripTrackingSessionLifecycleState.pausedBySystem ||
        TripTrackingSessionLifecycleState.signalDegraded ||
        TripTrackingSessionLifecycleState.signalLost ||
        TripTrackingSessionLifecycleState.recovering ||
        TripTrackingSessionLifecycleState.stopping ||
        TripTrackingSessionLifecycleState.completionPending ||
        TripTrackingSessionLifecycleState.failedRecoverable => true,
        TripTrackingSessionLifecycleState.idle ||
        TripTrackingSessionLifecycleState.completed ||
        TripTrackingSessionLifecycleState.cancelled ||
        TripTrackingSessionLifecycleState.failedUnrecoverable => false,
      };

  bool _isAuthoritativeReview(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      review.hasValidTimeline &&
      review.id == session.id &&
      review.vehicleId == session.vehicleId &&
      review.startingOdometer == session.startingOdometer &&
      review.startedAt == session.startedAt &&
      review.estimatedEndingOdometer >= review.startingOdometer;

  Future<TripSampleDecision?> ingest(
    TripLocationSample sample, {
    TripActivityObservation? activity,
    DateTime? referenceTime,
  }) => _enqueueIngestion(
    () => _ingest(sample, activity: activity, referenceTime: referenceTime),
  );

  Future<TripSampleDecision?> _ingest(
    TripLocationSample sample, {
    TripActivityObservation? activity,
    DateTime? referenceTime,
  }) async {
    if (_isDisposed) return null;
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;

    final receivedAt = (referenceTime ?? _clockNow()).toUtc();
    final needsInitialFixClassification =
        engine.snapshot.lastAccepted == null &&
        (session.lifecycleState ==
                TripTrackingSessionLifecycleState.awaitingInitialFix ||
            session.lifecycleState ==
                TripTrackingSessionLifecycleState.signalDegraded ||
            session.lifecycleState ==
                TripTrackingSessionLifecycleState.signalLost ||
            session.lifecycleState ==
                TripTrackingSessionLifecycleState.recovering);
    if (needsInitialFixClassification) {
      final sessionAge = receivedAt.difference(session.startedAt.toUtc());
      final initialFix = TripInitialFixClassifier.evaluate(
        sample: sample,
        sessionStartedAt: session.startedAt,
        receivedAt: receivedAt,
        preciseLocationAuthorized: _nativeTracking,
        recentKnownLocation: engine.snapshot.lastAccepted,
        motionState: engine.motionState,
        maximumFreshAge: sessionAge > const Duration(seconds: 30)
            ? sessionAge + const Duration(minutes: 2)
            : const Duration(seconds: 30),
        maximumUsableAccuracyMeters:
            engine.policy.maximumHorizontalAccuracyMeters,
      );
      _initialFixDecision = initialFix;
      _platformStatus = initialFix.reasonCode;
      if (!initialFix.canAnchorSession) {
        final rejected = engine.reject(
          _initialFixRejectionDisposition(initialFix, sample),
        );
        await _recordInitialFixRejection(
          session: session,
          decision: initialFix,
          receivedAt: receivedAt,
          engineSnapshot: engine.snapshot,
        );
        return rejected;
      }
    }

    if (sample.recordedAt.toUtc().isBefore(session.startedAt.toUtc())) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }

    // A caller may supply the native receipt time for a platform event. Direct
    // ingestion still uses the controller clock as a mandatory future-date
    // guard, while the odometer projection keeps its historical sample time
    // when no distinct receipt time is available.
    final projectionReceivedAt = (referenceTime ?? sample.recordedAt).toUtc();
    if (sample.recordedAt.toUtc().isAfter(
      receivedAt.add(engine.policy.maximumFutureSampleSkew),
    )) {
      return engine.reject(TripSampleDisposition.rejectedFutureTimestamp);
    }

    if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) {
      return engine.reject(TripSampleDisposition.rejectedInvalid);
    }
    if (!sample.hasValidReportedSpeed ||
        !sample.hasValidReportedSpeedAccuracy) {
      return engine.reject(TripSampleDisposition.rejectedInvalid);
    }

    final lastObservedAt = engine.snapshot.lastObservedAt?.toUtc();
    final lastObservedMonotonicElapsedNanos =
        engine.snapshot.lastObservedMonotonicElapsedNanos;
    final monotonicIsNewer =
        sample.monotonicElapsedNanos != null &&
        lastObservedMonotonicElapsedNanos != null &&
        sample.monotonicElapsedNanos! > lastObservedMonotonicElapsedNanos;
    final wallClockIsNewer =
        lastObservedAt == null ||
        sample.recordedAt.toUtc().isAfter(lastObservedAt);
    final monotonicClockReset = TripTrackingEngine.isMonotonicClockReset(
      candidate: sample.monotonicElapsedNanos,
      previous: lastObservedMonotonicElapsedNanos,
      candidateWallClock: sample.recordedAt,
      previousWallClock: lastObservedAt,
    );
    if (lastObservedAt != null && !wallClockIsNewer && !monotonicIsNewer) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }
    if (lastObservedMonotonicElapsedNanos != null &&
        sample.monotonicElapsedNanos != null &&
        !monotonicIsNewer &&
        !monotonicClockReset) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }

    final safeActivity = _activitySafeForSample(sample, activity);
    if (sample.mockedLocation != true) {
      await _sessionStore.savePending(
        TripTrackingPendingSample(
          sessionId: session.id,
          sample: sample,
          activity: safeActivity,
        ),
      );
    }

    // The filter is mutable. Keep a recoverable in-memory checkpoint until
    // its matching session state is safely local. Otherwise a failed write
    // could make the next sample measure from GPS evidence that did not
    // survive the local-first durability boundary.
    final previousEngineSnapshot = engine.snapshot;
    final previousMotionState = engine.motionState;
    final decision = engine.ingest(sample, activity: safeActivity);
    final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
      session,
      engineSnapshot: engine.snapshot,
      previousMotionState: previousMotionState,
      currentMotionState: engine.motionState,
      detectedAt: sample.recordedAt,
    );
    final persistsRecoveryState =
        decision.accepted ||
        decision.disposition == TripSampleDisposition.rejectedAccuracy ||
        decision.disposition == TripSampleDisposition.rejectedMockLocation ||
        decision.disposition == TripSampleDisposition.rejectedDrift ||
        decision.disposition == TripSampleDisposition.rejectedGap ||
        decision.disposition ==
            TripSampleDisposition.rejectedImplausibleSpeed ||
        decision.disposition == TripSampleDisposition.rejectedSpeedConflict ||
        decision.disposition == TripSampleDisposition.excludedWalking;
    if (persistsRecoveryState) {
      final naturalLifecycleState = _lifecycleAfterDecision(
        session.lifecycleState,
        decision,
      );
      if (naturalLifecycleState != session.lifecycleState) {
        TripTrackingSessionStateMachine.requireTransition(
          session.lifecycleState,
          naturalLifecycleState,
        );
      }
      _session = session.copyWith(
        updatedAt: sample.recordedAt,
        engineSnapshot: engine.snapshot,
        advisories: advisories,
        healthState: naturalLifecycleState == session.lifecycleState
            ? _healthAfterDecision(session.healthState, decision)
            : session.healthState,
      );
      try {
        _session = await _sessionStore.checkpoint(
          _session!,
          expectedRevision: session.revision,
        );
        if (naturalLifecycleState != session.lifecycleState) {
          final transitioned = await _sessionStore.commitTransition(
            sessionId: session.id,
            expectedRevision: _session!.revision,
            nextState: naturalLifecycleState,
            eventTimestamp: sample.recordedAt,
            healthState: _healthAfterDecision(session.healthState, decision),
            reasonCode: needsInitialFixClassification
                ? _initialFixDecision.reasonCode
                : 'validated_sample_quality_changed',
            initiatingSource: needsInitialFixClassification
                ? 'initial_fix_classifier'
                : 'gps_sample_validator',
            confidenceState: needsInitialFixClassification
                ? _initialFixDecision.confidence.name
                : decision.accepted
                ? 'medium'
                : 'low',
            trackingQualityMode: needsInitialFixClassification
                ? _initialFixDecision.classification.name
                : naturalLifecycleState.name,
          );
          if (!transitioned.accepted) {
            throw StateError('Validated sample transition was rejected.');
          }
          _session = transitioned.session;
        }
      } catch (_) {
        _session = session;
        _engine = TripTrackingEngine.fromSnapshot(
          previousEngineSnapshot,
          policy: engine.policy,
          profile: engine.profile,
        );
        rethrow;
      }
      final routeStore = _routeHistoryStore;
      final settings = _trackingSettings?.call();
      if (decision.accepted && routeStore != null && settings != null) {
        try {
          final routeResult = await routeStore.appendGpsPoint(
            tripId: session.id,
            latitude: sample.latitude,
            longitude: sample.longitude,
            recordedAtUtc: sample.recordedAt,
            horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
            localDayKey: _localDayKey(sample.recordedAt),
            settings: settings,
            nowUtc: receivedAt,
          );
          _routeStorageStatus = routeResult.reasonCode;
        } catch (_) {
          _routeStorageStatus = 'route_storage_failed_gps_continues';
        }
      }
      final estimatedOdometer = projection.updateAcceptedMeters(
        decision.totalAcceptedMeters,
        gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      );
      final liveProjectionUpdated = _odometer.updateLiveTripProjection(
        tripId: session.id,
        estimatedOdometer: estimatedOdometer,
        observedAtUtc: sample.recordedAt,
        receivedAtUtc: projectionReceivedAt,
      );
      final liveProjectionFailed =
          decision.accepted &&
          (projection.lastUpdateExceededMax || !liveProjectionUpdated);
      if (liveProjectionFailed) {
        _platformStatus = 'odometer_projection_invalid';
        _platformError = projection.lastUpdateExceededMax
            ? 'GPS distance exceeded the supported live odometer range. Review the trip before continuing.'
            : 'GPS live odometer projection could not be updated safely. The confirmed odometer remains unchanged.';
        if (TripTrackingSessionStateMachine.canTransition(
          _session!.lifecycleState,
          TripTrackingSessionLifecycleState.failedRecoverable,
        )) {
          await _transitionSession(
            TripTrackingSessionLifecycleState.failedRecoverable,
            health: TripTrackingHealthState.unavailable,
            eventTimestamp: sample.recordedAt,
          );
        }
      } else if (needsInitialFixClassification && decision.accepted) {
        _platformStatus = 'tracking';
        _platformError = null;
      }
      notifyListeners();
    }
    await _sessionStore.clearPending(session.id);
    return decision;
  }

  TripActivityObservation? _activitySafeForSample(
    TripLocationSample sample,
    TripActivityObservation? activity,
  ) {
    final evidence = activity;
    if (evidence == null) return null;
    if (evidence.confidence < 0 || evidence.confidence > 100) return null;
    if (evidence.recordedAt.isAfter(sample.recordedAt)) return null;
    final age = sample.recordedAt.difference(evidence.recordedAt);
    if (age > _policy.walkingConfirmationWindow) return null;
    return evidence;
  }

  /// Starts the platform collector only after an active trip exists. Native
  /// samples are queued one at a time so a fast EventChannel cannot reorder
  /// distance decisions or overwrite a newer recovery snapshot.
  Future<bool> startNativeTracking({
    required bool allowBackground,
    double? observedSpeedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingRecommendation? samplingOverride,
    TripTrackingSamplingPreset? samplingPreset,
    int customIntervalSeconds = 15,
    bool activityRecognitionEnabled = false,
    bool adaptiveSamplingEnabled = true,
    bool lowBatteryProtectionEnabled = true,
    bool lowBatteryOverrideEnabled = false,
    bool lowBatteryWarningDismissed = false,
  }) => _enqueueNativeLifecycle(
    () => _startNativeTracking(
      allowBackground: allowBackground,
      observedSpeedMetersPerSecond: observedSpeedMetersPerSecond,
      vehicleMovementConfirmed: vehicleMovementConfirmed,
      samplingOverride: samplingOverride,
      samplingPreset: samplingPreset,
      customIntervalSeconds: customIntervalSeconds,
      activityRecognitionEnabled: activityRecognitionEnabled,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    ),
  );

  Future<bool> _startNativeTracking({
    required bool allowBackground,
    double? observedSpeedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingRecommendation? samplingOverride,
    TripTrackingSamplingPreset? samplingPreset,
    int customIntervalSeconds = 15,
    bool activityRecognitionEnabled = false,
    bool adaptiveSamplingEnabled = true,
    bool lowBatteryProtectionEnabled = true,
    bool lowBatteryOverrideEnabled = false,
    bool lowBatteryWarningDismissed = false,
  }) async {
    final platform = _platform;
    var session = _session;
    if (_isDisposed || platform == null || session == null || _nativeTracking) {
      return false;
    }
    if (!await _tryTransitionSession(
      TripTrackingSessionLifecycleState.awaitingInitialFix,
      health: TripTrackingHealthState.healthy,
    )) {
      return false;
    }
    session = _session;
    if (session == null) return false;
    TripTrackingPlatformCapabilities capabilities;
    _lastKnownCapabilities = null;
    try {
      capabilities = await platform.readCapabilities();
      _lastKnownCapabilities = capabilities;
    } catch (error) {
      _platformError = 'Could not read GPS capabilities.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (!capabilities.locationAvailable) {
      _platformError = 'Device location is unavailable.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (allowBackground && !capabilities.backgroundTrackingAvailable) {
      _platformError = 'Background GPS tracking is unavailable on this device.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    final requestedActivityRecognition =
        activityRecognitionEnabled && capabilities.activityRecognitionAvailable;
    var batterySnapshot = const TripTrackingBatterySnapshot(
      batteryPercent: null,
      isCharging: false,
      lowPowerModeEnabled: false,
    );
    try {
      if (capabilities.batteryStateAvailable) {
        batterySnapshot = await platform.readBatterySnapshot();
      }
    } catch (_) {
      // Battery state is advisory for safety. If the platform cannot provide a
      // trustworthy reading, continue as "unknown" instead of fabricating data.
    }
    final batteryDecision = _policy.gpsBatteryDecision(
      batteryPercent: batterySnapshot.batteryPercent,
      isCharging: batterySnapshot.isCharging,
      lowPowerModeEnabled:
          capabilities.lowPowerModeAvailable &&
          batterySnapshot.lowPowerModeEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    );
    if (!batteryDecision.allowsGps) {
      _platformStatus = batteryDecision.reasonCode;
      _platformError = _gpsBatteryMessageFor(batteryDecision);
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    TripTrackingAuthorization authorization;
    try {
      authorization = await platform.requestAuthorization(
        allowBackground: allowBackground,
        activityRecognitionEnabled: requestedActivityRecognition,
      );
    } catch (error) {
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'Could not request GPS permission.',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.permissionBlocked,
      );
      notifyListeners();
      return false;
    }
    if (!authorization.canTrackPrecisely ||
        (allowBackground && !authorization.canTrackInBackground)) {
      _platformError = allowBackground
          ? 'Background location permission is required for this tracking mode.'
          : 'Precise location permission is required to start trip tracking.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.awaitingPermission,
        health: TripTrackingHealthState.permissionBlocked,
      );
      notifyListeners();
      return false;
    }
    final samplingPlan = samplingOverride == null && samplingPreset != null
        ? TripTrackingSamplingPresetPolicy.planFor(
            preset: samplingPreset,
            customIntervalSeconds: customIntervalSeconds,
            capabilities: capabilities,
          )
        : null;
    final request = TripTrackingNativeRequest(
      profile: session.profile,
      sampling:
          samplingOverride ??
          samplingPlan?.sampling ??
          _policy.samplingFor(
            speedMetersPerSecond: observedSpeedMetersPerSecond,
            vehicleMovementConfirmed: vehicleMovementConfirmed,
            profile: session.profile,
            activeTrip: true,
          ),
      activityRecognitionEnabled: requestedActivityRecognition,
      allowBackground: allowBackground,
    );
    if (!await _persistNativeCollectionPreferences(
      allowBackground: allowBackground,
      activityRecognitionEnabled: requestedActivityRecognition,
      nativeSampling: request.sampling,
      samplingCeiling: samplingPlan?.sampling,
      clearSamplingCeiling: samplingPlan == null,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    )) {
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      return false;
    }
    session = _session;
    if (session == null) return false;
    _latestActivity = null;
    _nativeCriticalBatteryStopPending = false;
    _pendingNativeStartRequest = request;
    _pendingNativeStartActivityUnavailable = false;
    _pendingNativeStartPreferenceSaveFailed = false;
    _pendingNativeStartStopped = false;
    _pendingNativeStartAuthorizationRevoked = false;
    _platformSubscription = _listenToPlatformEvents(platform);
    bool started;
    try {
      started = await platform.start(request);
    } catch (error) {
      _clearPendingNativeStart();
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'The device could not start GPS trip tracking.',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    final activityUnavailableDuringStart =
        _pendingNativeStartActivityUnavailable;
    final preferenceSaveFailedDuringStart =
        _pendingNativeStartPreferenceSaveFailed;
    final nativeStoppedDuringStart = _pendingNativeStartStopped;
    final authorizationRevokedDuringStart =
        _pendingNativeStartAuthorizationRevoked;
    _clearPendingNativeStart();
    if (_nativeCriticalBatteryStopPending) {
      await _cancelPlatformSubscriptionAfterNativeStop();
      _platformSubscription = null;
      _platformStatus = 'battery_critical_gps_blocked';
      _platformError = TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_battery_critical',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (!started) {
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = 'The device did not start GPS trip tracking.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (preferenceSaveFailedDuringStart ||
        nativeStoppedDuringStart ||
        authorizationRevokedDuringStart) {
      try {
        await platform.stop();
      } catch (_) {
        // The durable local failure is authoritative; best-effort native
        // cleanup must not replace that actionable error.
      }
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = preferenceSaveFailedDuringStart
          ? 'Motion activity became unavailable, and GPS tracking could not save that privacy change locally.'
          : authorizationRevokedDuringStart
          ? 'Precise location permission was removed while trip tracking was starting.'
          : 'GPS updates stopped while trip tracking was starting.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: authorizationRevokedDuringStart
            ? TripTrackingHealthState.permissionBlocked
            : TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    _nativeTracking = true;
    _nativeSampling = request.sampling;
    _nativeSamplingPlan = samplingPlan;
    _lastNativeHeartbeatUtc = _clockNow().toUtc();
    _nativeTrackingStartedAtUtc = _lastNativeHeartbeatUtc;
    _lastNativeLocationReceivedUtc = null;
    _backgroundTrackingAllowed = allowBackground;
    _activityRecognitionEnabled =
        requestedActivityRecognition && !activityUnavailableDuringStart;
    _adaptiveSamplingEnabled = adaptiveSamplingEnabled;
    _lowBatteryProtectionEnabled = lowBatteryProtectionEnabled;
    _lowBatteryOverrideEnabled = lowBatteryOverrideEnabled;
    _lowBatteryWarningDismissed = lowBatteryWarningDismissed;
    _lastBatterySafetyCheckUtc = _clockNow().toUtc();
    _platformError = null;
    _platformStatus = 'tracking';
    _initialFixDecision = TripInitialFixClassifier.evaluate(
      sample: null,
      sessionStartedAt: session.startedAt,
      receivedAt: _clockNow(),
      preciseLocationAuthorized: true,
    );
    notifyListeners();
    return true;
  }

  String _safeNativeCommandFailure(Object error, {required String fallback}) {
    if (error is PlatformException) {
      return TripTrackingNativeErrorPolicy.safeMessage(error.code);
    }
    return fallback;
  }

  String _gpsBatteryMessageFor(TripGpsBatteryDecision decision) {
    if (decision.reasonCode == 'battery_critical_gps_blocked') {
      return 'Battery is critically low. GPS-assisted tracking is paused below 10% to preserve your device and local TripLog.';
    }
    final lowPowerMode = decision.reasonCode.startsWith('low_power_mode');
    final prompt =
        decision.status == TripGpsBatteryDecisionStatus.userPromptRequired;
    if (lowPowerMode) {
      return prompt
          ? 'Battery saver is active. Choose whether to continue GPS while the device is conserving power.'
          : 'GPS tracking is blocked while battery saver is active by your saved battery setting.';
    }
    return prompt
        ? 'Battery is below the GPS safety threshold. Choose whether to continue GPS below 20% battery.'
        : 'GPS tracking is blocked below 20% battery by your saved battery setting.';
  }

  StreamSubscription<TripTrackingPlatformEvent> _listenToPlatformEvents(
    TripTrackingNativeGateway platform,
  ) => platform.events.listen(
    _enqueuePlatformEvent,
    onError: (Object error) {
      if (!_nativeTracking) return;
      unawaited(_handleNativeInterruption('GPS updates stopped unexpectedly.'));
    },
    onDone: () {
      if (!_nativeTracking) return;
      _deferPlatformCleanup(
        () => _handleNativeInterruption('GPS updates ended unexpectedly.'),
      );
    },
  );

  Future<void> _handleNativeInterruption(String message) async {
    if (_isDisposed || _nativeInterruptionPending) return;
    _nativeInterruptionPending = true;
    try {
      _platformError = message;
      _platformStatus = 'error';
      if (_session?.lifecycleState ==
              TripTrackingSessionLifecycleState.activeTracking ||
          _session?.lifecycleState ==
              TripTrackingSessionLifecycleState.signalDegraded ||
          _session?.lifecycleState ==
              TripTrackingSessionLifecycleState.awaitingInitialFix) {
        await _tryTransitionSession(
          TripTrackingSessionLifecycleState.signalLost,
          health: TripTrackingHealthState.interrupted,
        );
      }
      notifyListeners();
      await _stopNativeTracking(interrupted: true);
    } finally {
      _nativeInterruptionPending = false;
    }
  }

  void _enqueuePlatformEvent(TripTrackingPlatformEvent event) {
    _platformEventQueue = _platformEventQueue
        .then((_) async {
          if (_isDisposed) return;
          if (event.type == TripTrackingPlatformEventType.location &&
              event.location != null) {
            if (!_nativeTracking) return;
            // A received provider event is a runtime heartbeat. Deliberately
            // use receive time, not the untrusted payload timestamp.
            _lastNativeHeartbeatUtc = _clockNow().toUtc();
            _lastNativeLocationReceivedUtc = _lastNativeHeartbeatUtc;
            final activity = _latestActivity;
            final decision = await ingest(
              event.location!,
              activity:
                  activity != null &&
                      !event.location!.recordedAt.isBefore(
                        activity.recordedAt,
                      ) &&
                      event.location!.recordedAt.difference(
                            activity.recordedAt,
                          ) <=
                          const Duration(seconds: 90)
                  ? activity
                  : null,
              referenceTime: _clockNow().toUtc(),
            );
            await _maybeUpdateNativeSampling(event.location!, decision);
            if (decision?.accepted == true &&
                _platformStatus == 'gps_signal_stale') {
              _platformStatus = 'tracking';
              _platformError = null;
            }
            _scheduleRuntimeBatterySafetyCheck();
          } else if (event.activity != null) {
            // Native event streams are external input. Ignore motion evidence
            // unless this tracking session both asked for it and the platform
            // confirmed that the device can provide it.
            if (!_nativeTracking || !_activityRecognitionEnabled) return;
            _latestActivity = event.activity;
          } else if (event.type ==
                  TripTrackingPlatformEventType.authorization &&
              event.authorization != null) {
            final pendingStart = _pendingNativeStartRequest;
            if (!_nativeTracking && pendingStart == null) return;
            final authorization = event.authorization!;
            final authorizationStillAllowsTracking =
                authorization.canTrackPrecisely &&
                (!(_nativeTracking
                        ? _backgroundTrackingAllowed
                        : pendingStart!.allowBackground) ||
                    authorization.canTrackInBackground);
            if (authorizationStillAllowsTracking) return;
            if (pendingStart != null && !_nativeTracking) {
              _pendingNativeStartAuthorizationRevoked = true;
              _platformError = pendingStart.allowBackground
                  ? 'Background location permission was removed while trip tracking was starting.'
                  : 'Precise location permission was removed while trip tracking was starting.';
              notifyListeners();
              return;
            }
            // This handler is already serialized by the platform event queue.
            // Schedule interruption cleanup after it returns so its final
            // queue drain cannot wait on the event currently being processed.
            _deferPlatformCleanup(
              () => _handleNativeInterruption(
                _backgroundTrackingAllowed
                    ? 'Background location permission was removed while tracking.'
                    : 'Precise location permission was removed while tracking.',
              ),
            );
          } else if (event.type == TripTrackingPlatformEventType.status) {
            final status = event.status;
            if (status == 'stopped' || status == 'paused') {
              if (_pendingNativeStartRequest != null && !_nativeTracking) {
                _pendingNativeStartStopped = true;
                _platformStatus = 'interrupted';
                _platformError =
                    'GPS updates stopped while trip tracking was starting.';
                notifyListeners();
                return;
              }
              final expectedStop =
                  _nativeStopRequested ||
                  _nativeCriticalBatteryStopPending ||
                  status == 'paused';
              _platformStatus = expectedStop ? status : 'interrupted';
              if (!expectedStop) {
                _platformError =
                    'GPS updates stopped unexpectedly. Your local trip is preserved for review.';
              }
              _nativeTracking = false;
              _nativeSampling = null;
              _nativeSamplingPlan = null;
              _lastNativeHeartbeatUtc = null;
              _nativeTrackingStartedAtUtc = null;
              _lastNativeLocationReceivedUtc = null;
              _backgroundTrackingAllowed = false;
              _latestActivity = null;
              await _cancelPlatformSubscriptionAfterNativeStop();
              _platformSubscription = null;
              if (!expectedStop &&
                  (_session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.activeTracking ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.signalDegraded ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState
                              .awaitingInitialFix)) {
                await _tryTransitionSession(
                  TripTrackingSessionLifecycleState.signalLost,
                  health: TripTrackingHealthState.interrupted,
                );
              } else if (expectedStop &&
                  (_session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.activeTracking ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.signalDegraded ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState
                              .awaitingInitialFix)) {
                await _tryTransitionSession(
                  TripTrackingSessionLifecycleState.pausedByUser,
                );
              }
            } else if (status == 'tracking' && _nativeTracking) {
              final now = _clockNow().toUtc();
              _lastNativeHeartbeatUtc = now;
              await _markGpsSignalStaleIfNeeded(now);
              if (_platformStatus != 'gps_signal_stale') {
                _platformStatus = status;
              }
            } else if (status == 'idle' && !_nativeTracking) {
              _platformStatus = status;
            } else {
              return;
            }
            notifyListeners();
          } else if (event.type == TripTrackingPlatformEventType.error) {
            if (TripTrackingNativeErrorPolicy.isIgnorableMalformedPayload(
              event.errorCode,
            )) {
              return;
            }
            final message = TripTrackingNativeErrorPolicy.safeMessage(
              event.errorCode,
            );
            _platformError = message;
            if (event.errorCode == 'trip_tracking_battery_critical') {
              _nativeCriticalBatteryStopPending = true;
              unawaited(_handleNativeCriticalBatteryStop(message));
            } else if (event.errorCode ==
                'trip_tracking_activity_unavailable') {
              final pendingStart = _pendingNativeStartRequest;
              final activityAssistanceActive =
                  (_nativeTracking && !_nativeStopRequested) ||
                  (pendingStart?.activityRecognitionEnabled ?? false);
              if (!activityAssistanceActive) {
                notifyListeners();
                return;
              }
              // Walking assistance is optional. A permission revocation or
              // provider failure must retire only that sensor, never GPS,
              // TripLog, or the authoritative odometer workflow.
              _latestActivity = null;
              _activityRecognitionEnabled = false;
              if (pendingStart != null) {
                _pendingNativeStartActivityUnavailable = true;
              }
              final persisted = await _persistNativeCollectionPreferences(
                allowBackground:
                    pendingStart?.allowBackground ?? _backgroundTrackingAllowed,
                activityRecognitionEnabled: false,
              );
              if (!persisted) {
                if (pendingStart != null) {
                  _pendingNativeStartPreferenceSaveFailed = true;
                } else {
                  _platformError =
                      'Motion activity became unavailable, and GPS tracking stopped because that privacy change could not be saved locally.';
                  // This handler is executing inside the platform event queue.
                  // Stopping drains that queue, so schedule it after this event
                  // completes instead of awaiting a self-draining deadlock.
                  _deferPlatformCleanup(_stopNativeTracking);
                }
              }
              notifyListeners();
            } else if (_nativeTracking &&
                TripTrackingNativeErrorPolicy.requiresRecovery(
                  event.errorCode,
                )) {
              _deferPlatformCleanup(() => _handleNativeInterruption(message));
            } else {
              notifyListeners();
            }
          }
        })
        .catchError((Object error, StackTrace _) {
          if (_isDisposed) return;
          _platformError = 'GPS event could not be processed safely.';
          notifyListeners();
        });
  }

  void _scheduleRuntimeBatterySafetyCheck() {
    final platform = _platform;
    final capabilities = _lastKnownCapabilities;
    if (!_nativeTracking ||
        platform == null ||
        capabilities?.batteryStateAvailable != true) {
      return;
    }
    final now = _clockNow().toUtc();
    final previous = _lastBatterySafetyCheckUtc;
    if (previous != null &&
        now.difference(previous) < const Duration(minutes: 5)) {
      return;
    }
    _lastBatterySafetyCheckUtc = now;
    // This is deliberately scheduled after the current platform event. A
    // native stop drains that event queue, so stopping inline here could wait
    // on the event currently being processed.
    unawaited(_enqueueNativeLifecycle(_enforceRuntimeBatterySafety));
  }

  Future<void> _enforceRuntimeBatterySafety() async {
    final platform = _platform;
    final capabilities = _lastKnownCapabilities;
    if (!_nativeTracking ||
        platform == null ||
        capabilities?.batteryStateAvailable != true) {
      return;
    }
    TripTrackingBatterySnapshot snapshot;
    try {
      snapshot = await platform.readBatterySnapshot();
    } catch (_) {
      // An unavailable battery bridge must not fabricate a low-battery stop.
      return;
    }
    final decision = _policy.gpsBatteryDecision(
      batteryPercent: snapshot.batteryPercent,
      isCharging: snapshot.isCharging,
      lowPowerModeEnabled:
          capabilities!.lowPowerModeAvailable && snapshot.lowPowerModeEnabled,
      lowBatteryProtectionEnabled: _lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: _lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: _lowBatteryWarningDismissed,
    );
    if (decision.allowsGps) return;
    _platformStatus = decision.reasonCode;
    _platformError = _gpsBatteryMessageFor(decision);
    await _stopNativeTracking();
    // Stopping the optional collector must not erase the actionable reason.
    // The local TripLog remains active and the user can make a new explicit
    // decision after charging or changing the GPS battery preference.
    _platformStatus = decision.reasonCode;
    notifyListeners();
  }

  /// A native collector can enforce the critical cutoff while Dart is asleep.
  /// Keep that distinct, actionable state instead of presenting a generic GPS
  /// failure; local work and odometer truth remain intact.
  Future<void> _handleNativeCriticalBatteryStop(String message) async {
    if (_isDisposed) return;
    await _stopNativeTracking();
    _platformStatus = 'battery_critical_gps_blocked';
    _platformError = message;
    notifyListeners();
  }

  Future<void> _cancelPlatformSubscriptionAfterNativeStop() async {
    final subscription = _platformSubscription;
    if (subscription == null) return;
    try {
      await subscription.cancel();
    } catch (error) {
      _platformError ??= 'Could not detach GPS event listener cleanly.';
    }
  }

  Future<void> _markGpsSignalStaleIfNeeded(DateTime nowUtc) async {
    final session = _session;
    final lastEvidence =
        _lastNativeLocationReceivedUtc ?? _nativeTrackingStartedAtUtc;
    if (session == null || lastEvidence == null) return;
    if (nowUtc.difference(lastEvidence) <= _policy.maximumGap) return;
    _platformStatus = 'gps_signal_stale';
    _platformError =
        'GPS has not produced a location fix recently. Your local trip is preserved while signal recovers.';
    if (session.lifecycleState ==
            TripTrackingSessionLifecycleState.activeTracking ||
        session.lifecycleState ==
            TripTrackingSessionLifecycleState.awaitingInitialFix) {
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.signalDegraded,
        health: TripTrackingHealthState.reduced,
      );
    }
  }

  Future<void> _maybeUpdateNativeSampling(
    TripLocationSample sample,
    TripSampleDecision? decision,
  ) async {
    final platform = _platform;
    final session = _session;
    final current = _nativeSampling;
    final candidate = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: _policy,
      profile: session?.profile ?? TripTrackingProfile.roadVehicle,
      sample: sample,
      decision: decision,
      current: current,
      adaptiveSamplingEnabled: _adaptiveSamplingEnabled,
      nativeTracking: _nativeTracking,
      platformAvailable: platform != null,
      sessionAvailable: session != null,
    );
    if (platform == null || session == null || candidate == null) {
      return;
    }
    final next = _nativeSamplingPlan?.constrainAdaptive(candidate) ?? candidate;
    if (TripTrackingNativeSamplingPolicy.isSameRecommendation(current, next)) {
      return;
    }
    bool updated;
    try {
      updated = await platform.update(
        TripTrackingNativeRequest(
          profile: session.profile,
          sampling: next,
          allowBackground: _backgroundTrackingAllowed,
          activityRecognitionEnabled: _activityRecognitionEnabled,
        ),
      );
    } catch (error) {
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'Could not update GPS sampling.',
      );
      notifyListeners();
      return;
    }
    if (updated) {
      _nativeSampling = next;
      await _persistNativeCollectionPreferences(
        allowBackground: _backgroundTrackingAllowed,
        activityRecognitionEnabled: _activityRecognitionEnabled,
        nativeSampling: next,
      );
    } else {
      _platformError =
          'The device could not apply the updated GPS sampling mode.';
      notifyListeners();
    }
  }

  Future<void> stopNativeTracking() =>
      _enqueueNativeLifecycle(() => _stopNativeTracking(systemPause: false));

  Future<bool> pauseByUser() => _enqueueNativeLifecycle(() async {
    final session = _session;
    if (session == null || !isTracking) return false;
    await _stopNativeTracking(systemPause: false);
    return _session?.lifecycleState ==
        TripTrackingSessionLifecycleState.pausedByUser;
  });

  Future<bool> resumeByUser({
    required bool allowBackground,
    bool activityRecognitionEnabled = false,
  }) => startNativeTracking(
    allowBackground: allowBackground,
    activityRecognitionEnabled: activityRecognitionEnabled,
  );

  /// Withdraw optional motion-sensor assistance from an active collector.
  ///
  /// This is deliberately one-way for a running session: enabling a sensor
  /// later would require a fresh permission/capability decision, so it applies
  /// only when the next GPS session is started. Disabling must take effect now.
  Future<void> disableActivityRecognition() =>
      _enqueueNativeLifecycle(_disableActivityRecognition);

  Future<void> _disableActivityRecognition() async {
    if (!_activityRecognitionEnabled) return;
    _activityRecognitionEnabled = false;
    _latestActivity = null;
    if (!await _persistNativeCollectionPreferences(
      allowBackground: _backgroundTrackingAllowed,
      activityRecognitionEnabled: false,
    )) {
      _platformError =
          'Motion activity was disabled, but GPS tracking stopped because the privacy change could not be saved locally.';
      await _stopNativeTracking();
      return;
    }
    final platform = _platform;
    final session = _session;
    final sampling = _nativeSampling;
    if (!_nativeTracking || platform == null || session == null) {
      notifyListeners();
      return;
    }
    if (sampling == null) {
      // Legacy recoveries can lack a persisted sampling request. Continuing
      // would leave us unable to prove that the native motion sensor was
      // withdrawn, so stop the collector rather than retaining optional
      // sensor access after the driver opted out.
      _platformError =
          'Motion activity was disabled, but GPS tracking stopped because the recovered sampling state was unavailable.';
      await _stopNativeTracking();
      return;
    }
    try {
      final updated = await platform.update(
        TripTrackingNativeRequest(
          profile: session.profile,
          sampling: sampling,
          allowBackground: _backgroundTrackingAllowed,
          activityRecognitionEnabled: false,
        ),
      );
      if (updated) {
        notifyListeners();
        return;
      }
    } catch (_) {
      // A failed native update leaves the optional sensor state uncertain.
    }
    _platformError =
        'Motion activity was disabled, but GPS tracking stopped because the device could not apply that privacy change.';
    await _stopNativeTracking();
  }

  /// Foreground-only tracking must never continue after the app leaves the
  /// foreground. Background collection remains an explicit user setting and
  /// is separately permission-gated by [startNativeTracking]. Serializing this
  /// with native start/stop prevents a lifecycle transition from racing a
  /// just-started collector.
  Future<void> handleAppLifecycleState(
    AppLifecycleState state, {
    required bool backgroundTrackingAllowed,
  }) => _enqueueNativeLifecycle(() async {
    // The UI-provided preference is not authority by itself: it can be stale
    // across a settings change or process restoration. Continuing collection
    // in the background requires both that current preference and the
    // consent durably bound to this native collector at startup.
    final mayContinueInBackground =
        backgroundTrackingAllowed && _backgroundTrackingAllowed;
    if (state == AppLifecycleState.resumed && mayContinueInBackground) {
      await _enforceRuntimeBatterySafety();
      if (!_nativeTracking) return;
      await _checkNativeHeartbeat();
      return;
    }
    if (mayContinueInBackground ||
        (state != AppLifecycleState.paused &&
            state != AppLifecycleState.hidden &&
            state != AppLifecycleState.detached)) {
      return;
    }
    await _stopNativeTracking();
  });

  /// Reconciles the expected native collector after an app resume. This never
  /// creates distance, stops, or odometer changes; it only preserves the
  /// local session lifecycle for user-directed recovery.
  Future<TripTrackingHeartbeatWatchdogDecision?> checkNativeHeartbeat({
    DateTime? nowUtc,
  }) => _enqueueNativeLifecycle(() => _checkNativeHeartbeat(nowUtc: nowUtc));

  Future<TripTrackingHeartbeatWatchdogDecision?> _checkNativeHeartbeat({
    DateTime? nowUtc,
  }) async {
    final session = _session;
    if (_isDisposed || session == null) return null;
    final now = (nowUtc ?? _clockNow()).toUtc();
    final platform = _platform;
    var providerRunning = false;
    var providerProbeSucceeded = false;
    if (_nativeTracking && platform != null) {
      try {
        providerRunning = await platform.isTracking;
        providerProbeSucceeded = true;
      } catch (_) {
        // The heartbeat policy below will preserve the local trip and surface
        // a recoverable state instead of trusting an unavailable bridge.
      }
    }
    if (providerProbeSucceeded && !providerRunning) {
      const decision = TripTrackingHeartbeatWatchdogDecision(
        status: TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
        action: TripTrackingHeartbeatWatchdogAction.markInterrupted,
        reasonCode: 'heartbeat_interrupted_recovery_required',
        targetLifecycle: TripTrackingSessionLifecycleState.signalLost,
        canBridgeDistanceGap: false,
        shouldRetryNativeTracking: true,
        requiresUserReview: true,
      );
      await _handleNativeInterruption(
        'GPS tracking is no longer running. Your local trip is preserved for review.',
      );
      return decision;
    }
    if (providerRunning) {
      _lastNativeHeartbeatUtc = now;
    }
    final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
      currentLifecycle: session.lifecycleState,
      lastHeartbeatUtc: _lastNativeHeartbeatUtc,
      nowUtc: now,
      nativeTrackingExpected: _nativeTracking,
    );
    switch (decision.action) {
      case TripTrackingHeartbeatWatchdogAction.continueTracking:
        if (providerRunning && _nativeTracking) {
          _platformStatus = 'tracking';
          _platformError = null;
          notifyListeners();
        }
        break;
      case TripTrackingHeartbeatWatchdogAction.markDegraded:
        _platformStatus = 'native_heartbeat_stale';
        _platformError =
            'GPS tracking has not reported recently. Your local trip is preserved while it recovers.';
        await _tryTransitionSession(
          TripTrackingSessionLifecycleState.signalDegraded,
          health: TripTrackingHealthState.reduced,
        );
        notifyListeners();
        break;
      case TripTrackingHeartbeatWatchdogAction.markInterrupted:
        await _handleNativeInterruption(
          'GPS tracking stopped responding. Your local trip is preserved for review.',
        );
        break;
      case TripTrackingHeartbeatWatchdogAction.preservePaused ||
          TripTrackingHeartbeatWatchdogAction.protectTerminal ||
          TripTrackingHeartbeatWatchdogAction.ignoreInvalidClock:
        break;
    }
    return decision;
  }

  Future<void> _stopNativeTracking({
    bool interrupted = false,
    bool systemPause = true,
  }) async {
    final platform = _platform;
    final wasNativeTracking = _nativeTracking;
    if (wasNativeTracking) _nativeStopRequested = true;
    if (platform != null && wasNativeTracking) {
      try {
        await platform.stop();
      } catch (error) {
        _platformError = 'The device could not cleanly stop GPS tracking.';
      }
    }
    try {
      await _platformSubscription?.cancel();
    } catch (error) {
      _platformError ??= 'Could not detach GPS event listener cleanly.';
    } finally {
      _platformSubscription = null;
    }
    // Drain events emitted just before the native stop/cancel boundary so a
    // final credible sample cannot be dropped before review is recorded.
    await _platformEventQueue;
    _nativeTracking = false;
    _nativeSampling = null;
    _nativeSamplingPlan = null;
    _lastNativeHeartbeatUtc = null;
    _nativeTrackingStartedAtUtc = null;
    _lastNativeLocationReceivedUtc = null;
    _lastBatterySafetyCheckUtc = null;
    _nativeStopRequested = false;
    _backgroundTrackingAllowed = false;
    _latestActivity = null;
    _platformStatus = interrupted ? 'interrupted' : 'stopped';
    final currentState = _session?.lifecycleState;
    final targetState = systemPause
        ? TripTrackingSessionLifecycleState.pausedBySystem
        : TripTrackingSessionLifecycleState.pausedByUser;
    if (!interrupted &&
        currentState != null &&
        TripTrackingSessionStateMachine.canTransition(
          currentState,
          targetState,
        )) {
      await _tryTransitionSession(targetState);
    }
    notifyListeners();
  }

  void _clearPendingNativeStart() {
    _pendingNativeStartRequest = null;
    _pendingNativeStartActivityUnavailable = false;
    _pendingNativeStartPreferenceSaveFailed = false;
    _pendingNativeStartStopped = false;
    _pendingNativeStartAuthorizationRevoked = false;
  }

  /// Platform callbacks are serialized by [_platformEventQueue]. Stopping the
  /// collector drains that queue, so cleanup must begin only after the current
  /// callback has completed instead of waiting on its own in-flight future.
  void _deferPlatformCleanup(Future<void> Function() operation) {
    unawaited(Future<void>.delayed(Duration.zero, operation));
  }

  Future<T> _enqueueNativeLifecycle<T>(Future<T> Function() operation) {
    final next = _nativeLifecycleQueue.then<T>((_) => operation());
    _nativeLifecycleQueue = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }

  Future<T> _enqueueIngestion<T>(Future<T> Function() operation) {
    final next = _ingestionQueue.then<T>((_) => operation());
    _ingestionQueue = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }

  Future<void> _transitionSession(
    TripTrackingSessionLifecycleState next, {
    TripTrackingHealthState? health,
    DateTime? eventTimestamp,
    String reasonCode = 'lifecycle_condition_changed',
    String initiatingSource = 'coordinator',
  }) async {
    final session = _session;
    if (session == null || session.lifecycleState == next) return;
    final result = await _sessionStore.commitTransition(
      sessionId: session.id,
      expectedRevision: session.revision,
      nextState: next,
      eventTimestamp: eventTimestamp ?? _clockNow(),
      healthState: health,
      reasonCode: reasonCode,
      initiatingSource: initiatingSource,
    );
    _session = result.session;
    if (!result.accepted) {
      throw StateError('Illegal GPS session transition was rejected safely.');
    }
  }

  Future<bool> _tryTransitionSession(
    TripTrackingSessionLifecycleState next, {
    TripTrackingHealthState? health,
  }) async {
    try {
      await _transitionSession(next, health: health);
      return true;
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save trip recovery state locally.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _persistNativeCollectionPreferences({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
    TripSamplingRecommendation? nativeSampling,
    TripSamplingRecommendation? samplingCeiling,
    bool clearSamplingCeiling = false,
    bool? adaptiveSamplingEnabled,
    bool? lowBatteryProtectionEnabled,
    bool? lowBatteryOverrideEnabled,
    bool? lowBatteryWarningDismissed,
  }) async {
    final session = _session;
    if (session == null) return false;
    if (session.backgroundTrackingAllowed == allowBackground &&
        session.activityRecognitionEnabled == activityRecognitionEnabled &&
        (nativeSampling == null ||
            TripTrackingNativeSamplingPolicy.isSameRecommendation(
              session.nativeSampling,
              nativeSampling,
            )) &&
        (!clearSamplingCeiling &&
            (samplingCeiling == null ||
                TripTrackingNativeSamplingPolicy.isSameRecommendation(
                  session.samplingCeiling,
                  samplingCeiling,
                ))) &&
        (adaptiveSamplingEnabled == null ||
            session.adaptiveSamplingEnabled == adaptiveSamplingEnabled) &&
        (lowBatteryProtectionEnabled == null ||
            session.lowBatteryProtectionEnabled ==
                lowBatteryProtectionEnabled) &&
        (lowBatteryOverrideEnabled == null ||
            session.lowBatteryOverrideEnabled == lowBatteryOverrideEnabled) &&
        (lowBatteryWarningDismissed == null ||
            session.lowBatteryWarningDismissed == lowBatteryWarningDismissed)) {
      return true;
    }
    final next = session.copyWith(
      updatedAt: _clockNow(),
      backgroundTrackingAllowed: allowBackground,
      activityRecognitionEnabled: activityRecognitionEnabled,
      nativeSampling: nativeSampling,
      samplingCeiling: samplingCeiling,
      clearSamplingCeiling: clearSamplingCeiling,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    );
    try {
      _session = await _sessionStore.checkpoint(
        next,
        expectedRevision: session.revision,
      );
      return true;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError =
          'Could not save GPS background tracking permission locally.';
      notifyListeners();
      return false;
    }
  }

  TripTrackingHealthState _healthAfterDecision(
    TripTrackingHealthState current,
    TripSampleDecision decision,
  ) => switch (decision.disposition) {
    TripSampleDisposition.acceptedAnchor ||
    TripSampleDisposition.acceptedDistance => TripTrackingHealthState.healthy,
    TripSampleDisposition.rejectedAccuracy => TripTrackingHealthState.poor,
    TripSampleDisposition.rejectedGap => TripTrackingHealthState.interrupted,
    _ => current,
  };

  TripTrackingSessionLifecycleState _lifecycleAfterDecision(
    TripTrackingSessionLifecycleState current,
    TripSampleDecision decision,
  ) {
    if (decision.disposition == TripSampleDisposition.rejectedAccuracy &&
        current == TripTrackingSessionLifecycleState.activeTracking) {
      return TripTrackingSessionLifecycleState.signalDegraded;
    }
    if (decision.disposition == TripSampleDisposition.rejectedGap &&
        (current == TripTrackingSessionLifecycleState.activeTracking ||
            current == TripTrackingSessionLifecycleState.signalDegraded)) {
      return TripTrackingSessionLifecycleState.signalLost;
    }
    if (!decision.accepted) return current;
    return switch (current) {
      TripTrackingSessionLifecycleState.awaitingInitialFix =>
        TripTrackingSessionLifecycleState.activeTracking,
      TripTrackingSessionLifecycleState.signalDegraded ||
      TripTrackingSessionLifecycleState.recovering =>
        TripTrackingSessionLifecycleState.activeTracking,
      TripTrackingSessionLifecycleState.signalLost =>
        TripTrackingSessionLifecycleState.recovering,
      _ => current,
    };
  }

  Future<void> _recordInitialFixRejection({
    required TripTrackingSessionRecord session,
    required TripInitialFixDecision decision,
    required DateTime receivedAt,
    required TripTrackingEngineSnapshot engineSnapshot,
  }) async {
    final checkpoint = await _sessionStore.checkpoint(
      session.copyWith(updatedAt: receivedAt, engineSnapshot: engineSnapshot),
      expectedRevision: session.revision,
    );
    final result = await _sessionStore.commitTransition(
      sessionId: session.id,
      expectedRevision: checkpoint.revision,
      nextState: session.lifecycleState,
      eventTimestamp: receivedAt,
      reasonCode: decision.reasonCode,
      initiatingSource: 'initial_fix_classifier',
      confidenceState: decision.confidence.name,
      permissionState:
          decision.classification ==
              TripInitialFixClassification.approximateOnly
          ? 'approximate_only'
          : 'precise',
      trackingQualityMode: decision.classification.name,
    );
    _session = result.session;
    if (!result.accepted) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not preserve initial GPS fix diagnostics.';
    }
  }

  TripSampleDisposition _initialFixRejectionDisposition(
    TripInitialFixDecision decision,
    TripLocationSample sample,
  ) {
    if (sample.mockedLocation == true) {
      return TripSampleDisposition.rejectedMockLocation;
    }
    return switch (decision.classification) {
      TripInitialFixClassification.staleCached =>
        TripSampleDisposition.rejectedOutOfOrder,
      TripInitialFixClassification.approximateOnly =>
        TripSampleDisposition.rejectedAccuracy,
      _ => TripSampleDisposition.rejectedInvalid,
    };
  }

  /// Persists that a driver reviewed a GPS-assisted possible-stop cue.
  Future<void> acknowledgeLatestStopReview() =>
      reviewLatestStopAdvisory(TripTrackingAdvisoryDisposition.confirmed);

  Future<void> reviewLatestStopAdvisory(
    TripTrackingAdvisoryDisposition disposition,
  ) async {
    if (!TripStopAdvisoryReviewer.isFinalReviewDisposition(disposition)) {
      return;
    }
    final session = _session;
    final engine = _engine;
    if (session == null || engine == null) return;

    final reviewingWalkingStop = engine.needsWalkingReview;
    final latestPendingStopIndex =
        TripStopAdvisoryReviewer.latestPendingStopReviewIndex(
          session,
          preferHighConfidence: reviewingWalkingStop,
        );
    if (!reviewingWalkingStop && latestPendingStopIndex < 0) return;
    if (reviewingWalkingStop) engine.acknowledgeWalkingReview();
    final reviewedAdvisories = [...session.advisories];
    if (latestPendingStopIndex >= 0) {
      reviewedAdvisories[latestPendingStopIndex] =
          reviewedAdvisories[latestPendingStopIndex].copyWith(
            disposition: disposition,
          );
    }
    final next = session.copyWith(
      updatedAt: _clockNow(),
      engineSnapshot: engine.snapshot,
      advisories: reviewedAdvisories,
    );
    _session = await _sessionStore.checkpoint(
      next,
      expectedRevision: session.revision,
    );
    notifyListeners();
  }

  /// Backward-compatible walking stop review hook used by existing UI/tests.
  Future<void> acknowledgeWalkingReview() => acknowledgeLatestStopReview();

  /// Drops a just-created trip only when it has not accepted any distance.
  /// This is used after permission or hardware startup fails so the global
  /// odometer is not left locked by a trip that never actually began.
  Future<bool> discardEmptyTrip() =>
      _runExclusiveSessionOperation(false, _discardEmptyTrip);

  Future<bool> cancelSession({
    required bool userConfirmed,
    String reasonCode = 'user_cancelled',
    DateTime? cancelledAt,
  }) => _runExclusiveSessionOperation(
    false,
    () => _cancelSession(
      userConfirmed: userConfirmed,
      reasonCode: reasonCode,
      cancelledAt: cancelledAt,
    ),
  );

  Future<bool> _cancelSession({
    required bool userConfirmed,
    required String reasonCode,
    DateTime? cancelledAt,
  }) async {
    final session = _session;
    final engine = _engine;
    if (session == null ||
        engine == null ||
        !_isSafeTripTrackingIdentity(reasonCode)) {
      return false;
    }
    final pendingEvidence = _sessionStore.pendingSampleFor(session.id) != null;
    final meaningfulEvidence =
        engine.totalAcceptedMeters > 0 ||
        engine.snapshot.lastObservedAt != null ||
        session.advisories.isNotEmpty ||
        pendingEvidence;
    if (meaningfulEvidence && !userConfirmed) {
      _platformStatus = 'cancellation_confirmation_required';
      _platformError =
          'This trip contains GPS evidence. Confirm cancellation to preserve it in cancelled history.';
      notifyListeners();
      return false;
    }
    final at = cancelledAt ?? _clockNow();
    if (at.isBefore(session.startedAt) ||
        at.toUtc().isAfter(
          _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
        )) {
      return false;
    }
    await stopNativeTracking();
    final beforeCancellation = _session ?? session;
    final cancelled = TripTrackingCancelledSessionRecord(
      sessionId: session.id,
      vehicleId: session.vehicleId,
      profileId: session.profileId,
      startedAt: session.startedAt,
      cancelledAt: at,
      startingOdometer: session.startingOdometer,
      profile: session.profile,
      engineSnapshot: engine.snapshot,
      lifecycleBeforeCancellation: beforeCancellation.lifecycleState,
      reasonCode: reasonCode,
      userConfirmed: userConfirmed,
    );
    try {
      await _sessionStore.saveCancelled(cancelled);
      final transition = await _sessionStore.commitTransition(
        sessionId: beforeCancellation.id,
        expectedRevision: beforeCancellation.revision,
        nextState: TripTrackingSessionLifecycleState.cancelled,
        eventTimestamp: at,
        reasonCode: reasonCode,
        initiatingSource: 'user',
        confidenceState: 'user_confirmed',
        permissionState: 'not_required',
        trackingQualityMode: 'cancelled',
      );
      if (!transition.accepted ||
          !await _sessionStore.clearIfSession(session.id)) {
        throw StateError('Cancellation could not be committed safely.');
      }
    } catch (_) {
      _platformStatus = 'cancellation_save_failed';
      _platformError =
          'The trip remains recoverable because cancellation could not be saved safely.';
      notifyListeners();
      return false;
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    _platformStatus = 'cancelled';
    _platformError = null;
    notifyListeners();
    return true;
  }

  Future<bool> _discardEmptyTrip() async {
    final session = _session;
    if (session == null || acceptedMeters > 0 || _nativeTracking) return false;
    try {
      await _sessionStore.clearIfSession(session.id);
    } catch (error) {
      // Preserve the checkpoint and odometer projection if its durable delete
      // cannot be confirmed. A later retry is safer than inventing a clean
      // state while stale trip data may still exist on disk.
      _platformStatus = 'discard_failed';
      _platformError = 'Could not discard the empty trip locally.';
      notifyListeners();
      return false;
    }
    try {
      await _sessionStore.clearPending(session.id);
    } catch (error) {
      _platformStatus = 'pending_cleanup_failed';
      _platformError = 'Could not clear transient GPS recovery data.';
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    notifyListeners();
    return true;
  }

  /// Durably stores a review record before dropping crash-recovery state.
  /// The confirmed odometer stays untouched until a later review action makes
  /// one auditable permanent odometer event.
  Future<TripTrackingReviewRecord?> finishForReview({DateTime? finishedAt}) =>
      _runExclusiveSessionOperation(
        null,
        () => _finishForReview(finishedAt: finishedAt),
      );

  Future<TripTrackingReviewRecord?> _finishForReview({
    DateTime? finishedAt,
  }) async {
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;
    final completedAt = finishedAt ?? _clockNow();
    if (completedAt.isBefore(session.startedAt)) {
      _platformStatus = 'review_timeline_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is before the start time.';
      notifyListeners();
      return null;
    }
    if (completedAt.toUtc().isAfter(
      _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'review_finish_time_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is too far in the future.';
      notifyListeners();
      return null;
    }
    if (session.lifecycleState != TripTrackingSessionLifecycleState.stopping &&
        TripTrackingSessionStateMachine.canTransition(
          session.lifecycleState,
          TripTrackingSessionLifecycleState.stopping,
        )) {
      if (!await _tryTransitionSession(
        TripTrackingSessionLifecycleState.stopping,
      )) {
        _platformStatus = 'review_save_failed';
        _platformError =
            'Could not save the completed trip locally. It remains recoverable.';
        notifyListeners();
        return null;
      }
    }
    await stopNativeTracking();
    final stoppedSession = _session;
    if (stoppedSession == null) return null;
    if (stoppedSession.lifecycleState !=
            TripTrackingSessionLifecycleState.completionPending &&
        !await _tryTransitionSession(
          TripTrackingSessionLifecycleState.completionPending,
        )) {
      _platformStatus = 'completion_state_failed';
      _platformError =
          'GPS assistance stopped, but the trip could not enter safe review state.';
      notifyListeners();
      return null;
    }
    final review = TripTrackingReviewRecord(
      id: session.id,
      vehicleId: session.vehicleId,
      startingOdometer: session.startingOdometer,
      estimatedEndingOdometer: projection.updateAcceptedMeters(
        engine.totalAcceptedMeters,
        gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      ),
      profile: session.profile,
      startedAt: session.startedAt,
      finishedAt: completedAt,
      engineSnapshot: engine.snapshot,
    );
    try {
      await _sessionStore.saveReview(review);
    } catch (error) {
      // Keep the active checkpoint and live projection intact. The driver can
      // retry finishing after local storage recovers; clearing here would turn
      // a transient disk failure into lost mileage.
      _platformStatus = 'review_save_failed';
      _platformError =
          'Could not save the completed trip locally. It remains recoverable.';
      notifyListeners();
      return null;
    }
    try {
      await _sessionStore.clearPending(session.id);
    } catch (_) {
      _platformStatus = 'pending_cleanup_failed';
      _platformError = 'Could not flush transient GPS recovery data.';
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    notifyListeners();
    return review;
  }

  Future<void> _flushCloudMirror() async {
    try {
      await _cloudMirror.flushPending();
      if (_cloudMirrorError != null) {
        _cloudMirrorError = null;
        notifyListeners();
      }
    } catch (error) {
      _cloudMirrorError = 'Cloud mileage backup is pending.';
      notifyListeners();
    }
  }
}

bool _isSafeTripTrackingIdentity(String value) {
  final clean = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  return clean == value && clean.isNotEmpty && clean.length <= 160;
}

String _localDayKey(DateTime timestamp) {
  final local = timestamp.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

class TripTrackingScope extends InheritedNotifier<TripTrackingController> {
  const TripTrackingScope({
    super.key,
    required TripTrackingController controller,
    required super.child,
  }) : super(notifier: controller);

  static TripTrackingController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<TripTrackingScope>();
    assert(scope != null, 'TripTrackingScope is missing above this context.');
    return scope!.notifier!;
  }

  static TripTrackingController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TripTrackingScope>()?.notifier;
}
