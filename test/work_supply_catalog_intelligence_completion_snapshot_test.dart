import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';

void main() {
  test('catalog intelligence completion snapshot reports every trade', () {
    final items = workSupplyCatalogItems;
    final completeItems = items
        .where((item) => !item.intelligence.needsReview)
        .toList(growable: false);
    final needsReviewItems = items.length - completeItems.length;

    // ignore: avoid_print
    print(
      [
        'CATALOG_INTELLIGENCE_COMPLETION',
        'items=${items.length}',
        'complete=${completeItems.length}',
        'needsReview=$needsReviewItems',
        'completePercent=${_percent(completeItems.length, items.length)}',
      ].join(' '),
    );

    for (final trade in workSupplyTrades) {
      final tradeItems = items
          .where((item) => item.trade == trade.name)
          .toList(growable: false);
      final complete = tradeItems
          .where((item) => !item.intelligence.needsReview)
          .length;
      final needsReview = tradeItems.length - complete;
      // ignore: avoid_print
      print(
        [
          'TRADE_INTELLIGENCE_COMPLETION',
          'trade="${trade.name}"',
          'items=${tradeItems.length}',
          'complete=$complete',
          'needsReview=$needsReview',
          'completePercent=${_percent(complete, tradeItems.length)}',
        ].join(' '),
      );
    }

    expect(items, isNotEmpty);
    expect(completeItems, isNotEmpty);
  });
}

String _percent(int value, int total) {
  if (total == 0) return '0.0';
  return (value / total * 100).toStringAsFixed(1);
}
