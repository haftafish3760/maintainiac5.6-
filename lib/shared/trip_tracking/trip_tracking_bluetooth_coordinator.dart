import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_settings_store.dart';

typedef BluetoothVehicleDecisionResolver =
    BluetoothVehicleMatchDecision Function(String opaqueDeviceId);

/// Serializes Bluetooth vehicle suggestions outside an active trip.
/// It never discovers devices, changes the active vehicle, changes mileage,
/// or bypasses user review. A connection is evidence, not authorization.
class TripTrackingBluetoothCoordinator {
  TripTrackingBluetoothCoordinator({
    required this.linkStore,
    required this.settings,
    required this.hasActiveSession,
    required this.hasUnfinishedStoredSession,
    required this.currentVehicleId,
    required this.switchVehicle,
    this.decisionResolver,
  });

  final TripTrackingBluetoothVehicleLinkStore linkStore;
  final TripTrackingSettings Function() settings;
  final bool Function() hasActiveSession;
  final bool Function() hasUnfinishedStoredSession;
  final String Function() currentVehicleId;
  final Future<bool> Function(String vehicleId) switchVehicle;
  final BluetoothVehicleDecisionResolver? decisionResolver;
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
    late final BluetoothVehicleMatchDecision decision;
    try {
      decision =
          decisionResolver?.call(observation.opaqueDeviceId) ??
          resolveBluetoothVehicleMatchDecision(
            settings: settings(),
            link: linkStore.linkForDevice(observation.opaqueDeviceId),
            hasActiveGpsTrip: hasActiveSession(),
            hasUnfinishedStoredSession: hasUnfinishedStoredSession(),
            activeVehicleId: currentVehicleId(),
          );
    } catch (_) {
      return const BluetoothVehicleMatchDecision(
        disposition: BluetoothVehicleMatchDisposition.noMatch,
        vehicleId: null,
        safeReason: 'bluetooth_vehicle_context_unavailable',
      );
    }
    final vehicleId = decision.vehicleId;
    if (vehicleId == null) return decision;
    if (decision.disposition ==
        BluetoothVehicleMatchDisposition.alreadyActiveVehicle) {
      return decision;
    }
    if (!decision.canSwitchVehicle) return decision;

    // Defend against an outdated/custom resolver that still reports the
    // retired automatic-switch disposition. Never call switchVehicle here:
    // a Bluetooth observation must not rewrite global vehicle context.
    return BluetoothVehicleMatchDecision(
      disposition: BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      vehicleId: vehicleId,
      safeReason: 'bluetooth_vehicle_requires_confirmation',
    );
  }
}

// odometerIsGlobalTruth: true. Bluetooth may identify a vehicle, never start
// tracking, create mileage, or establish business purpose.
