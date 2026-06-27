import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('fuel vendor registry exposes command-center health metadata', () {
    final audit = auditFuelMerchantRegistry();

    expect(audit.vendorCount, greaterThanOrEqualTo(75));
    expect(audit.passesCoreHealth, isTrue);
    expect(audit.hasStateLevelCoverage, isTrue);
    expect(audit.duplicateVendorNames, isEmpty);
    expect(audit.invalidStateCodes, isEmpty);
    expect(audit.typeCounts[FuelMerchantType.fuelBrand], greaterThan(15));
    expect(
      audit.typeCounts[FuelMerchantType.regionalConvenience],
      greaterThan(40),
    );
    expect(
      audit.typeCounts[FuelMerchantType.truckStop],
      greaterThanOrEqualTo(3),
    );
    expect(
      audit.typeCounts[FuelMerchantType.evCharging],
      greaterThanOrEqualTo(4),
    );
  });

  test('fuel vendor registry has broad state and region coverage', () {
    final audit = auditFuelMerchantRegistry();

    expect(audit.regionCounts.keys, containsAll(['US', 'US-NE', 'US-MA']));
    expect(
      audit.regionCounts.keys,
      containsAll(['US-SE', 'US-MW', 'US-SC', 'US-MWST', 'US-W']),
    );
    expect(audit.stateCounts.keys, containsAll(['CA', 'FL', 'GA', 'NY', 'OH']));
    expect(audit.stateCounts.keys, containsAll(['PA', 'SC', 'TN', 'TX', 'VA']));
    expect(audit.stateCounts.keys, containsAll(['WA', 'WI', 'WV']));
    expect(audit.stateCounts.length, greaterThanOrEqualTo(40));
  });
}
