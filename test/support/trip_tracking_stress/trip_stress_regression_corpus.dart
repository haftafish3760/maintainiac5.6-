// Named permanent regression cases for the trip stress harness.
//
// Owns deterministic seeds and minimal cross-subsystem states for previously
// repaired or immutable product rules. It does not run policies or store route
// geometry. The stress runner executes these before generated scenarios.

import 'trip_stress_scenario.dart';

List<TripStressScenario> buildTripStressRegressionCorpus() {
  const seed = 7272026;
  const generator = TripStressScenarioGenerator(seed);
  final definitions = <(String, int, String)>[
    (
      'GPS-PR-001-delayed-provider',
      0,
      'delayed_provider_waits_for_registration',
    ),
    ('GPS-HB-001-fresh-after-fix', 3, 'fresh_heartbeat_preserves_active_state'),
    (
      'GPS-BAT-001-charging-projection',
      4,
      'charging_does_not_authorize_stale_distance',
    ),
    (
      'GPS-BT-001-active-vehicle-lock',
      5,
      'active_trip_vehicle_cannot_be_reassigned',
    ),
    ('GPS-AS-001-free-access', 6, 'free_access_cannot_automatically_start'),
    (
      'GPS-LOC-001-cached-start',
      9,
      'cached_location_cannot_become_current_start',
    ),
    ('GPS-DIST-001-walking', 15, 'walking_cannot_create_vehicle_mileage'),
    (
      'GPS-OWN-001-terminal-history',
      19,
      'confirmed_terminal_history_is_immutable',
    ),
  ];
  return [
    for (final definition in definitions)
      _named(generator.generate(definition.$2), definition.$1, definition.$3),
  ];
}

TripStressScenario _named(
  TripStressScenario source,
  String id,
  String expectedRule,
) => TripStressScenario(
  id: id,
  masterSeed: source.masterSeed,
  scenarioSeed: source.scenarioSeed,
  index: source.index,
  family: source.family,
  providerState: source.providerState,
  permissionState: source.permissionState,
  batteryState: source.batteryState,
  bluetoothState: source.bluetoothState,
  lifecycleEvent: source.lifecycleEvent,
  distanceClass: source.distanceClass,
  stopClass: source.stopClass,
  recoveryPath: source.recoveryPath,
  initialLifecycleIndex: source.initialLifecycleIndex,
  targetLifecycleIndex: source.targetLifecycleIndex,
  variant: source.variant,
  vehicleId: source.vehicleId,
  profileId: source.profileId,
  hasActiveSession: source.hasActiveSession,
  hasUnfinishedSession: source.hasUnfinishedSession,
  paidAccess: source.paidAccess,
  bluetoothRecognitionEnabled: source.bluetoothRecognitionEnabled,
  automaticVehicleSwitchEnabled: source.automaticVehicleSwitchEnabled,
  expectedRule: expectedRule,
);
