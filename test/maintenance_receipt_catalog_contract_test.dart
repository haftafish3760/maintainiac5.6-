import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';
import 'package:maintaniac/screens/maintenance/maintenance_models.dart';

void main() {
  test('every manual maintenance item has receipt parser coverage', () {
    final catalogNames = maintenanceCatalog.map((item) => item.name).toSet();

    expect(maintenanceReceiptSupportedItemNames, unorderedEquals(catalogNames));
  });

  test('receipt candidates use canonical manual-maintenance catalog names', () {
    final result = parseMaintenanceReceipt(
      const MaintenanceReceiptParserInput(
        activeVehicleId: 'vehicle_1',
        sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK ORDER 900
ODOMETER 100000
ENGINE OIL CHANGE 5W-30
OIL FILTER REPLACED
TRANSMISSION FLUSH
COOLANT FLUSH
BRAKE FLUID FLUSH
FRONT BRAKE PADS REPLACED
FRONT BRAKE ROTORS REPLACED
ENGINE AIR FILTER REPLACED
CABIN AIR FILTER REPLACED
SPARK PLUGS REPLACED
SERPENTINE BELT REPLACED
RADIATOR HOSE REPLACED
WIPER BLADES REPLACED
BATTERY REPLACEMENT
POWER STEERING FLUID FLUSH
DIFFERENTIAL FLUID SERVICE
FUEL FILTER REPLACED
NEW TIRES INSTALLED
WASHER FLUID REFILL
TIRE ROTATION
KEY FOB BATTERY REPLACED
VEHICLE REGISTRATION RENEWED
STATE INSPECTION PASSED
PAID IN FULL
''',
      ),
    );
    final catalogNames = maintenanceCatalog.map((item) => item.name).toSet();

    expect(result.candidates, isNotEmpty);
    for (final candidate in result.candidates) {
      expect(
        catalogNames,
        contains(candidate.itemName),
        reason: '${candidate.itemName} must be available to manual setup',
      );
    }
  });

  test('manual catalog has separate brake and tire service records', () {
    final names = maintenanceCatalog.map((item) => item.name);
    expect(names, containsAll(['Brake Pads', 'Brake Rotors']));
    expect(names, containsAll(['Tires', 'Tire Rotation']));
  });

  test(
    'time-based maintenance receipts remain explicit service candidates',
    () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_1',
          sourceText: '''
COUNTY SERVICE CENTER
07/23/2026
VEHICLE REGISTRATION RENEWED 48.00
STATE INSPECTION PASSED 20.00
KEY FOB BATTERY REPLACED 8.00
PAID IN FULL 76.00
''',
        ),
      );

      expect(
        {
          for (final candidate in result.candidates)
            candidate.itemName: candidate.action,
        },
        {
          'Registration': MaintenanceReceiptAction.reviewCompletedService,
          'Inspection': MaintenanceReceiptAction.reviewCompletedService,
          'Key Fob Battery': MaintenanceReceiptAction.reviewCompletedService,
        },
      );
    },
  );
}
