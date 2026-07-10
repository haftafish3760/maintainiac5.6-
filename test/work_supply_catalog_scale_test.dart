import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';

void main() {
  test('materials catalog exposes measurable trade scale', () {
    final audit = auditWorkSupplyCatalog();
    final countByTrade = {
      for (final trade in audit.tradeCoverage) trade.tradeName: trade.itemCount,
    };

    expect(audit.itemCount, greaterThanOrEqualTo(11000));
    expect(countByTrade['Plumbing'], greaterThanOrEqualTo(10000));
    expect(countByTrade.keys, containsAll(workSupplyTrades.map((t) => t.name)));
    expect(
      audit.tradeCoverage.every((coverage) => coverage.itemCount > 0),
      isTrue,
    );
    expect(
      audit.tradeCoverage.every((coverage) => coverage.aliasCoverage > .70),
      isTrue,
    );
    expect(audit.marketScopeCoverage, 1);
    expect(audit.packTierCoverage, 1);
    expect(audit.parserPriorityCoverage, 1);
  });

  test('materials catalog scale snapshot for pass planning', () {
    final audit = auditWorkSupplyCatalog();
    // ignore: avoid_print
    print('WORK_SUPPLY_TOTAL_ITEMS=${audit.itemCount}');
    for (final coverage in audit.tradeCoverage) {
      // ignore: avoid_print
      print(
        [
          'WORK_SUPPLY_TRADE',
          'name=${coverage.tradeName}',
          'items=${coverage.itemCount}',
          'categories=${coverage.categoryCount}',
          'systems=${coverage.systemCount}',
          'itemTypes=${coverage.itemTypeCount}',
          'aliases=${coverage.aliasCount}',
          'parserTerms=${coverage.parserTermCount}',
          'readiness=${coverage.parserReadinessLabel}',
        ].join(' '),
      );
    }

    expect(audit.tradeCoverage, hasLength(workSupplyTrades.length));
    expect(audit.marketScopeCoverage, 1);
    expect(audit.packTierCoverage, 1);
    expect(audit.parserPriorityCoverage, 1);
  });
}
