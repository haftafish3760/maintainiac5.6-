import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('explicit returned item does not contaminate a separate purchase', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
AUTOZONE
07/23/2026
RETURNED FRONT BRAKE PADS -49.99
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
REFUND TO CARD 15.00
TOTAL -15.00
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(candidates.keys, {'Brake Pads', 'Engine Oil'});
    expect(
      candidates['Brake Pads']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Brake Pads']!.returnOrExchangeIndicated, isTrue);
    expect(candidates['Brake Pads']!.productPurchased, isFalse);
    expect(
      candidates['Engine Oil']!.action,
      MaintenanceReceiptAction.reviewTrackingSetup,
    );
    expect(candidates['Engine Oil']!.returnOrExchangeIndicated, isFalse);
    expect(candidates['Engine Oil']!.productPurchased, isTrue);
  });

  test('explicit exchanged filter does not contaminate purchased wipers', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
O'REILLY AUTO PARTS
07/23/2026
OIL FILTER PH8A EXCHANGED -12.99
WIPER BLADES 22 IN 19.99
REFUND TO CARD 12.99
TOTAL 7.00
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(candidates.keys, {'Oil Filter', 'Wiper Blades'});
    expect(
      candidates['Oil Filter']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Oil Filter']!.returnOrExchangeIndicated, isTrue);
    expect(
      candidates['Wiper Blades']!.action,
      MaintenanceReceiptAction.reviewTrackingSetup,
    );
    expect(candidates['Wiper Blades']!.returnOrExchangeIndicated, isFalse);
  });

  test('unscoped refund keeps an ambiguous maintenance item manual', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
NAPA AUTO PARTS
07/23/2026
FULL SYNTHETIC MOTOR OIL 5W-30 34.99
REFUND TO CARD 34.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.itemName, 'Engine Oil');
    expect(oil.action, MaintenanceReceiptAction.manualReview);
    expect(oil.returnOrExchangeIndicated, isTrue);
    expect(oil.productPurchased, isFalse);
  });
}
