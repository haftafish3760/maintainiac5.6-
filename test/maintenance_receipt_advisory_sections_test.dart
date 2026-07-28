import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('technician notes cannot inherit completed status', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 233
WORK COMPLETED
ENGINE OIL CHANGE 59.99
TECHNICIAN NOTES
FRONT BRAKE PADS WORN
PAID IN FULL 59.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(
      candidates['Engine Oil']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(candidates['Engine Oil']!.notCompletedIndicated, isFalse);
    expect(
      candidates['Brake Pads']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Brake Pads']!.notCompletedIndicated, isTrue);
  });

  test('advisory section cannot imply battery installation', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 234
SERVICE PERFORMED
TIRE ROTATION 29.99
ADVISORIES
AUTOMOTIVE BATTERY WEAK
PAID IN FULL 29.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(
      candidates['Tire Rotation']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(
      candidates['Battery']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Battery']!.notCompletedIndicated, isTrue);
  });

  test('completed heading resets an observations section', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 235
OBSERVATIONS
CABIN AIR FILTER DIRTY
WORK COMPLETED
TIRE ROTATION 29.99
PAID IN FULL 29.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
    expect(
      candidates['Cabin Air Filter']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Cabin Air Filter']!.notCompletedIndicated, isTrue);
    expect(
      candidates['Tire Rotation']!.action,
      MaintenanceReceiptAction.reviewCompletedService,
    );
    expect(candidates['Tire Rotation']!.notCompletedIndicated, isFalse);
  });
}
