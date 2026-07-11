import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_export.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_staging.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';

void main() {
  group('inventory parser executable regression locks', () {
    test('regression lock cases carry stable required metadata', () {
      for (final lock in _parserLocks) {
        expect(lock.id, startsWith('reg_'));
        expect(lock.rawLine, isNotEmpty);
        expect(lock.merchant, isNotEmpty);
        expect(lock.locale, isNotEmpty);
        expect(lock.trade, isNotEmpty);
        expect(lock.packTier, isNotEmpty);
        expect(lock.reason, isNotEmpty);
        expect(lock.expectedReviewStatus, isNotEmpty);
        expect(lock.expectedConfidenceBand, isNotEmpty);
        expect(lock.expectedFailureCategory, isNotEmpty);
      }
    });

    test(
      'known good receipt lines keep matching expected trade and family',
      () {
        for (final lock in _parserLocks.where((lock) => !lock.expectUnknown)) {
          final match = matchReceiptLineToCatalog(
            lock.rawLine,
            tradeScope: lock.trade,
            localePackId: lock.locale == 'es-US' ? 'es-US' : '',
            maxCandidates: 320,
          );

          expect(match, isNotNull, reason: lock.id);
          expect(match!.item.trade, lock.trade, reason: lock.id);
          expect(
            match.item.name.toLowerCase(),
            contains(lock.expectedNameContains.toLowerCase()),
            reason: lock.id,
          );
          expect(match.needsReview, isTrue, reason: lock.id);
          expect(
            match.confidenceLevel,
            isNot(ReceiptConfidenceLevel.poor),
            reason: lock.id,
          );
        }
      },
    );

    test('known bad and dangerous receipt lines stay conservative', () {
      for (final lock in _parserLocks.where((lock) => lock.expectUnknown)) {
        final match = matchReceiptLineToCatalog(
          lock.rawLine,
          tradeScope: lock.trade == 'unknown' ? null : lock.trade,
          localePackId: lock.locale == 'es-US' ? 'es-US' : '',
          maxCandidates: 320,
        );

        expect(
          match == null || match.confidence <= lock.maxConfidence,
          isTrue,
          reason:
              '${lock.id} matched ${match?.item.name} at ${match?.confidence}',
        );
      }
    });

    test('major merchant normalization locks stay stable', () {
      final aliases = {
        'THE HOME DEPOT #4612': 'home depot',
        'LOWE S PRO DESK': 'lowes',
        'ACE HARDWARE 0091': 'ace hardware',
        'FERG WTRWORKS': 'ferguson',
        'WW GRAINGER WILL CALL': 'grainger',
        'MENARD 3027': 'menards',
        'WAL MART STORE': 'walmart',
        'TRUE VALUE HARDWARE': 'true value',
        'LOCAL CASH SALE': 'local cash sale',
      };

      for (final entry in aliases.entries) {
        expect(normalizeMerchantName(entry.key), entry.value);
      }
    });

    test('duplicate receipt regression locks source-line routing', () {
      final first = _record(sourceLineId: 'RCP-DUP-L1', storageArea: 'Truck A');
      final second = _record(
        sourceLineId: 'RCP-DUP-L2',
        storageArea: 'Truck B',
      );
      const edited = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        receiptLineId: 'RCP-DUP-L2',
        description: 'Edited duplicate line',
        inventoryItemId: 'same-item',
        quantity: 2,
        unitsPerPackage: 3,
        storageArea: 'Truck C',
      );

      final index = stagedInventoryRecordIndexForLine([first, second], edited);
      final synced = syncedInventoryRecordForLine(
        record: [first, second][index],
        line: edited,
      );

      expect(index, 1);
      expect(synced.sourceReceiptLineId, 'RCP-DUP-L2');
      expect(synced.onHand, 6);
      expect(first.storageArea, 'Truck A');
    });

    test('financial and source immutability regression lock stays stable', () {
      final record = _record(
        sourceLineId: 'RCP-MATH-L1',
        lineSubtotal: 120,
        taxRate: .075,
        markupRate: .25,
        packagesPurchased: 3,
        unitsPerPackage: 4,
      );
      final snapshot = WorkSupplyInventoryExportSnapshot(
        exportedAt: DateTime.utc(2026, 7, 2),
        inventoryRecords: [record],
        stockEvents: const [],
      );

      final before = [
        record.sourceReceiptLineId,
        record.lineSubtotal,
        record.unitCostWithTax,
        record.billableUnitCost,
      ];
      final csv = snapshot.toInventoryCsv();
      final after = [
        record.sourceReceiptLineId,
        record.lineSubtotal,
        record.unitCostWithTax,
        record.billableUnitCost,
      ];

      expect(record.totalUnitsPurchased, 12);
      expect(record.lineTax, 9);
      expect(record.unitCostWithTax, 10.75);
      expect(record.billableUnitCost, 13.4375);
      expect(csv, contains('RCP-MATH-L1'));
      expect(after, before);
    });

    test('search/index regression locks common alias families', () {
      final searches = {
        '1/2 pex crimp elbow': 'Plumbing',
        '3/4 pvc conduit coupling': 'Electrical',
        'filtro aire 20x25x1': 'HVAC',
      };

      for (final entry in searches.entries) {
        final match = matchReceiptLineToCatalog(
          entry.key,
          tradeScope: entry.value,
          localePackId: entry.key.startsWith('filtro') ? 'es-US' : '',
          maxCandidates: 320,
        );
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, entry.value, reason: entry.key);
      }
    });

    test('ambiguous cross-trade lines lose confidence by evidence risk', () {
      final cases = {
        'PVC 90 3/4': 'PVC elbow can be plumbing, electrical conduit, or HVAC',
        '3/4 COPPER 90': 'Copper elbow can be plumbing or HVAC refrigerant',
        'FILTER 20X25X1': 'Filter needs air/water/oil/HVAC evidence',
      };

      for (final entry in cases.entries) {
        final match = matchReceiptLineToCatalog(entry.key, maxCandidates: 320);

        if (match == null) continue;
        expect(
          match.confidenceLevel,
          isNot(ReceiptConfidenceLevel.good),
          reason:
              '${entry.key} matched ${match.item.trade} / ${match.item.name} '
              'at ${match.confidence}. ${entry.value}.',
        );
        expect(match.needsReview, isTrue, reason: entry.key);
      }
    });

    test('mixed PEH receipt lines keep overlapping materials in the right trade', () {
      final mixedReceiptExpectations = {
        '3/4 PVC COND CPLG': 'HVAC',
        '3/4 PVC COND COUPLING': 'HVAC',
        '3/4 PVC COND UNION': 'HVAC',
        '3/4 PVC CONDUIT CPLG': 'Electrical',
        '3/4 PVC CONDUIT LB': 'Electrical',
        '3/4 PVC COND MALE ADPT': 'Electrical',
        '1/2 PEX TEE': 'Plumbing',
        '3/4 SOFT COPPER TUBING': 'Plumbing',
        '1/2 SWEAT COPPER CAP': 'Plumbing',
        '3/8 ACR COPPER TUBING': 'HVAC',
        '3/4 COPPER REPAIR COUPLING': 'Plumbing',
        '3/8 COPPER LINE SET': 'HVAC',
        '18/5 STAT WIRE': 'HVAC',
        'VINYL CONDENSATE TUBING': 'Plumbing',
      };

      for (final entry in mixedReceiptExpectations.entries) {
        final match = matchReceiptLineToCatalog(entry.key, maxCandidates: 320);
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, entry.value, reason: entry.key);
      }
    });

    test('bare small PVC sizes stay conservative until the receipt gives context', () {
      final dangerousCases = {
        '3/4 PVC': 'Could be plumbing pressure, electrical conduit, or HVAC.',
        '1 IN PVC': 'Could be plumbing pressure, electrical conduit, or HVAC.',
        '3/4 PVC CPLG': 'Coupling alone still lacks trade context at these sizes.',
        '1 IN PVC TEE': 'Tee alone still lacks trade context at these sizes.',
      };

      for (final entry in dangerousCases.entries) {
        final match = matchReceiptLineToCatalog(entry.key, maxCandidates: 320);
        if (match == null) continue;
        expect(
          match.confidenceLevel,
          isNot(ReceiptConfidenceLevel.good),
          reason:
              '${entry.key} matched ${match.item.trade} / ${match.item.name} '
              'at ${match.confidence}. ${entry.value}',
        );
        expect(match.needsReview, isTrue, reason: entry.key);
      }
    });

    test('bare copper and tubing lines stay conservative until the receipt gives trade context', () {
      final dangerousCases = {
        '3/4 COPPER': 'Could be plumbing water tube or HVAC copper stock.',
        '1/2 COPPER TUBING': 'Could be plumbing tube or HVAC refrigerant tube.',
        '3/8 COPPER': 'Could be HVAC line-set copper or other copper stock.',
        'COPPER COIL': 'Could point to multiple plumbing or HVAC uses.',
        'TUBING 3/4': 'Tubing alone is too vague without trade context.',
      };

      for (final entry in dangerousCases.entries) {
        final match = matchReceiptLineToCatalog(entry.key, maxCandidates: 320);
        if (match == null) continue;
        expect(
          match.confidenceLevel,
          isNot(ReceiptConfidenceLevel.good),
          reason:
              '${entry.key} matched ${match.item.trade} / ${match.item.name} '
              'at ${match.confidence}. ${entry.value}',
        );
        expect(match.needsReview, isTrue, reason: entry.key);
      }
    });
  });
}

