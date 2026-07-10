import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('sync transport policy covers manual scheduled and automatic paths', () {
    const policy = maintainiacSyncTransportPolicy;

    expect(policy.validate(), isEmpty);
    expect(policy.casesForTrigger(MaintainiacSyncTrigger.manual), hasLength(2));
    expect(
      policy.toJson().toString(),
      contains('scheduled_battery_saver_paused'),
    );
    expect(policy.toJson().toString(), contains('automatic_wifi_allowed'));
    expect(policy.toJson().toString(), contains('manual_cellular_allowed'));
  });

  test('sync transport policy rejects unsafe network expectations', () {
    const policy = MaintainiacSyncTransportPolicy([
      MaintainiacSyncTransportCase(
        id: 'bad_roaming',
        trigger: MaintainiacSyncTrigger.manual,
        network: MaintainiacNetworkState.roaming,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: false,
        expectedAllowed: true,
        reason: '',
      ),
      MaintainiacSyncTransportCase(
        id: 'bad_battery',
        trigger: MaintainiacSyncTrigger.scheduled,
        network: MaintainiacNetworkState.wifi,
        wifiOnly: false,
        cellularAllowed: true,
        batterySaver: true,
        expectedAllowed: true,
        reason: 'bad',
      ),
    ]);

    final failures = policy.validate().join('\n');

    expect(failures, contains('bad_roaming missing reason'));
    expect(failures, contains('bad_roaming must not allow roaming sync'));
    expect(failures, contains('bad_battery must pause in battery saver'));
    expect(
      failures,
      contains('sync transport policy missing trigger automatic'),
    );
    expect(failures, contains('sync transport policy missing network offline'));
  });
}
