import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test(
    'device capability probe allows full local packs on high-end devices',
    () {
      const probe = MaintainiacDeviceCapabilityProbe();
      const device = FakeDeviceState(
        model: 'Galaxy S24 Ultra',
        appCheckValid: true,
        freeBytes: 1024 * 1024 * 1024,
        batterySaver: false,
      );

      expect(probe.classify(device), MaintainiacDeviceClass.highEnd);
      expect(
        probe.choosePackMode(
          device: device,
          userAllowsCloudAssist: false,
          online: false,
        ),
        MaintainiacPackDeliveryMode.local,
      );
    },
  );

  test('device capability probe falls back for low-storage older phones', () {
    const probe = MaintainiacDeviceCapabilityProbe();
    const device = FakeDeviceState(
      model: 'Galaxy S9 Plus',
      appCheckValid: true,
      freeBytes: 40 * 1024 * 1024,
      batterySaver: false,
    );

    expect(probe.classify(device), MaintainiacDeviceClass.legacy);
    expect(
      probe.choosePackMode(
        device: device,
        userAllowsCloudAssist: false,
        online: false,
      ),
      MaintainiacPackDeliveryMode.compactLocal,
    );
  });

  test('device capability probe blocks unsafe or offline cloud-only cases', () {
    const probe = MaintainiacDeviceCapabilityProbe();
    const unsafe = FakeDeviceState(
      model: 'Unknown',
      appCheckValid: false,
      freeBytes: 1024 * 1024 * 1024,
      batterySaver: false,
    );
    const lowStorage = FakeDeviceState(
      model: 'Unknown',
      appCheckValid: true,
      freeBytes: 5 * 1024 * 1024,
      batterySaver: false,
    );

    expect(
      probe.choosePackMode(
        device: unsafe,
        userAllowsCloudAssist: true,
        online: true,
      ),
      MaintainiacPackDeliveryMode.blocked,
    );
    expect(
      probe.choosePackMode(
        device: lowStorage,
        userAllowsCloudAssist: true,
        online: false,
      ),
      MaintainiacPackDeliveryMode.blocked,
    );
    expect(
      probe.choosePackMode(
        device: lowStorage,
        userAllowsCloudAssist: true,
        online: true,
      ),
      MaintainiacPackDeliveryMode.cloudAssist,
    );
  });

  test(
    'device delivery matrix covers local compact cloud and blocked modes',
    () {
      const matrix = maintainiacDeviceDeliveryMatrix;

      expect(matrix.validate(), isEmpty);
      expect(matrix.toJson().toString(), contains('s24_full_local_pack'));
      expect(matrix.toJson().toString(), contains('standard_compact_pack'));
      expect(
        matrix.toJson().toString(),
        contains('legacy_cloud_assist_opt_in'),
      );
      expect(matrix.toJson().toString(), contains('invalid_app_check_blocked'));
    },
  );

  test('device delivery matrix rejects unsafe cloud and App Check cases', () {
    const matrix = MaintainiacDeviceDeliveryMatrix([
      MaintainiacDeviceDeliveryCase(
        id: 'bad_cloud',
        device: FakeDeviceState(
          model: 'Galaxy S9 Plus',
          appCheckValid: true,
          freeBytes: 5 * 1024 * 1024,
          batterySaver: false,
        ),
        userAllowsCloudAssist: false,
        online: false,
        expectedClass: MaintainiacDeviceClass.legacy,
        expectedMode: MaintainiacPackDeliveryMode.cloudAssist,
        reason: '',
      ),
      MaintainiacDeviceDeliveryCase(
        id: 'bad_app_check',
        device: FakeDeviceState(
          model: 'Unknown Android',
          appCheckValid: false,
          freeBytes: 1024 * 1024 * 1024,
          batterySaver: false,
        ),
        userAllowsCloudAssist: true,
        online: true,
        expectedClass: MaintainiacDeviceClass.standard,
        expectedMode: MaintainiacPackDeliveryMode.local,
        reason: 'bad',
      ),
    ]);

    final failures = matrix.validate().join('\n');

    expect(failures, contains('bad_cloud missing reason'));
    expect(failures, contains('bad_cloud expected mode cloudAssist'));
    expect(failures, contains('bad_cloud cloud assist requires opt-in'));
    expect(
      failures,
      contains('bad_app_check invalid App Check must be blocked'),
    );
    expect(failures, contains('device delivery matrix missing class modern'));
  });
}
