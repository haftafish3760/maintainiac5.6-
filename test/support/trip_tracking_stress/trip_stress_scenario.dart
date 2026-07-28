// Deterministic scenario dimensions for GPS trip stress testing.
//
// Owns bounded scenario generation and failure-safe metadata. It does not
// evaluate production policy, persist trip data, or retain route geometry.
// The stress evaluator, saved corpus, and command-line runner consume it.

enum TripStressFamily {
  providerStartup,
  locationEvidence,
  motionStops,
  lifecycleRecovery,
  batteryDevice,
  bluetooth,
  automaticStart,
  distanceOdometer,
}

enum TripStressProviderState {
  immediate,
  delayed,
  unavailable,
  late,
  duplicate,
  lost,
}

enum TripStressPermissionState {
  always,
  whileInUse,
  approximate,
  denied,
  revoked,
}

enum TripStressBatteryState { normal, low, critical, charging, unplugged }

enum TripStressBluetoothState {
  correct,
  wrong,
  multiple,
  stale,
  disabled,
  denied,
  reconnect,
  duplicate,
}

enum TripStressLifecycleEvent {
  foreground,
  background,
  restart,
  processDeath,
  osKill,
  completionPending,
  clockForward,
  clockBackward,
  timeZoneChange,
}

enum TripStressDistanceClass { zero, measured, estimatedGap, rejected, mixed }

enum TripStressStopClass {
  none,
  briefPause,
  longDwell,
  walking,
  traffic,
  jobsite,
}

enum TripStressRecoveryPath {
  none,
  waiting,
  degraded,
  snapshot,
  duplicateCallback,
  providerLoss,
}

final class TripStressScenario {
  const TripStressScenario({
    required this.id,
    required this.masterSeed,
    required this.scenarioSeed,
    required this.index,
    required this.family,
    required this.providerState,
    required this.permissionState,
    required this.batteryState,
    required this.bluetoothState,
    required this.lifecycleEvent,
    required this.distanceClass,
    required this.stopClass,
    required this.recoveryPath,
    required this.initialLifecycleIndex,
    required this.targetLifecycleIndex,
    required this.variant,
    required this.vehicleId,
    required this.profileId,
    required this.hasActiveSession,
    required this.hasUnfinishedSession,
    required this.paidAccess,
    required this.bluetoothRecognitionEnabled,
    required this.automaticVehicleSwitchEnabled,
    required this.expectedRule,
  });

  final String id;
  final int masterSeed;
  final int scenarioSeed;
  final int index;
  final TripStressFamily family;
  final TripStressProviderState providerState;
  final TripStressPermissionState permissionState;
  final TripStressBatteryState batteryState;
  final TripStressBluetoothState bluetoothState;
  final TripStressLifecycleEvent lifecycleEvent;
  final TripStressDistanceClass distanceClass;
  final TripStressStopClass stopClass;
  final TripStressRecoveryPath recoveryPath;
  final int initialLifecycleIndex;
  final int targetLifecycleIndex;
  final int variant;
  final String vehicleId;
  final String profileId;
  final bool hasActiveSession;
  final bool hasUnfinishedSession;
  final bool paidAccess;
  final bool bluetoothRecognitionEnabled;
  final bool automaticVehicleSwitchEnabled;
  final String expectedRule;

  List<String> get eventSequence => [
    'initialize:${initialLifecycleIndex.clamp(0, 14)}',
    '${family.name}:${variant % 12}',
    'lifecycle:${lifecycleEvent.name}',
    'recovery:${recoveryPath.name}',
  ];

  Map<String, Object?> toFailureMap() => {
    'id': id,
    'masterSeed': masterSeed,
    'scenarioSeed': scenarioSeed,
    'scenarioIndex': index,
    'family': family.name,
    'eventSequence': eventSequence,
    'initialStateIndex': initialLifecycleIndex,
    'targetStateIndex': targetLifecycleIndex,
    'vehicleId': vehicleId,
    'profileId': profileId,
    'permissionState': permissionState.name,
    'providerState': providerState.name,
    'batteryState': batteryState.name,
    'bluetoothState': bluetoothState.name,
    'lifecycleEvent': lifecycleEvent.name,
    'distanceClass': distanceClass.name,
    'stopClass': stopClass.name,
    'recoveryPath': recoveryPath.name,
    'hasActiveSession': hasActiveSession,
    'hasUnfinishedSession': hasUnfinishedSession,
    'paidAccess': paidAccess,
    'expectedRule': expectedRule,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
  };

