import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_locale_pack.dart';

void main() {
  test('priority locale packs cover US and Canada release targets', () {
    final ids = workSupplyPriorityLocalePacks.map((pack) => pack.id).toSet();

    expect(ids, containsAll(['en-US', 'es-US', 'en-CA', 'fr-CA']));
    expect(workSupplyLocalePackEnUs.measurementSystem, 'us-customary');
    expect(workSupplyLocalePackEsUs.countryCodes, contains('US'));
    expect(workSupplyLocalePackEnCa.countryCodes, ['CA']);
    expect(workSupplyLocalePackFrCa.receiptLanguage, 'french');
  });
}
