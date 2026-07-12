import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('supplied catalog prevents fallback to the compiled catalog', () {
    final match = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: const [],
    );

    expect(match, isNull);
  });

  test('supplied catalog returns only its matching item', () {
    final item = _findPvcSchedule40Coupling();

    final match = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: [item],
    );

    expect(match, isNotNull);
    expect(match!.item.id, item.id);
  });

  test('default catalog behavior is restored after a scoped match', () {
    matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: const [],
    );

    final match = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );

    expect(match, isNotNull);
    expect(match!.item.trade, 'Plumbing');
  });
}

WorkSupplyItem _findPvcSchedule40Coupling() {
  return workSupplyCatalogItems.firstWhere(
    (item) =>
        item.trade == 'Plumbing' &&
        item.name.toLowerCase().contains('pvc schedule 40 coupling') &&
        item.name.startsWith('3/4'),
  );
}
