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

  test('kilometer odometer out cannot populate a mile field', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER IN 159990 KM
ODOMETER OUT 160000 KM
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('abbreviated kilometer odometer in requires manual conversion', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODO IN: 160000 KILOMETRES
TIRE ROTATION 29.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('plural KMS service odometer cannot populate a mile field', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER OUT 160000 KMS
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('plural KMS due odometer cannot populate a mile field', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100000 MI
ENGINE OIL CHANGE 59.99
NEXT DUE 170000 KMS
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.serviceOdometer, 100000);
    expect(oil.dueOdometer, isNull);
    expect(oil.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
  });

  test('plural KMS interval cannot populate a mile interval', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100000 MI
TIRE ROTATION 29.99
EVERY 10000 KMS
''',
      ),
    );

    expect(result.candidates.single.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('comma-formatted kilometer odometer cannot populate miles', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER OUT 160,000 KM
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('comma-formatted kilometer due value cannot populate miles', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100,000 MI
ENGINE OIL CHANGE 59.99
NEXT DUE 170,000 KM
''',
      ),
    );

    final oil = result.candidates.single;
    expect(oil.serviceOdometer, 100000);
    expect(oil.dueOdometer, isNull);
    expect(oil.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
  });

  test('comma-formatted kilometer interval cannot populate miles', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100,000 MI
TIRE ROTATION 29.99
EVERY 10,000 KM
''',
      ),
    );

    expect(result.candidates.single.intervalMiles, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('space-grouped kilometer odometer cannot populate miles', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER OUT 160 000 KM
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, isNull);
    expect(result.warnings, contains(_kilometerWarning));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('space-grouped mile odometer remains an editable suggestion', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER OUT 100 000 MI
ENGINE OIL CHANGE 59.99
''',
      ),
    );

    expect(result.candidates.single.serviceOdometer, 100000);
    expect(result.warnings, isNot(contains(_kilometerWarning)));
    expect(result.mayMutateMaintenance, isFalse);
  });

  test('space-grouped kilometer due and interval remain unset', () {
    final dueResult = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100 000 MI
ENGINE OIL CHANGE 59.99
NEXT DUE 170 000 KM
''',
      ),
    );
    final intervalResult = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
ODOMETER 100 000 MI
TIRE ROTATION 29.99
EVERY 10 000 KM
''',
      ),
    );

    expect(dueResult.candidates.single.dueOdometer, isNull);
    expect(dueResult.candidates.single.intervalMiles, isNull);
    expect(dueResult.warnings, contains(_kilometerWarning));
    expect(intervalResult.candidates.single.intervalMiles, isNull);
    expect(intervalResult.warnings, contains(_kilometerWarning));
  });
}
