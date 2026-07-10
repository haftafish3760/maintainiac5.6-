part of 'fuel_economy_metrics_test.dart';

void _registerFuelEconomyCycleTests() {
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
}
