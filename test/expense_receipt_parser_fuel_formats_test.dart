import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

part 'expense_receipt_parser_fuel_formats_core.dart';
part 'expense_receipt_parser_fuel_formats_core_late.dart';
part 'expense_receipt_parser_fuel_formats_alternative.dart';
part 'expense_receipt_parser_fuel_formats_diesel.dart';
part 'expense_receipt_parser_fuel_formats_diesel_late.dart';
part 'expense_receipt_parser_fuel_formats_edge_cases.dart';
part 'expense_receipt_parser_fuel_formats_metered_ev.dart';
part 'expense_receipt_parser_fuel_formats_hydrogen.dart';
part 'expense_receipt_parser_fuel_formats_propane.dart';
part 'expense_receipt_parser_fuel_formats_methanol.dart';
part 'expense_receipt_parser_fuel_formats_specialty.dart';
part 'expense_receipt_parser_fuel_formats_us_spanish.dart';

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
  _registerFuelFormatSpecialtyTests();
  _registerFuelFormatUsSpanishTests();
}
