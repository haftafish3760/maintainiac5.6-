import 'dart:async';

import 'package:flutter/widgets.dart';

import '../odometer/odometer_mileage_review.dart';
import '../state/global_odometer.dart';
import 'trip_live_odometer_projection.dart';
import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_durable_record_bridge.dart';
import 'trip_tracking_engine.dart';
import 'trip_tracking_firebase_bridge.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_native_error_policy.dart';
import 'trip_tracking_native_sampling_policy.dart';
import 'trip_tracking_odometer_calibration.dart';
import 'trip_tracking_odometer_reconciliation.dart';
import 'trip_tracking_odometer_usage_anomaly.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_recovery_policy.dart';
import 'trip_tracking_session_store.dart';
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
    TripTrackingCloudMirror cloudMirror = const NoopTripTrackingCloudMirror(),
    TripTrackingDurableRecordBridge? durableRecordBridge,
    double gpsAssistanceCalibrationMultiplier = 1,
  }) : _sessionStore = sessionStore,
       _odometer = odometer,
       _platform = platform,
       _policy = policy,
       _cloudMirror = cloudMirror,
       _durableRecordBridge = durableRecordBridge,
       _calibrationState = TripTrackingCalibrationState.initial(
         gpsAssistanceCalibrationMultiplier,
       );

  final TripTrackingSessionStore _sessionStore;
  final GlobalOdometerController _odometer;
  final TripTrackingNativeGateway? _platform;
  final TripTrackingPolicy _policy;
  final TripTrackingCloudMirror _cloudMirror;
  final TripTrackingDurableRecordBridge? _durableRecordBridge;
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
  bool _nativeTracking = false;
  bool _nativeInterruptionPending = false;
  TripSamplingRecommendation? _nativeSampling;
  bool _activityRecognitionEnabled = false;
  bool _adaptiveSamplingEnabled = true;
  String? _platformStatus;
  String? _platformError;
  String? _cloudMirrorError;
  String? _durableRecordError;
  TripActivityObservation? _latestActivity;
  TripTrackingPlatformCapabilities? _lastKnownCapabilities;

  TripTrackingSessionRecord? get activeSession => _session;
  bool get isTracking => _session != null;
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
  bool get hasDurableRecordBridge => _durableRecordBridge != null;
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
    nowUtc: nowUtc,
  );

  void refreshGpsAssistanceCalibration({required bool enabled}) {
    final next = _calibrationState.refresh(
      enabled: enabled,
      signal: odometerCalibrationSignal(),
    );
    if (identical(next, _calibrationState)) return;
    _calibrationState = next;
    notifyListeners();
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
    return odometerUsageAnomalySignal(
      currentOdometerMiles: miles,
      nowUtc: nowUtc,
    );
  }

  Future<bool> confirmOdometerReview({
    required String reviewId,
    required int confirmedEndingOdometer,
    DateTime? confirmedAt,
  }) async {
    final review = _sessionStore.reviewForTrip(reviewId);
    if (review == null ||
        !review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        review.vehicleId.trim().isEmpty ||
        review.isOdometerConfirmed ||
        review.vehicleId != _odometer.vehicleId ||
        review.estimatedEndingOdometer < review.startingOdometer ||
        confirmedEndingOdometer < review.startingOdometer) {
      return false;
    }
    final confirmationTime = confirmedAt ?? DateTime.now();
    if (confirmationTime.isBefore(review.finishedAt)) return false;
    if (confirmationTime.toUtc().isAfter(
      DateTime.now().toUtc().add(_policy.maximumFutureSampleSkew),
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
    if (_platformStatus == 'review_confirmation_save_failed') {
      _platformStatus = null;
      _platformError = null;
    }
    await _saveDurableReviewedTrip(confirmedReview);
    _calibrationState = _calibrationState.refreshEnabled(
      odometerCalibrationSignal(),
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
      await bridge.saveReviewedTrip(review);
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
          await bridge.saveReviewedTrip(review);
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
    _isDisposed = true;
    unawaited(_platformSubscription?.cancel());
    _platformSubscription = null;
    _cloudMirror.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<bool> start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    DateTime? startedAt,
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
    try {
      // Reviews are stored by trip id. Reusing an id would otherwise replace
      // an existing locally durable audit record when the new trip finishes.
      if (_sessionStore.recoveryReviewForTrip(tripId) != null) return false;
    } catch (error) {
      // Do not start GPS or alter the live odometer when we cannot establish
      // that the immutable local review history is available.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip locally.';
      notifyListeners();
      return false;
    }
    final now = DateTime.now();
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
    if (!_odometer.beginLiveTripProjection(
      tripId: tripId,
      startingOdometer: startingOdometer,
      observedAtUtc: started,
    )) {
      return false;
    }
    _engine = TripTrackingEngine(policy: _policy, profile: profile);
    _projection = TripLiveOdometerProjection(
      startingOdometer: startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    _activeTripCalibrationMultiplier = gpsAssistanceCalibrationMultiplier;
    _session = TripTrackingSessionRecord(
      id: tripId,
      vehicleId: vehicleId,
      startingOdometer: startingOdometer,
      profile: profile,
      startedAt: started,
      updatedAt: started,
      engineSnapshot: _engine!.snapshot,
    );
    try {
      await _sessionStore.save(_session!);
    } catch (error) {
      // An active trip is only recoverable after its initial local checkpoint
      // succeeds. Do not leave a phantom trip holding the live odometer when
      // storage is unavailable (for example, a full or closed local store).
      try {
        await _sessionStore.clear();
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
    notifyListeners();
    return true;
  }

  Future<bool> restore() async {
    if (_isDisposed || isTracking) return false;
    TripTrackingSessionRecord? session;
    try {
      session = _sessionStore.activeSession;
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip recovery data.';
      notifyListeners();
      return false;
    }
    if (session == null) return false;
    if (!_isRecoverableSession(session)) {
      try {
        await _sessionStore.clear();
      } catch (error) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not remove invalid local trip data.';
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
      try {
        await _sessionStore.clear();
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
          _nativeTracking = true;
          _platformStatus = 'tracking';
          _platformSubscription = _listenToPlatformEvents(platform);
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
        TripTrackingSessionLifecycleState.ready ||
        TripTrackingSessionLifecycleState.starting ||
        TripTrackingSessionLifecycleState.active ||
        TripTrackingSessionLifecycleState.paused ||
        TripTrackingSessionLifecycleState.degraded ||
        TripTrackingSessionLifecycleState.interrupted ||
        TripTrackingSessionLifecycleState.recovering ||
        TripTrackingSessionLifecycleState.stopping ||
        TripTrackingSessionLifecycleState.failedRecoverable => true,
        TripTrackingSessionLifecycleState.disabled ||
        TripTrackingSessionLifecycleState.permissionRequired ||
        TripTrackingSessionLifecycleState.awaitingReview ||
        TripTrackingSessionLifecycleState.completed ||
        TripTrackingSessionLifecycleState.failedTerminal => false,
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

    if (sample.recordedAt.toUtc().isBefore(session.startedAt.toUtc())) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }

    if (referenceTime != null &&
        sample.recordedAt.toUtc().isAfter(
          referenceTime.toUtc().add(engine.policy.maximumFutureSampleSkew),
        )) {
      return engine.reject(TripSampleDisposition.rejectedFutureTimestamp);
    }

    if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) {
      return engine.reject(TripSampleDisposition.rejectedInvalid);
    }

    if (sample.mockedLocation != true) {
      await _sessionStore.savePending(
        TripTrackingPendingSample(
          sessionId: session.id,
          sample: sample,
          activity: activity,
        ),
      );
    }

    final previousMotionState = engine.motionState;
    final decision = engine.ingest(sample, activity: activity);
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
      final estimatedOdometer = projection.updateAcceptedMeters(
        decision.totalAcceptedMeters,
        gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      );
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
        lifecycleState: naturalLifecycleState,
        healthState: _healthAfterDecision(session.healthState, decision),
      );
      await _sessionStore.save(_session!);
      final liveProjectionUpdated = _odometer.updateLiveTripProjection(
        tripId: session.id,
        estimatedOdometer: estimatedOdometer,
        observedAtUtc: sample.recordedAt,
        receivedAtUtc: referenceTime ?? sample.recordedAt,
      );
      final liveProjectionFailed =
          decision.accepted &&
          (projection.lastUpdateExceededMax || !liveProjectionUpdated);
      if (liveProjectionFailed) {
        _platformStatus = 'odometer_projection_invalid';
        _platformError =
            'GPS distance exceeded the supported live odometer range. Review the trip before continuing.';
        if (TripTrackingSessionStateMachine.canTransition(
          _session!.lifecycleState,
          TripTrackingSessionLifecycleState.failedRecoverable,
        )) {
          _session = _session!.copyWith(
            lifecycleState: TripTrackingSessionLifecycleState.failedRecoverable,
            healthState: TripTrackingHealthState.unavailable,
          );
          await _sessionStore.save(_session!);
        }
      }
      notifyListeners();
    }
    await _sessionStore.clearPending(session.id);
    return decision;
  }

  /// Starts the platform collector only after an active trip exists. Native
  /// samples are queued one at a time so a fast EventChannel cannot reorder
  /// distance decisions or overwrite a newer recovery snapshot.
  Future<bool> startNativeTracking({
    required bool allowBackground,
    double? observedSpeedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingRecommendation? samplingOverride,
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
      TripTrackingSessionLifecycleState.starting,
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
      _platformError = 'Could not request GPS permission.';
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
        TripTrackingSessionLifecycleState.permissionRequired,
        health: TripTrackingHealthState.permissionBlocked,
      );
      notifyListeners();
      return false;
    }
    _latestActivity = null;
    _platformSubscription = _listenToPlatformEvents(platform);
    final request = TripTrackingNativeRequest(
      profile: session.profile,
      sampling:
          samplingOverride ??
          _policy.samplingFor(
            speedMetersPerSecond: observedSpeedMetersPerSecond,
            vehicleMovementConfirmed: vehicleMovementConfirmed,
            profile: session.profile,
            activeTrip: true,
          ),
      activityRecognitionEnabled: requestedActivityRecognition,
    );
    bool started;
    try {
      started = await platform.start(request);
    } catch (error) {
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = 'The device could not start GPS trip tracking.';
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
    _nativeTracking = true;
    _nativeSampling = request.sampling;
    _activityRecognitionEnabled = requestedActivityRecognition;
    _adaptiveSamplingEnabled = adaptiveSamplingEnabled;
    _platformError = null;
    _platformStatus = 'tracking';
    if (!await _tryTransitionSession(
      TripTrackingSessionLifecycleState.active,
      health: TripTrackingHealthState.healthy,
    )) {
      try {
        await platform.stop();
      } catch (_) {
        // The local persistence failure is already surfaced. The platform
        // service also has its own cleanup path if this best-effort stop fails.
      }
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _nativeTracking = false;
      _nativeSampling = null;
      return false;
    }
    notifyListeners();
    return true;
  }

  String _gpsBatteryMessageFor(TripGpsBatteryDecision decision) {
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
      unawaited(_handleNativeInterruption('GPS updates ended unexpectedly.'));
    },
  );

  Future<void> _handleNativeInterruption(String message) async {
    if (_isDisposed || _nativeInterruptionPending) return;
    _nativeInterruptionPending = true;
    try {
      _platformError = message;
      _platformStatus = 'error';
      if (_session?.lifecycleState ==
              TripTrackingSessionLifecycleState.active ||
          _session?.lifecycleState ==
              TripTrackingSessionLifecycleState.degraded) {
        await _tryTransitionSession(
          TripTrackingSessionLifecycleState.interrupted,
          health: TripTrackingHealthState.interrupted,
        );
      }
      notifyListeners();
      await stopNativeTracking();
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
              referenceTime: DateTime.now().toUtc(),
            );
            await _maybeUpdateNativeSampling(event.location!, decision);
          } else if (event.activity != null) {
            if (!_nativeTracking) return;
            _latestActivity = event.activity;
          } else if (event.type == TripTrackingPlatformEventType.status) {
            final status = event.status;
            if (status == 'stopped') {
              _platformStatus = status;
              _nativeTracking = false;
              _nativeSampling = null;
              _latestActivity = null;
              await _cancelPlatformSubscriptionAfterNativeStop();
              _platformSubscription = null;
              if (_session?.lifecycleState ==
                  TripTrackingSessionLifecycleState.active) {
                await _tryTransitionSession(
                  TripTrackingSessionLifecycleState.paused,
                );
              }
            } else if (status == 'tracking' && _nativeTracking) {
              _platformStatus = status;
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
            if (_nativeTracking &&
                TripTrackingNativeErrorPolicy.requiresRecovery(
                  event.errorCode,
                )) {
              unawaited(_handleNativeInterruption(message));
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

  Future<void> _cancelPlatformSubscriptionAfterNativeStop() async {
    final subscription = _platformSubscription;
    if (subscription == null) return;
    try {
      await subscription.cancel();
    } catch (error) {
      _platformError ??= 'Could not detach GPS event listener cleanly.';
    }
  }

  Future<void> _maybeUpdateNativeSampling(
    TripLocationSample sample,
    TripSampleDecision? decision,
  ) async {
    final platform = _platform;
    final session = _session;
    final current = _nativeSampling;
    final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
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
    if (platform == null || session == null || next == null) {
      return;
    }
    bool updated;
    try {
      updated = await platform.update(
        TripTrackingNativeRequest(
          profile: session.profile,
          sampling: next,
          activityRecognitionEnabled: _activityRecognitionEnabled,
        ),
      );
    } catch (error) {
      _platformError = 'Could not update GPS sampling.';
      notifyListeners();
      return;
    }
    if (updated) {
      _nativeSampling = next;
    } else {
      _platformError =
          'The device could not apply the updated GPS sampling mode.';
      notifyListeners();
    }
  }

  Future<void> stopNativeTracking() =>
      _enqueueNativeLifecycle(_stopNativeTracking);

  /// Foreground-only tracking must never continue after the app leaves the
  /// foreground. Background collection remains an explicit user setting and
  /// is separately permission-gated by [startNativeTracking]. Serializing this
  /// with native start/stop prevents a lifecycle transition from racing a
  /// just-started collector.
  Future<void> handleAppLifecycleState(
    AppLifecycleState state, {
    required bool backgroundTrackingAllowed,
  }) => _enqueueNativeLifecycle(() async {
    if (backgroundTrackingAllowed ||
        (state != AppLifecycleState.paused &&
            state != AppLifecycleState.detached)) {
      return;
    }
    await _stopNativeTracking();
  });

  Future<void> _stopNativeTracking() async {
    final platform = _platform;
    if (platform != null && _nativeTracking) {
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
    _latestActivity = null;
    _platformStatus = 'stopped';
    if (_session?.lifecycleState == TripTrackingSessionLifecycleState.active ||
        _session?.lifecycleState ==
            TripTrackingSessionLifecycleState.degraded) {
      await _tryTransitionSession(TripTrackingSessionLifecycleState.paused);
    }
    notifyListeners();
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
  }) async {
    final session = _session;
    if (session == null || session.lifecycleState == next) return;
    TripTrackingSessionStateMachine.requireTransition(
      session.lifecycleState,
      next,
    );
    final nextSession = session.copyWith(
      updatedAt: DateTime.now(),
      lifecycleState: next,
      healthState: health,
    );
    await _sessionStore.save(nextSession);
    _session = nextSession;
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
        current == TripTrackingSessionLifecycleState.active) {
      return TripTrackingSessionLifecycleState.degraded;
    }
    if (decision.disposition == TripSampleDisposition.rejectedGap &&
        (current == TripTrackingSessionLifecycleState.active ||
            current == TripTrackingSessionLifecycleState.degraded)) {
      return TripTrackingSessionLifecycleState.interrupted;
    }
    if (!decision.accepted) return current;
    return switch (current) {
      TripTrackingSessionLifecycleState.degraded ||
      TripTrackingSessionLifecycleState.recovering =>
        TripTrackingSessionLifecycleState.active,
      TripTrackingSessionLifecycleState.interrupted =>
        TripTrackingSessionLifecycleState.recovering,
      _ => current,
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
    _session = session.copyWith(
      updatedAt: DateTime.now(),
      engineSnapshot: engine.snapshot,
      advisories: reviewedAdvisories,
    );
    await _sessionStore.save(_session!);
    notifyListeners();
  }

  /// Backward-compatible walking stop review hook used by existing UI/tests.
  Future<void> acknowledgeWalkingReview() => acknowledgeLatestStopReview();

  /// Drops a just-created trip only when it has not accepted any distance.
  /// This is used after permission or hardware startup fails so the global
  /// odometer is not left locked by a trip that never actually began.
  Future<bool> discardEmptyTrip() async {
    final session = _session;
    if (session == null || acceptedMeters > 0 || _nativeTracking) return false;
    try {
      await _sessionStore.clear();
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
  Future<TripTrackingReviewRecord?> finishForReview({
    DateTime? finishedAt,
  }) async {
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;
    final completedAt = finishedAt ?? DateTime.now();
    if (completedAt.isBefore(session.startedAt)) {
      _platformStatus = 'review_timeline_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is before the start time.';
      notifyListeners();
      return null;
    }
    if (completedAt.toUtc().isAfter(
      DateTime.now().toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'review_finish_time_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is too far in the future.';
      notifyListeners();
      return null;
    }
    if (session.lifecycleState == TripTrackingSessionLifecycleState.active ||
        session.lifecycleState == TripTrackingSessionLifecycleState.paused ||
        session.lifecycleState == TripTrackingSessionLifecycleState.degraded) {
      await _tryTransitionSession(TripTrackingSessionLifecycleState.stopping);
    }
    await stopNativeTracking();
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
      await _sessionStore.clear();
    } catch (error) {
      // The review is already durable. Clear the in-memory trip regardless so
      // it cannot be finished twice; restore will treat the review as
      // authoritative and retry cleanup on a future launch.
      _platformStatus = 'review_cleanup_failed';
      _platformError =
          'Trip review was saved, but stale recovery cleanup is pending.';
    }
    try {
      // A review contains only the completed-trip summary. Its transient
      // pending sample can contain a raw location, so it must not linger once
      // the review itself is durable.
      await _sessionStore.clearPending(session.id);
    } catch (error) {
      if (_platformStatus == null) {
        _platformStatus = 'pending_cleanup_failed';
        _platformError = 'Could not clear transient GPS recovery data.';
      }
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
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
