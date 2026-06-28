import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_parser_device_profile.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void main() {
  test('older phones use light inventory parser limits', () {
    final profile = WorkSupplyParserDeviceProfile.fromCapability(
      const ReceiptDeviceCapability.olderPhone(),
    );

    expect(profile.canRunInventoryMatching, isFalse);
    expect(profile.maxCatalogCandidates, 250);
    expect(profile.maxInventoryCacheItems, 1000);
    expect(profile.enableAdvancedConfidenceScoring, isFalse);
    expect(profile.statusLabel, 'Light receipt assist');
  });

  test('high capacity phones can use full inventory parser limits', () {
    final profile = WorkSupplyParserDeviceProfile.fromCapability(
      const ReceiptDeviceCapability.highCapacity(),
    );

    expect(profile.canRunInventoryMatching, isTrue);
    expect(profile.maxCatalogCandidates, 8000);
    expect(profile.maxInventoryCacheItems, 25000);
    expect(profile.enableTradeClassification, isTrue);
    expect(profile.statusLabel, 'Full inventory receipt assist');
  });
}
