import 'receipt_parse_accuracy_harness.dart';

final syntheticTradeReceiptFixturePack = [
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
];
