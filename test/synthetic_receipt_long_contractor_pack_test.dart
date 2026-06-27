import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('synthetic long contractor receipts stay parseable for review', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'long home center materials and tools receipt',
        text: '''
THE HOME DEPOT
06/20/2026 07:44 AM
2X4X8 KD STUD 4.29
2X4X8 KD STUD 4.29
1/2 IN COPPER 90 ELBOW 7.48
PVC PRIMER 8.99
PVC CEMENT 7.99
5LB DECK SCREWS 32.49
9 IN ROLLER COVER 6.49
PAINTERS TAPE 5.99
SAW BLADE 19.98
NITRILE GLOVES 12.99
SUBTOTAL 110.98
TAX 7.77
TOTAL 118.75
''',
        expectedMerchant: 'The Home Depot',
        expectedDate: DateTime(2026, 6, 20),
        expectedTimeMinutes: (7 * 60) + 44,
        expectedSubtotal: 110.98,
        expectedTax: 7.77,
        expectedTotal: 118.75,
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
            descriptionContains: 'COPPER',
            subtotal: 7.48,
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
            descriptionContains: 'DECK SCREWS',
            subtotal: 32.49,
          ),
          ReceiptLineExpectation(
            category: 'Tools',
            descriptionContains: 'ROLLER',
            subtotal: 6.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'TAPE',
            subtotal: 5.99,
          ),
          ReceiptLineExpectation(
            category: 'Tools',
            descriptionContains: 'SAW BLADE',
            subtotal: 19.98,
          ),
          ReceiptLineExpectation(
            category: 'Safety Gear',
            descriptionContains: 'GLOVES',
            subtotal: 12.99,
          ),
        ],
        minimumScore: .82,
      ),
      ReceiptParseFixture(
        name: 'long fuel stop receipt with mixed line types',
        text: '''
PILOT TRAVEL CENTER
06/20/2026 05:58 AM
ODOMETER 184220
PUMP 12 DIESEL 24.500 GAL 92.61
DEF FLUID 2.500 GAL 10.00
COFFEE 2.19
BREAKFAST SANDWICH 4.99
SHOP TOWELS 8.99
SUBTOTAL 118.78
TAX 1.13
TOTAL 119.91
''',
        expectedMerchant: 'Pilot Flying J',
        expectedDate: DateTime(2026, 6, 20),
        expectedTimeMinutes: (5 * 60) + 58,
        expectedSubtotal: 118.78,
        expectedTax: 1.13,
        expectedTotal: 119.91,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'DIESEL',
            quantity: 24.5,
            unit: 'gallon',
            subtotal: 92.61,
          ),
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'DEF',
            quantity: 2.5,
            unit: 'gallon',
            subtotal: 10.00,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'COFFEE',
            subtotal: 2.19,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'SANDWICH',
            subtotal: 4.99,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.99,
          ),
        ],
        minimumScore: .84,
      ),
      ReceiptParseFixture(
        name: 'long auto repair parts receipt',
        text: '''
ADVANCE AUTO PARTS
06/20/2026 06:11 PM
OIL FILTER PH8A 12.99
5QT FULL SYNTHETIC MOTOR OIL 34.99
AIR FILTER 18.49
WIPER BLADE 15.99
BRAKE CLEANER 5.49
SHOP TOWELS 8.99
CORE CHARGE 0.00
SUB-TOTAL 96.94
TAX 6.79
AMOUNT PAID 103.73
''',
        expectedMerchant: 'Advance Auto Parts',
        expectedDate: DateTime(2026, 6, 20),
        expectedTimeMinutes: (18 * 60) + 11,
        expectedSubtotal: 96.94,
        expectedTax: 6.79,
        expectedTotal: 103.73,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'OIL FILTER',
            subtotal: 12.99,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'SYNTHETIC',
            subtotal: 34.99,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'AIR FILTER',
            subtotal: 18.49,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'WIPER',
            subtotal: 15.99,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'BRAKE CLEANER',
            subtotal: 5.49,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.99,
          ),
        ],
        minimumScore: .84,
      ),
      ReceiptParseFixture(
        name: 'long warehouse mixed purchase receipt',
        text: '''
COSTCO WHOLESALE
06/20/2026
SHOP TOWELS 19.99
BOTTLED WATER 4.99
AA BATTERIES 16.99
TRASH BAGS 18.49
NITRILE GLOVES 14.99
HOT DOG COMBO 1.50
PHONE CHARGER 12.88
TOTAL 89.83
''',
        expectedMerchant: 'Costco',
        expectedDate: DateTime(2026, 6, 20),
        expectedTotal: 89.83,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 19.99,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'WATER',
            subtotal: 4.99,
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
            category: 'Meals',
            descriptionContains: 'HOT DOG',
            subtotal: 1.50,
          ),
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'CHARGER',
            subtotal: 12.88,
          ),
        ],
        minimumScore: .82,
      ),
    ]);

    expect(report.fixtureCount, 4);
    expect(
      report.averageScore,
      greaterThanOrEqualTo(.82),
      reason: report.summary,
    );
    expect(
      report.averageQuality,
      greaterThanOrEqualTo(.66),
      reason: report.summary,
    );
  });
}
