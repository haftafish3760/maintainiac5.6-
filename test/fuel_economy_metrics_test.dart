import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/fuel_economy_metrics.dart';

void main() {
  test('calculates liquid fuel MPG and cost per mile independent of UI', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'fuel-1',
        odometer: 10000,
        quantity: 10,
        unit: 'gallon',
        subtotal: 40,
        fuelType: 'Gasoline',
      ),
      _fuelReceipt(
        id: 'fuel-2',
        odometer: 10250,
        quantity: 12.5,
        unit: 'gallon',
        subtotal: 50,
        fuelType: 'Gasoline',
      ),
    ]);

    expect(metrics.odometerMiles, 250);
    expect(metrics.liquidGallons, 22.5);
    expect(metrics.electricKwh, 0);
    expect(metrics.fuelExpense, 90);
    expect(metrics.averageMpg, closeTo(11.111, .001));
    expect(metrics.averageLiquidFuelPrice, 4);
    expect(metrics.fuelCostPerMile, .36);
  });

  test('keeps EV charge economy separate from liquid MPG', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'ev-1',
        odometer: 20000,
        quantity: 42,
        unit: 'kWh',
        subtotal: 18.90,
        fuelType: 'Electric',
      ),
      _fuelReceipt(
        id: 'ev-2',
        odometer: 20126,
        quantity: 36,
        unit: 'kWh',
        subtotal: 16.20,
        fuelType: 'Electric',
      ),
    ]);

    expect(metrics.odometerMiles, 126);
    expect(metrics.liquidGallons, 0);
    expect(metrics.averageMpg, isNull);
    expect(metrics.electricKwh, 78);
    expect(metrics.milesPerKwh, closeTo(1.615, .001));
    expect(metrics.averageElectricKwhPrice, closeTo(.45, .0001));
    expect(metrics.electricFuelCostPerMile, closeTo(.2786, .0001));
  });

  test('converts liquid liters to gallons for fuel economy', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'liter-1',
        odometer: 40000,
        quantity: 42,
        unit: 'liter',
        subtotal: 37.76,
        fuelType: 'Gasoline',
      ),
      _fuelReceipt(
        id: 'liter-2',
        odometer: 40220,
        quantity: 38,
        unit: 'liters',
        subtotal: 34.16,
        fuelType: 'Gasoline',
      ),
    ]);

    expect(metrics.odometerMiles, 220);
    expect(metrics.liquidGallons, closeTo(21.1338, .0001));
    expect(metrics.averageMpg, closeTo(10.4099, .0001));
    expect(metrics.averageLiquidFuelPrice, closeTo(3.4031, .0001));
  });

  test('treats CNG GGE as gallon-equivalent for MPG and cost per mile', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'cng-1',
        odometer: 60000,
        quantity: 8.5,
        unit: 'GGE',
        subtotal: 23.80,
        fuelType: 'CNG',
      ),
      _fuelReceipt(
        id: 'cng-2',
        odometer: 60170,
        quantity: 9.0,
        unit: 'GGE',
        subtotal: 25.20,
        fuelType: 'CNG',
      ),
    ]);

    expect(metrics.odometerMiles, 170);
    expect(metrics.liquidGallons, 17.5);
    expect(metrics.averageMpg, closeTo(9.714, .001));
    expect(metrics.averageLiquidFuelPrice, 2.8);
    expect(metrics.fuelCostPerMile, closeTo(.2882, .0001));
  });

  test('treats LNG DGE as gallon-equivalent for MPG and cost per mile', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'lng-1',
        odometer: 61000,
        quantity: 14.75,
        unit: 'DGE',
        subtotal: 46.15,
        fuelType: 'LNG',
      ),
      _fuelReceipt(
        id: 'lng-2',
        odometer: 61295,
        quantity: 15.25,
        unit: 'DGE',
        subtotal: 47.72,
        fuelType: 'LNG',
      ),
    ]);

    expect(metrics.odometerMiles, 295);
    expect(metrics.liquidGallons, 30);
    expect(metrics.averageMpg, closeTo(9.833, .001));
    expect(metrics.averageLiquidFuelPrice, closeTo(3.129, .001));
    expect(metrics.fuelCostPerMile, closeTo(.3182, .0001));
  });

  test('keeps DEF expense out of diesel MPG and fuel cost per mile', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'diesel-def-stop',
        odometer: 80000,
        quantity: 10,
        unit: 'gallon',
        subtotal: 40,
        fuelType: 'Diesel',
        extraLines: [
          _fuelLine(
            id: 'diesel-def-stop-def',
            odometer: 80000,
            quantity: 2,
            unit: 'gallon',
            subtotal: 10,
            fuelType: 'DEF',
            description: 'Blue DEF diesel exhaust fluid',
          ),
        ],
      ),
      _fuelReceipt(
        id: 'diesel-next-fill',
        odometer: 80200,
        quantity: 10,
        unit: 'gallon',
        subtotal: 42,
        fuelType: 'Diesel',
      ),
    ]);

    expect(metrics.odometerMiles, 200);
    expect(metrics.fuelExpense, 92);
    expect(metrics.liquidFuelExpense, 82);
    expect(metrics.liquidGallons, 20);
    expect(metrics.averageMpg, 10);
    expect(metrics.averageLiquidFuelPrice, 4.1);
    expect(metrics.fuelCostPerMile, .41);
    expect(metrics.liquidFuelCostPerMile, .41);
  });

  test('suppresses liquid MPG when a vehicle has incompatible fuel types', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'gasoline-fill',
        odometer: 90000,
        quantity: 10,
        unit: 'gallon',
        subtotal: 40,
        fuelType: 'Gasoline',
      ),
      _fuelReceipt(
        id: 'diesel-fill',
        odometer: 90200,
        quantity: 10,
        unit: 'gallon',
        subtotal: 42,
        fuelType: 'Diesel',
      ),
    ]);

    expect(metrics.liquidFuelTypes, {'gasoline', 'diesel'});
    expect(metrics.hasMixedLiquidFuelTypes, isTrue);
    expect(metrics.liquidGallons, 20);
    expect(metrics.liquidFuelExpense, 82);
    expect(metrics.averageMpg, isNull);
    expect(metrics.averageLiquidFuelPrice, isNull);
    expect(metrics.liquidFuelCostPerMile, .41);
  });

  test('keeps hydrogen kg economy separate from liquid and EV metrics', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'h2-1',
        odometer: 70000,
        quantity: 4.0,
        unit: 'kg',
        subtotal: 64,
        fuelType: 'Hydrogen',
      ),
      _fuelReceipt(
        id: 'h2-2',
        odometer: 70240,
        quantity: 4.8,
        unit: 'kg',
        subtotal: 76.80,
        fuelType: 'Hydrogen',
      ),
    ]);

    expect(metrics.odometerMiles, 240);
    expect(metrics.liquidGallons, 0);
    expect(metrics.electricKwh, 0);
    expect(metrics.hydrogenKg, 8.8);
    expect(metrics.hydrogenFuelExpense, 140.80);
    expect(metrics.averageMpg, isNull);
    expect(metrics.milesPerKwh, isNull);
    expect(metrics.milesPerHydrogenKg, closeTo(27.273, .001));
    expect(metrics.averageHydrogenKgPrice, 16);
    expect(metrics.hydrogenFuelCostPerMile, closeTo(.5867, .0001));
  });

  test(
    'counts EV session fees in electric cost without changing kWh economy',
    () {
      final metrics = FuelEconomyMetrics.fromReceipts([
        _fuelReceipt(
          id: 'ev-fee-1',
          odometer: 30000,
          quantity: 40,
          unit: 'kWh',
          subtotal: 16,
          fuelType: 'Electric',
          extraLines: [
            _feeLine(id: 'ev-fee-1-session', subtotal: 1.25),
            _feeLine(id: 'ev-fee-1-idle', subtotal: 2.75),
          ],
        ),
        _fuelReceipt(
          id: 'ev-fee-2',
          odometer: 30120,
          quantity: 30,
          unit: 'kWh',
          subtotal: 12,
          fuelType: 'Electric',
          extraLines: [_feeLine(id: 'ev-fee-2-session', subtotal: 1.50)],
        ),
      ]);

      expect(metrics.odometerMiles, 120);
      expect(metrics.liquidGallons, 0);
      expect(metrics.electricKwh, 70);
      expect(metrics.fuelExpense, 33.50);
      expect(metrics.electricFuelExpense, 33.50);
      expect(metrics.milesPerKwh, closeTo(1.714, .001));
      expect(metrics.averageElectricKwhPrice, closeTo(.4786, .0001));
      expect(metrics.electricFuelCostPerMile, closeTo(.2792, .0001));
    },
  );

  test(
    'uses partial fill gallons only when the next full fill completes a cycle',
    () {
      final metrics = FuelEconomyMetrics.fromReceipts([
        _fuelReceipt(
          id: 'full-start',
          odometer: 50000,
          quantity: 12,
          unit: 'gallon',
          subtotal: 42,
          fuelType: 'Gasoline',
          fillType: 'Full fill-up',
        ),
        _fuelReceipt(
          id: 'partial-middle',
          odometer: 50120,
          quantity: 5,
          unit: 'gallon',
          subtotal: 17.50,
          fuelType: 'Gasoline',
          fillType: 'Partial fill',
        ),
        _fuelReceipt(
          id: 'full-end',
          odometer: 50240,
          quantity: 7,
          unit: 'gallon',
          subtotal: 24.50,
          fuelType: 'Gasoline',
          fillType: 'Full fill-up',
        ),
      ]);

      expect(metrics.odometerMiles, 240);
      expect(metrics.liquidGallons, 24);
      expect(metrics.completedLiquidFillGallons, 12);
      expect(metrics.completedLiquidFillMiles, 240);
      expect(metrics.averageMpg, 20);
    },
  );

  test(
    'replays a backdated partial fill into the correct full-to-full cycle',
    () {
      final metrics = FuelEconomyMetrics.fromReceipts([
        _fuelReceipt(
          id: 'full-end',
          odometer: 10300,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Gasoline',
          fillType: 'Full fill-up',
          receiptDate: DateTime(2026, 6, 15),
        ),
        _fuelReceipt(
          id: 'late-partial',
          odometer: 10150,
          quantity: 5,
          unit: 'gallon',
          subtotal: 20,
          fuelType: 'Gasoline',
          fillType: 'Partial fill',
          receiptDate: DateTime(2026, 6, 8),
        ),
        _fuelReceipt(
          id: 'full-start',
          odometer: 10000,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Gasoline',
          fillType: 'Full fill-up',
          receiptDate: DateTime(2026, 6, 1),
        ),
      ]);

      expect(metrics.hasOdometerSequenceConflict, isFalse);
      expect(metrics.completedLiquidFillMiles, 300);
      expect(metrics.completedLiquidFillGallons, 15);
      expect(metrics.averageMpg, 20);
    },
  );

  test('keeps fleet vehicle mileage calculations isolated', () {
    final fleet = FuelEconomyFleetMetrics.fromReceipts([
      _fuelReceipt(
        id: 'truck-start',
        vehicleId: 'truck-1',
        odometer: 10000,
        quantity: 10,
        unit: 'gallon',
        subtotal: 40,
        fuelType: 'Diesel',
      ),
      _fuelReceipt(
        id: 'car-start',
        vehicleId: 'car-1',
        odometer: 50000,
        quantity: 8,
        unit: 'gallon',
        subtotal: 32,
        fuelType: 'Gasoline',
      ),
      _fuelReceipt(
        id: 'truck-end',
        vehicleId: 'truck-1',
        odometer: 10200,
        quantity: 10,
        unit: 'gallon',
        subtotal: 42,
        fuelType: 'Diesel',
      ),
      _fuelReceipt(
        id: 'car-end',
        vehicleId: 'car-1',
        odometer: 50100,
        quantity: 8,
        unit: 'gallon',
        subtotal: 34,
        fuelType: 'Gasoline',
      ),
    ]);

    expect(fleet.unassignedFuelReceiptCount, 0);
    expect(fleet.metricsByVehicleId.keys, containsAll(['truck-1', 'car-1']));
    expect(fleet.metricsByVehicleId['truck-1']!.averageMpg, 10);
    expect(fleet.metricsByVehicleId['car-1']!.averageMpg, 6.25);
  });

  test(
    'suppresses distance metrics for conflicting chronological odometers',
    () {
      final metrics = FuelEconomyMetrics.fromReceipts([
        _fuelReceipt(
          id: 'later-lower-odometer',
          odometer: 9950,
          quantity: 8,
          unit: 'gallon',
          subtotal: 32,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 5),
        ),
        _fuelReceipt(
          id: 'earlier-higher-odometer',
          odometer: 10000,
          quantity: 8,
          unit: 'gallon',
          subtotal: 32,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 1),
        ),
      ]);

      expect(metrics.hasOdometerSequenceConflict, isTrue);
      expect(metrics.odometerMiles, isNull);
      expect(metrics.averageMpg, isNull);
      expect(metrics.fuelCostPerMile, isNull);
    },
  );

  test('replays backdated receipts into a date-window fuel recap', () {
    final recap = FuelRecapMetrics.fromReceipts(
      [
        _fuelReceipt(
          id: 'week-end',
          odometer: 10300,
          quantity: 10,
          unit: 'gallon',
          subtotal: 50,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 7),
        ),
        _fuelReceipt(
          id: 'before-week',
          odometer: 10000,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 1),
        ),
        _fuelReceipt(
          id: 'backdated-week-start',
          odometer: 10100,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 3),
        ),
      ],
      vehicleId: 'truck_1',
      period: FuelRecapPeriod(
        start: DateTime(2026, 6, 3),
        endExclusive: DateTime(2026, 6, 10),
      ),
    );

    expect(recap.hasOdometerSequenceConflict, isFalse);
    expect(recap.receiptPeriodMetrics.fuelExpense, 90);
    expect(recap.drivenMiles, 200);
    expect(recap.fuelCostPerMile, .45);
  });

  test('keeps date-window fuel recaps isolated by fleet vehicle', () {
    final recaps = FuelFleetRecapMetrics.fromReceipts(
      [
        _fuelReceipt(
          id: 'truck-start',
          vehicleId: 'truck-1',
          odometer: 10000,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Diesel',
          receiptDate: DateTime(2026, 6, 3),
        ),
        _fuelReceipt(
          id: 'car-start',
          vehicleId: 'car-1',
          odometer: 50000,
          quantity: 8,
          unit: 'gallon',
          subtotal: 32,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 3),
        ),
        _fuelReceipt(
          id: 'truck-end',
          vehicleId: 'truck-1',
          odometer: 10200,
          quantity: 10,
          unit: 'gallon',
          subtotal: 42,
          fuelType: 'Diesel',
          receiptDate: DateTime(2026, 6, 7),
        ),
        _fuelReceipt(
          id: 'car-end',
          vehicleId: 'car-1',
          odometer: 50100,
          quantity: 8,
          unit: 'gallon',
          subtotal: 34,
          fuelType: 'Gasoline',
          receiptDate: DateTime(2026, 6, 7),
        ),
      ],
      period: FuelRecapPeriod(
        start: DateTime(2026, 6, 3),
        endExclusive: DateTime(2026, 6, 10),
      ),
    );

    expect(recaps.unassignedFuelReceiptCount, 0);
    expect(recaps.metricsByVehicleId['truck-1']!.drivenMiles, 200);
    expect(recaps.metricsByVehicleId['truck-1']!.fuelCostPerMile, .41);
    expect(recaps.metricsByVehicleId['car-1']!.drivenMiles, 100);
    expect(recaps.metricsByVehicleId['car-1']!.fuelCostPerMile, .66);
  });
}

