import 'maintainiac_qa_environment.dart';

enum MaintainiacDeviceClass { legacy, standard, modern, highEnd }

enum MaintainiacPackDeliveryMode { local, compactLocal, cloudAssist, blocked }

class MaintainiacDeviceCapabilityProbe {
  const MaintainiacDeviceCapabilityProbe({
    this.minLocalPackBytes = 150 * 1024 * 1024,
    this.minCompactPackBytes = 25 * 1024 * 1024,
  });

  final int minLocalPackBytes;
  final int minCompactPackBytes;

  MaintainiacDeviceClass classify(FakeDeviceState device) {
    final model = device.model.toLowerCase();
    if (model.contains('s24') ||
        model.contains('s25') ||
        model.contains('iphone 15') ||
        model.contains('iphone 16')) {
      return MaintainiacDeviceClass.highEnd;
    }
    if (model.contains('s22') ||
        model.contains('s23') ||
        model.contains('pixel 7') ||
        model.contains('pixel 8')) {
      return MaintainiacDeviceClass.modern;
    }
    if (model.contains('s9') ||
        model.contains('iphone 8') ||
        model.contains('iphone x')) {
      return MaintainiacDeviceClass.legacy;
    }
    return MaintainiacDeviceClass.standard;
  }

  MaintainiacPackDeliveryMode choosePackMode({
    required FakeDeviceState device,
    required bool userAllowsCloudAssist,
    required bool online,
  }) {
    if (!device.appCheckValid) return MaintainiacPackDeliveryMode.blocked;
    if (device.freeBytes >= minLocalPackBytes && !device.batterySaver) {
      return MaintainiacPackDeliveryMode.local;
    }
    if (device.freeBytes >= minCompactPackBytes) {
      return MaintainiacPackDeliveryMode.compactLocal;
    }
    if (userAllowsCloudAssist && online) {
      return MaintainiacPackDeliveryMode.cloudAssist;
    }
    return MaintainiacPackDeliveryMode.blocked;
  }

  Map<String, Object?> explain({
    required FakeDeviceState device,
    required bool userAllowsCloudAssist,
    required bool online,
  }) {
    final deviceClass = classify(device);
    final mode = choosePackMode(
      device: device,
      userAllowsCloudAssist: userAllowsCloudAssist,
      online: online,
    );
    return {
      'deviceClass': deviceClass.name,
      'packMode': mode.name,
      'freeBytes': device.freeBytes,
      'batterySaver': device.batterySaver,
      'appCheckValid': device.appCheckValid,
      'online': online,
      'userAllowsCloudAssist': userAllowsCloudAssist,
    };
  }
}

class MaintainiacDeviceDeliveryCase {
  const MaintainiacDeviceDeliveryCase({
    required this.id,
    required this.device,
    required this.userAllowsCloudAssist,
    required this.online,
    required this.expectedClass,
    required this.expectedMode,
    required this.reason,
  });

  final String id;
  final FakeDeviceState device;
  final bool userAllowsCloudAssist;
  final bool online;
  final MaintainiacDeviceClass expectedClass;
  final MaintainiacPackDeliveryMode expectedMode;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) {
      failures.add('device delivery case missing id');
    }
    if (reason.trim().isEmpty) {
      failures.add('$id missing reason');
    }
    const probe = MaintainiacDeviceCapabilityProbe();
    final actualClass = probe.classify(device);
    final actualMode = probe.choosePackMode(
      device: device,
      userAllowsCloudAssist: userAllowsCloudAssist,
      online: online,
    );
    if (actualClass != expectedClass) {
      failures.add('$id expected class ${expectedClass.name}');
    }
    if (actualMode != expectedMode) {
      failures.add('$id expected mode ${expectedMode.name}');
    }
    if (expectedMode == MaintainiacPackDeliveryMode.cloudAssist &&
        (!userAllowsCloudAssist || !online)) {
      failures.add('$id cloud assist requires opt-in and online state');
    }
    if (!device.appCheckValid &&
        expectedMode != MaintainiacPackDeliveryMode.blocked) {
      failures.add('$id invalid App Check must be blocked');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'deviceModel': device.model,
      'userAllowsCloudAssist': userAllowsCloudAssist,
      'online': online,
      'expectedClass': expectedClass.name,
      'expectedMode': expectedMode.name,
      'freeBytes': device.freeBytes,
      'batterySaver': device.batterySaver,
      'appCheckValid': device.appCheckValid,
      'reason': reason,
    };
  }
}