const _parserLocks = [
  _ParserRegressionLock(
    id: 'reg_known_good_home_depot_pvc_coupling',
    rawLine: 'HD 3/4 PVC SCH40 COUPLING',
    merchant: 'Home Depot',
    locale: 'en-US',
    trade: 'Plumbing',
    packTier: 'core',
    expectedNameContains: 'coupling',
    expectedReviewStatus: 'review-only',
    expectedConfidenceBand: 'good',
    expectedFailureCategory: 'none',
    reason:
        'known good receipt line / merchant regression / pack tier regression',
  ),
  _ParserRegressionLock(
    id: 'reg_known_good_lowes_pex_elbow',
    rawLine: 'LOWES 1/2 PEX CRMP ELL 90 BR',
    merchant: 'Lowe',
    locale: 'en-US',
    trade: 'Plumbing',
    packTier: 'core',
    expectedNameContains: 'pex',
    expectedReviewStatus: 'review-only',
    expectedConfidenceBand: 'good',
    expectedFailureCategory: 'none',
    reason: 'known good receipt line / abbreviation regression',
  ),
  _ParserRegressionLock(
    id: 'reg_locale_spanish_hvac_filter',
    rawLine: 'WALMART FILTRO AIRE 20X25X1',
    merchant: 'Walmart',
    locale: 'es-US',
    trade: 'HVAC',
    packTier: 'core',
    expectedNameContains: 'filter',
    expectedReviewStatus: 'review-only',
    expectedConfidenceBand: 'good',
    expectedFailureCategory: 'none',
    reason: 'locale regression / Spanish / imperial',
  ),
  _ParserRegressionLock(
    id: 'reg_trade_electrical_pvc_conduit',
    rawLine: 'TRUE VALUE 3/4 PVC COND CPLG',
    merchant: 'True Value',
    locale: 'en-US',
    trade: 'Electrical',
    packTier: 'core',
    expectedNameContains: 'electrical',
    expectedReviewStatus: 'review-only',
    expectedConfidenceBand: 'good',
    expectedFailureCategory: 'none',
    reason: 'trade regression / dangerous PVC ambiguity',
  ),
  _ParserRegressionLock(
    id: 'reg_known_bad_subtotal_noise',
    rawLine: 'SUBTOTAL 123.45',
    merchant: 'unknown merchant',
    locale: 'en-US',
    trade: 'unknown',
    packTier: 'core',
    expectedNameContains: '',
    expectedReviewStatus: 'unknown',
    expectedConfidenceBand: 'none',
    expectedFailureCategory: 'noise',
    reason: 'known bad receipt line',
    expectUnknown: true,
    maxConfidence: 0,
  ),
  _ParserRegressionLock(
    id: 'reg_dangerous_word_pipe_alone',
    rawLine: 'PIPE',
    merchant: 'Menards',
    locale: 'en-US',
    trade: 'unknown',
    packTier: 'core',
    expectedNameContains: '',
    expectedReviewStatus: 'unknown',
    expectedConfidenceBand: 'none',
    expectedFailureCategory: 'dangerous_word',
    reason: 'dangerous word regression',
    expectUnknown: true,
    maxConfidence: 0,
  ),
];

