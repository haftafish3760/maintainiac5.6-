import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('siding exterior generated pack covers receipt-realistic stock', () {
    final sidingItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Siding and Exterior')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Siding and Exterior',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(sidingItems.length, greaterThanOrEqualTo(700));
    expect(fullPack.itemCount, sidingItems.length);
    expect(
      sidingItems.any(
        (item) => item.name == 'White Double 4 in Dutch Lap Vinyl Siding Panel',
      ),
      isTrue,
    );
    expect(
      sidingItems.any(
        (item) => item.name == 'Clay 12 ft J Channel Siding Trim',
      ),
      isTrue,
    );
  });

  test('siding parser understands panels trim and corners', () {
    final vinyl = matchReceiptLineToCatalog(
      'WHITE D4 DUTCH LAP VINYL SIDING',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(vinyl, isNotNull);
    expect(vinyl!.item.trade, 'Siding and Exterior');
    expect(vinyl.item.name, contains('White'));
    expect(vinyl.item.name, contains('Double 4 in Dutch Lap'));

    final cement = matchReceiptLineToCatalog(
      'GRAY 7-1/4 FIBER CEMENT LAP SIDING',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(cement, isNotNull);
    expect(cement!.item.trade, 'Siding and Exterior');
    expect(cement.item.name, contains('Gray'));
    expect(cement.item.name, contains('Fiber Cement Lap Siding'));

    final channel = matchReceiptLineToCatalog(
      'CLAY 12FT J CHANNEL',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(channel, isNotNull);
    expect(channel!.item.trade, 'Siding and Exterior');
    expect(channel.item.name, contains('Clay 12 ft J Channel'));
  });

  test('siding parser understands barriers vents shutters and fasteners', () {
    final wrap = matchReceiptLineToCatalog(
      '9X100 HOUSEWRAP ROLL',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(wrap, isNotNull);
    expect(wrap!.item.trade, 'Siding and Exterior');
    expect(wrap.item.name, contains('9 x 100 ft Housewrap Roll'));

    final tape = matchReceiptLineToCatalog(
      '6IN BUTYL FLASHING TAPE',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(tape, isNotNull);
    expect(tape!.item.trade, 'Siding and Exterior');
    expect(tape.item.name, contains('6 in Butyl Flashing Tape'));

    final shutter = matchReceiptLineToCatalog(
      'BLACK 55IN LOUVERED VINYL SHUTTER PAIR',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(shutter, isNotNull);
    expect(shutter!.item.trade, 'Siding and Exterior');
    expect(shutter.item.name, contains('Black 55 in Louvered'));

    final nail = matchReceiptLineToCatalog(
      'HDG 1-1/2 RING SHANK SIDING NAIL',
      tradeScope: 'Siding and Exterior',
      maxCandidates: 180,
    );
    expect(nail, isNotNull);
    expect(nail!.item.trade, 'Siding and Exterior');
    expect(nail.item.name, contains('1-1/2 in Ring Shank Siding Nail'));
  });
}
