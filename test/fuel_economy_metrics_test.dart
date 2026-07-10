import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/fuel_economy_metrics.dart';

part 'fuel_economy_metrics_core_test.dart';
part 'fuel_economy_metrics_cycle_test.dart';
part 'fuel_economy_metrics_recap_test.dart';

void main() {
  _registerFuelEconomyCoreTests();
  _registerFuelEconomyCycleTests();
  _registerFuelEconomyRecapTests();
}
