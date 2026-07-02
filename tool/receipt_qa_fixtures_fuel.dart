part of 'receipt_qa_runner.dart';

const _fuelReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'fuel',
    name: 'diesel station baseline',
    merchantNeedle: 'quick fuel',
    expectedMerchantName: 'Quick Fuel',
    expectFuel: true,
    expectTax: true,
    expectedDateIso: '2026-06-11',
    expectedSubtotal: 48.75,
    expectedTax: 2.93,
    expectedTotal: 51.68,
    expectedLineDescriptionNeedles: ['diesel'],
    expectedLineCategories: ['Fuel'],
    expectedLineFamilies: ['fuel'],
    expectedLineUses: ['business'],
    expectedFuelQuantity: 12.5,
    expectedFuelUnitPrice: 3.9,
    expectedFuelType: 'Diesel',
    expectedFuelUnit: 'gallon',
    expectedBusinessTotal: 51.68,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Fuel receipt review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 1,
      'priced_line_ready': 1,
      'category_family_fuel_ready': 1,
    },
    text: '''
Quick Fuel
06/11/2026 08:14 AM
Pump 03 Diesel 12.500 GAL 48.75
Subtotal 48.75
Sales Tax 2.93
Total 51.68
''',
  ),
  _ReceiptQaFixture(
    pack: 'fuel',
    name: 'split row fuel with tender rows',
    merchantNeedle: 'pilot',
    expectedMerchantName: 'Pilot Flying J',
    expectFuel: true,
    allowTenderAmountRows: true,
    expectedLineCount: 2,
    expectedLineSubtotals: [68.15, -1.20],
    expectedLineDescriptionNeedles: ['fuel', 'rewards'],
    expectedLineCategories: ['Fuel', 'Receipt Adjustment'],
    expectedLineFamilies: ['fuel', 'receipt_adjustment'],
    expectedLineUses: ['business', 'business'],
    expectedNegativeLineCount: 1,
    expectedAdjustmentLineCount: 1,
    expectReconciled: true,
    expectedFuelQuantity: 18.425,
    expectedFuelUnitPrice: 3.699,
    expectedFuelType: 'Diesel',
    expectedFuelUnit: 'gallon',
    expectedFuelOdometer: 184220,
    expectedBusinessTotal: 66.95,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Fuel receipt review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 2,
      'priced_line_ready': 2,
      'category_family_fuel_ready': 1,
      'category_family_adjustment_ready': 1,
    },
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
  ),
  _ReceiptQaFixture(
    pack: 'noisy',
    name: 'swapped total and date characters',
    merchantNeedle: 'sheetz',
    expectedMerchantName: 'Sheetz',
    expectFuel: true,
    expectedLineDescriptionNeedles: ['unleaded'],
    expectedLineCategories: ['Fuel'],
    expectedLineFamilies: ['fuel'],
    expectedLineUses: ['business'],
    expectedFuelQuantity: 14.25,
    expectedFuelType: 'Gasoline',
    expectedFuelUnit: 'gallon',
    expectedBusinessTotal: 47.01,
    expectedPersonalTotal: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Fuel receipt review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 1,
      'category_family_fuel_ready': 1,
    },
    text: '''
SHEETZ
O6/19/2O26 O7:15 AM
PUMP O4 UNLEADED 14.25O GAL 47.O1
T0TAL 47.O1
''',
  ),
  _ReceiptQaFixture(
    pack: 'noisy',
    name: 'noisy fuel subtotal tax and total',
    merchantNeedle: 'shell',
    expectedMerchantName: 'Shell',
    expectFuel: true,
    expectTax: true,
    expectedLineDescriptionNeedles: ['diesel'],
    expectedLineCategories: ['Fuel'],
    expectedLineFamilies: ['fuel'],
    expectedLineUses: ['business'],
    expectedFuelQuantity: 10,
    expectedFuelUnitPrice: 3.5,
    expectedFuelType: 'Diesel',
    expectedFuelUnit: 'gallon',
    expectedBusinessTotal: 37.10,
    expectedPersonalTotal: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Fuel receipt review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 1,
      'category_family_fuel_ready': 1,
    },
    text: '''
SHELL
O7/O1/2O26 O6:45 AM
PUMP O2 DIESEL 1O.OOO GAL 35.OO
SUBT0TAL 35.OO
T4X 2.1O
T0TAL 37.1O
''',
  ),
  _ReceiptQaFixture(
    pack: 'noisy',
    name: 'home center material OCR letter number swaps',
    merchantNeedle: 'home depot',
    expectedMerchantName: 'The Home Depot',
    expectLineItems: true,
    expectedDateIso: '2026-06-19',
    expectedTotal: 15.47,
    expectedLineCount: 2,
    expectedLineSubtotals: [7.48, 7.99],
    expectedLineDescriptionNeedles: ['copper', 'pvc glue'],
    expectedLineCategories: ['Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials'],
    expectedLineUses: ['business', 'business'],
    expectedBusinessTotal: 15.47,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'inventory_material_ready',
    expectedDownstreamReadinessSummary: 'Inventory/material review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_inventory_material_ready': 1,
      'line_ready': 2,
      'priced_line_ready': 2,
      'inventory_material_ready': 2,
      'category_family_materials_ready': 2,
    },
    text: '''
H0ME DEP0T
O6/19/2O26
1/2  IN   C0PPER  9O  ELB0W   7.48
PVC  GLUE  7,99
T0TAL 15.47
''',
  ),
  _ReceiptQaFixture(
    pack: 'noisy',
    name: 'home center truncated material rows',
    merchantNeedle: 'home depot',
    expectedMerchantName: 'The Home Depot',
    expectLineItems: true,
    expectedDateIso: '2026-06-19',
    expectedTotal: 46.07,
    expectedLineCount: 3,
    expectedLineSubtotals: [4.29, 6.98, 34.80],
    expectedLineDescriptionNeedles: ['stud', 'scrw', 'cable'],
    expectedLineCategories: ['Materials', 'Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials', 'materials'],
    expectedLineUses: ['business', 'business', 'business'],
    expectedBusinessTotal: 46.07,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'inventory_material_ready',
    expectedDownstreamReadinessSummary: 'Inventory/material review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_inventory_material_ready': 1,
      'line_ready': 3,
      'priced_line_ready': 3,
      'inventory_material_ready': 3,
      'category_family_materials_ready': 3,
    },
    text: '''
H0ME DEP0T
06-19-26
2X4X8 KD STUD      4.29
25PK #8 X 1-1/4 WD SCRW 6.98
12/2 NM-B CABLE    34.80
AM0UNT PAID 46.O7
''',
  ),
];
