import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

part 'expense_receipt_parser_fuel_formats_core_test.dart';
part 'expense_receipt_parser_fuel_formats_core_late_test.dart';
part 'expense_receipt_parser_fuel_formats_alternative_test.dart';
part 'expense_receipt_parser_fuel_formats_diesel_test.dart';
part 'expense_receipt_parser_fuel_formats_diesel_late_test.dart';
part 'expense_receipt_parser_fuel_formats_edge_cases_test.dart';
part 'expense_receipt_parser_fuel_formats_metered_ev_test.dart';
part 'expense_receipt_parser_fuel_formats_hydrogen_test.dart';
part 'expense_receipt_parser_fuel_formats_propane_test.dart';
part 'expense_receipt_parser_fuel_formats_methanol_test.dart';

void main() {
  _registerFuelFormatCoreTests();
  _registerFuelFormatCoreLateTests();
  _registerFuelFormatAlternativeFuelTests();
  _registerFuelFormatDieselTests();
  _registerFuelFormatDieselLateTests();
  _registerFuelFormatEdgeCaseTests();
  _registerFuelFormatMeteredEvTests();
  _registerFuelFormatHydrogenTests();
  _registerFuelFormatPropaneTests();
  _registerFuelFormatMethanolTests();
}
