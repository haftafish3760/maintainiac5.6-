import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_item_identity_resolver.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('PEH Core packs have unique trade-scoped canonical identities', () {
    for (final trade in const ['Plumbing', 'Electrical', 'HVAC']) {
      final seen = <String, WorkSupplyItem>{};
      final collisions = <String, List<String>>{};
      final coreItems = workSupplyCatalogItems.where(
        (item) =>
            item.trade == trade && item.packTier == WorkSupplyPackTier.core,
      );

      for (final item in coreItems) {
        final key = tradeScopedWorkSupplyItemKey(item);
        final previous = seen[key];
        if (previous == null) {
          seen[key] = item;
          continue;
        }
        collisions.putIfAbsent(key, () => [previous.id]).add(item.id);
      }

      expect(
        collisions,
        isEmpty,
        reason: '$trade Core canonical collisions: $collisions',
      );
      expect(seen, isNotEmpty, reason: '$trade Core must not be empty');
    }
  });
}