  TripStressScenario copyWith({
    TripStressBluetoothState? bluetoothState,
    bool? hasActiveSession,
    bool? hasUnfinishedSession,
    bool? paidAccess,
    bool? bluetoothRecognitionEnabled,
    bool? automaticVehicleSwitchEnabled,
  }) => TripStressScenario(
    id: id,
    masterSeed: masterSeed,
    scenarioSeed: scenarioSeed,
    index: index,
    family: family,
    providerState: providerState,
    permissionState: permissionState,
    batteryState: batteryState,
    bluetoothState: bluetoothState ?? this.bluetoothState,
    lifecycleEvent: lifecycleEvent,
    distanceClass: distanceClass,
    stopClass: stopClass,
    recoveryPath: recoveryPath,
    initialLifecycleIndex: initialLifecycleIndex,
    targetLifecycleIndex: targetLifecycleIndex,
    variant: variant,
    vehicleId: vehicleId,
    profileId: profileId,
    hasActiveSession: hasActiveSession ?? this.hasActiveSession,
    hasUnfinishedSession: hasUnfinishedSession ?? this.hasUnfinishedSession,
    paidAccess: paidAccess ?? this.paidAccess,
    bluetoothRecognitionEnabled:
        bluetoothRecognitionEnabled ?? this.bluetoothRecognitionEnabled,
    automaticVehicleSwitchEnabled:
        automaticVehicleSwitchEnabled ?? this.automaticVehicleSwitchEnabled,
    expectedRule: expectedRule,
  );
}

final class TripStressScenarioGenerator {
  const TripStressScenarioGenerator(this.masterSeed);

  final int masterSeed;

  TripStressScenario generate(int index) {
    if (index < 0) throw RangeError.value(index, 'index');
    final scenarioSeed = _mix64(masterSeed, index);
    final random = _StressRandom(scenarioSeed);
    final family =
        TripStressFamily.values[index % TripStressFamily.values.length];
    return TripStressScenario(
      id: 'GPS-STRESS-${index.toString().padLeft(7, '0')}',
      masterSeed: masterSeed,
      scenarioSeed: scenarioSeed,
      index: index,
      family: family,
      providerState: random.pick(TripStressProviderState.values),
      permissionState: random.pick(TripStressPermissionState.values),
      batteryState: random.pick(TripStressBatteryState.values),
      bluetoothState: random.pick(TripStressBluetoothState.values),
      lifecycleEvent: random.pick(TripStressLifecycleEvent.values),
      distanceClass: random.pick(TripStressDistanceClass.values),
      stopClass: random.pick(TripStressStopClass.values),
      recoveryPath: random.pick(TripStressRecoveryPath.values),
      initialLifecycleIndex: random.nextInt(15),
      targetLifecycleIndex: random.nextInt(15),
      variant: random.nextInt(120),
      vehicleId: 'vehicle_${random.nextInt(4) + 1}',
      profileId: const [
        'road',
        'delivery',
        'contractor',
        'equipment',
      ][random.nextInt(4)],
      hasActiveSession: random.nextBool(),
      hasUnfinishedSession: random.nextBool(),
      paidAccess: random.nextBool(),
      bluetoothRecognitionEnabled: random.nextBool(),
      automaticVehicleSwitchEnabled: random.nextBool(),
      expectedRule: _expectedRule(family),
    );
  }
}

String _expectedRule(TripStressFamily family) => switch (family) {
  TripStressFamily.providerStartup => 'native_events_obey_local_lifecycle',
  TripStressFamily.locationEvidence => 'unsafe_location_never_feeds_engine',
  TripStressFamily.motionStops => 'walking_and_stops_remain_advisory',
  TripStressFamily.lifecycleRecovery => 'terminal_history_is_immutable',
  TripStressFamily.batteryDevice => 'gps_pause_keeps_triplog_writable',
  TripStressFamily.bluetooth => 'bluetooth_never_reassigns_active_trip',
  TripStressFamily.automaticStart => 'paid_multi_signal_evidence_required',
  TripStressFamily.distanceOdometer => 'gps_never_becomes_odometer_truth',
};

int _mix64(int seed, int index) {
  var value = (seed ^ (index * 0x9E3779B97F4A7C15)) & 0xFFFFFFFFFFFFFFFF;
  value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF;
  value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF;
  return (value ^ (value >> 31)) & 0x7FFFFFFFFFFFFFFF;
}

final class _StressRandom {
  _StressRandom(int seed) : _state = seed == 0 ? 0x5EED : seed;

  int _state;

  int nextInt(int maximum) {
    if (maximum <= 0) throw RangeError.value(maximum, 'maximum');
    _state ^= (_state << 13) & 0x7FFFFFFFFFFFFFFF;
    _state ^= _state >> 7;
    _state ^= (_state << 17) & 0x7FFFFFFFFFFFFFFF;
    return (_state & 0x7FFFFFFFFFFFFFFF) % maximum;
  }

  bool nextBool() => nextInt(2) == 1;

  T pick<T>(List<T> values) => values[nextInt(values.length)];
}
