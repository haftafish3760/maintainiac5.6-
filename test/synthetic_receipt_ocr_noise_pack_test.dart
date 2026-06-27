import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('synthetic OCR noise pack tracks common receipt misreads', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'lowes ocr punctuation and spacing noise',
        text: '''
LOWES H0ME IMPROVEMENT
O6/19/2O26
1/2  IN   C0PPER  9O  ELB0W   7.48
PVC  GLUE  7,99
T0TAL 15.47
''',
        expectedMerchant: "Lowe's",
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 15.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'C0PPER',
            subtotal: 7.48,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC',
            subtotal: 7.99,
          ),
        ],
        minimumScore: .62,
      ),
      ReceiptParseFixture(
        name: 'fuel receipt ocr letter number swaps',
        text: '''
SHEETZ
O6/19/2O26 O7:15 AM
PUMP O4 UNLEADED 14.25O GAL 47.O1
T0TAL 47.O1
''',
        expectedMerchant: 'Sheetz',
        expectedDate: DateTime(2026, 6, 19),
        expectedTimeMinutes: (7 * 60) + 15,
        expectedTotal: 47.01,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'UNLEADED',
            quantity: 14.25,
            unit: 'gallon',
            subtotal: 47.01,
          ),
        ],
        minimumScore: .62,
      ),
      ReceiptParseFixture(
        name: 'home center truncated material rows',
        text: '''
H0ME DEP0T
06-19-26
2X4X8 KD STUD      4.29
25PK #8 X 1-1/4 WD SCRW 6.98
12/2 NM-B CABLE    34.80
AM0UNT PAID 46.O7
''',
        expectedMerchant: 'The Home Depot',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 46.07,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'STUD',
            subtotal: 4.29,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'SCRW',
            subtotal: 6.98,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'NM-B',
            subtotal: 34.80,
          ),
        ],
        minimumScore: .62,
      ),
      ReceiptParseFixture(
        name: 'mixed retail receipt missing subtotal',
        text: '''
WALMART
06/19/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWEL 8.97
CARD 32.44
''',
        expectedMerchant: 'Walmart',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 32.44,
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
            descriptionContains: 'SHOP TOWEL',
            subtotal: 8.97,
          ),
        ],
        minimumScore: .62,
      ),
    ]);

    expect(report.fixtureCount, 4);
    expect(
      report.averageScore,
      greaterThanOrEqualTo(.62),
      reason: report.summary,
    );
    expect(report.summary, contains('fixtures=4'));
  });
}
