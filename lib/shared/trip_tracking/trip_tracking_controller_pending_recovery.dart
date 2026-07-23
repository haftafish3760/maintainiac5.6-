// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// Replays a crash-safe sample only after the user has explicitly resumed a
/// paused trip. It never changes confirmed odometer truth.
extension TripTrackingControllerPendingRecovery on TripTrackingController {
  Future<bool> _replayDeferredPendingSample() async {
    final session = _session;
    if (session == null) return false;
    TripTrackingPendingSample? pending;
    try {
      pending = _sessionStore.pendingSampleFor(session.id);
    } catch (_) {
      _platformStatus = 'pending_replay_failed';
      _platformError = 'Could not read pending GPS evidence before resuming.';
      notifyListeners();
      return false;
    }
    if (pending == null) return true;
    final pendingToReplay = pending;
    final recovery = TripTrackingRecoveryPolicy.evaluate(
      session: session,
      currentVehicleId: _odometer.vehicleId,
      currentConfirmedOdometer: _odometer.confirmedReading,
      pendingSample: pendingToReplay,
    );
    if (recovery.status != TripTrackingRecoveryStatus.pendingReplayReady) {
      _platformStatus = 'pending_replay_failed';
      _platformError =
          'Pending GPS evidence needs review before tracking can resume.';
      notifyListeners();
      return false;
    }
    final decision = await _enqueueIngestion(
      () => _ingest(pendingToReplay.sample, activity: pendingToReplay.activity),
    );
    if (decision == null) {
      _platformStatus = 'pending_replay_failed';
      _platformError = 'Could not replay pending GPS evidence safely.';
      notifyListeners();
      return false;
    }
    try {
      await _sessionStore.clearPending(session.id);
    } catch (_) {
      _platformStatus = 'pending_cleanup_failed';
      _platformError =
          'GPS evidence is saved, but transient recovery cleanup is pending.';
      notifyListeners();
      return true;
    }
    if (_platformStatus == 'pending_replay_deferred' ||
        _platformStatus == 'pending_replay_failed') {
      _platformStatus = null;
      _platformError = null;
      notifyListeners();
    }
    return true;
  }
}
