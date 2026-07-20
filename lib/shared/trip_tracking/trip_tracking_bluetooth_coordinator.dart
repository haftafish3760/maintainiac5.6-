import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingBluetoothCoordinator {
  const TripTrackingBluetoothCoordinator({
    required this.linkStore,
    required this.settings,
    required this.hasActiveOrRecoverableSession,
    required this.currentVehicleId,
    required this.switchVehicle,
  });

  final TripTrackingBluetoothVehicleLinkStore linkStore;
  final TripTrackingSettings Function() settings;
  final bool Function() hasActiveOrRecoverableSession;
  final String Function() currentVehicleId;
  final Future<bool> Function(String vehicleId) switchVehicle;

  Future<BluetoothVehicleMatchDecision> handleConnection(
    DeviceBluetoothConnectionObservation observation, {
    DateTime? nowUtc,
  }) async {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final age = now.difference(observation.observedAtUtc.toUtc());
    if (!observation.connected ||
        age.isNegative ||
        age > const Duration(minutes: 5)) {
      return const BluetoothVehicleMatchDecision(
        disposition: BluetoothVehicleMatchDisposition.noMatch,
        vehicleId: null,
        safeReason: 'bluetooth_observation_stale_or_disconnected',
      );
    }
    final link = linkStore.linkForDevice(observation.opaqueDeviceId);
    final decision = resolveBluetoothVehicleMatchDecision(
      settings: settings(),
      link: link,
      hasActiveGpsTrip: hasActiveOrRecoverableSession(),
    );
    final vehicleId = decision.vehicleId;
    if (!decision.canSwitchVehicle ||
        vehicleId == null ||
        vehicleId == currentVehicleId()) {
      return decision;
    }
    final switched = await switchVehicle(vehicleId);
    if (switched) return decision;
    return BluetoothVehicleMatchDecision(
      disposition: BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      vehicleId: vehicleId,
      safeReason: 'bluetooth_vehicle_switch_failed_safely',
    );
  }
}
