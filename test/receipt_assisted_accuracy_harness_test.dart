import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test(
    'catalog matcher prefers receipt fastener type over size-only matches',
    () {
      expect(
        workSupplyCatalogItems.map((item) => item.name),
        contains('#8 x 1-1/4 in Wood Screws'),
      );
      final match = matchReceiptLineToCatalog(
        '25PK #8 X 1-1/4 WOOD SCREWS 6.98',
      );

      expect(match, isNotNull);
      expect(match!.item.name, '#8 x 1-1/4 in Wood Screws');
    },
  );

  test('catalog matcher keeps electrical amp ratings on receipt lines', () {
    final match = matchReceiptLineToCatalog('20A GFCI RECEPTACLE 18.49');

    expect(match, isNotNull);
    expect(match!.item.name, '20 Amp GFCI Outlet');
  });

  test('catalog matcher accepts strong short plumbing receipt matches', () {
    final match = matchReceiptLineToCatalog('PVC COUPLING 2.49');

    expect(match, isNotNull);
    expect(match!.item.name, contains('PVC'));
    expect(match.item.name, contains('Coupling'));
    expect(match.needsReview, isFalse);
  });

  test('catalog matcher accepts HVAC capacitor filter and tape lines', () {
    final capacitor = matchReceiptLineToCatalog('35/5 MFD RUN CAPACITOR 18.49');
    final filter = matchReceiptLineToCatalog('16X25X1 PLEATED FILTER 9.99');
    final tape = matchReceiptLineToCatalog('FOIL HVAC TAPE 12.99');

    expect(capacitor, isNotNull);
    expect(capacitor!.item.name, contains('Run Capacitor'));
    expect(capacitor.needsReview, isFalse);
    expect(filter, isNotNull);
    expect(filter!.item.name, contains('Pleated Air Filter'));
    expect(filter.needsReview, isFalse);
    expect(tape, isNotNull);
    expect(tape!.item.name, contains('Foil HVAC Tape'));
    expect(tape.needsReview, isFalse);
  });

  test('catalog matcher respects candidate caps after learned corrections', () {
    final correctedItem = searchWorkSupplies('1/2 in copper tee').first;
    final memory = ReceiptParserLearningMemory()
      ..confirmCorrection(
        receiptLine: 'COPPER THING HALF 7.49',
        item: correctedItem,
      );

    final capped = matchReceiptLineToCatalog(
      '25PK #8 X 1-1/4 WOOD SCREWS 6.98',
      maxCandidates: 0,
    );
    final learned = matchReceiptLineToCatalog(
      'COPPER THING HALF 7.49',
      memory: memory,
      maxCandidates: 0,
    );

    expect(capped, isNull);
    expect(learned, isNotNull);
    expect(learned!.item.id, correctedItem.id);
    expect(learned.source, ReceiptMatchSource.learnedCorrection);
  });

  test('expense parser passes catalog candidate caps to material matching', () {
    final capped = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''', maxCatalogCandidates: 0);
    final uncapped = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
25PK #8 X 1-1/4 WOOD SCREWS 6.98
TOTAL 6.98
''');

    expect(capped.lines.single.catalogItemId, isNull);
    expect(capped.diagnostics.maxCatalogCandidates, 0);
    expect(capped.diagnostics.catalogMatchedLineCount, 0);
    expect(capped.diagnostics.hasUnmatchedMaterials, isTrue);
    expect(uncapped.lines.single.catalogItemName, '#8 x 1-1/4 in Wood Screws');
    expect(uncapped.diagnostics.catalogMatchedLineCount, 1);
  });

  test('expense parser applies learned catalog corrections to saved lines', () {
    final correctedItem = searchWorkSupplies('1/2 in copper tee').first;
    final memory = ReceiptParserLearningMemory()
      ..confirmCorrection(
        receiptLine: 'COPPER THING HALF 7.49 COPPER THING HALF',
        item: correctedItem,
      );

    final parsed = parseExpenseReceiptText('''
LOWE'S HOME IMPROVEMENT
06/12/2026
COPPER THING HALF 7.49
TOTAL 7.49
''', materialCatalogMemory: memory);

    expect(parsed.lines.single.catalogItemId, correctedItem.id);
    expect(parsed.lines.single.catalogItemName, correctedItem.name);
    expect(parsed.lines.single.catalogMatchConfidence, .98);
    expect(parsed.lineReviews.single.catalogItemName, correctedItem.name);
  });

  test(
    'assisted receipt fixtures track material catalog matching accuracy',
    () {
      final result = expectReceiptFixtures(const [
        ReceiptParseFixture(
          name: 'lowes mixed material receipt',
          text: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
2 @ 4.98 2X4X8 KD STUD 9.96
25PK #8 X 1-1/4 WOOD SCREWS 6.98
12 FT ROMEX 12/2 W/G 34.80
TOTAL 51.74
''',
          expectedMerchant: "Lowe's",
          expectedLineCategories: ['Materials', 'Materials', 'Materials'],
          expectedTotal: 51.74,
          expectedCatalogItems: [
            '2 x 4 x 8 ft Dimensional Lumber',
            '#8 x 1-1/4 in Wood Screws',
            '12/2 NM-B Cable',
          ],
          minimumQuality: .70,
        ),
        ReceiptParseFixture(
          name: 'ferguson plumbing receipt',
          text: '''
FERGUSON ENTERPRISES
06/12/2026
3 EA 1/2 IN COPPER COUPLING 8.97
1/2 X 10 FT PVC PIPE SCH40 14.50
TOTAL 23.47
''',
          expectedMerchant: 'Ferguson',
          expectedLineCategories: ['Materials', 'Materials'],
          expectedTotal: 23.47,
          expectedCatalogItems: [
            '1/2 in Copper Coupling',
            '1/2 in x 10 ft PVC Schedule 40 Pipe',
          ],
          minimumQuality: .72,
        ),
        ReceiptParseFixture(
          name: 'electrical supply receipt',
          text: '''
CITY ELECTRIC SUPPLY
06/12/2026
20A GFCI RECEPTACLE 18.49
1/2 EMT CONDUIT 10 FT 8.99
TOTAL 27.48
''',
          expectedMerchant: 'City Electric Supply',
          expectedLineCategories: ['Materials', 'Materials'],
          expectedTotal: 27.48,
          expectedCatalogItems: ['20 Amp GFCI Outlet', '1/2 in EMT Conduit'],
          minimumQuality: .70,
        ),
      ]);

      expect(result.fixtureCount, 3);
      expect(result.passRate, 1);
      expect(result.averageQuality, greaterThanOrEqualTo(.74));
    },
  );
}
