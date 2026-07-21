enum DeviceBluetoothAuthorizationState {
  unknown,
  notRequested,
  denied,
  restricted,
  authorized,
}

class DeviceBluetoothCapabilities {
  const DeviceBluetoothCapabilities({
    this.adapterAvailable = false,
    this.poweredOn = false,
    this.authorization = DeviceBluetoothAuthorizationState.unknown,
    this.supportsApprovedDeviceObservation = false,
  });

  final bool adapterAvailable;
  final bool poweredOn;
  final DeviceBluetoothAuthorizationState authorization;
  final bool supportsApprovedDeviceObservation;

  bool get canObserveApprovedConnections =>
      adapterAvailable &&
      poweredOn &&
      authorization == DeviceBluetoothAuthorizationState.authorized &&
      supportsApprovedDeviceObservation;

  Map<String, Object?> toSafeSummary() => {
    'adapterAvailable': adapterAvailable,
    'poweredOn': poweredOn,
    'authorization': authorization.name,
    'supportsApprovedDeviceObservation': supportsApprovedDeviceObservation,
    'canObserveApprovedConnections': canObserveApprovedConnections,
    'connectedDeviceIdsIncluded': false,
    'rawBluetoothPayloadIncluded': false,
  };
}

class DeviceBluetoothConnectionObservation {
  const DeviceBluetoothConnectionObservation({
    required this.opaqueDeviceId,
    required this.connected,
    required this.observedAtUtc,
  });

  final String opaqueDeviceId;
  final bool connected;
  final DateTime observedAtUtc;
}

abstract interface class DeviceBluetoothCapabilityProbe {
  Future<DeviceBluetoothCapabilities> bluetoothCapabilities();
}

abstract interface class DeviceBluetoothConnectionProbe
    implements DeviceBluetoothCapabilityProbe {
  Stream<DeviceBluetoothConnectionObservation> get approvedConnectionChanges;
}
