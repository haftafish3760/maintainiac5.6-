import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_device_profile.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  test('plumbing residential core pack stays small and install-safe', () {
    final option = buildWorkSupplyTradePackOptionsForScope(
      'Plumbing',
      marketScope: WorkSupplyMarketScope.residential,
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.core);
    final profile = WorkSupplyParserDeviceProfile.fromCapability(
      const ReceiptDeviceCapability.highCapacity(),
    );
    final requiredBytes = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: null,
      isMeteredNetwork: false,
      deviceProfile: profile,
    ).requiredFreeBytes;

    expect(option.itemCount, greaterThan(100));
    expect(option.estimatedCompressedBytes, lessThan(15 * 1024 * 1024));
    expect(option.estimatedUncompressedBytes, lessThan(50 * 1024 * 1024));

    final tooTight = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: requiredBytes - 1,
      isMeteredNetwork: false,
      deviceProfile: profile,
    );
    final enoughRoom = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: requiredBytes,
      isMeteredNetwork: false,
      deviceProfile: profile,
    );

    expect(tooTight.canInstall, isFalse);
    expect(tooTight.status, WorkSupplyTradePackInstallStatus.notEnoughStorage);
    expect(enoughRoom.canInstall, isTrue);
    expect(enoughRoom.status, WorkSupplyTradePackInstallStatus.ready);
  });

  test(
    'blocks pack install when the phone does not have enough free space',
    () {
      final option = buildWorkSupplyTradePackOptions('Plumbing').firstWhere(
        (candidate) => candidate.tier == WorkSupplyTradePackTier.core,
      );
      final check = checkWorkSupplyTradePackInstall(
        option: option,
        availableStorageBytes: 2 * 1024 * 1024,
        isMeteredNetwork: false,
        deviceProfile: WorkSupplyParserDeviceProfile.fromCapability(
          const ReceiptDeviceCapability.highCapacity(),
        ),
      );

      expect(check.canInstall, isFalse);
      expect(check.status, WorkSupplyTradePackInstallStatus.notEnoughStorage);
      expect(
        check.requiredFreeBytes,
        greaterThan(option.estimatedCompressedBytes),
      );
      expect(
        check.requiredFreeBytes,
        greaterThanOrEqualTo(option.estimatedUncompressedBytes),
      );
    },
  );

  test('storage check accounts for unzipped on-device pack size', () {
    final option = buildWorkSupplyTradePackOptionsForScope(
      'Plumbing',
      marketScope: WorkSupplyMarketScope.residential,
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.full);
    final check = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: option.estimatedUncompressedBytes - 1,
      isMeteredNetwork: false,
      deviceProfile: WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      ),
    );

    expect(check.canInstall, isFalse);
    expect(check.status, WorkSupplyTradePackInstallStatus.notEnoughStorage);
    expect(check.message, contains('download, unpack, and recover'));
  });

  test('blocks pack install when free storage cannot be verified', () {
    final option = buildWorkSupplyTradePackOptions(
      'Plumbing',
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.core);
    final check = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: null,
      isMeteredNetwork: false,
      deviceProfile: WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      ),
    );

    expect(check.canInstall, isFalse);
    expect(check.status, WorkSupplyTradePackInstallStatus.storageUnknown);
    expect(check.message, contains('could not be verified'));
  });

  test('warns before large pack downloads on metered data', () {
    final option = buildWorkSupplyTradePackOptions(
      'Plumbing',
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.full);
    final check = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: 500 * 1024 * 1024,
      isMeteredNetwork: true,
      deviceProfile: WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      ),
    );

    expect(check.canInstall, isTrue);
    expect(check.status, WorkSupplyTradePackInstallStatus.wifiRecommended);
  });

  test('keeps older phones on smaller packs', () {
    final option = buildWorkSupplyTradePackOptions('Plumbing').firstWhere(
      (candidate) => candidate.tier == WorkSupplyTradePackTier.professional,
    );
    final check = checkWorkSupplyTradePackInstall(
      option: option,
      availableStorageBytes: 500 * 1024 * 1024,
      isMeteredNetwork: false,
      deviceProfile: WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.olderPhone(),
      ),
    );

    expect(check.canInstall, isFalse);
    expect(check.status, WorkSupplyTradePackInstallStatus.deviceTooLight);
  });
}
