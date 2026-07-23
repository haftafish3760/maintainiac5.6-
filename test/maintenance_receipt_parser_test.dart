import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/maintenance/data/maintenance_receipt_parser.dart';

void main() {
  group('maintenance receipt parser purchase safety', () {
    test('Advance purchase suggests setup but never completed service', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_work_truck_1',
          activeVehicleName: 'Work Truck 1',
          currentOdometer: 101000,
          sourceText: '''
ADVANCE AUTO PARTS
Store 04218
6/12/26 7:03 PM
OIL FILTER PH8A 12.99
5QT FULL SYNTHETIC MOTOR OIL 5W-30 34.99
SUB-TOTAL 47.98
TAX 3.36
AMOUNT PAID 51.34
''',
        ),
      );

      expect(result.kind, MaintenanceReceiptKind.partsPurchase);
      expect(result.merchantName, 'Advance Auto Parts');
      expect(result.receiptDate, DateTime(2026, 6, 12));
      expect(
        result.candidates.map((item) => item.itemName),
        containsAll(['Engine Oil', 'Oil Filter']),
      );
      final oil = result.candidates.firstWhere(
        (item) => item.itemName == 'Engine Oil',
      );
      expect(oil.action, MaintenanceReceiptAction.reviewTrackingSetup);
      expect(oil.detailA, 'Full Synthetic');
      expect(oil.detailB, '5W-30');
      expect(oil.productPurchased, isTrue);
      expect(oil.completedServiceIndicated, isFalse);
      expect(oil.serviceOdometer, isNull);
      expect(oil.requiresUserConfirmation, isTrue);
      expect(
        result.candidates
            .singleWhere((item) => item.itemName == 'Oil Filter')
            .detailB,
        'PH8A',
      );
      expect(result.mayMutateMaintenance, isFalse);
      expect(
        result.warnings,
        contains(
          'A parts purchase does not prove that any part or fluid was installed.',
        ),
      );
    });

    test(
      'O Reilly receipt recognizes brake parts without installation claim',
      () {
        final result = parseMaintenanceReceipt(
          const MaintenanceReceiptParserInput(
            activeVehicleId: 'vehicle_2',
            sourceText: '''
O'REILLY AUTO PARTS
07/20/2026
FRONT DISC BRAKE PADS 49.99
2 BRAKE ROTORS 119.98
TOTAL 169.97
CASHIER 104
''',
          ),
        );

        final brakes = result.candidates.singleWhere(
          (item) => item.itemName == 'Brake Pads',
        );
        expect(brakes.action, MaintenanceReceiptAction.reviewTrackingSetup);
        expect(brakes.detailA, 'Front');
        expect(brakes.completedServiceIndicated, isFalse);
        final rotors = result.candidates.singleWhere(
          (item) => item.itemName == 'Brake Rotors',
        );
        expect(rotors.action, MaintenanceReceiptAction.reviewTrackingSetup);
        expect(rotors.completedServiceIndicated, isFalse);
      },
    );

    test('NAPA receipt recognizes battery group size', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_3',
          sourceText: '''
NAPA AUTO PARTS
2026-07-22
AUTOMOTIVE BATTERY GROUP 65 189.99
CORE CHARGE 22.00
RETAIL SALE
TOTAL 211.99
''',
        ),
      );

      final battery = result.candidates.singleWhere(
        (item) => item.itemName == 'Battery',
      );
      expect(battery.detailB, '65');
      expect(battery.action, MaintenanceReceiptAction.reviewTrackingSetup);
    });

    test(
      'AutoZone gear-oil basket does not create an engine-oil false positive',
      () {
        final result = parseMaintenanceReceipt(
          const MaintenanceReceiptParserInput(
            activeVehicleId: 'vehicle_4',
            sourceText: '''
AUTOZONE
07/23/2026
75W-90 FULL SYNTHETIC GEAR OIL 18.99
POWER STEERING FLUID 9.99
FUEL FILTER FF7333 24.99
UPPER RADIATOR HOSE 31.99
TOTAL 85.96
''',
          ),
        );

        expect(result.merchantName, 'AutoZone');
        expect(
          result.candidates.map((candidate) => candidate.itemName),
          containsAll([
            'Differential Fluid',
            'Power Steering Fluid',
            'Fuel Filter',
            'Radiator Hose',
          ]),
        );
        expect(
          result.candidates.map((candidate) => candidate.itemName),
          isNot(contains('Engine Oil')),
        );
        expect(
          result.candidates
              .singleWhere((candidate) => candidate.itemName == 'Fuel Filter')
              .detailB,
          'FF7333',
        );
        expect(
          result.candidates,
          everyElement(
            isA<MaintenanceReceiptCandidate>()
                .having(
                  (candidate) => candidate.action,
                  'action',
                  MaintenanceReceiptAction.reviewTrackingSetup,
                )
                .having(
                  (candidate) => candidate.completedServiceIndicated,
                  'completed',
                  isFalse,
                ),
          ),
        );
      },
    );

    test('Carquest basket recognizes tires, wipers, and washer fluid', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_5',
          sourceText: '''
CARQUEST AUTO PARTS
07/23/2026
2 MICHELIN ALL-SEASON TIRES 235/65R17 298.00
WIPER BLADES 24 IN 19.99
WINDSHIELD WASHER FLUID 1 GAL 5.49
TOTAL 323.48
''',
        ),
      );

      expect(result.merchantName, 'Carquest Auto Parts');
      expect(
        result.candidates.map((candidate) => candidate.itemName),
        containsAll(['Tires', 'Wiper Blades', 'Washer Fluid']),
      );
      expect(
        result.candidates,
        everyElement(
          isA<MaintenanceReceiptCandidate>().having(
            (candidate) => candidate.action,
            'action',
            MaintenanceReceiptAction.reviewTrackingSetup,
          ),
        ),
      );
      expect(
        result.candidates
            .singleWhere((candidate) => candidate.itemName == 'Tires')
            .detailA,
        'Michelin / All-Season',
      );
      expect(
        result.candidates
            .singleWhere((candidate) => candidate.itemName == 'Tires')
            .detailB,
        '235/65R17',
      );
      expect(
        result.candidates
            .singleWhere((candidate) => candidate.itemName == 'Wiper Blades')
            .detailB,
        '24 in',
      );
    });

    test('split AutoZone battery lines remain purchase-only evidence', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_6',
          sourceText: '''
AUTOZONE
07/23/2026
DURALAST GOLD 24F BATTERY
SKU 124R-DLG
189.99
CORE CHARGE
22.00
TOTAL 211.99
DEBIT TENDER 211.99
''',
        ),
      );

      final battery = result.candidates.singleWhere(
        (candidate) => candidate.itemName == 'Battery',
      );
      expect(battery.detailB, '24F');
      expect(battery.productPurchased, isTrue);
      expect(battery.completedServiceIndicated, isFalse);
      expect(battery.action, MaintenanceReceiptAction.reviewTrackingSetup);
    });
  });

  group('maintenance receipt parser service evidence', () {
    test('oil service invoice extracts reviewed history fields', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_work_truck_1',
          activeVehicleName: 'Work Truck 1',
          currentOdometer: 101250,
          sourceText: '''
TAKE 5 OIL CHANGE
06/12/2026 08:30 AM
Repair Order 7742
Vehicle Mileage: 100000
Full Synthetic Oil Change 5W-30 79.99
Oil Filter Replacement 12.99
Next Service Due 105000
Every 6 months
Total 98.56
''',
        ),
      );

      expect(result.kind, MaintenanceReceiptKind.serviceInvoice);
      final oil = result.candidates.firstWhere(
        (item) => item.itemName == 'Engine Oil',
      );
      expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
      expect(oil.completedServiceIndicated, isTrue);
      expect(oil.serviceDate, DateTime(2026, 6, 12));
      expect(oil.serviceOdometer, 100000);
      expect(oil.dueOdometer, 105000);
      expect(oil.intervalMiles, 5000);
      expect(oil.intervalMonths, 6);
      expect(oil.detailA, 'Full Synthetic');
      expect(oil.detailB, '5W-30');
      expect(oil.requiresUserConfirmation, isTrue);
    });

    test('flags odometer disagreement instead of changing global truth', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_work_truck_1',
          currentOdometer: 90000,
          sourceText: '''
Jiffy Lube
07/22/2026
Repair Order 101
Odometer: 100000
Oil Change 5W-20 49.99
Next Due 105000
''',
        ),
      );

      expect(result.reviewStatus, MaintenanceReceiptReviewStatus.needsDetails);
      expect(
        result.warnings,
        contains(
          'The receipt odometer is above the selected vehicle current odometer.',
        ),
      );
      expect(result.mayMutateMaintenance, isFalse);
    });

    test('service invoice handles multiple maintenance families', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_4',
          sourceText: '''
MAIN STREET AUTO SERVICE
2026-07-21
WORK ORDER 441
ODOMETER 88740
TRANSMISSION FLUSH SERVICE MERCON LV 189.00
COOLANT FLUSH DEX-COOL 129.00
FRONT BRAKE PADS REPLACED 249.00
TIRE ROTATION 29.00
TOTAL 596.00
''',
        ),
      );

      expect(
        result.candidates.map((item) => item.itemName),
        containsAll([
          'Transmission Fluid and Filter',
          'Coolant',
          'Brake Pads',
          'Tire Rotation',
        ]),
      );
      expect(
        result.candidates,
        everyElement(
          isA<MaintenanceReceiptCandidate>().having(
            (item) => item.action,
            'action',
            MaintenanceReceiptAction.reviewCompletedService,
          ),
        ),
      );
    });

    test('service invoice covers additional maintenance catalog families', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_7',
          sourceText: '''
DEALER SERVICE CENTER
07/23/2026
WORK ORDER 7781
ODOMETER 74400
DIFFERENTIAL FLUID SERVICE 75W-90 149.00
POWER STEERING FLUID FLUSH 99.00
FUEL FILTER REPLACED 89.00
UPPER RADIATOR HOSE REPLACEMENT 179.00
4 NEW TIRES INSTALLED 760.00
WINDSHIELD WASHER FLUID REFILL 4.00
WORK COMPLETED - PAID IN FULL
''',
        ),
      );

      expect(
        result.candidates.map((candidate) => candidate.itemName),
        containsAll([
          'Differential Fluid',
          'Power Steering Fluid',
          'Fuel Filter',
          'Radiator Hose',
          'Tires',
          'Washer Fluid',
        ]),
      );
      expect(
        result.candidates,
        everyElement(
          isA<MaintenanceReceiptCandidate>().having(
            (candidate) => candidate.action,
            'action',
            MaintenanceReceiptAction.reviewCompletedService,
          ),
        ),
      );
    });

    test('mixed invoice never completes an item that is estimate-only', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_8',
          sourceText: '''
MAIN STREET AUTO SERVICE
07/23/2026
REPAIR ORDER 812
ODOMETER 55000
ENGINE OIL CHANGE COMPLETED 69.00
ESTIMATE - FRONT BRAKE PADS REPLACEMENT 399.00
PAID IN FULL 69.00
''',
        ),
      );

      final oil = result.candidates.singleWhere(
        (candidate) => candidate.itemName == 'Engine Oil',
      );
      final brakes = result.candidates.singleWhere(
        (candidate) => candidate.itemName == 'Brake Pads',
      );
      expect(oil.action, MaintenanceReceiptAction.reviewCompletedService);
      expect(brakes.action, MaintenanceReceiptAction.manualReview);
      expect(brakes.completedServiceIndicated, isFalse);
      expect(brakes.notCompletedIndicated, isTrue);
    });

    test('generic next due does not leak across mixed service items', () {
      final result = parseMaintenanceReceipt(
        const MaintenanceReceiptParserInput(
          activeVehicleId: 'vehicle_1',
          sourceText: '''
MAIN STREET AUTO
07/23/2026
WORK ORDER 881
ODOMETER 100000
ENGINE OIL CHANGE COMPLETED 69.00
FRONT BRAKE PADS REPLACED 399.00
NEXT DUE 105000
PAID IN FULL 468.00
''',
        ),
      );

      final oil = result.candidates.singleWhere(
        (candidate) => candidate.itemName == 'Engine Oil',
      );
      final brakes = result.candidates.singleWhere(
        (candidate) => candidate.itemName == 'Brake Pads',
      );
      expect(oil.intervalMiles, 5000);
      expect(oil.dueOdometer, 105000);
      expect(brakes.intervalMiles, isNull);
      expect(brakes.dueOdometer, isNull);
    });
  });
}
