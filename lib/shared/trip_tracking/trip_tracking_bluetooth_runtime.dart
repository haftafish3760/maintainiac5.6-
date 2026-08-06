// User-reviewable Bluetooth vehicle-link runtime and app lifecycle owner.
//
// Owns one idempotent observation binding, a bounded latest-device prompt,
// and explicit local link approval. It does not scan, expose hardware IDs,
// grant paid access, start trips, or alter odometer truth. The app root and
// trip settings screen consume this controller.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_bluetooth_binding.dart';
import 'trip_tracking_bluetooth_coordinator.dart';

class TripTrackingBluetoothRuntimeController extends ChangeNotifier {
  TripTrackingBluetoothRuntimeController({
    required DeviceBluetoothConnectionProbe probe,
    required TripTrackingBluetoothCoordinator coordinator,
    required this.linkStore,
    DateTime Function()? clockNow,
    Future<bool> Function()? requestObservationAccess,
  }) : _clockNow = clockNow ?? DateTime.now {
    _requestObservationAccess = requestObservationAccess;
    _binding = TripTrackingBluetoothBinding(
      probe: probe,
      coordinator: coordinator,
      onObservation: _recordObservation,
      onUnavailable: () => _setAvailability(false),
    );
  }

  static const pendingLifetime = Duration(minutes: 5);

  final TripTrackingBluetoothVehicleLinkStore linkStore;
  final DateTime Function() _clockNow;
  late final TripTrackingBluetoothBinding _binding;
  late final Future<bool> Function()? _requestObservationAccess;
  DeviceBluetoothConnectionObservation? _pendingObservation;
  BluetoothVehicleMatchDecision? _lastDecision;
  bool _disposed = false;
  Future<bool>? _startFuture;
  Future<bool>? _observationAccessFuture;
  bool _observationAvailable = false;

  bool get observationAvailable => _observationAvailable;
  bool get canRequestObservationAccess => _requestObservationAccess != null;
  bool get isListening => _binding.isListening;
  BluetoothVehicleMatchDecision? get lastDecision => _lastDecision;

  /// A currently connected, already user-linked vehicle may corroborate an
  /// App Assistant proposal. It is evidence only: callers must not use it to
  /// select a vehicle, start a trip, or confirm mileage.
  String? get connectedEvidenceVehicleId {
    final decision = _lastDecision;
    if (decision == null) return null;
    return switch (decision.disposition) {
      BluetoothVehicleMatchDisposition.requiresUserConfirmation ||
      BluetoothVehicleMatchDisposition.automaticSwitchAllowed ||
      BluetoothVehicleMatchDisposition.alreadyActiveVehicle =>
        decision.vehicleId,
      BluetoothVehicleMatchDisposition.noMatch ||
      BluetoothVehicleMatchDisposition.recognitionDisabled ||
      BluetoothVehicleMatchDisposition.blockedByActiveTrip ||
      BluetoothVehicleMatchDisposition.blockedByUnfinishedSession => null,
    };
  }

  bool get hasPendingDevice => _usablePendingObservation() != null;

  DateTime? get pendingObservedAtUtc =>
      _usablePendingObservation()?.observedAtUtc;

  List<TripTrackingBluetoothVehicleLink> linksForVehicle(String vehicleId) =>
      linkStore.linksForVehicle(vehicleId);

  Future<bool> start() async {
    if (_disposed) return false;
    if (_binding.isListening) {
      _setAvailability(true);
      return true;
    }
    final pendingStart = _startFuture;
    if (pendingStart != null) return pendingStart;
    final operation = () async {
      final started = await _binding.start();
      _setAvailability(started);
      return started;
    }();
    _startFuture = operation;
    return operation.whenComplete(() {
      if (identical(_startFuture, operation)) _startFuture = null;
    });
  }

  Future<bool> requestObservationAccess() async {
    final request = _requestObservationAccess;
    if (_disposed || request == null) return false;
    if (_observationAvailable) return true;
    final pending = _observationAccessFuture;
    if (pending != null) return pending;
    final operation = () async {
      bool granted;
      try {
        granted = await request();
      } catch (_) {
        _setAvailability(false);
        return false;
      }
      if (!granted || _disposed) {
        _setAvailability(false);
        return false;
      }
      return start();
    }();
    _observationAccessFuture = operation;
    return operation.whenComplete(() {
      if (identical(_observationAccessFuture, operation)) {
        _observationAccessFuture = null;
      }
    });
  }

  Future<bool> approvePendingForVehicle({
    required String vehicleId,
    required String vehicleLabel,
  }) async {
    final pending = _usablePendingObservation();
    final cleanVehicleId = vehicleId.trim();
    if (_disposed || pending == null || cleanVehicleId.isEmpty) return false;
    await linkStore.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: pending.opaqueDeviceId,
        vehicleId: cleanVehicleId,
        createdAt: _clockNow().toUtc(),
        displayName: vehicleLabel.trim().isEmpty
            ? 'Approved vehicle device'
            : '${vehicleLabel.trim()} Bluetooth',
      ),
    );
    if (_pendingObservation?.opaqueDeviceId == pending.opaqueDeviceId) {
      _pendingObservation = null;
    }
    notifyListeners();
    return true;
  }

  Future<void> removeLink(String deviceId) async {
    if (_disposed || deviceId.trim().isEmpty) return;
    await linkStore.removeDevice(deviceId);
    notifyListeners();
  }

  void _recordObservation(
    DeviceBluetoothConnectionObservation observation,
    BluetoothVehicleMatchDecision decision,
  ) {
    if (_disposed) return;
    _lastDecision = decision;
    final existingLink = linkStore.linkForDevice(observation.opaqueDeviceId);
    if (!observation.connected) {
      if (_pendingObservation?.opaqueDeviceId == observation.opaqueDeviceId) {
        _pendingObservation = null;
      }
    } else if (existingLink == null && _isRecent(observation)) {
      // Keep only the latest unlinked observation. This bounds memory and
      // requires approval while the connection event is still fresh.
      _pendingObservation = observation;
    }
    notifyListeners();
  }

  DeviceBluetoothConnectionObservation? _usablePendingObservation() {
    final pending = _pendingObservation;
    if (pending == null || !_isRecent(pending)) return null;
    return pending;
  }

  bool _isRecent(DeviceBluetoothConnectionObservation observation) {
    final age = _clockNow().toUtc().difference(
      observation.observedAtUtc.toUtc(),
    );
    return !age.isNegative && age <= pendingLifetime;
  }

  void _setAvailability(bool available) {
    if (_observationAvailable == available || _disposed) return;
    _observationAvailable = available;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pendingObservation = null;
    _observationAccessFuture = null;
    unawaited(_binding.dispose());
    super.dispose();
  }
}

class TripTrackingBluetoothRuntimeScope
    extends InheritedNotifier<TripTrackingBluetoothRuntimeController> {
  const TripTrackingBluetoothRuntimeScope({
    super.key,
    required TripTrackingBluetoothRuntimeController controller,
    required super.child,
  }) : super(notifier: controller);

  static TripTrackingBluetoothRuntimeController? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<TripTrackingBluetoothRuntimeScope>()
      ?.notifier;
}
