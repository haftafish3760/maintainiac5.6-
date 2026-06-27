import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('synthetic damaged receipt inputs remain reviewable', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'ocr swapped home center receipt',
        text: '''
L0WES H0ME IMPR0VEMENT
O6/2O/2O26
PVC C0UPLING 2.49
PVC GLUE 7,99
AM0UNT PAID 10.48
''',
        expectedMerchant: "Lowe's",
        expectedDate: DateTime(2026, 6, 20),
        expectedTotal: 10.48,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COUPLING',
            subtotal: 2.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC GLUE',
            subtotal: 7.99,
          ),
        ],
        minimumScore: .78,
      ),
      ReceiptParseFixture(
        name: 'receipt with duplicated header and footer',
        text: '''
SHEETZ
SHEETZ
06/20/2026 07:15 AM
PUMP 04 UNLEADED 14.250 GAL 47.01
TOTAL 47.01
TOTAL 47.01
''',
        expectedMerchant: 'Sheetz',
        expectedDate: DateTime(2026, 6, 20),
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
        minimumScore: .84,
      ),
      ReceiptParseFixture(
        name: 'lowercase merchant and compact total receipt',
        text: '''
ace hardware
6-20-26
galv pipe coupling 4.29
nitrile gloves 12.99
total:17.28
''',
        expectedMerchant: 'Ace Hardware',
        expectedDate: DateTime(2026, 6, 20),
        expectedTotal: 17.28,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'coupling',
            subtotal: 4.29,
          ),
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'gloves',
            subtotal: 12.99,
          ),
        ],
        minimumScore: .80,
      ),
      ReceiptParseFixture(
        name: 'card paid total without subtotal',
        text: '''
WALMART
06/20/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
VISA CARD 32.44
''',
        expectedMerchant: 'Walmart',
        expectedDate: DateTime(2026, 6, 20),
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
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.97,
          ),
        ],
        minimumScore: .78,
      ),
      ReceiptParseFixture(
        name: 'truncated supply receipt with amount paid',
        text: '''
GRAYBAR
06/20/26
1/2 EMT C0NDUIT 10 FT 8.99
20A GFCI RECEPTACLE 18.49
AM0UNT 27.48
''',
        expectedMerchant: 'Graybar',
        expectedDate: DateTime(2026, 6, 20),
        expectedTotal: 27.48,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'CONDUIT',
            subtotal: 8.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'GFCI',
            subtotal: 18.49,
          ),
        ],
        minimumScore: .78,
      ),
    ]);

    expect(report.fixtureCount, 5);
    expect(
      report.averageScore,
      greaterThanOrEqualTo(.78),
      reason: report.summary,
    );
    expect(
      report.averageQuality,
      greaterThanOrEqualTo(.58),
      reason: report.summary,
    );
  });
}
