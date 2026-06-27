import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('long retail and contractor receipts stay reviewable', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'long walmart mixed business and personal receipt',
        text: '''
WALMART
06/21/2026 08:14 PM
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
AA BATTERIES 16.99
TRASH BAGS 18.49
NITRILE GLOVES 14.99
HOT DOG BUNS 3.48
PHONE CHARGER 12.88
SUBTOTAL 99.27
TAX 6.95
TOTAL 106.22
''',
        expectedMerchant: 'Walmart',
        expectedDate: DateTime(2026, 6, 21),
        expectedTimeMinutes: (20 * 60) + 14,
        expectedSubtotal: 99.27,
        expectedTax: 6.95,
        expectedTotal: 106.22,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Uncategorized',
            descriptionContains: 'GEN MDSE',
            subtotal: 17.48,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'WATER',
            subtotal: 5.99,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.97,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'BATTERIES',
            subtotal: 16.99,
          ),
          ReceiptLineExpectation(
            category: 'Cleaning Supplies',
            descriptionContains: 'TRASH BAGS',
            subtotal: 18.49,
          ),
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'GLOVES',
            subtotal: 14.99,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'BUNS',
            subtotal: 3.48,
          ),
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'CHARGER',
            subtotal: 12.88,
          ),
        ],
        minimumScore: .78,
      ),
      ReceiptParseFixture(
        name: 'long cvs style receipt with repeated promo footer',
        text: '''
CVS PHARMACY
06/21/2026 09:04 AM
FIRST AID KIT 12.99
NITRILE GLOVES 10.49
PAPER TOWELS 8.99
BOTTLED WATER 5.99
PHONE CABLE 9.99
EXTRABUCKS REWARDS
EXTRABUCKS REWARDS
SUBTOTAL 48.45
TAX 3.39
TOTAL 51.84
''',
        expectedMerchant: 'CVS',
        expectedDate: DateTime(2026, 6, 21),
        expectedTimeMinutes: (9 * 60) + 4,
        expectedSubtotal: 48.45,
        expectedTax: 3.39,
        expectedTotal: 51.84,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'FIRST AID',
            subtotal: 12.99,
          ),
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'GLOVES',
            subtotal: 10.49,
          ),
          ReceiptLineExpectation(
            category: 'Cleaning Supplies',
            descriptionContains: 'PAPER TOWELS',
            subtotal: 8.99,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'WATER',
            subtotal: 5.99,
          ),
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'PHONE CABLE',
            subtotal: 9.99,
          ),
        ],
        minimumScore: .76,
      ),
      ReceiptParseFixture(
        name: 'long lowes contractor materials receipt',
        text: '''
LOWE'S HOME IMPROVEMENT
06/21/2026 06:55 AM
2X4X8 KD STUD 4.29
2X4X8 KD STUD 4.29
1/2 IN COPPER 90 ELBOW 7.48
1/2 IN COPPER COUPLING 2.99
PVC PRIMER 8.99
PVC CEMENT 7.99
PIPE STRAP 3.49
5LB DECK SCREWS 32.49
NITRILE GLOVES 12.99
SUBTOTAL 84.71
TAX 5.93
TOTAL 90.64
''',
        expectedMerchant: "Lowe's",
        expectedDate: DateTime(2026, 6, 21),
        expectedTimeMinutes: (6 * 60) + 55,
        expectedSubtotal: 84.71,
        expectedTax: 5.93,
        expectedTotal: 90.64,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'STUD',
            subtotal: 4.29,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'STUD',
            subtotal: 4.29,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COPPER 90',
            subtotal: 7.48,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COUPLING',
            subtotal: 2.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC PRIMER',
            subtotal: 8.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC CEMENT',
            subtotal: 7.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PIPE STRAP',
            subtotal: 3.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'DECK SCREWS',
            subtotal: 32.49,
          ),
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'GLOVES',
            subtotal: 12.99,
          ),
        ],
        minimumScore: .78,
      ),
      ReceiptParseFixture(
        name: 'long fuel stop receipt with truck supplies and food',
        text: '''
LOVES TRAVEL STOP
06/21/2026 05:31 AM
PUMP 03 DIESEL 31.250 GAL 121.56
DEF FLUID 2.500 GAL 10.00
WINDSHIELD WASHER 4.99
SHOP TOWELS 8.99
COFFEE 2.19
BREAKFAST BURRITO 5.49
SUBTOTAL 153.22
TAX 1.52
TOTAL 154.74
''',
        expectedMerchant: "Love's",
        expectedDate: DateTime(2026, 6, 21),
        expectedTimeMinutes: (5 * 60) + 31,
        expectedSubtotal: 153.22,
        expectedTax: 1.52,
        expectedTotal: 154.74,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'DIESEL',
            quantity: 31.25,
            unit: 'gallon',
            subtotal: 121.56,
          ),
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'DEF',
            quantity: 2.5,
            unit: 'gallon',
            subtotal: 10.00,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'WINDSHIELD',
            subtotal: 4.99,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.99,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'COFFEE',
            subtotal: 2.19,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'BURRITO',
            subtotal: 5.49,
          ),
        ],
        minimumScore: .78,
      ),
    ]);

    expect(report.fixtureCount, 4);
    expect(
      report.averageScore,
      greaterThanOrEqualTo(.77),
      reason: report.summary,
    );
    expect(
      report.averageReadiness,
      greaterThanOrEqualTo(.66),
      reason: report.readinessSummary,
    );
  });

  test('multi-photo long receipt overlap is suppressed for app fill', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          _textAttachment(
            id: 'top',
            text: '''
WALMART
06/21/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
AA BATTERIES 16.99
''',
          ),
          _textAttachment(
            id: 'middle',
            text: '''
AA BATTERIES 16.99
TRASH BAGS 18.49
NITRILE GLOVES 14.99
PHONE CHARGER 12.88
''',
          ),
          _textAttachment(
            id: 'bottom',
            text: '''
PHONE CHARGER 12.88
HOT DOG BUNS 3.48
SUBTOTAL 99.27
TAX 6.95
TOTAL 106.22
''',
          ),
        ]);
    final parsed = parseExpenseReceiptText(result.appFillText);

    expect(result.diagnostics.hadDuplicateOrOverlapText, isTrue);
    expect('AA BATTERIES 16.99'.allMatches(result.rawText), hasLength(2));
    expect('AA BATTERIES 16.99'.allMatches(result.appFillText), hasLength(1));
    expect('PHONE CHARGER 12.88'.allMatches(result.rawText), hasLength(2));
    expect('PHONE CHARGER 12.88'.allMatches(result.appFillText), hasLength(1));
    expect(parsed.merchantName, 'Walmart');
    expect(parsed.lines, hasLength(8));
    expect(parsed.enteredTotal, 106.22);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'missing middle receipt section becomes reviewable, not trusted',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'top',
              text: '''
LOWE'S HOME IMPROVEMENT
06/21/2026
2X4X8 KD STUD 4.29
2X4X8 KD STUD 4.29
1/2 IN COPPER 90 ELBOW 7.48
''',
            ),
            _textAttachment(
              id: 'bottom',
              text: '''
5LB DECK SCREWS 32.49
NITRILE GLOVES 12.99
SUBTOTAL 84.71
TAX 5.93
TOTAL 90.64
''',
            ),
          ]);
      final parsed = parseExpenseReceiptText(result.appFillText);

      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(parsed.merchantName, "Lowe's");
      expect(parsed.lines.length, lessThan(9));
      expect(parsed.diagnostics.reconciled, isFalse);
      expect(parsed.diagnostics.trustLabel, isNot('Ready'));
      expect(parsed.warnings.join(' '), contains('do not match'));
    },
  );
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 21),
    importedText: text,
  );
}
