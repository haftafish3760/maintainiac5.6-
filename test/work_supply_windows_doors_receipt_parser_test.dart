import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('windows doors generated pack covers receipt-realistic stock', () {
    final items = workSupplyCatalogItems
        .where((item) => item.trade == 'Windows and Doors')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Windows and Doors',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(items.length, greaterThanOrEqualTo(900));
    expect(fullPack.itemCount, items.length);
    expect(
      items.any(
        (item) =>
            item.name ==
            '30 in x 48 in Low E White Vinyl Double Hung Window Window Unit',
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) =>
            item.name ==
            '36 in White Right Hand Inswing 6 Panel Steel Prehung Entry Door Exterior Door Unit',
      ),
      isTrue,
    );
  });

  test('windows doors parser understands windows and repair parts', () {
    final window = matchReceiptLineToCatalog(
      '30X48 WHITE VINYL DOUBLE HUNG WINDOW',
      tradeScope: 'Windows and Doors',
      maxCandidates: 180,
    );
    expect(window, isNotNull);
    expect(window!.item.trade, 'Windows and Doors');
    expect(window.item.name, contains('30 in x 48 in'));
    expect(window.item.name, contains('Double Hung Window'));

    final screen = matchReceiptLineToCatalog(
      'BLACK 30X48 REPLACEMENT WINDOW SCREEN',
      tradeScope: 'Windows and Doors',
      maxCandidates: 180,
    );
    expect(screen, isNotNull);
    expect(screen!.item.trade, 'Windows and Doors');
    expect(
      screen.item.name,
      contains('Black 30 x 48 in Replacement Window Screen'),
    );

    final balance = matchReceiptLineToCatalog(
      'WINDOW SASH BALANCE PAIR',
      tradeScope: 'Windows and Doors',
      maxCandidates: 180,
    );
    expect(balance, isNotNull);
    expect(balance!.item.trade, 'Windows and Doors');
    expect(balance.item.name, contains('Window Sash Balance Pair'));
  });

  test(
    'windows doors parser understands door units hardware and install stock',
    () {
      final entry = matchReceiptLineToCatalog(
        '36IN RH INSWING 6 PANEL STEEL PREHUNG ENTRY DOOR',
        tradeScope: 'Windows and Doors',
        maxCandidates: 180,
      );
      expect(entry, isNotNull);
      expect(entry!.item.trade, 'Windows and Doors');
      expect(entry.item.name, contains('36 in'));
      expect(entry.item.name, contains('6 Panel Steel Prehung Entry Door'));

      final threshold = matchReceiptLineToCatalog(
        'BRONZE 36IN ADJUSTABLE DOOR THRESHOLD',
        tradeScope: 'Windows and Doors',
        maxCandidates: 180,
      );
      expect(threshold, isNotNull);
      expect(threshold!.item.trade, 'Windows and Doors');
      expect(
        threshold.item.name,
        contains('Bronze 36 in Adjustable Door Threshold'),
      );

      final foam = matchReceiptLineToCatalog(
        '16OZ LOW EXPANSION WINDOW DOOR FOAM',
        tradeScope: 'Windows and Doors',
        maxCandidates: 180,
      );
      expect(foam, isNotNull);
      expect(foam!.item.trade, 'Windows and Doors');
      expect(foam.item.name, contains('16 oz Low Expansion Window Door Foam'));
    },
  );

  test('windows doors does not steal legacy carpentry lockset receipts', () {
    final lockset = matchReceiptLineToCatalog('SATIN NICKEL ENTRY DOOR KNOB');
    expect(lockset, isNotNull);
    expect(lockset!.item.trade, 'Carpentry');
  });
}
