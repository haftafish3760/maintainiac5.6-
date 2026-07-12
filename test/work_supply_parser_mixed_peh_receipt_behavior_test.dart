import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('mixed plumbing electrical HVAC receipt behavior', () {
    test('one realistic receipt keeps explicit PEH lines in their trades', () {
      const expectedTrades = <String, String>{
        '1001 2 3/4 PVC DWV COUPLING 1.98 3.96': 'Plumbing',
        '1002 4 3/4 PVC CONDUIT CPLG 0.88 3.52': 'Electrical',
        '1003 1 3/4 PVC COND CPLG 2.49 2.49': 'HVAC',
        '1004 2 1/2 PEX TEE 3.29 6.58': 'Plumbing',
        '1005 1 18/5 STAT WIRE 49.98 49.98': 'HVAC',
        '1006 3 3/4 PVC COND MALE ADPT 0.79 2.37': 'Electrical',
        '1007 1 3/8 ACR COPPER TUBING 74.00 74.00': 'HVAC',
        '1008 2 3/4 COPPER REPAIR COUPLING 8.49 16.98': 'Plumbing',
      };

      for (final entry in expectedTrades.entries) {
        final match = matchReceiptLineToCatalog(entry.key, maxCandidates: 320);
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, entry.value, reason: entry.key);
      }
    });

    test('totals discounts payment and store text never become materials', () {
      const noise = [
        'THE HOME DEPOT #0123 ANYTOWN GA',
        'ITEMS 8',
        'SUBTOTAL 159.88',
        'PRO XTRA DISCOUNT -10.00',
        'SALES TAX 10.49',
        'TOTAL 160.37',
        'VISA 1234 APPROVED 160.37',
        'CHANGE DUE 0.00',
      ];

      for (final line in noise) {
        expect(
          matchReceiptLineToCatalog(line, maxCandidates: 320),
          isNull,
          reason: line,
        );
      }
    });

    test('shared bare PVC and copper stay review-only without context', () {
      const sharedLines = [
        '2001 2 3/4 PVC 4.49 8.98',
        '2002 1 3/4 PVC CPLG 1.29 1.29',
        '2003 10 FT 1/2 COPPER TUBING 39.80',
        '2004 1 COPPER COIL 89.00',
      ];

      for (final line in sharedLines) {
        final match = matchReceiptLineToCatalog(line, maxCandidates: 320);
        if (match == null) continue;
        expect(
          match.confidenceLevel,
          isNot(ReceiptConfidenceLevel.good),
          reason: '$line chose ${match.item.trade} / ${match.item.name}',
        );
        expect(match.needsReview, isTrue, reason: line);
      }
    });

    test('selected trade resolves shared stock without crossing trades', () {
      const scopedCases = <({String line, String scope})>[
        (line: '3/4 PVC COUPLING SCH40 2 EA 3.98', scope: 'Plumbing'),
        (line: '3/4 PVC CONDUIT COUPLING 4 EA 3.52', scope: 'Electrical'),
        (line: '3/4 PVC CONDENSATE COUPLING 2 EA 4.98', scope: 'HVAC'),
        (line: '3/8 ACR COPPER TUBING 1 EA 74.00', scope: 'HVAC'),
        (line: '3/4 COPPER REPAIR COUPLING 2 EA 16.98', scope: 'Plumbing'),
      ];

      for (final testCase in scopedCases) {
        final match = matchReceiptLineToCatalog(
          testCase.line,
          tradeScope: testCase.scope,
          maxCandidates: 320,
        );
        expect(match, isNotNull, reason: testCase.line);
        expect(match!.item.trade, testCase.scope, reason: testCase.line);
      }
    });
  });
}
