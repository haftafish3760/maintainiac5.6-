import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
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
    expect(map['marketScopes'], isA<List>());
    expect(map['packTier'], isA<String>());
    expect(map['parserPriority'], isA<String>());
    expect(map['intelligence'], isA<Map>());
  });

  test('catalog pack payload exports smart item intelligence', () {
    const item = WorkSupplyItem(
      id: 'MI-999999',
      name: '1/2 in Brass PEX Crimp 90 Elbow',
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'PEX',
      itemType: '90 Elbows',
      variant: '1/2 in brass crimp',
      unit: 'each',
      aliases: ['PEX 90', 'brass PEX ell'],
      marketScopes: [
        WorkSupplyMarketScope.residential,
        WorkSupplyMarketScope.lightIndustrial,
      ],
      packTier: WorkSupplyPackTier.core,
      parserPriority: WorkSupplyParserPriority.everydayCore,
      intelligence: WorkSupplyItemIntelligence(
        material: 'brass',
        size: '1/2 in',
        connectionType: 'crimp',
        shapeOrStyle: '90 elbow',
        receiptPatterns: ['1/2 PEX CRMP ELL', 'BR PEX 90'],
        ocrMistakePatterns: ['PEX->PFX', 'ELB->E18'],
        vendorMappings: [
          WorkSupplyVendorMapping(
            vendor: 'sample supplier',
            code: 'PEX-BR-90-050',
            label: 'counter code',
          ),
        ],
        attributeTokens: ['half inch', 'brass', 'pex', 'crimp', '90'],
        negativeMatchTokens: ['pvc elbow', 'push fit elbow'],
        highImportanceTokens: ['1/2', 'brass', 'crimp'],
        mediumImportanceTokens: ['brand'],
        lowImportanceTokens: ['color'],
        ignoreTokens: ['aisle'],
        classification: WorkSupplyItemClassification(
          inventoryCategory: 'Plumbing fittings',
          expenseCategory: 'Materials',
          jobMaterialCategory: 'Plumbing rough-in',
          taxReportingCategory: 'Supplies',
          defaultUnitCostBehavior: 'each',
          defaultMarkupBehavior: 'materials markup',
        ),
        catalogVersion: '2026.06.local-starter',
        parserVersion: 'materials_parser_v1',
        sourceConfidence: 'manual-fixture',
        verifiedManually: true,
      ),
    );

    final payload = buildWorkSupplyCatalogPackItemPayload(item);
    final map = payload.toMap();
    final intelligence = map['intelligence'] as Map;
    final classification = intelligence['classification'] as Map;

    expect(map['marketScopes'], ['residential', 'lightIndustrial']);
    expect(map['packTier'], 'core');
    expect(map['parserPriority'], 'everydayCore');
    expect(payload.searchTerms, containsAll(['brass', 'pex', 'crimp']));
    expect(intelligence['material'], 'brass');
    expect(intelligence['receiptPatterns'], contains('BR PEX 90'));
    expect(intelligence['ocrMistakePatterns'], contains('PEX->PFX'));
    expect(intelligence['negativeMatchTokens'], contains('pvc elbow'));
    expect(intelligence['vendorMappings'], isA<List>());
    expect(map['merchantSkuAliases'], isA<List>());
    expect(
      map['merchantSkuAliases'],
      contains(
        containsPair('normalized', 'pex-br-90-050'),
      ),
    );
    expect(classification['jobMaterialCategory'], 'Plumbing rough-in');
    expect(classification['billableMaterial'], isTrue);
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
      expect(firstItem['marketScopes'], isA<List>());
      expect(firstItem['packTier'], isA<String>());
      expect(firstItem['parserPriority'], isA<String>());
      expect(firstItem['intelligence'], isA<Map>());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
