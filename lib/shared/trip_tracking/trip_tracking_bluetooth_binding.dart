import 'dart:async';

import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_bluetooth_coordinator.dart';

/// Connects the shared, permission-aware Bluetooth observation stream to the
/// trip-side vehicle coordinator. It never scans, pairs, or changes mileage.
class TripTrackingBluetoothBinding {
  TripTrackingBluetoothBinding({
    required this.probe,
    required this.coordinator,
    this.onDecision,
    this.onObservation,
    this.onUnavailable,
  });

  final DeviceBluetoothConnectionProbe probe;
  final TripTrackingBluetoothCoordinator coordinator;
  final void Function(BluetoothVehicleMatchDecision decision)? onDecision;
  final void Function(
    DeviceBluetoothConnectionObservation observation,
    BluetoothVehicleMatchDecision decision,
  )?
  onObservation;
  final void Function()? onUnavailable;

  StreamSubscription<DeviceBluetoothConnectionObservation>? _subscription;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  bool get isListening => _subscription != null;

  Future<bool> start() async {
    if (_disposed) return false;
    if (_subscription != null) return true;

    DeviceBluetoothCapabilities capabilities;
    try {
      capabilities = await probe.bluetoothCapabilities();
    } catch (_) {
      return false;
    }
    if (!capabilities.canObserveApprovedConnections || _disposed) return false;

    _subscription = probe.approvedConnectionChanges.listen(
      _enqueueObservation,
      onError: (_, _) => _markUnavailable(),
      onDone: _markUnavailable,
    );
    return true;
  }

  void _markUnavailable() {
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    if (!_disposed) onUnavailable?.call();
  }

  void _enqueueObservation(DeviceBluetoothConnectionObservation observation) {
    _tail = _tail.then((_) => _handleObservation(observation)).catchError((_) {
      // One failed callback cannot poison later approved observations.
    });
  }

  Future<void> _handleObservation(
    DeviceBluetoothConnectionObservation observation,
  ) async {
    if (_disposed) return;
    final decision = await coordinator.handleConnection(observation);
    if (!_disposed) {
      onDecision?.call(decision);
      onObservation?.call(observation, decision);
    }
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _tail;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
  }
}

// odometerIsGlobalTruth: true. Bluetooth identifies a vehicle only.
