import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  test('electrical core supplemental service stock resolves as Core', () {
    _expectCoreItem('Electrical', ['old work box']);
    _expectCoreItem('Electrical', ['fan rated retrofit brace box']);
    _expectCoreItem('Electrical', ['in-use bubble cover']);
    _expectCoreItem('Electrical', ['mc cable connector']);
    _expectCoreItem('Electrical', ['lever connector']);
    _expectCoreItem('Electrical', ['smoke co combo alarm']);
    _expectCoreItem('Electrical', ['doorbell transformer']);
    _expectCoreItem('Electrical', ['wr gfci receptacle']);
    _expectCoreItem('Electrical', ['afci breaker']);
    _expectCoreItem('Electrical', ['dual function breaker']);
    _expectCoreItem('Electrical', ['fixture crossbar']);
    _expectCoreItem('Electrical', ['pvc male terminal adapter']);
    _expectCoreItem('Electrical', ['wire marker']);
    _expectCoreItem('Electrical', ['occupancy vacancy sensor']);
  });

  test('hvac core supplemental service stock resolves as Core', () {
    _expectCoreItem('HVAC', ['wet switch flood detector']);
    _expectCoreItem('HVAC', ['condensate neutralizer cartridge']);
    _expectCoreItem('HVAC', ['hot surface ignitor']);
    _expectCoreItem('HVAC', ['pressure switch tubing kit']);
    _expectCoreItem('HVAC', ['fan center']);
    _expectCoreItem('HVAC', ['ac disconnect']);
    _expectCoreItem('HVAC', ['equipment whip']);
    _expectCoreItem('HVAC', ['surge protector']);
    _expectCoreItem('HVAC', ['control board']);
    _expectCoreItem('HVAC', ['defrost control board']);
    _expectCoreItem('HVAC', ['control transformer']);
    _expectCoreItem('HVAC', ['condensate drain ball valve']);
    _expectCoreItem('HVAC', ['heat pump thermostat']);
    _expectCoreItem('HVAC', ['takeoff collar']);
  });
}

void _expectCoreItem(String trade, List<String> requiredTerms) {
  final match = workSupplyCatalogItems.where((item) {
    final text = item.searchableText.toLowerCase();
    return item.trade == trade &&
        requiredTerms.every((term) => text.contains(term));
  }).toList();

  expect(match, isNotEmpty, reason: '$trade missing $requiredTerms');
  expect(
    match.any((item) => item.packTier == WorkSupplyPackTier.core),
    isTrue,
    reason:
        '$trade $requiredTerms exists but no matching item resolves as Core: '
        '${match.map((item) => '${item.name}:${item.packTier.name}').join(', ')}',
  );
}
