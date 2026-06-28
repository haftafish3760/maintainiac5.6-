import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac airflow parser understands flex duct and takeoffs', () {
    final flex = matchReceiptLineToCatalog(
      '8IN R8 INSULATED FLEX DUCT 25FT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(flex, isNotNull);
    expect(flex!.item.trade, 'HVAC');
    expect(flex.item.name, contains('8 in R8'));
    expect(flex.item.name, contains('Flex Duct'));

    final takeoff = matchReceiptLineToCatalog(
      '6IN SPIN IN TAKEOFF WITH DAMPER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(takeoff, isNotNull);
    expect(takeoff!.item.trade, 'HVAC');
    expect(takeoff.item.name, contains('Spin In Takeoff With Damper'));
  });

  test('hvac airflow parser understands boots and grille repair', () {
    final boot = matchReceiptLineToCatalog(
      '4X10 X 6IN STRAIGHT REGISTER BOOT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(boot, isNotNull);
    expect(boot!.item.trade, 'HVAC');
    expect(boot.item.name, contains('Straight Register Boot'));

    final grille = matchReceiptLineToCatalog(
      '20X25 RETURN FILTER GRILLE',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(grille, isNotNull);
    expect(grille!.item.trade, 'HVAC');
    expect(grille.item.name, contains('Return Filter Grille'));
  });

  test('hvac airflow parser understands dampers reducers and sheet metal', () {
    final damper = matchReceiptLineToCatalog(
      '8IN 26GA MANUAL BALANCING DAMPER',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(damper, isNotNull);
    expect(damper!.item.trade, 'HVAC');
    expect(damper.item.name, contains('Manual Balancing Damper'));

    final metal = matchReceiptLineToCatalog(
      '24X36 26GA GALVANIZED SHEET METAL',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(metal, isNotNull);
    expect(metal!.item.trade, 'HVAC');
    expect(metal.item.name, contains('Galvanized Sheet Metal'));
  });

  test('hvac airflow parser understands duct consumables', () {
    final tape = matchReceiptLineToCatalog(
      '3IN X 100YD UL181 FOIL TAPE',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(tape, isNotNull);
    expect(tape!.item.trade, 'HVAC');
    expect(tape.item.name, contains('UL181 Foil Tape'));

    final strap = matchReceiptLineToCatalog(
      'FLEX DUCT ZIP TIE 36IN 25PK',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(strap, isNotNull);
    expect(strap!.item.trade, 'HVAC');
    expect(strap.item.name, contains('Flex Duct Zip Tie'));
  });
}
