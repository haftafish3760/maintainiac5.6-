import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  test('future receipt date is never prefilled as completed service', () {
    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        referenceDate: DateTime(2026, 7, 23),
        sourceText: '''
MAIN STREET AUTO
07/24/2026
SERVICE PERFORMED
ODOMETER 40000
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.receiptDate, isNull);
    expect(result.candidates.single.serviceDate, isNull);
    expect(
      result.warnings,
      contains(
        'A future receipt date was ignored; confirm or enter the service date manually.',
      ),
    );
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('future metadata date does not hide a later valid receipt date', () {
    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        referenceDate: DateTime(2026, 7, 23),
        sourceText: '''
SYSTEM DATE 08/01/2026
MAIN STREET AUTO
RECEIPT DATE 07/22/2026
SERVICE PERFORMED
ODOMETER 40000
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 22));
    expect(result.candidates.single.serviceDate, DateTime(2026, 7, 22));
    expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
  });

  test('dot-separated US receipt date supports a two-digit year', () {
    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        referenceDate: DateTime(2026, 7, 23),
        sourceText: '''
MAIN STREET AUTO
DATE: 07.08.26
SERVICE PERFORMED
ODOMETER 40000
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 8));
    expect(result.candidates.single.serviceDate, DateTime(2026, 7, 8));
    expect(
      result.warnings,
      contains(
        'Ambiguous numeric receipt date was interpreted using en-US; confirm the date.',
      ),
    );
  });

  test('dot-separated day-first date follows a supported locale', () {
    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'en-GB',
        referenceDate: DateTime(2026, 7, 23),
        sourceText: '''
MAIN STREET AUTO
DATE: 23.07.26
SERVICE PERFORMED
ODOMETER 40000
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.receiptDate, DateTime(2026, 7, 23));
    expect(result.candidates.single.serviceDate, DateTime(2026, 7, 23));
    expect(
      result.warnings,
      isNot(contains(contains('Ambiguous numeric receipt date'))),
    );
  });

  test('ambiguous dot-separated date is not guessed for unknown locale', () {
    final result = parseMaintenanceReceipt(
      MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        locale: 'fr-FR',
        referenceDate: DateTime(2026, 7, 23),
        sourceText: '''
MAIN STREET AUTO
DATE: 07.08.26
SERVICE PERFORMED
ODOMETER 40000
OIL CHANGE 49.99
''',
      ),
    );

    expect(result.receiptDate, isNull);
    expect(result.candidates.single.serviceDate, isNull);
    expect(
      result.warnings,
      contains(
        'The receipt date locale is unsupported; enter the service date manually.',
      ),
    );
  });
}
