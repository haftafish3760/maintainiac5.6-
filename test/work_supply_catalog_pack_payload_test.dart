import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('catalog pack item payload carries parser-ready metadata', () {
    final item = workSupplyCatalogItems.firstWhere(
      (candidate) =>
          candidate.trade == 'Plumbing' &&
          candidate.name.toLowerCase().contains('pvc') &&
          candidate.aliases.isNotEmpty,
    );

    final payload = buildWorkSupplyCatalogPackItemPayload(item);
    final map = payload.toMap();

    expect(payload.canonicalKey, isNotEmpty);
    expect(payload.searchTerms, containsAll(['plumbing', 'pvc']));
    expect(payload.aliases, isNotEmpty);
    expect(
      payload.aliases.every(
        (alias) => alias.normalized == alias.normalized.toLowerCase(),
      ),
      isTrue,
    );
    expect(map['merchantAliases'], isA<List>());
    expect(map['barcodeAliases'], isA<List>());
    expect(map['merchantSkuAliases'], isA<List>());
    expect(map['packageHints'], isA<List>());
  });

  test(
    'trade pack gzip chunks include parser metadata but no per-item writes',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pack_export_test_',
      );
      addTearDown(() async {
        if (await base.exists()) await base.delete(recursive: true);
      });
      final option = buildWorkSupplyTradePackOptions('Plumbing').firstWhere(
        (candidate) => candidate.tier == WorkSupplyTradePackTier.core,
      );

      final result = await WorkSupplyTradePackExportWriter(baseDirectory: base)
          .writeTradePack(
            option: option,
            generatedAt: DateTime.utc(2026, 6, 27, 12),
          );

      final chunk = result.manifest.chunks.first;
      final chunkBytes = await File(
        '${result.directoryPath}/${chunk.storagePath}',
      ).readAsBytes();
      final decoded = jsonDecode(utf8.decode(gzip.decode(chunkBytes))) as Map;
      final items = decoded['items'] as List;
      final firstItem = items.first as Map;

      expect(decoded['schemaVersion'], workSupplyCatalogPackSchemaVersion);
      expect(result.manifest.firestoreItemDocumentReadCount, 0);
      expect(firstItem['canonicalKey'], isNotEmpty);
      expect(firstItem['searchTerms'], isA<List>());
      expect(firstItem['aliases'], isA<List>());
      expect(firstItem['merchantAliases'], isA<List>());
      expect(firstItem['barcodeAliases'], isA<List>());
      expect(firstItem['merchantSkuAliases'], isA<List>());
      expect(firstItem['packageHints'], isA<List>());
    },
  );
}
