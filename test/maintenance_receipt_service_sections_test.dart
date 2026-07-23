import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('performed heading resets an earlier recommendation section', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 220
RECOMMENDED SERVICES
CABIN AIR FILTER 49.99
SERVICE PERFORMED
ENGINE OIL CHANGE 59.99
PAID IN FULL 59.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(candidates.keys, {'Cabin Air Filter', 'Engine Oil'});
    expect(
      candidates['Cabin Air Filter']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Cabin Air Filter']!.notCompletedIndicated, isTrue);
    expect(
      candidates['Engine Oil']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(candidates['Engine Oil']!.notCompletedIndicated, isFalse);
  });

  test('completed heading resets an earlier declined section', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 221
SERVICE PERFORMED
ENGINE OIL CHANGE 59.99
DECLINED SERVICES
FRONT BRAKE PADS 249.99
WORK COMPLETED
TIRE ROTATION 29.99
PAID IN FULL 89.98
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(candidates.keys, {'Engine Oil', 'Brake Pads', 'Tire Rotation'});
    expect(
      candidates['Engine Oil']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(
      candidates['Brake Pads']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Brake Pads']!.notCompletedIndicated, isTrue);
    expect(
      candidates['Tire Rotation']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(candidates['Tire Rotation']!.notCompletedIndicated, isFalse);
  });
}
