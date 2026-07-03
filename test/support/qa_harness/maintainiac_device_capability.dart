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
