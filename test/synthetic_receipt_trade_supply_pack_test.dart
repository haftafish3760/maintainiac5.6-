import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';

void main() {
  test('synthetic trade supply receipts cover contractor merchant lanes', () {
    final report = scoreReceiptFixtures([
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
        expectedLines: const [
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
        name: 'winsupply plumbing receipt',
        text: '''
WINSUPPLY
06/21/2026
3/4 IN BRASS BALL VALVE 12.49
1/2 IN COPPER COUPLING 8.97
PEX CRIMP RING 25PK 6.98
TOTAL 28.44
''',
        expectedMerchant: 'Winsupply',
        expectedDate: DateTime(2026, 6, 21),
        expectedTotal: 28.44,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'BALL VALVE',
            subtotal: 12.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'COPPER COUPLING',
            subtotal: 8.97,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'CRIMP RING',
            subtotal: 6.98,
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
            descriptionContains: 'HVAC TAPE',
            subtotal: 12.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'floor and decor tile receipt',
        text: '''
FLOOR & DECOR
06/21/2026
PORCELAIN TILE 39.99
THINSET MORTAR 18.99
SANDED GROUT 14.99
TOTAL 73.97
''',
        expectedMerchant: 'Floor & Decor',
        expectedDate: DateTime(2026, 6, 21),
        expectedTotal: 73.97,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'TILE',
            subtotal: 39.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'THINSET',
            subtotal: 18.99,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'GROUT',
            subtotal: 14.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'siteone landscape receipt',
        text: '''
SITEONE LANDSCAPE SUPPLY
06/21/2026
PVC IRRIGATION PIPE 14.50
SPRINKLER HEAD 8.49
LANDSCAPE FABRIC 19.99
TOTAL 42.98
''',
        expectedMerchant: 'SiteOne Landscape Supply',
        expectedDate: DateTime(2026, 6, 21),
        expectedTotal: 42.98,
        expectedLines: const [
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'PVC',
            subtotal: 14.50,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'SPRINKLER',
            subtotal: 8.49,
          ),
          ReceiptLineExpectation(
            category: 'Materials',
            descriptionContains: 'FABRIC',
            subtotal: 19.99,
          ),
        ],
      ),
      ReceiptParseFixture(
        name: 'beacon roofing receipt',
        text: '''
BEACON ROOFING
06/21/2026
ARCHITECTURAL SHINGLES BUNDLE 38.99
DRIP EDGE 10FT 8.49
UNDERLAYMENT ROLL 44.99
TOTAL 92.47
''',
        expectedMerchant: 'Beacon Building Products',
        expectedDate: DateTime(2026, 6, 21),
        expectedTotal: 92.47,
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
            descriptionContains: 'UNDERLAYMENT',
            subtotal: 44.99,
          ),
        ],
      ),
    ]);

    expect(report.fixtureCount, 6);
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
