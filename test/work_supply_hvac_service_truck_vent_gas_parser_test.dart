import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac vent gas parser understands furnace pvc venting', () {
    final pvc = matchReceiptLineToCatalog(
      '3IN PVC LONG SWEEP 90 VENT ELBOW',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(pvc, isNotNull);
    expect(pvc!.item.trade, 'HVAC');
    expect(pvc.item.name, contains('PVC Long Sweep 90 Vent Elbow'));

    final concentric = matchReceiptLineToCatalog(
      '3IN CONCENTRIC VENT KIT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(concentric, isNotNull);
    expect(concentric!.item.trade, 'HVAC');
    expect(concentric.item.name, contains('Concentric Vent Kit'));
  });

  test('hvac vent gas parser understands b vent and flue repair', () {
    final bVent = matchReceiptLineToCatalog(
      '4IN B VENT 90 ELBOW',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(bVent, isNotNull);
    expect(bVent!.item.trade, 'HVAC');
    expect(bVent.item.name, contains('B Vent 90 Elbow'));

    final flue = matchReceiptLineToCatalog(
      '5IN SINGLE WALL FLUE PIPE 5FT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(flue, isNotNull);
    expect(flue!.item.trade, 'HVAC');
    expect(flue.item.name, contains('Single Wall Flue Pipe'));
  });

  test('hvac vent gas parser understands gas connection stock', () {
    final connector = matchReceiptLineToCatalog(
      '1/2 X 48IN GAS APPLIANCE CONNECTOR',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(connector, isNotNull);
    expect(connector!.item.trade, 'HVAC');
    expect(connector.item.name, contains('Gas Appliance Connector'));

    final trap = matchReceiptLineToCatalog(
      '3/4IN SEDIMENT TRAP KIT',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(trap, isNotNull);
    expect(trap!.item.trade, 'HVAC');
    expect(trap.item.name, contains('Sediment Trap Kit'));
  });

  test('hvac vent gas parser understands exhaust caps and dryer vent', () {
    final dryer = matchReceiptLineToCatalog(
      '4IN DRYER VENT HOOD',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(dryer, isNotNull);
    expect(dryer!.item.trade, 'HVAC');
    expect(dryer.item.name, contains('Dryer Vent Hood'));

    final wallCap = matchReceiptLineToCatalog(
      '6IN BATH FAN WALL CAP',
      tradeScope: 'HVAC',
      maxCandidates: 120,
    );
    expect(wallCap, isNotNull);
    expect(wallCap!.item.trade, 'HVAC');
    expect(wallCap.item.name, contains('Bath Fan Wall Cap'));
  });
}
