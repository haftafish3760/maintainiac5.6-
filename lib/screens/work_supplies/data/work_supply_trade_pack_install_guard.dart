import 'work_supply_parser_device_profile.dart';
import 'work_supply_trade_pack_tiers.dart';

const workSupplyTradePackStorageSafetyMultiplier = 3;
const workSupplyTradePackMinimumSafetyBytes = 25 * 1024 * 1024;

enum WorkSupplyTradePackInstallStatus {
  ready,
  wifiRecommended,
  storageUnknown,
  notEnoughStorage,
  deviceTooLight,
}

class WorkSupplyTradePackInstallCheck {
  const WorkSupplyTradePackInstallCheck({
    required this.status,
    required this.requiredFreeBytes,
    required this.message,
  });

  final WorkSupplyTradePackInstallStatus status;
  final int requiredFreeBytes;
  final String message;

  bool get canInstall =>
      status == WorkSupplyTradePackInstallStatus.ready ||
      status == WorkSupplyTradePackInstallStatus.wifiRecommended;
}

WorkSupplyTradePackInstallCheck checkWorkSupplyTradePackInstall({
  required WorkSupplyTradePackOption option,
  required int? availableStorageBytes,
  required bool isMeteredNetwork,
  required WorkSupplyParserDeviceProfile deviceProfile,
}) {
  final requiredBytes = _requiredFreeBytes(option.estimatedCompressedBytes);
  if (availableStorageBytes == null) {
    return WorkSupplyTradePackInstallCheck(
      status: WorkSupplyTradePackInstallStatus.storageUnknown,
      requiredFreeBytes: requiredBytes,
      message:
          'Free storage could not be verified. Needs about ${workSupplyByteSizeLabel(requiredBytes)} free before downloading safely.',
    );
  }
  if (availableStorageBytes < requiredBytes) {
    return WorkSupplyTradePackInstallCheck(
      status: WorkSupplyTradePackInstallStatus.notEnoughStorage,
      requiredFreeBytes: requiredBytes,
      message:
          'Needs about ${workSupplyByteSizeLabel(requiredBytes)} free so the pack can download, unpack, and recover safely.',
    );
  }
  if (_deviceShouldAvoidPack(option, deviceProfile)) {
    return WorkSupplyTradePackInstallCheck(
      status: WorkSupplyTradePackInstallStatus.deviceTooLight,
      requiredFreeBytes: requiredBytes,
      message:
          'This device should use a smaller pack so receipt matching stays responsive.',
    );
  }
  if (isMeteredNetwork && option.estimatedCompressedBytes > 0) {
    return WorkSupplyTradePackInstallCheck(
      status: WorkSupplyTradePackInstallStatus.wifiRecommended,
      requiredFreeBytes: requiredBytes,
      message:
          'This pack may use ${option.estimatedSizeLabel}. Wi-Fi is recommended before downloading.',
    );
  }
  return WorkSupplyTradePackInstallCheck(
    status: WorkSupplyTradePackInstallStatus.ready,
    requiredFreeBytes: requiredBytes,
    message: 'Ready to install with bundled chunks and no per-item reads.',
  );
}

String workSupplyByteSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
  return '${(kib / 1024).toStringAsFixed(1)} MB';
}

int _requiredFreeBytes(int compressedBytes) {
  final buffered = compressedBytes * workSupplyTradePackStorageSafetyMultiplier;
  return buffered < workSupplyTradePackMinimumSafetyBytes
      ? workSupplyTradePackMinimumSafetyBytes
      : buffered;
}

bool _deviceShouldAvoidPack(
  WorkSupplyTradePackOption option,
  WorkSupplyParserDeviceProfile deviceProfile,
) {
  if (deviceProfile.canRunInventoryMatching) return false;
  return option.tier == WorkSupplyTradePackTier.professional ||
      option.tier == WorkSupplyTradePackTier.full;
}
