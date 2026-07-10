import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_custom_catalog_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_item_identity_resolver.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  group('inventory parser current-phase custom catalog behavior', () {
    late Directory hiveDirectory;

    setUp(() async {
      hiveDirectory = await Directory.systemTemp.createTemp(
        'work_supply_custom_catalog_behavior_',
      );
      Hive.init(hiveDirectory.path);
    });

    tearDown(() async {
      await Hive.close();
      if (hiveDirectory.existsSync()) {
        await hiveDirectory.delete(recursive: true);
      }
    });

    test('custom store trims parser identity fields and aliases', () async {
      final store = await WorkSupplyCustomCatalogStore.create();

      await store.saveItem(
        const WorkSupplyItem(
          id: ' USER-PVC-SERVICE-PART ',
          name: '  Field PVC Service Part  ',
          trade: ' Plumbing ',
          category: ' Repair ',
          system: ' PVC ',
          itemType: ' Specialty Coupling ',
          variant: ' 3/4 in ',
          unit: ' ',
          aliases: [' pvc svc ', '', 'PVC SVC'],
        ),
      );

      final saved = store.loadItems().single;

      expect(saved.id, 'USER-PVC-SERVICE-PART');
      expect(saved.name, 'Field PVC Service Part');
      expect(saved.trade, 'Plumbing');
      expect(saved.unit, 'each');
      expect(saved.aliases, containsAll(['pvc svc', 'PVC SVC']));
      expect(saved.aliases, isNot(contains('')));
    });

    test(
      'custom store generates a local USER id when parser draft is new',
      () async {
        final store = await WorkSupplyCustomCatalogStore.create();

        await store.saveItem(
          const WorkSupplyItem(
            id: '',
            name: 'Field-only cleanout cover',
            trade: 'Plumbing',
            category: 'Drainage',
            system: 'PVC',
            itemType: 'Cleanout Cover',
            variant: '4 in',
            unit: 'each',
            aliases: ['co cover', 'clean out cover'],
          ),
        );

        final saved = store.loadItems().single;

        expect(saved.id, startsWith('USER-'));
        expect(saved.searchableText, contains('clean out cover'));
      },
    );

    test('custom search uses parser aliases and all query tokens', () async {
      final store = await WorkSupplyCustomCatalogStore.create();
      await store.saveItem(_customAdapter('USER-PEX-ODD', 'PEX Odd Adapter'));
      await store.saveItem(
        _customAdapter('USER-COPPER-ODD', 'Copper Odd Adapter'),
      );

      final pex = store.searchItems('field pex adapter');
      final copper = store.searchItems('field copper adapter');
      final impossible = store.searchItems('field pex copper adapter');

      expect(pex.map((item) => item.id), ['USER-PEX-ODD']);
      expect(copper.map((item) => item.id), ['USER-COPPER-ODD']);
      expect(impossible, isEmpty);
    });

    test(
      'merged search prefers custom parser identities and dedupes by id',
      () {
        final catalogItem = searchWorkSupplies('1/2 copper 90').first;
        final customSameId = WorkSupplyItem(
          id: catalogItem.id,
          name: 'User corrected ${catalogItem.name}',
          trade: catalogItem.trade,
          category: catalogItem.category,
          system: catalogItem.system,
          itemType: catalogItem.itemType,
          variant: catalogItem.variant,
          unit: catalogItem.unit,
          aliases: const ['field corrected copper ninety'],
        );

        final merged = mergeWorkSupplySearchResults(
          query: 'field corrected copper ninety',
          customItems: [customSameId],
        );

        expect(merged.where((item) => item.id == catalogItem.id), hasLength(1));
        expect(merged.first.name, startsWith('User corrected'));
      },
    );

    test(
      'resolver reuses custom item before creating another local identity',
      () {
        const draft = WorkSupplyItemIdentityDraft(
          trade: 'Plumbing',
          category: 'Repair',
          template: 'Odd Adapter',
          composition: 'PEX',
          size: '7/8',
          aliases: ['field pex adapter'],
        );
        final created = resolveWorkSupplyItemIdentity(draft: draft);
        final resolved = resolveWorkSupplyItemIdentity(
          draft: draft,
          customItems: [created.item],
          catalogItems: workSupplyCatalogItems,
        );

        expect(created.created, isTrue);
        expect(resolved.created, isFalse);
        expect(resolved.item.id, created.item.id);
        expect(resolved.canonicalKey, canonicalWorkSupplyItemKey(created.item));
      },
    );
  });
}

WorkSupplyItem _customAdapter(String id, String name) {
  final system = name.startsWith('PEX') ? 'PEX' : 'Copper';
  return WorkSupplyItem(
    id: id,
    name: name,
    trade: 'Plumbing',
    category: 'Repair',
    system: system,
    itemType: 'Odd Adapter',
    variant: '7/8 in',
    unit: 'each',
    aliases: ['field ${system.toLowerCase()} adapter', '$system adapter'],
  );
}
