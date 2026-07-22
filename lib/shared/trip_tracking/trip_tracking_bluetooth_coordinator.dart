import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_settings_store.dart';

/// Serializes user-approved Bluetooth vehicle hints outside an active trip.
/// It never discovers devices, changes mileage, or bypasses review settings.
class TripTrackingBluetoothCoordinator {
  TripTrackingBluetoothCoordinator({
    required this.linkStore,
    required this.settings,
    required this.hasActiveSession,
    required this.hasUnfinishedStoredSession,
    required this.currentVehicleId,
    required this.switchVehicle,
  });

  final TripTrackingBluetoothVehicleLinkStore linkStore;
  final TripTrackingSettings Function() settings;
  final bool Function() hasActiveSession;
  final bool Function() hasUnfinishedStoredSession;
  final String Function() currentVehicleId;
  final Future<bool> Function(String vehicleId) switchVehicle;
  Future<void> _tail = Future<void>.value();

  Future<BluetoothVehicleMatchDecision> handleConnection(
    DeviceBluetoothConnectionObservation observation, {
    DateTime? nowUtc,
  }) {
    final operation = _tail.then(
      (_) => _handleConnection(
        observation,
        nowUtc: (nowUtc ?? DateTime.now()).toUtc(),
      ),
    );
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<BluetoothVehicleMatchDecision> _handleConnection(
    DeviceBluetoothConnectionObservation observation, {
    required DateTime nowUtc,
  }) async {
    final observedAt = observation.observedAtUtc.toUtc();
    final age = nowUtc.difference(observedAt);
    if (!observation.connected ||
        age.isNegative ||
        age > const Duration(minutes: 5)) {
      return const BluetoothVehicleMatchDecision(
        disposition: BluetoothVehicleMatchDisposition.noMatch,
        vehicleId: null,
        safeReason: 'bluetooth_observation_stale_or_disconnected',
      );
    }
    final decision = resolveBluetoothVehicleMatchDecision(
      settings: settings(),
      link: linkStore.linkForDevice(observation.opaqueDeviceId),
      hasActiveGpsTrip: hasActiveSession(),
      hasUnfinishedStoredSession: hasUnfinishedStoredSession(),
      activeVehicleId: currentVehicleId(),
    );
    final vehicleId = decision.vehicleId;
    if (!decision.canSwitchVehicle || vehicleId == null) return decision;

    try {
      if (await switchVehicle(vehicleId)) return decision;
    } catch (_) {
      // A failed global-vehicle switch remains an explicit review request.
    }
    return BluetoothVehicleMatchDecision(
      disposition: BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      vehicleId: vehicleId,
      safeReason: 'bluetooth_vehicle_switch_failed_safely',
    );
  }
}

// odometerIsGlobalTruth: true. Bluetooth may identify a vehicle, never mileage.
