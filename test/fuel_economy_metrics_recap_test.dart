part of 'fuel_economy_metrics_test.dart';

void _registerFuelEconomyRecapTests() {
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

  test('excludes DEF from a date-window propulsion cost per mile', () {
    final recap = FuelRecapMetrics.fromReceipts(
      [
        _fuelReceipt(
          id: 'diesel-start',
          odometer: 10000,
          quantity: 10,
          unit: 'gallon',
          subtotal: 40,
          fuelType: 'Diesel',
          receiptDate: DateTime(2026, 6, 3),
          extraLines: [
            _fuelLine(
              id: 'def-line',
              odometer: 10000,
              quantity: 2.5,
              unit: 'gallon',
              subtotal: 20,
              fuelType: 'DEF',
            ),
          ],
        ),
        _fuelReceipt(
          id: 'diesel-end',
          odometer: 10200,
          quantity: 10,
          unit: 'gallon',
          subtotal: 50,
          fuelType: 'Diesel',
          receiptDate: DateTime(2026, 6, 7),
        ),
      ],
      vehicleId: 'truck_1',
      period: FuelRecapPeriod(
        start: DateTime(2026, 6, 3),
        endExclusive: DateTime(2026, 6, 10),
      ),
    );

    expect(recap.receiptPeriodMetrics.fuelExpense, 110);
    expect(recap.drivenMiles, 200);
    expect(recap.fuelCostPerMile, .45);
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
