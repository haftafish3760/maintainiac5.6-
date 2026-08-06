import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart';
import '../odometer/odometer_mileage_review.dart';
import '../state/global_odometer.dart';
import 'trip_live_odometer_projection.dart';
import 'trip_driver_pattern_assistant.dart';
import 'trip_driver_pattern_review_adapter.dart';
import 'trip_odometer_end_review_policy.dart';
import 'trip_odometer_calibration_prompt_policy.dart';
import 'trip_signal_quality_action_policy.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_automatic_evidence_candidate.dart';
import 'trip_automatic_evidence_candidate_store.dart';
import 'trip_automatic_evidence_observation_buffer.dart';
import 'trip_automatic_start_detector.dart';
import 'trip_initial_fix_classifier.dart';
import 'trip_boundary_candidate.dart';
import 'trip_failure_classification.dart';
import 'trip_tracking_calibration_state.dart';
import 'trip_tracking_calibration_apply_guard.dart';
import 'trip_tracking_durable_record_bridge.dart';
import 'trip_tracking_engine.dart';
import 'trip_tracking_heartbeat_watchdog_policy.dart';
import 'trip_tracking_backup_port.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_native_error_policy.dart';
import 'trip_tracking_native_sampling_policy.dart';
import 'trip_tracking_odometer_calibration.dart';
import 'trip_tracking_odometer_reconciliation.dart';
import 'trip_tracking_odometer_usage_anomaly.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_policy.dart';
import 'trip_tracking_recovery_policy.dart';
import 'trip_tracking_route_point_store.dart';
import 'trip_tracking_sampling_preset_policy.dart';
import 'trip_tracking_session_recovery_validation.dart';
import 'trip_tracking_session_store.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_signal_quality.dart';
import 'trip_tracking_state_machine.dart';
import 'trip_stop_advisory_reviewer.dart';
import 'trip_tracking_trip_log_proposal.dart';

part 'trip_tracking_controller_native_events.dart';
part 'trip_tracking_controller_ingestion.dart';
part 'trip_tracking_controller_pending_recovery.dart';
part 'trip_tracking_controller_native_collection.dart';
part 'trip_tracking_controller_native_lifecycle.dart';
part 'trip_tracking_controller_runtime_settings.dart';
part 'trip_tracking_controller_odometer_review.dart';
part 'trip_tracking_controller_review_actions.dart';
part 'trip_tracking_controller_session_lifecycle.dart';

bool _isSafeUserEventCommandId(String value) =>
    value.isNotEmpty &&
    value.length <= 96 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

TripTrackingDiagnostics _diagnosticsSince(
  TripTrackingDiagnostics current,
  TripTrackingDiagnostics baseline,
) {
  final received = (current.receivedSamples - baseline.receivedSamples).clamp(
    0,
    current.receivedSamples,
  );
  final accepted = (current.acceptedSamples - baseline.acceptedSamples).clamp(
    0,
    received,
  );
  final counts = <TripSampleDisposition, int>{};
  for (final disposition in TripSampleDisposition.values) {
    final count =
        (current.dispositionCounts[disposition] ?? 0) -
        (baseline.dispositionCounts[disposition] ?? 0);
    if (count > 0) counts[disposition] = count;
  }
  return TripTrackingDiagnostics(
    receivedSamples: received,
    acceptedSamples: accepted,
    dispositionCounts: Map.unmodifiable(counts),
    rejectedDistanceMeters:
        (current.rejectedDistanceMeters - baseline.rejectedDistanceMeters)
            .clamp(0, current.rejectedDistanceMeters),
    estimatedGapDistanceMeters:
        (current.estimatedGapDistanceMeters -
                baseline.estimatedGapDistanceMeters)
            .clamp(0, current.estimatedGapDistanceMeters),
  );
}

/// Owns one active GPS-assisted trip. Platform adapters feed it samples; this
/// controller keeps the UI, local recovery record, and live odometer aligned.
class TripTrackingController extends ChangeNotifier {
  TripTrackingController({
    required TripTrackingSessionStore sessionStore,
    required GlobalOdometerController odometer,
    TripTrackingNativeGateway? platform,
    TripTrackingPolicy policy = const TripTrackingPolicy(),
    TripInitialFixClassifier initialFixClassifier =
        const TripInitialFixClassifier(),
    Duration initialFixPreparationWindow = const Duration(seconds: 45),
    TripTrackingCloudMirror cloudMirror = const NoopTripTrackingCloudMirror(),
    TripTrackingDurableRecordBridge? durableRecordBridge,
    TripTrackingTripLogProposalSink? tripLogProposalSink,
    TripAutomaticEvidenceCandidateStore? automaticEvidenceCandidateStore,
    TripAutomaticEvidenceObservationBuffer? automaticEvidenceObservationBuffer,
    TripTrackingRoutePointStore? routePointStore,
    TripTrackingSettings Function()? routeSettings,
    String Function(DateTime utc)? localRouteDayKey,
    double gpsAssistanceCalibrationMultiplier = 1,
    DateTime Function()? clockNow,
    DateTime Function()? heartbeatNow,
    int Function()? activeVehicleConfigurationRevision,
  }) : _sessionStore = sessionStore,
       _odometer = odometer,
       _platform = platform,
       _policy = policy,
       _initialFixClassifier = initialFixClassifier,
       _initialFixPreparationWindow =
           initialFixPreparationWindow > Duration.zero
           ? initialFixPreparationWindow
           : const Duration(seconds: 45),
       _cloudMirror = cloudMirror,
       _durableRecordBridge = durableRecordBridge,
       _tripLogProposalSink = tripLogProposalSink,
       _automaticEvidenceCandidateStore = automaticEvidenceCandidateStore,
       _automaticEvidenceObservationBuffer =
           automaticEvidenceObservationBuffer ??
           TripAutomaticEvidenceObservationBuffer(),
       _routePointStore = routePointStore,
       _routeSettings = routeSettings,
       _localRouteDayKey = localRouteDayKey,
       _calibrationState = TripTrackingCalibrationState.initial(
         gpsAssistanceCalibrationMultiplier,
       ),
       _activeVehicleConfigurationRevision = activeVehicleConfigurationRevision,
       _clockNow = clockNow ?? heartbeatNow ?? DateTime.now {
    _lastObservedConfirmedOdometer = odometer.confirmedReading;
    odometer.addListener(_handleConfirmedOdometerChanged);
  }

