part of 'fuel_economy_metrics_test.dart';

void _registerFuelEconomyCoreTests() {
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

  test('keeps gasoline and standard E10/E15 blends in one MPG series', () {
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
        id: 'e10-fill',
        odometer: 90200,
        quantity: 10,
        unit: 'gallon',
        subtotal: 42,
        fuelType: 'E10',
      ),
    ]);

    expect(metrics.liquidFuelTypes, {'gasoline', 'e10'});
    expect(metrics.hasMixedLiquidFuelTypes, isFalse);
    expect(metrics.averageMpg, 10);
    expect(metrics.averageLiquidFuelPrice, 4.1);
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

  test('preserves unmeasured fuel spend without inventing fuel economy', () {
    final metrics = FuelEconomyMetrics.fromReceipts([
      _fuelReceipt(
        id: 'cng-kg-start',
        odometer: 71000,
        quantity: 8,
        unit: 'kg',
        subtotal: 24,
        fuelType: 'CNG',
      ),
      _fuelReceipt(
        id: 'cng-kg-end',
        odometer: 71200,
        quantity: 9,
        unit: 'kg',
        subtotal: 27,
        fuelType: 'CNG',
      ),
    ]);

    expect(metrics.odometerMiles, 200);
    expect(metrics.hydrogenKg, 0);
    expect(metrics.liquidFuelExpense, 51);
    expect(metrics.liquidGallons, 0);
    expect(metrics.hasUnmeasuredLiquidFuel, isTrue);
    expect(metrics.averageMpg, isNull);
    expect(metrics.averageLiquidFuelPrice, isNull);
    expect(metrics.fuelCostPerMile, .255);
  });
}
