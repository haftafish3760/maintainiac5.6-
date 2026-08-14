// Production bridge for opt-in App Assistant evidence observation.
//
// Owns native observer lifecycle and routes only dedicated evidence events to
// TripTrackingController. It does not start active trip tracking, request
// permission, persist coordinates, or confirm business records. Consumed by
// app bootstrap and controlled by the saved trip-tracking settings.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'trip_automatic_start_detector.dart';
import 'trip_tracking_controller.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

class TripAutomaticEvidenceRuntimeController extends ChangeNotifier {
  TripAutomaticEvidenceRuntimeController({
    required TripAutomaticEvidenceNativeGateway gateway,
    required TripTrackingController tripTracking,
    required TripTrackingSettings Function() settings,
    String? Function()? bluetoothEvidenceVehicleId,
    this.accessLevel = TripAutomaticStartAccessLevel.free,
  }) : _gateway = gateway,
       _tripTracking = tripTracking,
       _settings = settings,
       _bluetoothEvidenceVehicleId = bluetoothEvidenceVehicleId;

  final TripAutomaticEvidenceNativeGateway _gateway;
  final TripTrackingController _tripTracking;
  final TripTrackingSettings Function() _settings;
  final String? Function()? _bluetoothEvidenceVehicleId;
  final TripAutomaticStartAccessLevel accessLevel;

  StreamSubscription<TripTrackingPlatformEvent>? _subscription;
  Future<void> _syncTail = Future<void>.value();
  bool _disposed = false;
  bool _observationRunning = false;
  String? _lastStatus;

  bool get observationRunning => _observationRunning;
  String? get lastStatus => _lastStatus;

  Future<bool> synchronize() async {
    if (_disposed) return false;
    // Queue every requested reconciliation. A disable, active-trip start, or
    // permission change that arrives while an enable is in flight must run
    // after that enable; merely awaiting the older operation can leave native
    // collection in the opposite state from the latest user choice.
    final operation = _syncTail.then((_) async {
      if (!_disposed) await _synchronize();
    });
    _syncTail = operation.catchError((_) {});
    await operation;
    return _observationRunning;
  }

  Future<void> _synchronize() async {
    final settings = _settings();
    final enabled =
        settings.gpsAssistedTrackingEnabled &&
        settings.automaticStartAssistanceEnabled;
    if (!enabled || _tripTracking.isTracking) {
      _tripTracking.clearAutomaticEvidenceObservationWindow();
      final nativeState = await _nativeObservationState();
      if (nativeState != false) {
        await _stopNativeObservation();
      } else {
        _observationRunning = false;
        _setStatus('automatic_evidence_observation_stopped');
      }
      return;
    }
    _subscription ??= _gateway.events.listen(
      _handleEvent,
      onError: (error, stackTrace) =>
          _setStatus('automatic_evidence_stream_unavailable'),
    );
    final nativeState = await _nativeObservationState();
    if (nativeState == null) {
      _observationRunning = false;
      _setStatus('automatic_evidence_observation_state_unavailable');
      return;
    }
    if (nativeState) {
      _observationRunning = true;
      _setStatus('automatic_evidence_observing');
      return;
    }
    try {
      final started = await _gateway.startAutomaticEvidenceObservation(
        activityRecognitionEnabled: settings.activityRecognitionEnabled,
      );
      final confirmed = started && await _waitForNativeObservationStart();
      _observationRunning = confirmed;
      _setStatus(
        confirmed
            ? 'automatic_evidence_observing'
            : 'automatic_evidence_observation_unavailable',
      );
    } catch (_) {
      _observationRunning = false;
      _setStatus('automatic_evidence_observation_unavailable');
    }
  }

  void _handleEvent(TripTrackingPlatformEvent event) {
    if (_disposed) return;
    final settings = _settings();
    switch (event.type) {
      case TripTrackingPlatformEventType.automaticEvidenceLocation:
        if (!_observationRunning) return;
        final location = event.location;
        if (location == null) return;
        unawaited(
          _tripTracking.captureAutomaticLocationEvidence(
            settings: settings,
            accessLevel: accessLevel,
            location: location,
            bluetoothVehicleId: _bluetoothEvidenceVehicleId?.call(),
          ),
        );
      case TripTrackingPlatformEventType.automaticEvidenceActivity:
        if (!_observationRunning) return;
        final activity = event.activity;
        if (activity == null) return;
        _tripTracking.captureAutomaticActivityEvidence(
          settings: settings,
          activity: activity,
        );
      case TripTrackingPlatformEventType.automaticEvidenceStatus:
        if (event.status == 'automatic_evidence_observing') {
          _observationRunning = true;
          _setStatus('automatic_evidence_observing');
        } else if (event.status == 'automatic_evidence_stopped') {
          _observationRunning = false;
          _setStatus('automatic_evidence_observation_stopped');
        }
        return;
      case TripTrackingPlatformEventType.error:
        final code = event.errorCode;
        if (code != null && code.startsWith('automatic_evidence_activity_')) {
          _setStatus('automatic_evidence_observing_without_activity');
        } else if (code != null && code.startsWith('automatic_evidence_')) {
          _observationRunning = false;
          _setStatus('automatic_evidence_observation_unavailable');
        }
        return;
      default:
        return;
    }
  }

  Future<void> _stopNativeObservation() async {
    try {
      await _gateway.stopAutomaticEvidenceObservation();
    } catch (_) {
      final nativeState = await _nativeObservationState();
      // A failed stop or an unreadable native state can never be represented
      // as a successful privacy opt-out.
      _observationRunning = nativeState != false;
      _setStatus('automatic_evidence_observation_stop_unconfirmed');
      return;
    }
    final nativeState = await _nativeObservationState();
    if (nativeState == false) {
      _observationRunning = false;
      _setStatus('automatic_evidence_observation_stopped');
    } else {
      _observationRunning = true;
      _setStatus('automatic_evidence_observation_stop_unconfirmed');
    }
  }

  Future<bool?> _nativeObservationState() async {
    try {
      return await _gateway.isAutomaticEvidenceObservationRunning;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _waitForNativeObservationStart() async {
    // Android foreground-service startup and provider registration are
    // asynchronous. Never call the observer live until native code confirms
    // registration; iOS normally confirms on the first check.
    for (var attempt = 0; attempt < 20; attempt += 1) {
      final state = await _nativeObservationState();
      if (state == true) return true;
      if (state == null) return false;
      if (attempt < 19) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    return false;
  }

  void _setStatus(String status) {
    if (_lastStatus == status) return;
    _lastStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
