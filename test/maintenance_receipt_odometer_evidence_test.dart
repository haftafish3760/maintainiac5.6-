import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('reversed mileage out and in readings require review', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        currentOdometer: 110000,
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
MILEAGE IN 100,010
MILEAGE OUT 100,000
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.serviceOdometer, 100000);
    expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(
      result.warnings,
      contains(
        'The receipt mileage out is below mileage in; confirm the service odometer.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
    expect(result.mayMutateMaintenance, isFalse);
  });

  test('historical mileage cannot outrank current mileage in', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        currentOdometer: 110000,
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 500
PRIOR MILEAGE 90,000
MILEAGE IN 100,000
SERVICE PERFORMED
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.serviceOdometer, 100000);
    expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(
      result.warnings,
      isNot(contains(contains('above the selected vehicle'))),
    );
  });
}
