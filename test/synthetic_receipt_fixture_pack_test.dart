import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('synthetic receipt pack covers common contractor expense patterns', () {
    final report = scoreReceiptFixtures([
      ReceiptParseFixture(
        name: 'walmart mixed business personal style receipt',
        text: '''
WALMART
06/18/2026 04:22 PM
SHOP TOWELS 8.97
CASE WATER 5.98
PHONE CHARGER 12.88
SUBTOTAL 27.83
TAX 1.95
TOTAL 29.78
''',
        expectedMerchant: 'Walmart',
        expectedDate: DateTime(2026, 6, 18),
        expectedTimeMinutes: (16 * 60) + 22,
        expectedSubtotal: 27.83,
        expectedTax: 1.95,
        expectedTotal: 29.78,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 8.97,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'CASE WATER',
            subtotal: 5.98,
          ),
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'PHONE CHARGER',
            subtotal: 12.88,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'lowes plumbing material receipt',
        text: '''
LOWE'S HOME IMPROVEMENT
06/18/2026
2 EA 1/2 IN COPPER 90 ELBOW 14.96
1/2 X 10 FT PVC PIPE SCH40 14.50
PVC PRIMER 8.99
TOTAL 38.45
''',
        expectedMerchant: "Lowe's",
        expectedDate: DateTime(2026, 6, 18),
        expectedTotal: 38.45,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COPPER',
            catalogItemName: '1/2 in Copper 90 Elbow',
            quantity: 2,
            subtotal: 14.96,
            needsReview: false,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC PIPE',
            catalogItemName: '1/2 in x 10 ft PVC Schedule 40 Pipe',
            subtotal: 14.50,
            needsReview: false,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC PRIMER',
            subtotal: 8.99,
          ),
        ],
        expectedCatalogItems: const [
          '1/2 in Copper 90 Elbow',
          '1/2 in x 10 ft PVC Schedule 40 Pipe',
        ],
      ),
      ReceiptParseFixture(
        name: 'home depot electrical material receipt',
        text: '''
THE HOME DEPOT
06/18/2026
20A GFCI RECEPTACLE 18.49
12 FT ROMEX 12/2 W/G 34.80
1G PLASTIC ELEC BOX 2.48
TOTAL 55.77
''',
        expectedMerchant: 'The Home Depot',
        expectedDate: DateTime(2026, 6, 18),
        expectedTotal: 55.77,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'GFCI',
            catalogItemName: '20 Amp GFCI Outlet',
            subtotal: 18.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'ROMEX',
            catalogItemName: '12/2 NM-B Cable',
            subtotal: 34.80,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'ELEC BOX',
            subtotal: 2.48,
          ),
        ],
        expectedCatalogItems: const ['20 Amp GFCI Outlet', '12/2 NM-B Cable'],
      ),
      ReceiptParseFixture(
        name: 'autozone repair parts receipt',
        text: '''
AUTOZONE
06/18/2026 09:05 AM
BRAKE PADS FRONT 49.99
BRAKE CLEANER 5.49
SHOP RAGS 7.99
TOTAL 63.47
''',
        expectedMerchant: 'AutoZone',
        expectedDate: DateTime(2026, 6, 18),
        expectedTimeMinutes: (9 * 60) + 5,
        expectedTotal: 63.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Vehicle Parts',
            descriptionContains: 'BRAKE PADS',
            subtotal: 49.99,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'BRAKE CLEANER',
            subtotal: 5.49,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP RAGS',
            subtotal: 7.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'fuel plus meal mixed receipt',
        text: '''
SHEETZ
06/18/2026 06:40 AM
PUMP 07 UNLEADED 12.00 GAL 42.84
COFFEE 2.19
BREAKFAST SANDWICH 4.99
TOTAL 50.02
''',
        expectedMerchant: 'Sheetz',
        expectedDate: DateTime(2026, 6, 18),
        expectedTimeMinutes: (6 * 60) + 40,
        expectedTotal: 50.02,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Fuel',
            descriptionContains: 'UNLEADED',
            quantity: 12,
            unit: 'gallon',
            subtotal: 42.84,
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
        ],
      ),
      ReceiptParseFixture(
        name: 'fast food meal receipt',
        text: '''
CHICK-FIL-A
06/18/2026 12:18 PM
COMBO MEAL 10.89
DRINK 2.19
TOTAL 13.08
''',
        expectedMerchant: 'Chick-fil-A',
        expectedDate: DateTime(2026, 6, 18),
        expectedTimeMinutes: (12 * 60) + 18,
        expectedTotal: 13.08,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'COMBO',
            subtotal: 10.89,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'DRINK',
            subtotal: 2.19,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'telecom business phone receipt',
        text: '''
VERIZON WIRELESS
06/18/2026
MONTHLY PHONE SERVICE 86.42
DEVICE PROTECTION 8.00
TOTAL 94.42
''',
        expectedMerchant: 'Verizon Wireless',
        expectedDate: DateTime(2026, 6, 18),
        expectedTotal: 94.42,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'PHONE SERVICE',
            subtotal: 86.42,
          ),
          ReceiptLineExpectation(
            category: 'Cell Phone',
            descriptionContains: 'DEVICE PROTECTION',
            subtotal: 8.00,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'supply house plumbing receipt',
        text: '''
FERGUSON ENTERPRISES
06/18/2026
3 EA 1/2 IN COPPER COUPLING 8.97
1 EA 3/4 IN BRASS BALL VALVE 12.49
TOTAL 21.46
''',
        expectedMerchant: 'Ferguson',
        expectedDate: DateTime(2026, 6, 18),
        expectedTotal: 21.46,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COPPER COUPLING',
            catalogItemName: '1/2 in Copper Coupling',
            quantity: 3,
            subtotal: 8.97,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'BALL VALVE',
            subtotal: 12.49,
          ),
        ],
        expectedCatalogItems: const ['1/2 in Copper Coupling'],
      ),
      ReceiptParseFixture(
        name: 'menards carpentry and fastener receipt',
        text: '''
MENARDS
06/19/2026
2X4X8 SPF STUD 4.29
3/4 IN 4X8 OSB SHEATHING 18.99
5LB DECK SCREWS 32.49
TOTAL 55.77
''',
        expectedMerchant: 'Menards',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 55.77,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: '2X4X8',
            subtotal: 4.29,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'OSB',
            subtotal: 18.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'DECK SCREWS',
            subtotal: 32.49,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'oreilly auto parts vehicle repair receipt',
        text: '''
O'REILLY AUTO PARTS
06/19/2026
ALTERNATOR 189.99
SERPENTINE BELT 24.49
BRAKE CLEANER 5.49
TOTAL 219.97
''',
        expectedMerchant: "O'Reilly Auto Parts",
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 219.97,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Vehicle Parts',
            descriptionContains: 'ALTERNATOR',
            subtotal: 189.99,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'SERPENTINE',
            subtotal: 24.49,
          ),
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'BRAKE CLEANER',
            subtotal: 5.49,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'hvac supply house receipt',
        text: '''
JOHNSTONE SUPPLY
06/19/2026
35/5 MFD RUN CAPACITOR 18.49
16X25X1 PLEATED FILTER 9.99
FOIL HVAC TAPE 12.99
TOTAL 41.47
''',
        expectedMerchant: 'Johnstone Supply',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 41.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'CAPACITOR',
            subtotal: 18.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'FILTER',
            subtotal: 9.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'FOIL HVAC TAPE',
            subtotal: 12.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'roofing supply receipt',
        text: '''
ABC SUPPLY
06/19/2026
ARCHITECTURAL SHINGLES BUNDLE 38.99
DRIP EDGE 10FT 8.49
ROOFING NAILS 1-1/4 24.99
TOTAL 72.47
''',
        expectedMerchant: 'ABC Supply',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 72.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'SHINGLES',
            subtotal: 38.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'DRIP EDGE',
            subtotal: 8.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'ROOFING NAILS',
            subtotal: 24.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'painting supply receipt',
        text: '''
SHERWIN-WILLIAMS
06/19/2026
1 GAL INTERIOR LATEX PAINT 42.99
9 IN ROLLER COVER 6.49
PAINTERS TAPE 5.99
TOTAL 55.47
''',
        expectedMerchant: 'Sherwin-Williams',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 55.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'LATEX PAINT',
            subtotal: 42.99,
          ),
          ReceiptLineExpectation(
            category: 'Tools',
            descriptionContains: 'ROLLER COVER',
            subtotal: 6.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PAINTERS TAPE',
            subtotal: 5.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'costco mixed warehouse receipt',
        text: '''
COSTCO WHOLESALE
06/19/2026
SHOP TOWELS 19.99
BOTTLED WATER 4.99
AA BATTERIES 16.99
HOT DOG COMBO 1.50
TOTAL 43.47
''',
        expectedMerchant: 'Costco',
        expectedDate: DateTime(2026, 6, 19),
        expectedTotal: 43.47,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Vehicle Supplies',
            descriptionContains: 'SHOP TOWELS',
            subtotal: 19.99,
          ),
          ReceiptLineExpectation(
            category: 'Groceries',
            descriptionContains: 'BOTTLED WATER',
            subtotal: 4.99,
          ),
          ReceiptLineExpectation(
            category: 'Maintenance',
            descriptionContains: 'BATTERIES',
            subtotal: 16.99,
          ),
          ReceiptLineExpectation(
            category: 'Meals',
            descriptionContains: 'HOT DOG',
            subtotal: 1.50,
          ),
        ],
      ),
    ]);

    expect(report.fixtureCount, 14);
    expect(
      report.averageScore,
      greaterThanOrEqualTo(.82),
      reason: report.summary,
    );
    expect(
      report.averageQuality,
      greaterThanOrEqualTo(.68),
      reason: report.summary,
    );
  });
}
