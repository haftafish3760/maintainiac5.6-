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

  test('manual catalog separates adjacent maintenance families', () {
    final names = maintenanceCatalog.map((item) => item.name);
    expect(
      names,
      containsAll([
        'Brake Pads',
        'Brake Rotors',
        'Brake Shoes',
        'Brake Drums',
        'Brake Calipers',
        'Brake Hoses and Lines',
      ]),
    );
    expect(names, contains('Brake Inspection'));
    expect(names, containsAll(['Tires', 'Tire Rotation']));
    expect(names, containsAll(['Wheel Alignment', 'Wheel Balancing']));
    expect(names, contains('Steering and Suspension Inspection'));
    expect(
      names,
      containsAll(['Shocks and Struts', 'Ball Joints', 'Tie Rod Ends']),
    );
    expect(names, containsAll(['Sway Bar Links', 'Wheel Bearings']));
    expect(names, containsAll(['CV Axles', 'Engine Mounts']));
    expect(names, containsAll(['Serpentine Belt', 'Timing Belt']));
    expect(names, containsAll(['Belt Tensioner', 'Idler Pulley']));
    expect(names, containsAll(['Water Pump', 'Thermostat']));
    expect(names, containsAll(['Radiator', 'Radiator Cap']));
    expect(
      names,
      containsAll([
        'Transmission Fluid and Filter',
        'Differential Fluid',
        'Transfer Case Fluid',
      ]),
    );
    expect(names, contains('PCV Valve'));
    expect(names, contains('Oxygen Sensors'));
    expect(names, contains('Catalytic Converter'));
    expect(names, containsAll(['EGR Valve', 'Mass Air Flow Sensor']));
    expect(names, containsAll(['Valve Cover Gasket', 'Oil Pan Gasket']));
    expect(names, contains('Fuel Pump'));
    expect(names, containsAll(['Ignition Coils', 'Spark Plug Wires']));
    expect(names, containsAll(['Alternator', 'Starter']));
    expect(
      names,
      containsAll(['Fuel System Service', 'Air Conditioning Service']),
    );
    for (final name in [
      'Brake Pads',
      'Brake Rotors',
      'Brake Shoes',
      'Brake Drums',
      'Brake Calipers',
      'Brake Hoses and Lines',
    ]) {
      final item = maintenanceCatalog.singleWhere((item) => item.name == name);
      expect(
        item.detailAOptions,
        containsAll(['Front', 'Rear', 'Front and rear']),
        reason: '$name axle options',
      );
    }
    final alignment = maintenanceCatalog.singleWhere(
      (item) => item.name == 'Wheel Alignment',
    );
    final balancing = maintenanceCatalog.singleWhere(
      (item) => item.name == 'Wheel Balancing',
    );
    expect(alignment.detailAOptions, containsAll(['Four-wheel', 'Front-end']));
    expect(
      balancing.detailAOptions,
      containsAll(['Road force', 'Computerized', 'Standard']),
    );
  });

  test('new periodic families are representable in Basic manual setup', () {
    for (final name in ['Timing Belt', 'Transfer Case Fluid', 'PCV Valve']) {
      final item = maintenanceCatalog.singleWhere(
        (candidate) => candidate.name == name,
      );
      expect(item.timeOnly, isFalse, reason: name);
      expect(item.defaultMiles, greaterThan(0), reason: '$name miles');
      expect(item.defaultMonths, greaterThan(0), reason: '$name months');
      expect(
        item.mileageIntervalOptions,
        contains(item.defaultMiles),
        reason: '$name mileage options',
      );
      expect(
        item.monthIntervalOptions,
        contains(item.defaultMonths),
        reason: '$name month options',
      );
    }
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
