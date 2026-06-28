import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac rtu parser understands belts and filters', () {
    final belt = matchReceiptLineToCatalog(
      'BX42 COGGED BLOWER BELT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(belt, isNotNull);
    expect(belt!.item.trade, 'HVAC');
    expect(belt.item.name, contains('BX42 Cogged Blower Belt'));

    final filter = matchReceiptLineToCatalog(
      '20X25X2 PLEATED ROOFTOP UNIT FILTER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(filter, isNotNull);
    expect(filter!.item.trade, 'HVAC');
    expect(filter.item.name, contains('20 x 25 x 2 Pleated'));
  });

  test('hvac rtu parser understands package unit repair stock', () {
    final drainTrap = matchReceiptLineToCatalog(
      'RTU CONDENSATE DRAIN TRAP KIT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(drainTrap, isNotNull);
    expect(drainTrap!.item.trade, 'HVAC');
    expect(drainTrap.item.name, contains('RTU Condensate Drain Trap Kit'));

    final heater = matchReceiptLineToCatalog(
      '70W 208/230V CRANKCASE HEATER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(heater, isNotNull);
    expect(heater!.item.trade, 'HVAC');
    expect(heater.item.name, contains('70W 208/230V Crankcase Heater'));
  });

  test('hvac rtu parser understands economizer service parts', () {
    final enthalpy = matchReceiptLineToCatalog(
      'ECONOMIZER ENTHALPY SENSOR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(enthalpy, isNotNull);
    expect(enthalpy!.item.trade, 'HVAC');
    expect(enthalpy.item.name, contains('Economizer Enthalpy Sensor'));

    final actuator = matchReceiptLineToCatalog(
      '45 IN-LB SPRING RETURN ECONOMIZER DAMPER ACTUATOR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(actuator, isNotNull);
    expect(actuator!.item.trade, 'HVAC');
    expect(actuator.item.name, contains('Economizer Damper Actuator'));
  });
}
