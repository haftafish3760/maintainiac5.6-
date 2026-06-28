import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('garage doors openers generated pack covers receipt-realistic stock', () {
    final items = workSupplyCatalogItems
        .where((item) => item.trade == 'Garage Doors and Openers')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Garage Doors and Openers',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(items.length, greaterThanOrEqualTo(900));
    expect(fullPack.itemCount, items.length);
    expect(
      items.any(
        (item) =>
            item.name ==
            'White 16 ft x 7 ft Insulated Steel Raised Panel Door Section Garage Door Section',
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) =>
            item.name ==
            '3/4 HP Belt Drive Wi-Fi Smart Opener Garage Door Opener',
      ),
      isTrue,
    );
  });

  test('garage parser understands sections springs and balance parts', () {
    final section = matchReceiptLineToCatalog(
      'WHITE 16FT X 7FT INSULATED STEEL RAISED PANEL GARAGE DOOR SECTION',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(section, isNotNull);
    expect(section!.item.trade, 'Garage Doors and Openers');
    expect(section.item.name, contains('White 16 ft x 7 ft'));
    expect(section.item.name, contains('Insulated Steel Raised Panel'));

    final spring = matchReceiptLineToCatalog(
      '0.243 X 32IN TORSION SPRING LEFT WIND',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(spring, isNotNull);
    expect(spring!.item.trade, 'Garage Doors and Openers');
    expect(spring.item.name, contains('0.243 in x 32 in'));
    expect(spring.item.name, contains('Left Wind'));

    final cable = matchReceiptLineToCatalog(
      '7FT GARAGE DOOR LIFT CABLE PAIR',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(cable, isNotNull);
    expect(cable!.item.trade, 'Garage Doors and Openers');
    expect(cable.item.name, contains('7 ft Lift Cable Pair'));
  });

  test('garage parser understands openers controls seals and hardware', () {
    final opener = matchReceiptLineToCatalog(
      '3/4 HP BELT DRIVE WIFI SMART GARAGE DOOR OPENER',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(opener, isNotNull);
    expect(opener!.item.trade, 'Garage Doors and Openers');
    expect(opener.item.name, contains('3/4 HP Belt Drive'));

    final sensor = matchReceiptLineToCatalog(
      'UNIVERSAL GARAGE SAFETY SENSOR PAIR PHOTO EYE',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(sensor, isNotNull);
    expect(sensor!.item.trade, 'Garage Doors and Openers');
    expect(sensor.item.name, contains('Safety Sensor Pair'));

    final seal = matchReceiptLineToCatalog(
      '16FT GARAGE DOOR T STYLE BOTTOM SEAL',
      tradeScope: 'Garage Doors and Openers',
      maxCandidates: 220,
    );
    expect(seal, isNotNull);
    expect(seal!.item.trade, 'Garage Doors and Openers');
    expect(seal.item.name, contains('16 ft T Style Bottom Seal'));
  });

  test('garage doors does not steal normal door or cabinet receipts', () {
    final entryDoor = matchReceiptLineToCatalog(
      '36IN STEEL PREHUNG ENTRY DOOR',
    );
    expect(entryDoor, isNotNull);
    expect(entryDoor!.item.trade, 'Windows and Doors');

    final cabinetHinge = matchReceiptLineToCatalog('SOFT CLOSE CABINET HINGE');
    expect(cabinetHinge, isNotNull);
    expect(cabinetHinge!.item.trade, isNot('Garage Doors and Openers'));
  });
}
