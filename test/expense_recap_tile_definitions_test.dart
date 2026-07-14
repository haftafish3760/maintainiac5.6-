import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/reports/expense_recap_models.dart';

void main() {
  test('exposes liquid, EV, and hydrogen economy recap tiles', () {
    final ids = expenseRecapTileDefinitions.map((tile) => tile.id).toSet();

    expect(
      ids,
      containsAll([
        'averageMpg',
        'averageElectricKwhPrice',
        'milesPerKwh',
        'electricFuelCostPerMile',
        'averageHydrogenKgPrice',
        'milesPerHydrogenKg',
        'hydrogenFuelCostPerMile',
      ]),
    );
  });
}