  final TripTrackingSessionStore _sessionStore;
  final GlobalOdometerController _odometer;
  final TripTrackingNativeGateway? _platform;
  final TripTrackingPolicy _policy;
  final TripInitialFixClassifier _initialFixClassifier;
  final Duration _initialFixPreparationWindow;
  final TripTrackingCloudMirror _cloudMirror;
  final TripTrackingDurableRecordBridge? _durableRecordBridge;
  final TripTrackingTripLogProposalSink? _tripLogProposalSink;
  final TripAutomaticEvidenceCandidateStore? _automaticEvidenceCandidateStore;
  final TripAutomaticEvidenceObservationBuffer
  _automaticEvidenceObservationBuffer;
  bool _automaticEvidenceCandidateProposalInFlight = false;
  final TripTrackingRoutePointStore? _routePointStore;
  final TripTrackingSettings Function()? _routeSettings;
  final String Function(DateTime utc)? _localRouteDayKey;
  final int Function()? _activeVehicleConfigurationRevision;

  int get _currentVehicleConfigurationRevision {
    final revision = _activeVehicleConfigurationRevision?.call() ?? 0;
    return revision < 0 ? 0 : revision;
  }

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
  bool _nativeProviderRegistered = false;
  bool _awaitingInitialFix = false;
  // Distinguishes a driver/app-requested shutdown from a collector that
  // stopped on its own. An unexpected stop must remain recoverable evidence,
  // not be silently presented as a normal paused trip.
  bool _nativeStopRequested = false;
  bool _nativeInterruptionPending = false;
  bool _nativeCriticalBatteryStopPending = false;
  bool _signalSafetyPausePending = false;
  TripTrackingDiagnostics? _nativeSignalEpochBaseline;
  TripTrackingNativeRequest? _pendingNativeStartRequest;
  bool _pendingNativeStartActivityUnavailable = false;
  bool _pendingNativeStartPreferenceSaveFailed = false;
  bool _pendingNativeStartStopped = false;
  bool _pendingNativeStartProviderRegistered = false;
  bool _pendingNativeStartAuthorizationRevoked = false;
  String? _pendingNativeStartErrorCode;
  String? _pendingNativeSystemPauseStatus;
  TripSamplingRecommendation? _nativeSampling;
  TripTrackingSamplingPlan? _nativeSamplingPlan;
  int _deviceLocationIntervalFloorSeconds = 1;
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
  String? _tripLogProposalError;
  TripActivityObservation? _latestActivity;
  TripTrackingPlatformCapabilities? _lastKnownCapabilities;
  DateTime? _lastBatterySafetyCheckUtc;
  bool _lowBatteryProtectionEnabled = true;
  bool _lowBatteryOverrideEnabled = false;
  bool _lowBatteryWarningDismissed = false;
  DateTime? _lastRoutePointPersistedAtUtc;
  String? _routeStorageStatus;
  String? _acceptedCalibrationEvidenceSignature;
  int? _lastObservedConfirmedOdometer;

