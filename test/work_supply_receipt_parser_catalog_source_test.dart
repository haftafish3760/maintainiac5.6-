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

  test('reuses an immutable index for a stable supplied catalog list', () {
    final items = [_findPvcSchedule40Coupling()];
    final first = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: items,
    );
    items.clear();
    final second = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: items,
    );

    expect(first, isNotNull);
    expect(second?.item.id, first!.item.id);
  });

  test('caches separate supplied-catalog indexes for each trade scope', () {
    final items = [_findPvcSchedule40Coupling()];
    final wrongScope = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Electrical',
      catalogItems: items,
    );
    final plumbingScope = matchReceiptLineToCatalog(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      catalogItems: items,
    );

    expect(wrongScope, isNull);
    expect(plumbingScope?.item.id, items.single.id);
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
