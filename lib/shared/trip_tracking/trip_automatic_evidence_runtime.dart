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
  Future<void>? _pendingSync;
  bool _disposed = false;
  bool _observationRunning = false;
  String? _lastStatus;

  bool get observationRunning => _observationRunning;
  String? get lastStatus => _lastStatus;

  Future<bool> synchronize() async {
    if (_disposed) return false;
    final current = _pendingSync;
    if (current != null) {
      await current;
      return _observationRunning;
    }
    final operation = _synchronize();
    _pendingSync = operation;
    try {
      await operation;
      return _observationRunning;
    } finally {
      if (identical(_pendingSync, operation)) _pendingSync = null;
    }
  }

  Future<void> _synchronize() async {
    final settings = _settings();
    final enabled =
        settings.gpsAssistedTrackingEnabled &&
        settings.automaticStartAssistanceEnabled;
    if (!enabled || _tripTracking.isTracking) {
      _tripTracking.clearAutomaticEvidenceObservationWindow();
      if (await _isNativeObservationRunning()) {
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
    if (await _isNativeObservationRunning()) {
      _observationRunning = true;
      _setStatus('automatic_evidence_observing');
      return;
    }
    try {
      final started = await _gateway.startAutomaticEvidenceObservation(
        activityRecognitionEnabled: settings.activityRecognitionEnabled,
      );
      _observationRunning = started;
      _setStatus(
        started
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
      case TripTrackingPlatformEventType.error:
        final code = event.errorCode;
        if (code != null && code.startsWith('automatic_evidence_')) {
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
      // Explicit opt-out still clears local transient evidence. Native state is
      // retried at the next bootstrap/settings synchronization.
    }
    _observationRunning = false;
    _setStatus('automatic_evidence_observation_stopped');
  }

  Future<bool> _isNativeObservationRunning() async {
    try {
      return await _gateway.isAutomaticEvidenceObservationRunning;
    } catch (_) {
      return false;
    }
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