class _ParserRegressionLock {
  const _ParserRegressionLock({
    required this.id,
    required this.rawLine,
    required this.merchant,
    required this.locale,
    required this.trade,
    required this.packTier,
    required this.expectedNameContains,
    required this.expectedReviewStatus,
    required this.expectedConfidenceBand,
    required this.expectedFailureCategory,
    required this.reason,
    this.expectUnknown = false,
    this.maxConfidence = 1,
  });

  final String id;
  final String rawLine;
  final String merchant;
  final String locale;
  final String trade;
  final String packTier;
  final String expectedNameContains;
  final String expectedReviewStatus;
  final String expectedConfidenceBand;
  final String expectedFailureCategory;
  final String reason;
  final bool expectUnknown;
  final double maxConfidence;
}

WorkSupplyInventoryRecord _record({
  String sourceLineId = 'RCP-LOCK-L1',
  String storageArea = 'Truck A',
  double lineSubtotal = 10,
  double taxRate = 0,
  double markupRate = 0,
  double packagesPurchased = 1,
  double unitsPerPackage = 1,
}) {
  const item = WorkSupplyItem(
    id: 'REG-PEX-ELBOW',
    name: 'Regression PEX Elbow',
    trade: 'Plumbing',
    category: 'Fittings',
    system: 'PEX',
    itemType: '90 Elbow',
    variant: '1/2 in',
    unit: 'each',
    aliases: ['pex elbow'],
  );
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: 1,
    threshold: 1,
    lastUnitCost: 1,
    storageArea: storageArea,
    receiptLinked: true,
    sourceReceiptId: 'RCP-LOCK',
    sourceReceiptLineId: sourceLineId,
    lineSubtotal: lineSubtotal,
    taxRate: taxRate,
    markupRate: markupRate,
    packagesPurchased: packagesPurchased,
    unitsPerPackage: unitsPerPackage,
  );
}