ExpenseReceiptRecord _fuelReceipt({
  required String id,
  required int odometer,
  required double quantity,
  required String unit,
  required double subtotal,
  required String fuelType,
  String? fillType,
  String vehicleId = 'truck_1',
  DateTime? receiptDate,
  List<ExpenseReceiptLineRecord> extraLines = const [],
}) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: receiptDate ?? DateTime(2026, 6, 1),
    vehicleId: vehicleId,
    lines: [
      _fuelLine(
        id: '$id-line',
        quantity: quantity,
        unit: unit,
        subtotal: subtotal,
        odometer: odometer,
        fuelType: fuelType,
        fillType: fillType,
      ),
      ...extraLines,
    ],
  );
}

ExpenseReceiptLineRecord _fuelLine({
  required String id,
  required int odometer,
  required double quantity,
  required String unit,
  required double subtotal,
  required String fuelType,
  String? fillType,
  String? description,
}) {
  return ExpenseReceiptLineRecord(
    id: id,
    description: description ?? '$fuelType fuel',
    category: 'Fuel',
    use: ExpenseLineUse.business,
    quantity: quantity,
    unitsPerPackage: 1,
    unit: unit,
    subtotal: subtotal,
    odometerReading: odometer,
    fuelType: fuelType,
    fillType: fillType,
  );
}

ExpenseReceiptLineRecord _feeLine({
  required String id,
  required double subtotal,
}) {
  return ExpenseReceiptLineRecord(
    id: id,
    description: 'Charging fee',
    category: 'Charging Fees',
    use: ExpenseLineUse.business,
    quantity: 1,
    unitsPerPackage: 1,
    unit: 'each',
    subtotal: subtotal,
  );
}
