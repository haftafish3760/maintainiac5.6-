import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';

import '../odometer/odometer_mileage_review.dart';
import '../state/global_odometer.dart';
import 'trip_live_odometer_projection.dart';
import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_calibration_apply_guard.dart';
import 'trip_tracking_durable_record_bridge.dart';
import 'trip_tracking_engine.dart';
import 'trip_tracking_heartbeat_watchdog_policy.dart';
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
import 'trip_tracking_sampling_preset_policy.dart';
import 'trip_tracking_session_store.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_state_machine.dart';
import 'trip_stop_advisory_reviewer.dart';

part 'trip_tracking_controller_native_events.dart';
part 'trip_tracking_controller_ingestion.dart';
part 'trip_tracking_controller_native_collection.dart';
part 'trip_tracking_controller_native_lifecycle.dart';
part 'trip_tracking_controller_odometer_review.dart';
part 'trip_tracking_controller_review_actions.dart';
part 'trip_tracking_controller_session_lifecycle.dart';

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
    DateTime Function()? clockNow,
    DateTime Function()? heartbeatNow,
  }) : _sessionStore = sessionStore,
       _odometer = odometer,
       _platform = platform,
       _policy = policy,
       _cloudMirror = cloudMirror,
       _durableRecordBridge = durableRecordBridge,
       _calibrationState = TripTrackingCalibrationState.initial(
         gpsAssistanceCalibrationMultiplier,
       ),
       _clockNow = clockNow ?? heartbeatNow ?? DateTime.now;

  final TripTrackingSessionStore _sessionStore;
  final GlobalOdometerController _odometer;
  final TripTrackingNativeGateway? _platform;
  final TripTrackingPolicy _policy;
  final TripTrackingCloudMirror _cloudMirror;
  final TripTrackingDurableRecordBridge? _durableRecordBridge;

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
      updatedAt: _clockNow(),
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
      await _sessionStore.save(next);
      _session = next;
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
