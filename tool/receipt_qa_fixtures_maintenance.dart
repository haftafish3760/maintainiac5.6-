part of 'receipt_qa_runner.dart';

const _maintenanceReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'maintenance',
    name: 'oil change interval baseline',
    merchantNeedle: 'quick lube',
    expectedMerchantName: 'Quick Lube',
    expectTax: true,
    expectLineItems: true,
    expectMaintenance: true,
    expectedLineCount: 3,
    expectedLineSubtotals: [39.99, 8.49, 19.99],
    expectedLineDescriptionNeedles: [
      'synthetic oil',
      'oil filter',
      'tire rotation',
    ],
    expectedLineCategories: ['Maintenance', 'Maintenance', 'Maintenance'],
    expectedLineFamilies: [
      'vehicle_supplies',
      'vehicle_supplies',
      'vehicle_supplies',
    ],
    expectedLineUses: ['business', 'business', 'business'],
    expectedMaintenanceServiceType: 'Oil Change',
    expectedMaintenanceOilWeight: '5W-20',
    expectedMaintenanceDueOdometer: 92500,
    expectedBusinessTotal: 72.58,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Vehicle cost review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 3,
      'vehicle_cost_ready': 3,
      'category_family_vehicle_ready': 3,
    },
    text: '''
QUICK LUBE
2026-06-30
5W-20 SYNTHETIC OIL 39.99
OIL FILTER 8.49
TIRE ROTATION 19.99
SALES TAX 4.11
TOTAL 72.58
NEXT SERVICE 92,500 MILES
''',
  ),
  _ReceiptQaFixture(
    pack: 'maintenance',
    name: 'oil change odometer due interval',
    merchantNeedle: 'take 5',
    expectedMerchantName: 'Take 5 Oil Change',
    expectTax: true,
    expectLineItems: true,
    expectMaintenance: true,
    expectedDateIso: '2026-06-12',
    expectedSubtotal: 92.98,
    expectedTax: 5.58,
    expectedTotal: 98.56,
    expectedLineCount: 2,
    expectedLineSubtotals: [79.99, 12.99],
    expectedLineDescriptionNeedles: ['oil change', 'oil filter'],
    expectedLineCategories: ['Maintenance', 'Maintenance'],
    expectedLineFamilies: ['vehicle_supplies', 'vehicle_supplies'],
    expectedLineUses: ['business', 'business'],
    expectedMaintenanceServiceType: 'Oil Change',
    expectedMaintenanceOilWeight: '5W-30',
    expectedMaintenanceServiceOdometer: 100000,
    expectedMaintenanceDueOdometer: 105000,
    expectedMaintenanceIntervalMiles: 5000,
    expectedMaintenanceIntervalMonths: 6,
    expectedBusinessTotal: 98.56,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'vehicle_cost_ready',
    expectedDownstreamReadinessSummary: 'Vehicle cost review ready',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_vehicle_cost_ready': 1,
      'line_ready': 2,
      'vehicle_cost_ready': 2,
      'category_family_vehicle_ready': 2,
    },
    text: '''
TAKE 5 OIL CHANGE
06/12/2026 08:30 AM
Odometer: 100000
Full Synthetic Oil Change 5W-30 79.99
Oil Filter 12.99
Next Service Due 105000
Every 6 months
Subtotal 92.98
Tax 5.58
Total 98.56
''',
  ),
];
