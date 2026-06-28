import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac hydronic parser understands boiler pump controls', () {
    final circulator = matchReceiptLineToCatalog(
      'UNIVERSAL CIRCULATOR PUMP',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(circulator, isNotNull);
    expect(circulator!.item.trade, 'HVAC');
    expect(circulator.item.name, contains('Universal Circulator Pump'));

    final zoneHead = matchReceiptLineToCatalog(
      'ZONE VALVE POWER HEAD',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(zoneHead, isNotNull);
    expect(zoneHead!.item.trade, 'HVAC');
    expect(zoneHead.item.name, contains('Zone Valve Power Head'));

    final aquastat = matchReceiptLineToCatalog(
      'BOILER AQUASTAT TEMP CONTROL',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(aquastat, isNotNull);
    expect(aquastat!.item.trade, 'HVAC');
    expect(aquastat.item.name, contains('Aquastat Temperature Control'));
  });

  test('hvac hydronic parser understands boiler safety and fill parts', () {
    final expansion = matchReceiptLineToCatalog(
      'HYDRONIC EXPANSION TANK NO 30',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(expansion, isNotNull);
    expect(expansion!.item.trade, 'HVAC');
    expect(expansion.item.name, contains('Hydronic Expansion Tank No 30'));

    final fillValve = matchReceiptLineToCatalog(
      'PRESSURE REDUCING FILL VALVE',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(fillValve, isNotNull);
    expect(fillValve!.item.trade, 'HVAC');
    expect(fillValve.item.name, contains('Pressure Reducing Fill Valve'));

    final airVent = matchReceiptLineToCatalog(
      '1/8IN AUTOMATIC AIR VENT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(airVent, isNotNull);
    expect(airVent!.item.trade, 'HVAC');
    expect(airVent.item.name, contains('Automatic Air Vent'));
  });

  test('hvac hydronic parser understands baseboard repair stock', () {
    final element = matchReceiptLineToCatalog(
      '6FT BASEBOARD HEATING ELEMENT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(element, isNotNull);
    expect(element!.item.trade, 'HVAC');
    expect(element.item.name, contains('Baseboard Heating Element'));

    final endCap = matchReceiptLineToCatalog(
      'BASEBOARD END CAP LEFT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(endCap, isNotNull);
    expect(endCap!.item.trade, 'HVAC');
    expect(endCap.item.name, contains('Baseboard End Cap Left'));
  });

  test('hvac hydronic parser understands radiant repair stock', () {
    final flowMeter = matchReceiptLineToCatalog(
      'RADIANT MANIFOLD FLOW METER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(flowMeter, isNotNull);
    expect(flowMeter!.item.trade, 'HVAC');
    expect(flowMeter.item.name, contains('Radiant Manifold Flow Meter'));

    final pex = matchReceiptLineToCatalog(
      '1/2IN OXYGEN BARRIER PEX COUPLING',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(pex, isNotNull);
    expect(pex!.item.trade, 'HVAC');
    expect(pex.item.name, contains('Oxygen Barrier PEX Coupling'));
  });
}
