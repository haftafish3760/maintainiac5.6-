enum DeviceStorageStatus { unknown, green, yellow, orange, red }

/// A non-blocking storage warning shared by every module.
///
/// Workloads may scale down under pressure, but this assessment never denies
/// access to an app feature.
class DeviceStorageAssessment {
  const DeviceStorageAssessment._(this.status, this.freeStorageMb);

  factory DeviceStorageAssessment.fromFreeMb(int? freeStorageMb) {
    final status = switch (freeStorageMb) {
      null => DeviceStorageStatus.unknown,
      <= 250 => DeviceStorageStatus.red,
      < 500 => DeviceStorageStatus.orange,
      < 1024 => DeviceStorageStatus.yellow,
      _ => DeviceStorageStatus.green,
    };
    return DeviceStorageAssessment._(status, freeStorageMb);
  }

  final DeviceStorageStatus status;
  final int? freeStorageMb;

  bool get shouldWarn =>
      status == DeviceStorageStatus.yellow ||
      status == DeviceStorageStatus.orange ||
      status == DeviceStorageStatus.red;

  /// Storage warnings are advisory; modules must not block the user.
  bool get blocksUserAction => false;

  String? get userMessage => switch (status) {
    DeviceStorageStatus.unknown => null,
    DeviceStorageStatus.green => null,
    DeviceStorageStatus.yellow =>
      'Device storage is getting low. Consider freeing space soon.',
    DeviceStorageStatus.orange =>
      'Device storage is very low. Freeing space is strongly recommended.',
    DeviceStorageStatus.red =>
      'Device storage is critically low. Free space to avoid failed saves.',
  };
}
