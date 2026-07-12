import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/inventory_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('loaded-catalog entry point restricts matching to its pack', () {
    final item = _pvcSchedule40Coupling();
    final parser = InventoryParser(catalogItems: [item]);

    final match = parser.matchReceiptLine(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );

    expect(match, isNotNull);
    expect(match!.item.id, item.id);
  });

  test('empty loaded-catalog entry point does not use the full catalog', () {
    final parser = InventoryParser(catalogItems: const []);

    final match = parser.matchReceiptLine(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );

    expect(match, isNull);
  });
}

WorkSupplyItem _pvcSchedule40Coupling() => workSupplyCatalogItems.firstWhere(
  (item) =>
      item.trade == 'Plumbing' &&
      item.name.startsWith('3/4') &&
      item.name.toLowerCase().contains('pvc schedule 40 coupling'),
);
