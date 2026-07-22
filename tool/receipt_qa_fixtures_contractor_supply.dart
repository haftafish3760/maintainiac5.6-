part of 'receipt_qa_runner.dart';

const _contractorSupplyReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'contractor_supply',
    name: 'home center material quantities and packs',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectTax: true,
    expectLineItems: true,
    expectedDateIso: '2026-06-12',
    expectedSubtotal: 51.74,
    expectedTax: 3.10,
    expectedTotal: 54.84,
    expectedLineCount: 3,
    expectedLineSubtotals: [9.96, 6.98, 34.80],
    expectedLineDescriptionNeedles: ['stud', 'screws', 'romex'],
    expectedLineCategories: ['Materials', 'Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials', 'materials'],
    expectedLineUses: ['business', 'business', 'business'],
    expectedLineReviewModes: ['detailedLine', 'detailedLine', 'detailedLine'],
    expectedLineNumberLabels: ['Line 3', 'Line 4', 'Line 5'],
    expectedDownstreamReadinessStatus: 'inventory_material_ready',
    expectedDownstreamReadinessSummary: 'Inventory/material review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_inventory_material_ready': 1,
      'line_ready': 3,
      'inventory_material_ready': 3,
      'category_family_materials_ready': 3,
    },
    barcodeCodes: [
      ReceiptQaBarcodeCode(
        format: 'ean13',
        valueType: 'product',
        rawValue: '0 12345-67890 5',
      ),
      ReceiptQaBarcodeCode(
        format: 'code128',
        valueType: 'text',
        rawValue: '',
        displayValue: 'LOWES-SKU-14-2-NMB',
      ),
      ReceiptQaBarcodeCode(
        format: 'qrCode',
        valueType: 'wifi',
        rawValue: 'WIFI:T:WPA;S:PrivateNetwork;P:secret;;',
      ),
    ],
    barcodeWarnings: ['receipt_scanner_inventory_suggestion_only'],
    expectedBarcodeCodeCount: 3,
    expectedQrCodeCount: 1,
    expectedInventoryLookupCandidateCount: 2,
    expectedBarcodeFormatBuckets: {'ean13': 1, 'code128': 1, 'qr': 1},
    expectedBarcodeWarningBuckets: [
      'receipt_scanner_inventory_suggestion_only',
    ],
    text: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
2 @ 4.98 2X4X8 KD STUD 9.96
25PK #8 X 1-1/4 WOOD SCREWS 6.98
12 FT ROMEX 12/2 W/G 34.80
SUBTOTAL 51.74
SALES TAX 3.10
TOTAL 54.84
''',
  ),
  _ReceiptQaFixture(
    pack: 'contractor_supply',
    name: 'split OCR material description rows rejoin cleanly',
    merchantNeedle: 'city electric',
    expectedMerchantName: 'City Electric Supply',
    expectLineItems: true,
    expectedDateIso: '2026-06-13',
    expectedTotal: 65.47,
    expectedLineCount: 3,
    expectedLineSubtotals: [36.98, 18.49, 9.99],
    expectedLineDescriptionNeedles: [
      'gfci receptacle',
      'emt conduit',
      'junction box',
    ],
    expectedLineCategories: ['Materials', 'Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials', 'materials'],
    expectedLineUses: ['business', 'business', 'business'],
    expectedLineReviewModes: ['detailedLine', 'detailedLine', 'detailedLine'],
    expectedLineNumberLabels: ['Line 4', 'Line 6', 'Line 8'],
    expectedDownstreamReadinessStatus: 'inventory_material_ready',
    expectedDownstreamReadinessSummary: 'Inventory/material review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_inventory_material_ready': 1,
      'line_ready': 3,
      'inventory_material_ready': 3,
      'category_family_materials_ready': 3,
    },
    text: '''
CITY ELECTRIC SUPPLY
06/13/2026
20A GFCI RECEPTACLE
2 EA @ 18.49 36.98
1/2 EMT CONDUIT 10 FT
EXTENDED 18.49
4IN JUNCTION BOX
ITEM PRICE 9.99
TOTAL 65.47
''',
  ),
];
