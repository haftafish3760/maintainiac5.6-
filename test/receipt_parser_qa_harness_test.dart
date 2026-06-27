import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('receipt QA harness scores broad expense receipt fixtures', () {
    final result = expectReceiptFixtures([
      ReceiptParseFixture(
        name: 'fuel station diesel receipt',
        text: '''
Quick Fuel
06/11/2026 08:14 AM
Pump 03 Diesel 12.500 GAL 48.75
Subtotal 48.75
Sales Tax 2.93
Total 51.68
''',
        expectedMerchant: 'Quick Fuel',
        expectedDate: DateTime(2026, 6, 11),
        expectedTimeMinutes: (8 * 60) + 14,
        expectedSubtotal: 48.75,
        expectedTax: 2.93,
        expectedTotal: 51.68,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'Diesel',
            quantity: 12.5,
            unit: 'gallon',
            subtotal: 48.75,
            needsReview: false,
          ),
        ],
        minimumQuality: .84,
        minimumScore: .94,
      ),
      ReceiptParseFixture(
        name: 'auto parts maintenance receipt',
        text: '''
ADVANCE AUTO PARTS
Store 04218
6/12/26 7:03 PM
OIL FILTER PH8A 12,99
5QT FULL SYNTHETIC MOTOR OIL 34.99
CORE CHARGE 0.00
SUB-TOTAL 47.98
TAX 3.36
AMOUNT PAID 51.34
''',
        expectedMerchant: 'Advance Auto Parts',
        expectedDate: DateTime(2026, 6, 12),
        expectedTimeMinutes: (19 * 60) + 3,
        expectedSubtotal: 47.98,
        expectedTax: 3.36,
        expectedTotal: 51.34,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'OIL FILTER',
            subtotal: 12.99,
            needsReview: false,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'SYNTHETIC',
            subtotal: 34.99,
            needsReview: false,
          ),
        ],
        minimumQuality: .84,
        minimumScore: .94,
      ),
      ReceiptParseFixture(
        name: 'mixed retail quick classify receipt',
        text: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
CASE WATER 5.99
TOTAL 23.47
''',
        expectedMerchant: 'Walmart',
        expectedDate: DateTime(2026, 6, 12),
        expectedTotal: 23.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Uncategorized',
            descriptionContains: 'GENERAL MDSE',
            subtotal: 17.48,
            needsReview: true,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'CASE WATER',
            subtotal: 5.99,
            needsReview: false,
          ),
        ],
        minimumQuality: .58,
        minimumScore: .86,
      ),
      ReceiptParseFixture(
        name: 'home center materials receipt',
        text: '''
THE HOME DEPOT
2026-06-10
1/2 IN COPPER 90 ELBOW 7.48
QTY 2 SAW BLADE 19.98
MISC ITEM 4.50
TOTAL 31.96
''',
        expectedMerchant: 'The Home Depot',
        expectedDate: DateTime(2026, 6, 10),
        expectedTotal: 31.96,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COPPER',
            catalogItemName: '1/2 in Copper 90 Elbow',
            subtotal: 7.48,
            needsReview: false,
          ),
          ReceiptLineExpectation(
            category: 'Tools',
            descriptionContains: 'SAW BLADE',
            quantity: 2,
            subtotal: 19.98,
            needsReview: false,
          ),
          ReceiptLineExpectation(
            category: 'Uncategorized',
            descriptionContains: 'MISC ITEM',
            subtotal: 4.50,
            needsReview: true,
          ),
        ],
        expectedCatalogItems: const ['1/2 in Copper 90 Elbow'],
        minimumQuality: .70,
        minimumScore: .88,
      ),
    ]);

    expect(result.fixtureCount, 4);
    expect(
      result.averageScore,
      greaterThanOrEqualTo(.90),
      reason: result.summary,
    );
    expect(
      result.averageQuality,
      greaterThanOrEqualTo(.74),
      reason: result.summary,
    );
    expect(
      result.averageReadiness,
      greaterThanOrEqualTo(.80),
      reason: result.readinessSummary,
    );
    expect(result.fixtureReadiness, contains('fuel station diesel receipt'));
    expect(
      result.fixtureReadiness['fuel station diesel receipt']!.label,
      ReceiptReadinessLabel.ready,
    );
    expect(result.readinessSummary, contains('ready='));
  });

  test(
    'receipt QA harness can score imperfect fixtures without failing early',
    () {
      final report = scoreReceiptFixtures([
        ReceiptParseFixture(
          name: 'ambiguous club store receipt',
          text: '''
SAM'S CLUB
06/12/2026
SHOP SUPPLIES 18.44
HOT DOG COMBO 1.50
TOTAL 19.94
''',
          expectedMerchant: "Sam's Club",
          expectedDate: DateTime(2026, 6, 12),
          expectedTotal: 19.94,
          expectedLines: const [
            ReceiptLineExpectation(
              category: 'Uncategorized',
              descriptionContains: 'SHOP SUPPLIES',
              subtotal: 18.44,
              needsReview: true,
            ),
            ReceiptLineExpectation(
              category: 'Meals',
              descriptionContains: 'HOT DOG',
              subtotal: 1.50,
            ),
          ],
          minimumQuality: .58,
          minimumScore: .70,
        ),
      ]);

      expect(report.fixtureCount, 1);
      expect(report.fixtureReadiness, contains('ambiguous club store receipt'));
      expect(
        report.fixtureReadiness['ambiguous club store receipt']!.label,
        isNot(ReceiptReadinessLabel.blocked),
      );
      expect(
        report.weakestFixtures.single.name,
        'ambiguous club store receipt',
      );
      expect(
        report.averageScore,
        greaterThanOrEqualTo(.70),
        reason: report.summary,
      );
      expect(report.summary, contains('avgScore='));
      expect(report.summary, contains('avgReadiness='));
    },
  );

  test('receipt QA harness reports issue buckets for weak fixtures', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'bad totals and weak material catalog receipt',
        text: '''
THE HOME DEPOT
06/12/2026
MYSTERY MATERIAL 10.00
Subtotal 10.00
Tax 0.80
Total 15.80
''',
        expectedMerchant: 'The Home Depot',
        expectedDate: DateTime(2026, 6, 12),
        expectedSubtotal: 10.00,
        expectedTax: 0.80,
        expectedTotal: 15.80,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'MYSTERY',
            subtotal: 10.00,
          ),
        ],
        expectedCatalogItems: const ['Definitely Not In Catalog'],
        minimumScore: .1,
      ),
    ]);

    final readiness = report
        .fixtureReadiness['bad totals and weak material catalog receipt']!;

    expect(readiness.label, ReceiptReadinessLabel.blocked);
    expect(readiness.issues, contains('tax_math_mismatch'));
    expect(readiness.issues, contains('catalog'));
    expect(readiness.issues, contains('heavy_review'));
    expect(report.issueCounts['tax_math_mismatch'], 1);
    expect(report.issueCounts['catalog'], 1);
    expect(report.readinessSummary, contains('tax_math_mismatch=1'));
  });
}
