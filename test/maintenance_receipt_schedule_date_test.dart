import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('next-due date cannot become the completed-service date', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
TAKE 5 OIL CHANGE
NEXT SERVICE DUE 01/23/2027
RECEIPT DATE 07/23/2026
WORK ORDER 100
ODOMETER 50000
OIL CHANGE 5W-30 79.99
PAID IN FULL 79.99
''',
      ),
    );

    final oil = result.candidates.single;
    expect(result.receiptDate, DateTime(2026, 7, 23));
    expect(oil.serviceDate, DateTime(2026, 7, 23));
    expect(oil.intervalMonths, 6);
    expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
  });

  test('named next-service date infers an exact whole-month interval', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
JULY 31, 2026
REPAIR ORDER 101
ODOMETER 60000
RADIATOR FLUSH 129.99
NEXT SERVICE DUE JANUARY 31, 2027
WORK COMPLETED
''',
      ),
    );

    final coolant = result.candidates.single;
    expect(coolant.itemName, 'Coolant');
    expect(coolant.intervalMonths, 6);
    expect(coolant.requiresUserConfirmation, isTrue);
  });

  test('next oil change date is treated as schedule, not service date', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
JIFFY LUBE
NEXT OIL CHANGE JANUARY 23, 2027
RECEIPT DATE JULY 23, 2026
WORK ORDER 101A
ODOMETER 60500
OIL CHANGE 49.99
PAID IN FULL 49.99
''',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 23));
    expect(result.candidates.single.intervalMonths, 6);
  });

  test('month-end clamping supports a real calendar-month interval', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
RECEIPT DATE 08/31/2026
REPAIR ORDER 102
ODOMETER 61000
BATTERY INSTALLATION 210.00
NEXT SERVICE DATE FEBRUARY 28, 2027
WORK COMPLETED
''',
      ),
    );

    expect(result.candidates.single.intervalMonths, 6);
  });

  test('reversed next-service date is review-only schedule evidence', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
RECEIPT DATE 07/23/2026
REPAIR ORDER 103
ODOMETER 62000
OIL CHANGE 49.99
NEXT SERVICE DUE 01/23/2026
WORK COMPLETED
''',
      ),
    );

    expect(result.candidates.single.intervalMonths, isNull);
    expect(
      result.warnings,
      contains('The next-service date is not after the receipt service date.'),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('unsupported ambiguous due-date locale is never guessed', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'fr-FR',
        sourceText: '''
MAIN STREET AUTO
JULY 23, 2026
REPAIR ORDER 104
ODOMETER 63000
OIL CHANGE 49.99
NEXT SERVICE DUE 01/02/2027
WORK COMPLETED
''',
      ),
    );

    expect(result.candidates.single.intervalMonths, isNull);
    expect(
      result.warnings,
      contains(
        'The next-service date locale is unsupported; enter the time interval manually.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('generic due date does not leak across a multi-service invoice', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
RECEIPT DATE 07/23/2026
REPAIR ORDER 105
ODOMETER 64000
OIL CHANGE 49.99
FRONT BRAKE PADS REPLACED 299.99
NEXT SERVICE DUE 01/23/2027
WORK COMPLETED
''',
      ),
    );

    final oil = result.candidates.singleWhere(
      (candidate) => candidate.itemName == 'Engine Oil',
    );
    final brakes = result.candidates.singleWhere(
      (candidate) => candidate.itemName == 'Brake Pads',
    );
    expect(oil.intervalMonths, 6);
    expect(brakes.intervalMonths, isNull);
  });

  test('item-specific due date applies to that non-oil service', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
RECEIPT DATE JULY 23, 2026
REPAIR ORDER 106
ODOMETER 65000
OIL CHANGE 49.99
TIRE ROTATION 29.99
TIRE ROTATION NEXT DUE JANUARY 23, 2027
WORK COMPLETED
''',
      ),
    );

    final rotation = result.candidates.singleWhere(
      (candidate) => candidate.itemName == 'Tire Rotation',
    );
    expect(rotation.intervalMonths, 6);
  });

  test('non-whole-month due date does not invent a month interval', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
RECEIPT DATE 07/23/2026
REPAIR ORDER 107
ODOMETER 66000
OIL CHANGE 49.99
NEXT SERVICE DUE 01/20/2027
WORK COMPLETED
''',
      ),
    );

    expect(result.candidates.single.intervalMonths, isNull);
    expect(
      result.warnings,
      contains(
        'The next-service date is not a whole-month interval; confirm the time interval.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });
}
