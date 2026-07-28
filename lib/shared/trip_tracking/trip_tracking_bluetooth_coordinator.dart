import '../device_capabilities/device_bluetooth_capabilities.dart';
import 'trip_automatic_start_detector.dart';
import 'trip_tracking_bluetooth.dart';
import 'trip_tracking_settings_store.dart';

typedef BluetoothVehicleDecisionResolver =
    BluetoothVehicleMatchDecision Function(String opaqueDeviceId);

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
    this.decisionResolver,
    this.automaticStartAccess = _freeAutomaticStartAccess,
    this.startAutomaticTracking,
  });

  final TripTrackingBluetoothVehicleLinkStore linkStore;
  final TripTrackingSettings Function() settings;
  final bool Function() hasActiveSession;
  final bool Function() hasUnfinishedStoredSession;
  final String Function() currentVehicleId;
  final Future<bool> Function(String vehicleId) switchVehicle;
  final BluetoothVehicleDecisionResolver? decisionResolver;
  final TripAutomaticStartAccessLevel Function() automaticStartAccess;
  final Future<bool> Function(String vehicleId, DateTime startedAt)?
  startAutomaticTracking;
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
      await _maybeStartAutomaticTracking(vehicleId, observedAt);
      return decision;
    }
    if (!decision.canSwitchVehicle) return decision;

    try {
      if (await switchVehicle(vehicleId)) {
        await _maybeStartAutomaticTracking(vehicleId, observedAt);
        return decision;
      }
    } catch (_) {
      // A failed global-vehicle switch remains an explicit review request.
    }
    return BluetoothVehicleMatchDecision(
      disposition: BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      vehicleId: vehicleId,
      safeReason: 'bluetooth_vehicle_switch_failed_safely',
    );
  }

  Future<void> _maybeStartAutomaticTracking(
    String vehicleId,
    DateTime observedAt,
  ) async {
    final startTracking = startAutomaticTracking;
    final currentSettings = settings();
    if (startTracking == null ||
        automaticStartAccess() != TripAutomaticStartAccessLevel.paid ||
        !currentSettings.gpsAssistedTrackingEnabled ||
        !currentSettings.bluetoothVehicleRecognitionEnabled ||
        !currentSettings.automaticStartAssistanceEnabled ||
        hasActiveSession() ||
        hasUnfinishedStoredSession()) {
      return;
    }
    try {
      await startTracking(vehicleId, observedAt);
    } catch (_) {
      // The caller owns actionable startup status. A Bluetooth observation
      // never bypasses the controller's local-storage and permission gates.
    }
  }
}

// odometerIsGlobalTruth: true. Bluetooth may identify a vehicle, never mileage.

TripAutomaticStartAccessLevel _freeAutomaticStartAccess() =>
    TripAutomaticStartAccessLevel.free;
