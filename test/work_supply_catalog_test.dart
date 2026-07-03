import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_destination.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_item_identity_resolver.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_shared_stock_context.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test('materials catalog finds common service-truck searches', () {
    expect(
      searchWorkSupplies('half inch 90').map((item) => item.name),
      contains('1/2 in Copper 90 Elbow'),
    );
    expect(
      searchWorkSupplies('gfci').map((item) => item.name),
      contains('15 Amp GFCI Outlet'),
    );
    expect(
      searchWorkSupplies('capacitor').map((item) => item.name),
      contains('35/5 MFD Run Capacitor'),
    );
    expect(
      searchWorkSupplies('deck screw').map((item) => item.name),
      contains('#9 x 2-1/2 in Deck Screws'),
    );
    final copper90 = searchWorkSupplies('half inch copper 90').first;
    expect(copper90.trade, 'Plumbing');
    expect(copper90.category, 'Fittings');
    expect(copper90.system, 'Copper');
    expect(copper90.itemType, '90 Elbows');
    expect(copper90.variant, '1/2 in');
  });

  test('inventory record calculates package cost, tax, and reminders', () {
    const item = WorkSupplyItem(
      id: 'MI-TEST',
      name: '1/2 in Copper 90 Elbow',
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'Copper',
      itemType: '90 Elbows',
      variant: '1/2 in',
      unit: 'each',
    );
    const record = WorkSupplyInventoryRecord(
      item: item,
      onHand: 20,
      threshold: 6,
      lastUnitCost: 5,
      storageArea: 'Active vehicle',
      receiptLinked: true,
      packagesPurchased: 1,
      unitsPerPackage: 20,
      lineSubtotal: 100,
      taxRate: .05,
    );

    expect(record.isRunningLow, isFalse);
    expect(record.lineTax, 5);
    expect(record.lineTotal, 105);
    expect(record.unitCostWithTax, 5.25);
    expect(record.businessUse, 'business');
    expect(record.businessPercent, 1);
    expect(record.copyWith(onHand: 5).isRunningLow, isTrue);
  });

  test('catalog item smart metadata supports scope tier and parser hints', () {
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
        attributeTokens: ['half inch', 'brass', 'pex', 'crimp', '90'],
        negativeMatchTokens: ['pvc elbow', 'push fit elbow'],
        highImportanceTokens: ['1/2', 'brass', 'crimp'],
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

    expect(item.marketScopes, contains(WorkSupplyMarketScope.residential));
    expect(item.marketScopes, contains(WorkSupplyMarketScope.lightIndustrial));
    expect(item.packTier, WorkSupplyPackTier.core);
    expect(item.parserPriority, WorkSupplyParserPriority.everydayCore);
    expect(item.searchableText, contains('br pex 90'));
    expect(item.searchableText, contains('pfx'));
    expect(item.searchableText, contains('push fit elbow'));
    expect(item.searchableText, contains('plumbing rough-in'));
  });

  test('plumbing catalog has parser-depth scale', () {
    final plumbingCount = workSupplyCatalogItems
        .where((item) => item.trade == 'Plumbing')
        .length;

    expect(plumbingCount, greaterThanOrEqualTo(10000));
  });

  test('catalog item ids are stable, unique, and app-owned', () {
    final audit = auditWorkSupplyCatalog();

    expect(audit.itemCount, greaterThanOrEqualTo(11000));
    expect(audit.invalidIdCount, 0);
    expect(audit.duplicateIdCount, 0);
  });

  test('catalog items have complete inventory identity fields', () {
    final audit = auditWorkSupplyCatalog();

    expect(audit.incompleteItemCount, 0);
    expect(audit.marketScopeCoverage, 1);
    expect(audit.packTierCoverage, 1);
    expect(audit.parserPriorityCoverage, 1);
  });

  test('catalog items expose parser-searchable identity text', () {
    final audit = auditWorkSupplyCatalog();

    expect(audit.weakSearchTextCount, 0);
    expect(audit.passesCoreIntegrity, isTrue);
  });

  test('catalog audit reports trade parser coverage watchlist', () {
    final audit = auditWorkSupplyCatalog();

    expect(audit.packReadiness.packId, workSupplyCatalogPackId);
    expect(audit.packReadiness.packVersion, workSupplyCatalogPackVersion);
    expect(audit.packReadiness.hasStableAppIds, isTrue);
    expect(audit.packReadiness.parserTermCoverage, greaterThan(.95));
    expect(audit.packReadiness.averageParserTermsPerItem, greaterThan(5));
    expect(audit.packReadiness.parserReadinessLabel, 'Parser ready');
    expect(audit.packReadiness.estimatedPackedBytes, greaterThan(100000));
    expect(audit.packReadiness.estimatedPackSizeLabel, isNotEmpty);
    expect(audit.deliveryPlan.packId, workSupplyCatalogPackId);
    expect(audit.deliveryPlan.packVersion, workSupplyCatalogPackVersion);
    expect(audit.deliveryPlan.deliveryModeLabel, 'Manifest + Storage chunks');
    expect(audit.deliveryPlan.estimatedCompressedSizeLabel, isNotEmpty);
    expect(audit.tradeCoverage, hasLength(workSupplyTrades.length));
    expect(
      audit.tradeCoverage.map((coverage) => coverage.tradeName),
      containsAll(workSupplyTrades.map((trade) => trade.name)),
    );
    expect(
      audit.tradeCoverage
          .firstWhere((coverage) => coverage.tradeName == 'Plumbing')
          .itemCount,
      greaterThanOrEqualTo(10000),
    );
    final plumbing = audit.tradeCoverage.firstWhere(
      (coverage) => coverage.tradeName == 'Plumbing',
    );
    expect(plumbing.systemCount, greaterThan(5));
    expect(plumbing.itemTypeCount, greaterThan(10));
    expect(plumbing.parserTermCount, greaterThan(plumbing.itemCount * 4));
    expect(audit.weakestTrades, hasLength(4));
    expect(
      audit.weakestTrades.map((coverage) => coverage.parserReadinessScore),
      orderedEquals(
        audit.weakestTrades
            .map((coverage) => coverage.parserReadinessScore)
            .toList()
          ..sort(),
      ),
    );
  });

  test('catalog delivery plan is Firestore-read safe for hosted packs', () {
    final audit = auditWorkSupplyCatalog();
    final delivery = audit.deliveryPlan;

    expect(
      delivery.manifestDocumentPath,
      workSupplyCatalogManifestDocumentPath,
    );
    expect(delivery.storagePrefix, workSupplyCatalogStoragePrefix);
    expect(delivery.isFirestoreReadSafe, isTrue);
    expect(delivery.firestoreManifestReadCount, 1);
    expect(delivery.firestoreItemDocumentReadCount, 0);
    expect(delivery.chunkCount, greaterThan(1));
    expect(delivery.hasValidChunkPlan, isTrue);
    expect(
      delivery.chunks.map((chunk) => chunk.tradeName).toSet(),
      containsAll(workSupplyTrades.map((trade) => trade.name)),
    );
    expect(
      delivery.chunks.every((chunk) => chunk.storagePath.endsWith('.json.gz')),
      isTrue,
    );
    expect(
      delivery.chunks.every(
        (chunk) =>
            chunk.itemCount > 0 &&
            chunk.itemCount <= workSupplyCatalogMaxChunkItemCount,
      ),
      isTrue,
    );
    expect(
      delivery.chunks.every(
        (chunk) =>
            chunk.estimatedCompressedBytes <=
            workSupplyCatalogMaxCompressedChunkBytes,
      ),
      isTrue,
    );
  });

  test('catalog audit catches broken inventory identity samples', () {
    final audit = auditWorkSupplyCatalog(
      items: const [
        WorkSupplyItem(
          id: 'bad-id',
          name: 'Mystery',
          trade: '',
          category: 'General',
          system: 'General',
          itemType: 'Part',
          variant: '',
          unit: 'each',
        ),
        WorkSupplyItem(
          id: 'bad-id',
          name: 'Mystery',
          trade: 'Plumbing',
          category: 'General',
          system: 'General',
          itemType: 'Part',
          variant: 'small',
          unit: 'each',
        ),
      ],
    );

    expect(audit.invalidIdCount, 2);
    expect(audit.duplicateIdCount, 1);
    expect(audit.packReadiness.hasStableAppIds, isFalse);
    expect(audit.packReadiness.parserReadinessLabel, 'Fix IDs');
    expect(audit.incompleteItemCount, 1);
    expect(audit.passesCoreIntegrity, isFalse);
  });

  test('plumbing catalog has no duplicate trade-scoped item identities', () {
    final duplicates = <String, List<String>>{};
    final seen = <String, WorkSupplyItem>{};
    for (final item in workSupplyCatalogItems.where(
      (item) => item.trade == 'Plumbing',
    )) {
      final key = tradeScopedWorkSupplyItemKey(item);
      final previous = seen[key];
      if (previous == null) {
        seen[key] = item;
      } else {
        duplicates.putIfAbsent(key, () => [previous.name]).add(item.name);
      }
    }

    expect(duplicates, isEmpty);
  });

  test('drywall and decking have practical searchable starter depth', () {
    final drywall = workSupplyTrades.firstWhere(
      (trade) => trade.name == 'Drywall',
    );
    expect(
      drywall.categories.map((category) => category.name),
      containsAll([
        'Panels and Board',
        'Compound and Mud',
        'Tape Bead and Trim',
        'Texture and Patch',
        'Fasteners and Adhesives',
      ]),
    );
    expect(
      searchWorkSupplies('drywall mud').map((item) => item.name),
      contains('4.5 gal All Purpose Joint Compound'),
    );
    expect(
      searchWorkSupplies('spackle').map((item) => item.name),
      contains('16 oz Spackling Compound'),
    );
    expect(
      searchWorkSupplies('decking board').map((item) => item.name),
      contains('5/4 x 6 x 12 ft Pressure Treated Deck Board'),
    );
    expect(
      searchWorkSupplies('hidden deck fasteners').map((item) => item.name),
      contains('175 count Hidden Deck Fasteners'),
    );
  });

  test('core trades are ordered for contractor workflows', () {
    expect(workSupplyTrades.take(8).map((trade) => trade.name), [
      'Plumbing',
      'Electrical',
      'HVAC',
      'Carpentry',
      'Drywall',
      'Painting',
      'Roofing',
      'Tile',
    ]);
    expect(workSupplyTrades.map((trade) => trade.name), contains('Drywall'));
    expect(workSupplyTrades.map((trade) => trade.name), contains('Painting'));
    expect(workSupplyTrades.map((trade) => trade.name), contains('Fencing'));
    expect(
      workSupplyTrades.map((trade) => trade.name),
      isNot(contains('Drywall and Paint')),
    );
    final landscaping = workSupplyTrades.firstWhere(
      (trade) => trade.name == 'Landscaping',
    );
    expect(
      landscaping.categories.map((category) => category.name),
      isNot(contains('Landscape Supplies')),
    );
  });

  test('fencing catalog has starter categories and searchable items', () {
    final fencing = workSupplyTrades.firstWhere(
      (trade) => trade.name == 'Fencing',
    );

    expect(
      fencing.categories.map((category) => category.name),
      containsAll([
        'Fence Materials',
        'Posts and Framework',
        'Gates and Hardware',
        'Wire and Farm Fence',
        'Fasteners and Accessories',
      ]),
    );
    expect(
      searchWorkSupplies('barbed wire').map((item) => item.name),
      contains('2 Point 1320 ft Barbed Wire Roll'),
    );
    expect(
      searchWorkSupplies('fence post concrete').map((item) => item.name),
      contains('50 lb Fast Setting Concrete Mix'),
    );
  });

  test('electrical conduit fittings include larger raceway sizes', () {
    expect(
      searchWorkSupplies('4 inch emt coupling').map((item) => item.name),
      contains('4 in EMT Coupling'),
    );
    expect(
      searchWorkSupplies(
        '6 inch pvc electrical elbow',
      ).map((item) => item.name),
      contains('6 in PVC Electrical 90 Elbow'),
    );
    expect(
      searchWorkSupplies('3 inch rigid locknut').map((item) => item.name),
      contains('3 in Rigid Locknut'),
    );
  });

  test('plumbing catalog uses field names before vendor wording', () {
    expect(
      searchWorkSupplies('service weight gasket').map((item) => item.name),
      contains('2 in Cast Iron Compression Gasket'),
    );
    expect(
      searchWorkSupplies('compression gasket').map((item) => item.name),
      contains('2 in Cast Iron Compression Gasket'),
    );
    expect(
      searchWorkSupplies(
        'half by three quarter by half copper t',
      ).map((item) => item.name),
      contains('1/2 x 3/4 x 1/2 Copper Tee'),
    );
    expect(
      searchWorkSupplies(
        'half inch copper repair coupling without stop',
      ).map((item) => item.name),
      contains('1/2 in Copper Repair Coupling'),
    );
    expect(
      searchWorkSupplies('3/4 copper street 45').map((item) => item.name),
      contains('3/4 in Copper Street 45 Elbow'),
    );
    expect(
      searchWorkSupplies(
        'copper drop ear shower elbow',
      ).map((item) => item.name),
      contains('1/2 in Copper Drop-Ear 90 Elbow'),
    );
    expect(
      searchWorkSupplies(
        'water heater dielectric union',
      ).map((item) => item.name),
      contains('1/2 in Copper Dielectric Union'),
    );
    expect(
      searchWorkSupplies(
        '3/4 by 1/2 by 1/2 pex reducing tee',
      ).map((item) => item.name),
      contains('3/4 x 1/2 x 1/2 PEX Tee'),
    );
    expect(
      searchWorkSupplies('2 x 1 pvc reducer').map((item) => item.name),
      contains('2 x 1 PVC Schedule 40 Reducing Coupling'),
    );
    expect(
      searchWorkSupplies('black iron floor flange').map((item) => item.name),
      contains('1/4 in Black Iron Floor Flange'),
    );
    expect(
      searchWorkSupplies('brass compression union').map((item) => item.name),
      contains('1/4 in Brass Compression Union'),
    );
    expect(
      searchWorkSupplies('4 inch dwv coupling').map((item) => item.name),
      contains('4 in PVC DWV Coupling'),
    );
    expect(
      searchWorkSupplies('4 by 3 no hub reducer').map((item) => item.name),
      contains('4 x 3 Reducing No-Hub Coupling'),
    );
    expect(
      searchWorkSupplies('half inch pex 100 ft roll').map((item) => item.name),
      contains('1/2 in x 100 ft PEX Tubing'),
    );
    expect(
      searchWorkSupplies(
        'frost free hose bibb 12 inch',
      ).map((item) => item.name),
      contains('1/2 in x 12 in Frost-Free Sillcock'),
    );
    expect(
      searchWorkSupplies('purple primer').map((item) => item.name),
      contains('4 oz PVC Primer'),
    );
    expect(
      searchWorkSupplies('trap washer').map((item) => item.name),
      contains('1-1/4 in Slip Joint Nut and Washer'),
    );
    expect(
      searchWorkSupplies('nail plate').map((item) => item.name),
      contains('1-1/2 x 3 in Stud Guard Plate'),
    );
    expect(
      searchWorkSupplies('flange repair ring').map((item) => item.name),
      contains('stainless Toilet Flange Repair Ring'),
    );
    expect(
      searchWorkSupplies('pop up drain').map((item) => item.name),
      contains('chrome Lavatory Pop-Up Assembly'),
    );
    expect(
      searchWorkSupplies('sump float switch').map((item) => item.name),
      contains('tethered Pump Float Switch'),
    );
    expect(
      searchWorkSupplies('water heater drain valve').map((item) => item.name),
      contains('3/4 in brass Water Heater Drain Valve'),
    );
  });

  test('receipt parser normalizes merchants and learns corrections', () {
    expect(normalizeMerchantName('LOWE S #1042'), 'lowes');
    expect(normalizeMerchantName('THE HOME DEPOT 4652'), 'home depot');

    final parsed = matchReceiptLineToCatalog('1/2 PVC MALE ADAPT SCH40');
    expect(parsed, isNotNull);
    expect(parsed!.item.name, contains('PVC Schedule 40 Male Adapter'));

    final correctedItem = searchWorkSupplies('1/2 in copper tee').first;
    final memory = ReceiptParserLearningMemory()
      ..confirmCorrection(
        receiptLine: 'LOWES ABBREV COP TEE HALF',
        item: correctedItem,
      );
    final learned = matchReceiptLineToCatalog(
      'lowes abbrev cop tee half',
      memory: memory,
    );
    expect(learned, isNotNull);
    expect(learned!.source, ReceiptMatchSource.learnedCorrection);
    expect(learned.item.id, correctedItem.id);
    expect(learned.confidenceLevel, ReceiptConfidenceLevel.good);
    expect(learned.confidenceLabel, 'Good');
  });

  test('receipt parser understands plumbing field and receipt shorthand', () {
    final copper90 = matchReceiptLineToCatalog('LOWES 1/2IN COP 90 ELL');
    expect(copper90, isNotNull);
    expect(copper90!.item.name, '1/2 in Copper 90 Elbow');
    expect(copper90.needsReview, isFalse);
    expect(copper90.confidenceLevel, ReceiptConfidenceLevel.good);
    expect(copper90.confidenceGuidance, 'Matched with strong confidence.');

    final pexTee = matchReceiptLineToCatalog('HD 3/4X1/2X1/2 PEX RED TEE');
    expect(pexTee, isNotNull);
    expect(pexTee!.item.name, '3/4 x 1/2 x 1/2 PEX Tee');

    final pvcReducer = matchReceiptLineToCatalog('PVC S40 2X1 RED COUP');
    expect(pvcReducer, isNotNull);
    expect(pvcReducer!.item.name, '2 x 1 PVC Schedule 40 Reducing Coupling');

    final noHub = matchReceiptLineToCatalog('4X3 NH REDUCING COUPLING');
    expect(noHub, isNotNull);
    expect(noHub!.item.name, '4 x 3 Reducing No-Hub Coupling');

    final slipJoint = matchReceiptLineToCatalog('1-1/4 S/J NUT WASHER');
    expect(slipJoint, isNotNull);
    expect(slipJoint!.item.name, '1-1/4 in Slip Joint Nut and Washer');
  });

  test(
    'shared copper fitting stock can appear in plumbing and hvac context',
    () {
      final copper90 = searchWorkSupplies('half inch copper 90').first;
      final records = [
        WorkSupplyInventoryRecord(
          item: copper90,
          onHand: 5,
          threshold: 2,
          lastUnitCost: 2.50,
          storageArea: 'Work Truck 1 inventory',
          receiptLinked: true,
        ),
      ];

      final contexts = workSupplyTradeContextsForItem(
        copper90,
        enabledTrades: const ['Plumbing', 'HVAC'],
      );

      expect(
        canonicalWorkSupplyItemKey(copper90),
        '90_elbow:copper:1_2_in:each',
      );
      expect(
        contexts.map((context) => context.path),
        containsAll([
          'Plumbing / Fittings / Copper / 90 Elbows',
          'HVAC / Refrigerant Lines / Copper Fittings / 90 Elbows',
        ]),
      );
      expect(workSupplyItemHasSharedTradeContext(copper90), isTrue);
      expect(workSupplyOnHandForPhysicalItem(records, copper90), 5);
    },
  );

  test('receipt parser confidence level labels guide review behavior', () {
    const item = WorkSupplyItem(
      id: 'MI-TEST',
      name: '1/2 in Copper 90 Elbow',
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'Copper',
      itemType: '90 Elbows',
      variant: '1/2 in',
      unit: 'each',
    );

    const good = ReceiptLineMatch(
      rawText: '1/2 COP 90',
      item: item,
      confidence: .86,
      matchedTerms: ['1/2', 'copper', '90'],
    );
    const okay = ReceiptLineMatch(
      rawText: 'COP EL',
      item: item,
      confidence: .70,
      matchedTerms: ['copper', 'elbow'],
    );
    const poor = ReceiptLineMatch(
      rawText: 'MISC PART',
      item: item,
      confidence: .42,
      matchedTerms: ['part'],
    );

    expect(good.confidenceLevel, ReceiptConfidenceLevel.good);
    expect(good.needsReview, isFalse);
    expect(okay.confidenceLevel, ReceiptConfidenceLevel.okay);
    expect(okay.confidenceLabel, 'Review');
    expect(okay.needsReview, isTrue);
    expect(poor.confidenceLevel, ReceiptConfidenceLevel.poor);
    expect(poor.confidenceLabel, 'Poor');
    expect(
      poor.confidenceGuidance,
      'Low confidence. Correct manually or retake the receipt photo.',
    );
  });

  test(
    'inventory destinations include company, vehicles, job staging, custom',
    () {
      final appState = AppStateController();
      final destinations = buildWorkSupplyInventoryDestinations(
        appState: appState,
        jobNumber: 'JOB-042',
      );

      expect(destinations, contains(workSupplyCompanyInventoryLabel));
      expect(destinations, contains(workSupplyActiveVehicleInventoryLabel));
      expect(destinations, contains('Work Truck 1 inventory'));
      expect(destinations, contains('Job staging - JOB-042'));
      expect(destinations, contains(workSupplyCustomDestinationLabel));
      expect(
        resolveWorkSupplyInventoryDestination(
          selectedDestination: workSupplyCustomDestinationLabel,
          customDestination: 'Trailer shelf 2',
        ),
        'Trailer shelf 2',
      );
    },
  );
}
