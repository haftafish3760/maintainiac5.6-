import 'maintainiac_qa_environment.dart';
import 'maintainiac_qa_quality_gates.dart';

enum MaintainiacSyncTrigger { automatic, manual, scheduled }

class MaintainiacSyncTransportCase {
  const MaintainiacSyncTransportCase({
    required this.id,
    required this.trigger,
    required this.network,
    required this.wifiOnly,
    required this.cellularAllowed,
    required this.batterySaver,
    required this.expectedAllowed,
    required this.reason,
  });

  final String id;
  final MaintainiacSyncTrigger trigger;
  final MaintainiacNetworkState network;
  final bool wifiOnly;
  final bool cellularAllowed;
  final bool batterySaver;
  final bool expectedAllowed;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('sync transport case missing id');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    final actual = const MaintainiacSyncPolicyProbe().shouldSync(
      network: network,
      wifiOnly: wifiOnly,
      cellularAllowed: cellularAllowed,
      batterySaver: batterySaver,
    );
    if (actual != expectedAllowed) {
      failures.add('$id expected $expectedAllowed but policy returned $actual');
    }
    if (network == MaintainiacNetworkState.roaming && expectedAllowed) {
      failures.add('$id must not allow roaming sync');
    }
    if (batterySaver && expectedAllowed) {
      failures.add('$id must pause in battery saver');
    }
    if (network == MaintainiacNetworkState.cellular &&
        wifiOnly &&
        expectedAllowed) {
      failures.add('$id must block cellular when wifi-only is enabled');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'trigger': trigger.name,
      'network': network.name,
      'wifiOnly': wifiOnly,
      'cellularAllowed': cellularAllowed,
      'batterySaver': batterySaver,
      'expectedAllowed': expectedAllowed,
      'reason': reason,
    };
  }
}

class MaintainiacSyncTransportPolicy {
  const MaintainiacSyncTransportPolicy(this.cases);

  final List<MaintainiacSyncTransportCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final triggers = <MaintainiacSyncTrigger>{};
    final networks = <MaintainiacNetworkState>{};
    for (final entry in cases) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate sync transport case ${entry.id}');
      }
      triggers.add(entry.trigger);
      networks.add(entry.network);
      failures.addAll(entry.validate());
    }
    for (final required in MaintainiacSyncTrigger.values) {
      if (!triggers.contains(required)) {
        failures.add('sync transport policy missing trigger ${required.name}');
      }
    }
    for (final required in MaintainiacNetworkState.values) {
      if (!networks.contains(required)) {
        failures.add('sync transport policy missing network ${required.name}');
      }
    }
    if (!cases.any((entry) => entry.expectedAllowed)) {
      failures.add('sync transport policy has no allowed path');
    }
    if (!cases.any((entry) => !entry.expectedAllowed)) {
      failures.add('sync transport policy has no blocked path');
    }
    return failures;
  }

  List<MaintainiacSyncTransportCase> casesForTrigger(
    MaintainiacSyncTrigger trigger,
  ) {
    return [
      for (final entry in cases)
        if (entry.trigger == trigger) entry,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'triggers': ({for (final entry in cases) entry.trigger.name}.toList()
        ..sort()),
      'networks': ({for (final entry in cases) entry.network.name}.toList()
        ..sort()),
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacSyncTransportPolicy = MaintainiacSyncTransportPolicy([
  MaintainiacSyncTransportCase(
    id: 'automatic_wifi_allowed',
    trigger: MaintainiacSyncTrigger.automatic,
    network: MaintainiacNetworkState.wifi,
    wifiOnly: true,
    cellularAllowed: false,
    batterySaver: false,
    expectedAllowed: true,
    reason: 'Wi-Fi is the safest automatic sync path.',
  ),
  MaintainiacSyncTransportCase(
    id: 'automatic_offline_blocked',
    trigger: MaintainiacSyncTrigger.automatic,
    network: MaintainiacNetworkState.offline,
    wifiOnly: false,
    cellularAllowed: true,
    batterySaver: false,
    expectedAllowed: false,
    reason: 'Offline records stay dirty for retry.',
  ),
  MaintainiacSyncTransportCase(
    id: 'automatic_blocked_network_blocked',
    trigger: MaintainiacSyncTrigger.automatic,
    network: MaintainiacNetworkState.blocked,
    wifiOnly: false,
    cellularAllowed: true,
    batterySaver: false,
    expectedAllowed: false,
    reason: 'Blocked network state must not attempt cloud mirror writes.',
  ),
  MaintainiacSyncTransportCase(
    id: 'scheduled_cellular_wifi_only_blocked',
    trigger: MaintainiacSyncTrigger.scheduled,
    network: MaintainiacNetworkState.cellular,
    wifiOnly: true,
    cellularAllowed: true,
    batterySaver: false,
    expectedAllowed: false,
    reason: 'Scheduled sync respects Wi-Fi-only user preference.',
  ),
  MaintainiacSyncTransportCase(
    id: 'manual_cellular_allowed',
    trigger: MaintainiacSyncTrigger.manual,
    network: MaintainiacNetworkState.cellular,
    wifiOnly: false,
    cellularAllowed: true,
    batterySaver: false,
    expectedAllowed: true,
    reason: 'Manual sync may use cellular only when the policy allows it.',
  ),
  MaintainiacSyncTransportCase(
    id: 'manual_roaming_blocked',
    trigger: MaintainiacSyncTrigger.manual,
    network: MaintainiacNetworkState.roaming,
    wifiOnly: false,
    cellularAllowed: true,
    batterySaver: false,
    expectedAllowed: false,
    reason: 'Roaming is blocked to protect user data plans.',
  ),
  MaintainiacSyncTransportCase(
    id: 'scheduled_battery_saver_paused',
    trigger: MaintainiacSyncTrigger.scheduled,
    network: MaintainiacNetworkState.wifi,
    wifiOnly: false,
    cellularAllowed: true,
    batterySaver: true,
    expectedAllowed: false,
    reason: 'Battery saver pauses background sync.',
  ),
]);
