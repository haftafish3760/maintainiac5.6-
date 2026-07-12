import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/inventory_online_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('bounded Plumbing cloud candidates use the compiled matcher', () async {
    final source = _FakeRemoteCatalogSource([_plumbingCoupling()]);
    final parser = InventoryOnlineParser(source: source);

    final match = await parser.matchReceiptLine(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
      maxCandidates: 500,
    );

    expect(match, isNotNull);
    expect(match!.item.id, _plumbingCoupling().id);
    expect(source.lastQuery?.tradeScope, 'Plumbing');
    expect(source.lastQuery?.limit, 100);
  });

  test('online parser rejects cross-trade remote candidates', () async {
    final source = _FakeRemoteCatalogSource([
      workSupplyCatalogItems.firstWhere((item) => item.trade == 'Electrical'),
    ]);
    final parser = InventoryOnlineParser(source: source);

    await expectLater(
      parser.matchReceiptLine('3/4 PVC COUPLING', tradeScope: 'Plumbing'),
      throwsA(isA<StateError>()),
    );
  });

  test('online parser requires a trade scope before remote reads', () async {
    final source = _FakeRemoteCatalogSource(const []);
    final parser = InventoryOnlineParser(source: source);

    await expectLater(
      parser.matchReceiptLine('PVC COUPLING', tradeScope: ' '),
      throwsA(isA<ArgumentError>()),
    );
    expect(source.queryCount, 0);
  });

  test('online parser rejects responses above the cloud read budget', () async {
    final item = _plumbingCoupling();
    final source = _FakeRemoteCatalogSource(List.filled(101, item));
    final parser = InventoryOnlineParser(source: source);

    await expectLater(
      parser.matchReceiptLine(
        '3/4 PVC COUPLING',
        tradeScope: 'Plumbing',
        maxCandidates: 500,
      ),
      throwsA(isA<StateError>()),
    );
    expect(source.lastQuery?.limit, 100);
  });

  test('online parser rejects duplicate remote item IDs', () async {
    final item = _plumbingCoupling();
    final parser = InventoryOnlineParser(
      source: _FakeRemoteCatalogSource([item, item]),
    );

    await expectLater(
      parser.matchReceiptLine('3/4 PVC COUPLING', tradeScope: 'Plumbing'),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'bounded Electrical cloud candidates use the compiled matcher',
    () async {
      final item = _electricalGfci();
      final source = _FakeRemoteCatalogSource([item]);
      final parser = InventoryOnlineParser(source: source);

      final match = await parser.matchReceiptLine(
        'LOWES 20A WR GFCI RECPT WHITE',
        tradeScope: 'Electrical',
      );

      expect(match, isNotNull);
      expect(match!.item.id, item.id);
      expect(source.lastQuery?.tradeScope, 'Electrical');
    },
  );

  test('bounded HVAC cloud candidates use the compiled matcher', () async {
    final item = _hvacDualRunCapacitor();
    final source = _FakeRemoteCatalogSource([item]);
    final parser = InventoryOnlineParser(source: source);

    final match = await parser.matchReceiptLine(
      'SUPPLY 45/5 MFD DUAL RUN CAP',
      tradeScope: 'HVAC',
    );

    expect(match, isNotNull);
    expect(match!.item.id, item.id);
    expect(source.lastQuery?.tradeScope, 'HVAC');
  });
}

class _FakeRemoteCatalogSource implements InventoryRemoteCatalogSource {
  _FakeRemoteCatalogSource(this.items);

  final List<WorkSupplyItem> items;
  InventoryRemoteCatalogQuery? lastQuery;
  int queryCount = 0;

  @override
  Future<List<WorkSupplyItem>> queryCandidates(
    InventoryRemoteCatalogQuery query,
  ) async {
    queryCount++;
    lastQuery = query;
    return items;
  }
}

WorkSupplyItem _plumbingCoupling() => workSupplyCatalogItems.firstWhere(
  (item) =>
      item.trade == 'Plumbing' &&
      item.name.startsWith('3/4') &&
      item.name.toLowerCase().contains('pvc schedule 40 coupling'),
);

WorkSupplyItem _electricalGfci() => workSupplyCatalogItems.firstWhere(
  (item) =>
      item.trade == 'Electrical' &&
      item.packTier == WorkSupplyPackTier.core &&
      item.name.toLowerCase().contains('gfci'),
);

WorkSupplyItem _hvacDualRunCapacitor() => workSupplyCatalogItems.firstWhere(
  (item) =>
      item.trade == 'HVAC' &&
      item.packTier == WorkSupplyPackTier.core &&
      item.name.toLowerCase().contains('45/5') &&
      item.name.toLowerCase().contains('capacitor'),
);
