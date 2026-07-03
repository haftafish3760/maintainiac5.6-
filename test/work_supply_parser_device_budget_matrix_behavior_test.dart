import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_device_profile.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_delivery_policy.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  group('inventory parser device budget matrix behavior', () {
    test('device class selects conservative or full parser profiles', () {
      final older = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.olderPhone(),
      );
      final midrange = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.standard(),
      );
      final flagship = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      );

      expect(older.canRunInventoryMatching, isFalse);
      expect(older.enableAdvancedConfidenceScoring, isFalse);
      expect(older.maxCatalogCandidates, lessThan(midrange.maxCatalogCandidates));
      expect(midrange.canRunInventoryMatching, isFalse);
      expect(midrange.enableTradeClassification, isTrue);
      expect(flagship.canRunInventoryMatching, isTrue);
      expect(flagship.enableTradeClassification, isTrue);
      expect(flagship.enableAdvancedConfidenceScoring, isTrue);
      expect(flagship.maxCatalogCandidates, greaterThan(midrange.maxCatalogCandidates));
      expect(flagship.statusLabel, contains('Full inventory'));
    });

    test('low storage blocks large local pack before installation', () {
      final option = _packOption(WorkSupplyTradePackTier.full);
      final profile = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      );
      final unknown = checkWorkSupplyTradePackInstall(
        option: option,
        availableStorageBytes: null,
        isMeteredNetwork: false,
        deviceProfile: profile,
      );
      final shortByOneByte = checkWorkSupplyTradePackInstall(
        option: option,
        availableStorageBytes: unknown.requiredFreeBytes - 1,
        isMeteredNetwork: false,
        deviceProfile: profile,
      );
      final enough = checkWorkSupplyTradePackInstall(
        option: option,
        availableStorageBytes: unknown.requiredFreeBytes,
        isMeteredNetwork: false,
        deviceProfile: profile,
      );

      expect(unknown.status, WorkSupplyTradePackInstallStatus.storageUnknown);
      expect(unknown.canInstall, isFalse);
      expect(shortByOneByte.status, WorkSupplyTradePackInstallStatus.notEnoughStorage);
      expect(shortByOneByte.canInstall, isFalse);
      expect(enough.status, WorkSupplyTradePackInstallStatus.ready);
      expect(enough.canInstall, isTrue);
      expect(
        enough.requiredFreeBytes,
        greaterThanOrEqualTo(option.estimatedUncompressedBytes),
      );
      expect(enough.message, contains('no per-item reads'));
    });

    test('older phones can install core but not professional/full packs', () {
      final older = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.olderPhone(),
      );
      final core = _packOption(WorkSupplyTradePackTier.core);
      final professional = _packOption(WorkSupplyTradePackTier.professional);
      final full = _packOption(WorkSupplyTradePackTier.full);

      final coreCheck = checkWorkSupplyTradePackInstall(
        option: core,
        availableStorageBytes: 500 * 1024 * 1024,
        isMeteredNetwork: false,
        deviceProfile: older,
      );
      final professionalCheck = checkWorkSupplyTradePackInstall(
        option: professional,
        availableStorageBytes: 500 * 1024 * 1024,
        isMeteredNetwork: false,
        deviceProfile: older,
      );
      final fullCheck = checkWorkSupplyTradePackInstall(
        option: full,
        availableStorageBytes: 500 * 1024 * 1024,
        isMeteredNetwork: false,
        deviceProfile: older,
      );

      expect(coreCheck.canInstall, isTrue);
      expect(professionalCheck.status, WorkSupplyTradePackInstallStatus.deviceTooLight);
      expect(fullCheck.status, WorkSupplyTradePackInstallStatus.deviceTooLight);
      expect(professionalCheck.message, contains('smaller pack'));
      expect(fullCheck.message, contains('responsive'));
    });

    test('metered network warns instead of silently downloading packs', () {
      final option = _packOption(WorkSupplyTradePackTier.expanded);
      final profile = WorkSupplyParserDeviceProfile.fromCapability(
        const ReceiptDeviceCapability.highCapacity(),
      );
      final check = checkWorkSupplyTradePackInstall(
        option: option,
        availableStorageBytes: 500 * 1024 * 1024,
        isMeteredNetwork: true,
        deviceProfile: profile,
      );

      expect(check.canInstall, isTrue);
      expect(check.status, WorkSupplyTradePackInstallStatus.wifiRecommended);
      expect(check.message, contains(option.estimatedDownloadSizeLabel));
      expect(check.message, contains(option.estimatedOnDeviceSizeLabel));
      expect(check.message.toLowerCase(), contains('wi-fi'));
    });

    test('local and cloud delivery policy stays explicit and budgeted', () {
      final map = workSupplyTradePackDeliveryPolicy.toMap();
      final local = map['local']! as Map<String, Object?>;
      final cloud = map['cloudFallback']! as Map<String, Object?>;

      expect(local['offlineCapable'], isTrue);
      expect(local['fastest'], isTrue);
      expect(local['requiresDeviceStorage'], isTrue);
      expect(cloud['offlineCapable'], isFalse);
      expect(cloud['requiresInternet'], isTrue);
      expect(cloud['requiresSubscription'], isTrue);
      expect(cloud['slowerThanLocal'], isTrue);
      expect(cloud['usesCarrierOrWifiData'], isTrue);
      expect(cloud['targetCatalogReadsPerReceipt'], lessThanOrEqualTo(100));
      expect(cloud['targetCatalogReadsPerUserPerDay'], lessThanOrEqualTo(100));
    });

    test('runtime profile report records budget signals without live services', () {
      final report = _runtimeBudgetReport(
        deviceClass: 'Galaxy S24',
        packSizeBytes: 12 * 1024 * 1024,
        availableBytes: 300 * 1024 * 1024,
        coldStartMs: 180,
        warmRunMs: 24,
        indexingTimeMs: 90,
        memoryGrowthBytes: 4 * 1024 * 1024,
        slowestRule: 'merchant_alias_normalization',
        checksPerSecond: 1200,
        readBudget: 0,
        liveFirebaseUsed: false,
      );

      expect(report['deviceClass'], 'Galaxy S24');
      expect(report['packSizeBytes'], greaterThan(0));
      expect(report['availableBytes'], greaterThan(report['packSizeBytes'] as int));
      expect(report['coldStartMs'], greaterThan(report['warmRunMs'] as int));
      expect(report['indexingTimeMs'], greaterThan(0));
      expect(report['memoryGrowthBytes'], greaterThan(0));
      expect(report['slowestRule'], isNotEmpty);
      expect(report['checksPerSecond'], greaterThan(0));
      expect(report['readBudget'], 0);
      expect(report['liveFirebaseUsed'], isFalse);
    });
  });
}

WorkSupplyTradePackOption _packOption(WorkSupplyTradePackTier tier) {
  return buildWorkSupplyTradePackOptionsForScope(
    'Plumbing',
    marketScope: WorkSupplyMarketScope.residential,
  ).firstWhere((option) => option.tier == tier);
}

Map<String, Object?> _runtimeBudgetReport({
  required String deviceClass,
  required int packSizeBytes,
  required int availableBytes,
  required int coldStartMs,
  required int warmRunMs,
  required int indexingTimeMs,
  required int memoryGrowthBytes,
  required String slowestRule,
  required int checksPerSecond,
  required int readBudget,
  required bool liveFirebaseUsed,
}) {
  return {
    'deviceClass': deviceClass,
    'packSizeBytes': packSizeBytes,
    'availableBytes': availableBytes,
    'coldStartMs': coldStartMs,
    'warmRunMs': warmRunMs,
    'indexingTimeMs': indexingTimeMs,
    'memoryGrowthBytes': memoryGrowthBytes,
    'slowestRule': slowestRule,
    'checksPerSecond': checksPerSecond,
    'readBudget': readBudget,
    'liveFirebaseUsed': liveFirebaseUsed,
  };
}
