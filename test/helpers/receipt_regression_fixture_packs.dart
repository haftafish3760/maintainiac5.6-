import 'receipt_parse_accuracy_harness.dart';

final coreReceiptRegressionFixtures = [
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
    expectedLines: [
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
    expectedLines: [
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
    expectedLines: [
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
    expectedCatalogItems: ['1/2 in Copper 90 Elbow'],
    minimumQuality: .70,
    minimumScore: .88,
  ),
];

final materialReceiptRegressionFixtures = [
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
];

final noisyReceiptRegressionFixtures = [
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
    expectedLines: [
      ReceiptLineExpectation(
        category: 'Materials',
        descriptionContains: 'COPPER',
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
    expectedLines: [
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
    name: 'truck stop split-row fuel receipt with discount',
    text: '''
PILOT TRVL CTR
06/23/2026 05:42 AM
PUMP 12
PRODUCT DIESEL
GALLONS 18.425
PRICE/GAL 3.699
FUEL SALE 68.15
REWARDS DISC -1.20
TOTAL 66.95
VISA FLEET CARD 66.95
AUTH 442193
TRACE 77801
ODOMETER 184220
''',
    expectedMerchant: 'Pilot Flying J',
    expectedDate: DateTime(2026, 6, 23),
    expectedTimeMinutes: (5 * 60) + 42,
    expectedTotal: 66.95,
    expectedLines: [
      ReceiptLineExpectation(
        category: 'Fuel',
        descriptionContains: 'Diesel',
        quantity: 18.425,
        unit: 'gallon',
        subtotal: 68.15,
        needsReview: false,
      ),
      ReceiptLineExpectation(
        category: 'Receipt Adjustment',
        descriptionContains: 'REWARDS',
        subtotal: -1.20,
        needsReview: false,
      ),
    ],
    minimumScore: .82,
  ),
  ReceiptParseFixture(
    name: 'faded fuel receipt with separate gallons and ppg',
    text: '''
SHELL OIL
O6/23/2O26 O7:O5 AM
PUMP O3
REG UNL
GALS 12.347
PPG 3.459
FUEL SALE 42.71
TOTAL 42.71
FLEET CARD 42.71
DRIVER ID 1042
''',
    expectedMerchant: 'Shell',
    expectedDate: DateTime(2026, 6, 23),
    expectedTimeMinutes: (7 * 60) + 5,
    expectedTotal: 42.71,
    expectedLines: [
      ReceiptLineExpectation(
        category: 'Fuel',
        descriptionContains: 'REG UNL',
        quantity: 12.347,
        unit: 'gallon',
        subtotal: 42.71,
        needsReview: false,
      ),
    ],
    minimumScore: .82,
  ),
];

final damagedReceiptRegressionFixtures = [
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
    expectedLines: [
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
    expectedLines: [
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
];

final tradeSupplyReceiptRegressionFixtures = [
  ReceiptParseFixture(
    name: 'graybar electrical supply receipt',
    text: '''
GRAYBAR
06/21/2026
12/2 NM-B CABLE 34.80
20A GFCI RECEPTACLE 18.49
1/2 EMT CONDUIT 10 FT 8.99
TOTAL 62.28
''',
    expectedMerchant: 'Graybar',
    expectedDate: DateTime(2026, 6, 21),
    expectedTotal: 62.28,
    expectedLines: [
      ReceiptLineExpectation(
        category: 'Materials',
        descriptionContains: 'NM-B',
        subtotal: 34.80,
      ),
      ReceiptLineExpectation(
        category: 'Materials',
        descriptionContains: 'GFCI',
        subtotal: 18.49,
      ),
      ReceiptLineExpectation(
        category: 'Materials',
        descriptionContains: 'EMT',
        subtotal: 8.99,
      ),
    ],
  ),
  ReceiptParseFixture(
    name: 'united refrigeration hvac receipt',
    text: '''
UNITED REFRIGERATION
06/21/2026
35/5 MFD RUN CAPACITOR 18.49
16X25X1 PLEATED FILTER 9.99
FOIL HVAC TAPE 12.99
TOTAL 41.47
''',
    expectedMerchant: 'United Refrigeration',
    expectedDate: DateTime(2026, 6, 21),
    expectedTotal: 41.47,
    expectedLines: [
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
        descriptionContains: 'HVAC TAPE',
        subtotal: 12.99,
      ),
    ],
  ),
];

final receiptRegressionFixturePacks = {
  'core': coreReceiptRegressionFixtures,
  'materials': materialReceiptRegressionFixtures,
  'noisy_ocr': noisyReceiptRegressionFixtures,
  'damaged': damagedReceiptRegressionFixtures,
  'trade_supply': tradeSupplyReceiptRegressionFixtures,
};
