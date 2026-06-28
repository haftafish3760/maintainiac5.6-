import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac service truck parser understands thermostat and zone controls', () {
    final thermostat = matchReceiptLineToCatalog(
      '2H/2C WIFI THERMOSTAT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(thermostat, isNotNull);
    expect(thermostat!.item.trade, 'HVAC');
    expect(thermostat.item.name, contains('WiFi Thermostat'));

    final zonePanel = matchReceiptLineToCatalog(
      '3 ZONE HEAT PUMP ZONE CONTROL PANEL',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(zonePanel, isNotNull);
    expect(zonePanel!.item.trade, 'HVAC');
    expect(zonePanel.item.name, contains('Zone Control Panel'));

    final actuator = matchReceiptLineToCatalog(
      'ZONE DAMPER MOTOR ACTUATOR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(actuator, isNotNull);
    expect(actuator!.item.trade, 'HVAC');
    expect(actuator.item.name, contains('Damper Motor Actuator'));
  });

  test('hvac service truck parser understands boards and heat pump controls', () {
    final board = matchReceiptLineToCatalog(
      '24V UNIVERSAL FURNACE CONTROL BOARD',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(board, isNotNull);
    expect(board!.item.trade, 'HVAC');
    expect(board.item.name, contains('Furnace Control Board'));

    final defrost = matchReceiptLineToCatalog(
      'UNIVERSAL HEAT PUMP DEFROST BOARD',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(defrost, isNotNull);
    expect(defrost!.item.trade, 'HVAC');
    expect(defrost.item.name, contains('Defrost Board'));

    final reversing = matchReceiptLineToCatalog(
      'REVERSING VALVE COIL',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(reversing, isNotNull);
    expect(reversing!.item.trade, 'HVAC');
    expect(reversing.item.name, contains('Reversing Valve Coil'));
  });

  test('hvac service truck parser understands mini split service stock', () {
    final remote = matchReceiptLineToCatalog(
      'MINI SPLIT REMOTE CONTROL',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(remote, isNotNull);
    expect(remote!.item.trade, 'HVAC');
    expect(remote.item.name, contains('Mini Split Remote Control'));

    final flare = matchReceiptLineToCatalog(
      '3/8 MINI SPLIT FLARE UNION',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(flare, isNotNull);
    expect(flare!.item.trade, 'HVAC');
    expect(flare.item.name, contains('Mini Split Flare Union'));

    final washBag = matchReceiptLineToCatalog(
      'MINI SPLIT CLEANING BIB KIT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(washBag, isNotNull);
    expect(washBag!.item.trade, 'HVAC');
    expect(washBag.item.name, contains('Cleaning Bib Kit'));
  });

  test('hvac service truck parser understands filter case and small stock', () {
    final filters = matchReceiptLineToCatalog(
      '16X25X1 MERV 11 PLEATED FILTER 12PK',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(filters, isNotNull);
    expect(filters!.item.trade, 'HVAC');
    expect(filters.item.name, contains('16 x 25 x 1'));
    expect(filters.item.name, contains('MERV 11'));

    final marker = matchReceiptLineToCatalog(
      'WIRE NUMBER MARKER BOOK',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(marker, isNotNull);
    expect(marker!.item.trade, 'HVAC');
    expect(marker.item.name, contains('Wire Number Marker Book'));
  });
}
