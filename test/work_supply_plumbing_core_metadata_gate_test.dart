import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('Plumbing Core rows carry professional parser metadata', () {
    final failures = <String>[];
    final coreRows = workSupplyCatalogItems
        .where(
          (item) =>
              item.trade == 'Plumbing' &&
              item.packTier == WorkSupplyPackTier.core &&
              item.marketScopes.contains(WorkSupplyMarketScope.residential),
        )
        .toList(growable: false);

    for (final item in coreRows) {
      final intelligence = item.intelligence;
      final searchable = item.searchableText;
      _expect(
        failures,
        item,
        item.aliases.length >= 4,
        'needs at least four aliases',
      );
      _expect(
        failures,
        item,
        intelligence.receiptPatterns.length >= 8,
        'needs rich receipt patterns',
      );
      _expect(
        failures,
        item,
        intelligence.negativeMatchTokens.length >= 3,
        'needs negative-match ambiguity tokens',
      );
      _expect(
        failures,
        item,
        intelligence.highImportanceTokens.length >= 4,
        'needs high-importance parser tokens',
      );
      _expect(
        failures,
        item,
        intelligence.attributeTokens.contains('plumbing-core'),
        'needs plumbing-core attribute token',
      );
      _expect(
        failures,
        item,
        intelligence.attributeTokens.contains('residential-service'),
        'needs residential-service attribute token',
      );
      _expect(
        failures,
        item,
        searchable.contains('spanish') || searchable.contains('es-us'),
        'needs Spanish metadata',
      );
      _expect(
        failures,
        item,
        intelligence.classification.inventoryCategory.isNotEmpty &&
            intelligence.classification.expenseCategory.isNotEmpty &&
            intelligence.classification.jobMaterialCategory.isNotEmpty,
        'needs classification metadata',
      );
      _expect(
        failures,
        item,
        intelligence.catalogVersion.isNotEmpty &&
            intelligence.parserVersion.isNotEmpty,
        'needs catalog/parser versions',
      );
      _expect(
        failures,
        item,
        intelligence.sourceConfidence.isNotEmpty,
        'needs source confidence metadata',
      );
    }

    expect(coreRows.length, greaterThan(1000));
    expect(failures, isEmpty, reason: failures.take(80).join('\n'));
  });
}

void _expect(
  List<String> failures,
  WorkSupplyItem item,
  bool condition,
  String message,
) {
  if (condition) return;
  failures.add('${item.id} / ${item.path} / ${item.name}: $message');
}