  void _handleConfirmedOdometerChanged() {
    if (_isDisposed) return;
    final confirmed = _odometer.confirmedReading;
    if (_lastObservedConfirmedOdometer == confirmed) return;
    _lastObservedConfirmedOdometer = confirmed;
    final session = _session;
    if (session == null ||
        _projection == null ||
        _odometer.activeLiveTripId != session.id) {
      return;
    }

    final anchorMeters = acceptedMeters;
    _projection = TripLiveOdometerProjection(
      startingOdometer: confirmed,
      acceptedMetersBaseline: anchorMeters,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    final anchoredSession = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session, _clockNow()),
      revision: session.revision + 1,
      projectionAnchorOdometer: confirmed,
      projectionAnchorAcceptedMeters: anchorMeters,
    );
    _session = anchoredSession;
    _ingestionQueue = _ingestionQueue.then((_) async {
      final current = _session;
      if (_isDisposed ||
          current == null ||
          current.id != anchoredSession.id ||
          current.effectiveProjectionAnchorOdometer != confirmed ||
          current.projectionAnchorAcceptedMeters != anchorMeters) {
        return;
      }
      try {
        await _sessionStore.save(current);
      } catch (_) {
        _platformStatus = 'storage_failed';
        _platformError =
            'Your confirmed odometer was saved, but the GPS projection anchor '
            'could not be saved. GPS remains advisory until recovery.';
        notifyListeners();
      }
    });
  }

  TripTrackingSessionRecord? get activeSession => _session;
  bool get isTracking => _session != null;
  double get acceptedMeters => _engine?.totalAcceptedMeters ?? 0;
  double get acceptedMiles => acceptedMeters / metersPerMile;
  bool get awaitingInitialFix => _awaitingInitialFix;
  int get pendingStopReviewCount => advisories
      .where(
        (event) =>
            event.type == TripTrackingAdvisoryType.probableStop &&
            event.disposition == TripTrackingAdvisoryDisposition.pending,
      )
      .length;
  bool get needsWalkingReview =>
      (_engine?.needsWalkingReview ?? false) || pendingStopReviewCount > 0;
  TripMotionState get motionState =>
      _engine?.motionState ?? TripMotionState.unknown;
  TripTrackingDiagnostics get diagnostics =>
      _engine?.snapshot.diagnostics ?? const TripTrackingDiagnostics();
  TripTrackingSignalQualitySummary get cumulativeSignalQualitySummary =>
      TripTrackingSignalQualitySummary.evaluate(diagnostics);
  TripTrackingSignalQualitySummary get signalQualitySummary =>
      TripTrackingSignalQualitySummary.evaluate(
        switch (_nativeSignalEpochBaseline) {
          final baseline? => _diagnosticsSince(diagnostics, baseline),
          null => diagnostics,
        },
      );
  TripSignalQualityActionDecision signalQualityAction({
    bool userCanReviewNow = true,
  }) => TripSignalQualityActionPolicy.evaluate(
    signal: signalQualitySummary,
    activeTripHasLocalCheckpoint: _session != null,
    userCanReviewNow: userCanReviewNow,
  );
  List<TripTrackingAdvisoryEvent> get advisories =>
      List.unmodifiable(_session?.advisories ?? const []);
  List<TripBoundaryCandidate> get boundaryCandidates =>
      TripBoundaryCandidateResolver.fromAdvisories(advisories);
  TripBoundaryCandidate? get latestPendingStopBoundaryCandidate {
    final session = _session;
    if (session == null) return null;
    final index = TripStopAdvisoryReviewer.latestPendingStopReviewIndex(
      session,
      preferHighConfidence: _engine?.needsWalkingReview ?? false,
    );
    if (index < 0) return null;
    final candidates = TripBoundaryCandidateResolver.fromAdvisories([
      session.advisories[index],
    ]);
    return candidates.isEmpty ? null : candidates.single;
  }

  List<TripTrackingSessionTransitionAudit> get transitionAudits =>
      List.unmodifiable(_session?.transitionAudits ?? const []);
  TripTrackingSessionLifecycleState? get lifecycleState =>
      _session?.lifecycleState;
  TripTrackingSessionLifecycleContractState? get contractLifecycleState =>
      _session?.effectiveContractState;
  TripTrackingHealthState? get healthState => _session?.healthState;
  TripTrackingRecoveryDecision get recoveryDecision =>
      TripTrackingRecoveryPolicy.evaluate(
        session: _session,
        currentVehicleId: _odometer.vehicleId,
        currentConfirmedOdometer: _odometer.confirmedReading,
      );
  bool get nativeTracking => _nativeTracking;

  /// True only after the native collector confirms its provider request.
  bool get nativeProviderRegistered => _nativeProviderRegistered;
  bool get deviceAdjustedSampling =>
      _nativeSamplingPlan?.deviceAdjusted == true;
  int? get nativeSamplingIntervalSeconds => _nativeSampling?.interval.inSeconds;
  List<TripTrackingSignalGap> get signalGaps =>
      _engine?.signalGaps ?? const <TripTrackingSignalGap>[];
  TripInitialFixAssessment? get initialFixAssessment =>
      _engine?.initialFixAssessment;
  List<TripInitialFixAssessment> get initialFixHistory =>
      _engine?.initialFixHistory ?? const [];

  /// Consumes only a user-approved local link. Discovery and permissions stay
  /// in the shared device-capabilities adapter; this coordinator owns the
  /// active-trip vehicle lock and never performs a silent reassignment.
  BluetoothVehicleMatchDecision evaluateBluetoothVehicleIdentity({
    required String deviceId,
    required TripTrackingSettings settings,
    required TripTrackingBluetoothVehicleLinkStore linkStore,
  }) {
    TripTrackingSessionRecord? storedSession;
    try {
      storedSession = _sessionStore.activeSession;
      if (_platformStatus == 'bluetooth_session_storage_state_unknown') {
        _platformStatus = null;
        _platformError = null;
      }
    } catch (_) {
      _platformStatus = 'bluetooth_session_storage_state_unknown';
      _platformError =
          'Could not verify unfinished trip state. Bluetooth vehicle switching is paused.';
      return const BluetoothVehicleMatchDecision(
        disposition:
            BluetoothVehicleMatchDisposition.blockedByUnfinishedSession,
        vehicleId: null,
        safeReason: 'bluetooth_vehicle_storage_state_unknown',
      );
    }
    TripTrackingBluetoothVehicleLink? link;
    try {
      link = linkStore.linkForDevice(deviceId);
      if (_platformStatus == 'bluetooth_link_storage_failed') {
        _platformStatus = null;
        _platformError = null;
      }
    } catch (_) {
      _platformStatus = 'bluetooth_link_storage_failed';
      _platformError =
          'Could not read the local Bluetooth vehicle link. Select the vehicle manually.';
      return const BluetoothVehicleMatchDecision(
        disposition: BluetoothVehicleMatchDisposition.noMatch,
        vehicleId: null,
        safeReason: 'bluetooth_vehicle_link_storage_unavailable',
      );
    }
    final activeVehicleId = _session?.vehicleId ?? storedSession?.vehicleId;
    return resolveBluetoothVehicleMatchDecision(
      settings: settings,
      link: link,
      hasActiveGpsTrip: _session != null,
      hasUnfinishedStoredSession: _session == null && storedSession != null,
      activeVehicleId: activeVehicleId,
    );
  }

  TripAutomaticStartDecision evaluateAutomaticStartAssistance({
    required TripTrackingSettings settings,
    required TripAutomaticStartAccessLevel accessLevel,
    required Iterable<TripAutomaticStartObservation> observations,
    int acceptedFreeUsesInPeriod = 0,
    TripAutomaticStartDetector detector = const TripAutomaticStartDetector(),
  }) {
    var hasUnfinishedSession = _session != null;
    if (!hasUnfinishedSession) {
      try {
        hasUnfinishedSession = _sessionStore.activeSession != null;
        if (_platformStatus == 'automatic_start_storage_state_unknown') {
          _platformStatus = null;
          _platformError = null;
        }
      } catch (_) {
        hasUnfinishedSession = true;
        _platformStatus = 'automatic_start_storage_state_unknown';
        _platformError =
            'Could not verify local trip recovery state. Automatic start assistance is paused.';
      }
    }
    return detector.evaluate(
      enabled:
          settings.gpsAssistedTrackingEnabled &&
          settings.automaticStartAssistanceEnabled,
      accessLevel: accessLevel,
      hasActiveOrRecoverableSession: hasUnfinishedSession,
      observations: observations,
      evaluatedAt: _clockNow(),
      acceptedFreeUsesInPeriod: acceptedFreeUsesInPeriod,
    );
  }

  /// Saves a current, proposal-only automatic-evidence candidate when possible.
  ///
  /// This never starts tracking, creates a workday, changes the odometer, or
  /// confirms a business record. A storage failure leaves manual tracking fully
  /// available and is surfaced through the existing safe platform status.
  Future<TripAutomaticStartDecision> captureAutomaticStartAssistance({
    required TripTrackingSettings settings,
    required TripAutomaticStartAccessLevel accessLevel,
    required Iterable<TripAutomaticStartObservation> observations,
    int acceptedFreeUsesInPeriod = 0,
    TripAutomaticStartDetector detector = const TripAutomaticStartDetector(),
  }) async => (await _captureAutomaticStartAssistance(
    settings: settings,
    accessLevel: accessLevel,
    observations: observations,
    acceptedFreeUsesInPeriod: acceptedFreeUsesInPeriod,
    detector: detector,
  )).decision;

  Future<_AutomaticEvidenceCaptureOutcome> _captureAutomaticStartAssistance({
    required TripTrackingSettings settings,
    required TripAutomaticStartAccessLevel accessLevel,
    required Iterable<TripAutomaticStartObservation> observations,
    required int acceptedFreeUsesInPeriod,
    required TripAutomaticStartDetector detector,
  }) async {
    final decision = evaluateAutomaticStartAssistance(
      settings: settings,
      accessLevel: accessLevel,
      observations: observations,
      acceptedFreeUsesInPeriod: acceptedFreeUsesInPeriod,
      detector: detector,
    );
    if (!decision.shouldCreateReviewCandidate) {
      return _AutomaticEvidenceCaptureOutcome(
        decision: decision,
        candidatePersisted: false,
      );
    }
    final store = _automaticEvidenceCandidateStore;
    if (store == null || _automaticEvidenceCandidateProposalInFlight) {
      return _AutomaticEvidenceCaptureOutcome(
        decision: decision,
        candidatePersisted: false,
      );
    }
    _automaticEvidenceCandidateProposalInFlight = true;
    try {
      await store.propose(
        TripAutomaticEvidenceCandidate.fromDecision(
          decision: decision,
          detectedAt: _clockNow(),
        ),
      );
      notifyListeners();
      return _AutomaticEvidenceCaptureOutcome(
        decision: decision,
        candidatePersisted: true,
      );
    } catch (_) {
      _platformStatus = 'automatic_evidence_candidate_storage_unavailable';
      _platformError =
          'Possible vehicle movement could not be saved for review. Manual tracking remains available.';
      notifyListeners();
      return _AutomaticEvidenceCaptureOutcome(
        decision: decision,
        candidatePersisted: false,
      );
    } finally {
      _automaticEvidenceCandidateProposalInFlight = false;
    }
  }

  /// Captures one opt-in live location as possible-drive evidence only.
  ///
  /// This path keeps coordinates in memory only long enough to derive a
  /// displacement. It never starts native tracking, a workday, a trip, or an
  /// odometer change. A caller supplies current settings on every event so
  /// disabled assistance cannot retain stale evidence.
  Future<TripAutomaticStartDecision?> captureAutomaticLocationEvidence({
    required TripTrackingSettings settings,
    required TripAutomaticStartAccessLevel accessLevel,
    required TripLocationSample location,
    String? bluetoothVehicleId,
    int acceptedFreeUsesInPeriod = 0,
    TripAutomaticStartDetector detector = const TripAutomaticStartDetector(),
  }) async {
    if (!settings.gpsAssistedTrackingEnabled ||
        !settings.automaticStartAssistanceEnabled) {
      _automaticEvidenceObservationBuffer.reset();
      return null;
    }
    final observation = _automaticEvidenceObservationBuffer.recordLocation(
      location,
      bluetoothVehicleId: bluetoothVehicleId,
    );
    if (observation == null ||
        !_automaticEvidenceObservationBuffer.canEmitReviewCandidate) {
      return null;
    }
    final outcome = await _captureAutomaticStartAssistance(
      settings: settings,
      accessLevel: accessLevel,
      observations: _automaticEvidenceObservationBuffer.observations,
      acceptedFreeUsesInPeriod: acceptedFreeUsesInPeriod,
      detector: detector,
    );
    if (outcome.candidatePersisted) {
      _automaticEvidenceObservationBuffer.markReviewCandidateEmitted();
    }
    return outcome.decision;
  }

  /// Records optional activity evidence for a later review proposal only.
  void captureAutomaticActivityEvidence({
    required TripTrackingSettings settings,
    required TripActivityObservation activity,
  }) {
    if (!settings.gpsAssistedTrackingEnabled ||
        !settings.automaticStartAssistanceEnabled) {
      return;
    }
    _automaticEvidenceObservationBuffer.recordActivity(activity);
  }

  /// Clears transient evidence after opt-out or native observation shutdown.
  /// Nothing durable is removed or changed.
  void clearAutomaticEvidenceObservationWindow() =>
      _automaticEvidenceObservationBuffer.reset();

  List<TripAutomaticEvidenceCandidate> get automaticEvidenceCandidates =>
      _automaticEvidenceCandidateStore?.candidates ??
      const <TripAutomaticEvidenceCandidate>[];

  List<TripAutomaticEvidenceCandidate> get pendingAutomaticEvidenceCandidates =>
      _automaticEvidenceCandidateStore?.reviewNeeded ??
      const <TripAutomaticEvidenceCandidate>[];

  /// Records the user's decision about a possible drive without creating a
  /// session, trip, odometer entry, vehicle switch, or business classification.
  Future<TripAutomaticEvidenceCandidate> decideAutomaticEvidenceCandidate({
    required String candidateId,
    required int expectedRevision,
    required bool approved,
  }) async {
    final store = _automaticEvidenceCandidateStore;
    if (store == null) {
      throw StateError('Automatic evidence review is unavailable.');
    }
    final decided = await store.decide(
      candidateId: candidateId,
      expectedRevision: expectedRevision,
      approved: approved,
      decidedAt: _clockNow(),
    );
    notifyListeners();
    return decided;
  }

  String? get platformStatus => _platformStatus;
  String? get platformError => _platformError;
  String? get cloudMirrorError => _cloudMirrorError;
  String? get durableRecordError => _durableRecordError;
  String? get tripLogProposalError => _tripLogProposalError;
  String? get routeStorageStatus => _routeStorageStatus;
  TripFailureDecision get failureDecision => TripFailureClassifier.evaluate(
    health: healthState ?? TripTrackingHealthState.healthy,
    lifecycle: lifecycleState ?? TripTrackingSessionLifecycleState.disabled,
    hasUsableGpsEvidence:
        acceptedMeters > 0 || initialFixAssessment?.mayUseProvisionally == true,
    localStorageFailed:
        _platformStatus == 'storage_failed' || _durableRecordError != null,
  );
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

  @visibleForTesting
  Future<bool> tryTransitionForTest(
    TripTrackingSessionLifecycleState nextState, {
    TripTrackingHealthState? health,
    String? reasonCode,
    String? source,
  }) => _runExclusiveSessionOperation(
    false,
    () => _tryTransitionSession(
      nextState,
      health: health,
      reasonCode: reasonCode,
      source: source,
    ),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );
  double get gpsAssistanceCalibrationMultiplier => _calibrationState.multiplier;
  TripTrackingPlatformCapabilities? get lastKnownCapabilities =>
      _lastKnownCapabilities;
  TripTrackingReviewRecord? get latestReview {
    final reviews = _readPendingReviewsSafely();
    return reviews.isEmpty ? null : reviews.first;
  }

  TripTrackingReviewRecord? latestReviewForVehicle(String vehicleId) {
    final safeVehicleId = vehicleId.trim();
    if (safeVehicleId.isEmpty) return null;
    for (final review in _readPendingReviewsSafely()) {
      if (review.vehicleId == safeVehicleId) return review;
    }
    return null;
  }

  TripTrackingReviewRecord? get latestUnconfirmedReview =>
      _readPendingReviewsSafely()
          .where((review) => !review.isOdometerConfirmed)
          .firstOrNull;

  TripTrackingReviewRecord? get latestPendingTripLogProposal =>
      _readPendingReviewsSafely()
          .where(
            (review) =>
                review.tripLogProposalState ==
                TripTrackingTripLogProposalState.pending,
          )
          .firstOrNull;

  TripOdometerCalibrationSignal odometerCalibrationSignal({
    String? vehicleId,
    DateTime? nowUtc,
  }) => TripOdometerCalibrationSignal.evaluateConfirmedReviews(
    reviews: _readPendingReviewsSafely(),
    vehicleId: vehicleId ?? _odometer.vehicleId,
    vehicleConfigurationRevision: _currentVehicleConfigurationRevision,
    // Persisted reviews are an external trust boundary. A caller that does
    // not supply a reference clock must still not let future-dated records
    // influence advisory GPS calibration.
    nowUtc: nowUtc ?? _clockNow(),
    requireTrustedSignalDiagnostics: true,
  );

  TripDriverPatternDecision driverPatternDecision({
    required String profileId,
    DateTime? nowUtc,
  }) => TripDriverPatternAssistant.evaluate(
    observations: TripDriverPatternReviewAdapter.fromReviews(
      _readPendingReviewsSafely(),
    ),
    vehicleId: _odometer.vehicleId,
    profileId: profileId,
    nowUtc: nowUtc ?? _clockNow(),
  );

  List<TripTrackingReviewRecord> _readPendingReviewsSafely() {
    try {
      final reviews = _sessionStore.pendingReviews;
      if (_platformStatus == 'storage_failed' &&
          _platformError == 'Could not read locally saved trip reviews.') {
        _platformStatus = null;
        _platformError = null;
      }
      return reviews;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read locally saved trip reviews.';
      return const <TripTrackingReviewRecord>[];
    }
  }

  TripTrackingReviewRecord? _readReviewSafely(String tripId) {
    try {
      final review = _sessionStore.reviewForTrip(tripId);
      if (_platformStatus == 'storage_failed' &&
          _platformError == 'Could not read the locally saved trip review.') {
        _platformStatus = null;
        _platformError = null;
      }
      return review;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read the locally saved trip review.';
      return null;
    }
  }

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
    _odometer.removeListener(_handleConfirmedOdometerChanged);
    // A detached Dart controller has no safe path to persist native events.
    // Stop collection rather than leaving a foreground service running with
    // no local consumer. Normal background tracking keeps this controller
    // alive; a later restore can resume from the durable local checkpoint.
    // Cleanup is queued behind any in-flight native start/update. Otherwise a
    // dispose that lands while platform.start is awaiting its result can
    // detach the listener first and still leave the collector running.
    unawaited(
      _enqueueNativeLifecycle(() async {
        if (_nativeTracking) {
          await _stopNativeTracking(
            interrupted: true,
            interruptionHealth: TripTrackingHealthState.interrupted,
            interruptionSource: 'controller_dispose',
            interruptionReasonCode: 'controller_disposed_system_pause',
          );
          return;
        }
        try {
          await _platformSubscription?.cancel();
        } catch (_) {
          // The controller is already detached. Native collection was not
          // active, so there is no trusted distance to preserve here.
        } finally {
          _platformSubscription = null;
        }
      }),
    );
    _cloudMirror.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<T> _runExclusiveSessionOperation<T>(
    T busyValue,
    Future<T> Function() operation, {
    String? busyStatus,
    String? busyError,
  }) async {
    if (_isDisposed || _sessionOperationInProgress) {
      if (busyStatus != null) {
        _platformStatus = busyStatus;
        _platformError =
            busyError ?? 'A trip-tracking operation is already in progress.';
        notifyListeners();
      }
      return busyValue;
    }
    _sessionOperationInProgress = true;
    try {
      // A completion, cancellation, restore, or start boundary must observe
      // every sample that was already accepted into the ingestion queue.
      // While the queue drains, new ingestion is rejected by [ingest], so an
      // older captured session cannot overwrite or outlive the boundary.
      await _ingestionQueue;
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
    TripTrackingPauseKind? pauseKind,
    TripTrackingSessionLifecycleContractState? contractState,
    String? reasonCode,
    String? source,
    DateTime? eventTimestamp,
  }) async {
    final session = _session;
    if (session == null) return;
    final nextContractState =
        contractState ??
        _contractStateForTransition(next, pauseKind: pauseKind);
    if (session.lifecycleState == next &&
        session.effectiveContractState == nextContractState) {
      return;
    }
    final evaluatedReason =
        reasonCode ??
        (session.lifecycleState == next
            ? TripTrackingSessionContractStateMachine.evaluateTransition(
                session.effectiveContractState,
                nextContractState,
              ).reasonCode
            : TripTrackingSessionStateMachine.evaluateTransition(
                session.lifecycleState,
                next,
              ).reasonCode);
    if (session.lifecycleState != next) {
      TripTrackingSessionStateMachine.requireTransition(
        session.lifecycleState,
        next,
      );
    }
    if (session.effectiveContractState != nextContractState) {
      TripTrackingSessionContractStateMachine.requireTransition(
        session.effectiveContractState,
        nextContractState,
      );
    }
    final nextRevision = session.revision + 1;
    final nextTransitionSequence = session.transitionAudits.isEmpty
        ? nextRevision
        : session.transitionAudits.last.sequenceNumber + 1;
    final observedAt = (eventTimestamp ?? _clockNow()).toUtc();
    final previousUpdatedAt = session.updatedAt.toUtc();
    final now = observedAt.isBefore(previousUpdatedAt)
        ? previousUpdatedAt
        : observedAt;
    final nextSession = session.copyWith(
      updatedAt: now,
      engineSnapshot: _engine?.snapshot ?? session.engineSnapshot,
      lifecycleState: next,
      persistedContractState: nextContractState,
      healthState: health,
      pauseKind: next == TripTrackingSessionLifecycleState.paused
          ? pauseKind ?? TripTrackingPauseKind.system
          : null,
      clearPauseKind: next != TripTrackingSessionLifecycleState.paused,
      revision: nextRevision,
      transitionAudits: [
        ...session.transitionAudits,
        TripTrackingSessionTransitionAudit(
          id: '${session.id}:$nextRevision',
          sessionId: session.id,
          vehicleId: session.vehicleId,
          profile: session.profile,
          profileId: session.effectiveProfileId,
          fromState: session.lifecycleState,
          toState: next,
          fromContractState: session.effectiveContractState,
          toContractState: nextContractState,
          eventTimestamp: now.toUtc(),
          sequenceNumber: nextTransitionSequence,
          reasonCode: evaluatedReason,
          initiatingSource: _safeTransitionSource(source),
          revision: nextRevision,
          permissionState: _permissionStateForHealth(
            health ?? session.healthState,
          ),
          confidenceState: _confidenceStateForHealth(
            health ?? session.healthState,
          ),
          trackingQualityMode: _trackingQualityModeForHealth(
            health ?? session.healthState,
          ),
        ),
      ],
    );
    await _sessionStore.save(nextSession);
    _session = nextSession;
  }

  Future<bool> _tryTransitionSession(
    TripTrackingSessionLifecycleState next, {
    TripTrackingHealthState? health,
    TripTrackingPauseKind? pauseKind,
    TripTrackingSessionLifecycleContractState? contractState,
    String? reasonCode,
    String? source,
    DateTime? eventTimestamp,
  }) async {
    final session = _session;
    if (session == null) return false;
    final nextContractState =
        contractState ??
        _contractStateForTransition(next, pauseKind: pauseKind);
    if (session.lifecycleState == next &&
        session.effectiveContractState == nextContractState) {
      return true;
    }
    final runtimeDecision = TripTrackingSessionStateMachine.evaluateTransition(
      session.lifecycleState,
      next,
    );
    final contractDecision =
        TripTrackingSessionContractStateMachine.evaluateTransition(
          session.effectiveContractState,
          nextContractState,
        );
    final runtimeAllowed =
        session.lifecycleState == next || runtimeDecision.allowed;
    final contractAllowed =
        session.effectiveContractState == nextContractState ||
        contractDecision.allowed;
    if (!runtimeAllowed || !contractAllowed) {
      final nextRevision = session.revision + 1;
      final nextTransitionSequence = session.transitionAudits.isEmpty
          ? nextRevision
          : session.transitionAudits.last.sequenceNumber + 1;
      final observedAt = eventTimestamp ?? _clockNow();
      final eventAt = observedAt.isBefore(session.updatedAt)
          ? session.updatedAt
          : observedAt;
      final rejection = TripTrackingSessionTransitionAudit(
        id: '${session.id}:rejected:$nextRevision',
        sessionId: session.id,
        vehicleId: session.vehicleId,
        profile: session.profile,
        profileId: session.effectiveProfileId,
        fromState: session.lifecycleState,
        toState: next,
        fromContractState: session.effectiveContractState,
        toContractState: nextContractState,
        eventTimestamp: eventAt.toUtc(),
        sequenceNumber: nextTransitionSequence,
        reasonCode: !runtimeAllowed
            ? runtimeDecision.reasonCode
            : contractDecision.reasonCode,
        initiatingSource: _safeTransitionSource(source),
        revision: nextRevision,
        permissionState: _permissionStateForHealth(session.healthState),
        confidenceState: _confidenceStateForHealth(session.healthState),
        trackingQualityMode: _trackingQualityModeForHealth(session.healthState),
        accepted: false,
      );
      try {
        final preserved = session.copyWith(
          updatedAt: eventAt,
          revision: nextRevision,
          transitionAudits: [...session.transitionAudits, rejection],
        );
        await _sessionStore.save(preserved);
        _session = preserved;
      } catch (_) {
        _platformStatus = 'transition_rejected_storage_failed';
        _platformError =
            'Illegal GPS session transition was rejected, but its diagnostic could not be saved.';
        notifyListeners();
        return false;
      }
      _platformStatus = 'transition_rejected';
      _platformError =
          'Illegal GPS session transition: ${session.lifecycleState.name} -> ${next.name}';
      notifyListeners();
      return false;
    }
    try {
      await _transitionSession(
        next,
        health: health,
        pauseKind: pauseKind,
        contractState: nextContractState,
        reasonCode: reasonCode,
        source: source,
        eventTimestamp: eventTimestamp,
      );
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
    int? deviceLocationIntervalFloorSeconds,
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
            session.lowBatteryWarningDismissed == lowBatteryWarningDismissed) &&
        (deviceLocationIntervalFloorSeconds == null ||
            session.deviceLocationIntervalFloorSeconds ==
                deviceLocationIntervalFloorSeconds)) {
      return true;
    }
    final next = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session),
      revision: session.revision + 1,
      backgroundTrackingAllowed: allowBackground,
      activityRecognitionEnabled: activityRecognitionEnabled,
      nativeSampling: nativeSampling,
      samplingCeiling: samplingCeiling,
      clearSamplingCeiling: clearSamplingCeiling,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
      deviceLocationIntervalFloorSeconds: deviceLocationIntervalFloorSeconds,
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

  Future<bool> _persistBatteryStateSummary(
    TripTrackingBatteryStateSummary summary,
  ) async {
    final session = _session;
    if (session == null) return false;
    final next = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session),
      revision: session.revision + 1,
      batteryStateSummary: summary,
    );
    try {
      await _sessionStore.save(next);
      _session = next;
      return true;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save GPS battery safety state locally.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _persistPermissionEvidence(
    TripTrackingAuthorization authorization, {
    required String source,
  }) async {
    final session = _session;
    if (session == null) return false;
    final evidence = TripTrackingPermissionEvidence(
      observedAt: _clockNow(),
      state: authorization.state.name,
      preciseLocation: authorization.preciseLocation,
      canTrackInBackground: authorization.canTrackInBackground,
      source: source,
    );
    final history = [...session.permissionHistory, evidence];
    final next = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session),
      revision: session.revision + 1,
      permissionHistory: history.length <= 24
          ? history
          : history.skip(history.length - 24).toList(growable: false),
    );
    try {
      await _sessionStore.save(next);
      _session = next;
      return true;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save GPS permission state locally.';
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

  TripTrackingSessionLifecycleContractState _contractStateForTransition(
    TripTrackingSessionLifecycleState state, {
    TripTrackingPauseKind? pauseKind,
  }) {
    if (state == TripTrackingSessionLifecycleState.paused) {
      return pauseKind == TripTrackingPauseKind.user
          ? TripTrackingSessionLifecycleContractState.PAUSED_BY_USER
          : TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM;
    }
    return state.toContractState();
  }

  DateTime _nonRegressingSessionTime(
    TripTrackingSessionRecord session, [
    DateTime? candidate,
  ]) {
    final observedAt = (candidate ?? _clockNow()).toUtc();
    final previous = session.updatedAt.toUtc();
    return observedAt.isBefore(previous) ? previous : observedAt;
  }

  String _safeTransitionSource(String? value) {
    if (value == null || value.trim().isEmpty) return 'controller';
    return value.trim().length > 48
        ? value.trim().substring(0, 48)
        : value.trim();
  }

  String _permissionStateForHealth(TripTrackingHealthState health) =>
      switch (health) {
        TripTrackingHealthState.permissionBlocked => 'permission_blocked',
        TripTrackingHealthState.platformRestricted => 'platform_restricted',
        TripTrackingHealthState.unavailable => 'permission_unknown',
        _ => 'permission_granted',
      };

  String _confidenceStateForHealth(TripTrackingHealthState health) =>
      health.name;

  String _trackingQualityModeForHealth(TripTrackingHealthState health) =>
      switch (health) {
        TripTrackingHealthState.healthy => 'high_quality',
        TripTrackingHealthState.reduced => 'reduced_quality',
        TripTrackingHealthState.poor => 'poor_quality',
        TripTrackingHealthState.interrupted => 'interrupted',
        TripTrackingHealthState.unavailable => 'unavailable',
        TripTrackingHealthState.permissionBlocked => 'permission_blocked',
        TripTrackingHealthState.platformRestricted => 'platform_restricted',
      };

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

class _AutomaticEvidenceCaptureOutcome {
  const _AutomaticEvidenceCaptureOutcome({
    required this.decision,
    required this.candidatePersisted,
  });

  final TripAutomaticStartDecision decision;
  final bool candidatePersisted;
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
