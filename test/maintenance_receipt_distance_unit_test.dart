import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

const _kilometerWarning =
    'Receipt distance evidence is in kilometers, but maintenance currently stores miles; enter converted values manually.';

void main() {
  test('kilometer service odometer is never prefilled as miles', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        currentOdometer: 100000,
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 160000 KM
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(oil.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
    expect(result.mayMutateMaintenance, isFalse);
  });

  test('kilometer next due cannot populate a mile field', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        currentOdometer: 100000,
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100000 MI
ENGINE OIL CHANGE 59.99
NEXT DUE 170000 KM
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.serviceOdometer, 100000);
    expect(oil.dueOdometer, isNull);
    expect(oil.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
  });

  test('kilometer interval cannot populate a mile interval', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100000 MI
TIRE ROTATION 29.99
EVERY 10000 KM
''',
      ),
    );

    final rotation = result.candidates.single;
    expect(rotation.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });
}
