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
}
