import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';

void main() {
  test('plumbing catalog retains exact ABS DWV sanitary-tee identities', () {
    final matches = workSupplyCatalogItems.where(
      (item) =>
          item.trade == 'Plumbing' &&
          item.name.toLowerCase().contains('abs dwv sanitary tee'),
    );

    expect(matches, isNotEmpty);
    expect(
      matches.map((item) => item.name),
      contains('3 in ABS DWV Sanitary Tee'),
    );
  });
}