class MaintainiacDeviceDeliveryMatrix {
  const MaintainiacDeviceDeliveryMatrix(this.cases);

  final List<MaintainiacDeviceDeliveryCase> cases;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    final classes = <MaintainiacDeviceClass>{};
    final modes = <MaintainiacPackDeliveryMode>{};
    for (final entry in cases) {
      if (!ids.add(entry.id)) {
        failures.add('duplicate device delivery case ${entry.id}');
      }
      classes.add(entry.expectedClass);
      modes.add(entry.expectedMode);
      failures.addAll(entry.validate());
    }
    for (final required in MaintainiacDeviceClass.values) {
      if (!classes.contains(required)) {
        failures.add('device delivery matrix missing class ${required.name}');
      }
    }
    for (final required in MaintainiacPackDeliveryMode.values) {
      if (!modes.contains(required)) {
        failures.add('device delivery matrix missing mode ${required.name}');
      }
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'caseCount': cases.length,
      'cases': [for (final entry in cases) entry.toJson()],
    };
  }
}

const maintainiacDeviceDeliveryMatrix = MaintainiacDeviceDeliveryMatrix([
  MaintainiacDeviceDeliveryCase(
    id: 's24_full_local_pack',
    device: FakeDeviceState(
      model: 'Galaxy S24 Ultra',
      appCheckValid: true,
      freeBytes: 1024 * 1024 * 1024,
      batterySaver: false,
    ),
    userAllowsCloudAssist: false,
    online: false,
    expectedClass: MaintainiacDeviceClass.highEnd,
    expectedMode: MaintainiacPackDeliveryMode.local,
    reason: 'High-end devices with space should use fastest local packs.',
  ),
  MaintainiacDeviceDeliveryCase(
    id: 's23_modern_local_pack',
    device: FakeDeviceState(
      model: 'Galaxy S23 Ultra',
      appCheckValid: true,
      freeBytes: 512 * 1024 * 1024,
      batterySaver: false,
    ),
    userAllowsCloudAssist: false,
    online: false,
    expectedClass: MaintainiacDeviceClass.modern,
    expectedMode: MaintainiacPackDeliveryMode.local,
    reason: 'Modern devices with enough storage can run local packs.',
  ),
  MaintainiacDeviceDeliveryCase(
    id: 'standard_compact_pack',
    device: FakeDeviceState(
      model: 'Midrange Android',
      appCheckValid: true,
      freeBytes: 50 * 1024 * 1024,
      batterySaver: false,
    ),
    userAllowsCloudAssist: false,
    online: false,
    expectedClass: MaintainiacDeviceClass.standard,
    expectedMode: MaintainiacPackDeliveryMode.compactLocal,
    reason: 'Standard low-storage devices should use compact local packs.',
  ),
  MaintainiacDeviceDeliveryCase(
    id: 'legacy_cloud_assist_opt_in',
    device: FakeDeviceState(
      model: 'Galaxy S9 Plus',
      appCheckValid: true,
      freeBytes: 5 * 1024 * 1024,
      batterySaver: false,
    ),
    userAllowsCloudAssist: true,
    online: true,
    expectedClass: MaintainiacDeviceClass.legacy,
    expectedMode: MaintainiacPackDeliveryMode.cloudAssist,
    reason: 'Very low-storage legacy devices need explicit cloud assist.',
  ),
  MaintainiacDeviceDeliveryCase(
    id: 'invalid_app_check_blocked',
    device: FakeDeviceState(
      model: 'Unknown Android',
      appCheckValid: false,
      freeBytes: 1024 * 1024 * 1024,
      batterySaver: false,
    ),
    userAllowsCloudAssist: true,
    online: true,
    expectedClass: MaintainiacDeviceClass.standard,
    expectedMode: MaintainiacPackDeliveryMode.blocked,
    reason: 'Invalid App Check blocks pack delivery.',
  ),
]);
