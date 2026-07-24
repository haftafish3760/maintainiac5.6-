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

  test('completed section proves terse no-charge warranty work', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK COMPLETED
AUTOMOTIVE BATTERY WARRANTY 0.00
NO CHARGE 0.00
''',
      ),
    );

    expect(result.kind, MaintenanceReceiptKind.serviceInvoice);
    final battery = result.candidates.single;
    expect(battery.itemName, 'Battery');
    expect(battery.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(battery.completedServiceIndicated, isTrue);
    expect(battery.productPurchased, isFalse);
  });

  test('completed section proves terse comeback work', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 222
COMEBACK - NO CHARGE
WORK COMPLETED
FRONT BRAKE PADS 0.00
PAID IN FULL 0.00
''',
      ),
    );

    final brakes = result.candidates.single;
    expect(brakes.itemName, 'Brake Pads');
    expect(brakes.action, MaintenanceReceiptAction.reviewCompletedService);
    expect(brakes.completedServiceIndicated, isTrue);
    expect(brakes.notCompletedIndicated, isFalse);
  });

  test('customer request section cannot inherit completed status', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 223
WORK COMPLETED
ENGINE OIL CHANGE 59.99
CUSTOMER REQUESTED SERVICES
CABIN AIR FILTER 49.99
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
    expect(
      candidates['Cabin Air Filter']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Cabin Air Filter']!.notCompletedIndicated, isTrue);
  });

  test('completed heading resets a customer concern section', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 224
CUSTOMER CONCERNS
FRONT BRAKE PADS 249.99
SERVICE PERFORMED
TIRE ROTATION 29.99
PAID IN FULL 29.99
''',
      ),
    );

    final candidates = {
      for (final candidate in result.candidates) candidate.itemName: candidate,
    };
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

  test('authorized repairs cannot inherit completed status', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 225
WORK COMPLETED
ENGINE OIL CHANGE 59.99
AUTHORIZED REPAIRS
FRONT BRAKE PADS 249.99
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
    expect(
      candidates['Brake Pads']!.action,
      MaintenanceReceiptAction.manualReview,
    );
    expect(candidates['Brake Pads']!.notCompletedIndicated, isTrue);
  });

  test('completed heading resets an inspection findings section', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
REPAIR ORDER 226
INSPECTION FINDINGS
CABIN AIR FILTER DIRTY
SERVICE PERFORMED
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
