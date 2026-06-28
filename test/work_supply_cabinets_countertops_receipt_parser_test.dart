import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test(
    'cabinets countertops generated pack covers receipt-realistic stock',
    () {
      final items = workSupplyCatalogItems
          .where((item) => item.trade == 'Cabinets and Countertops')
          .toList(growable: false);
      final fullPack = buildWorkSupplyTradePackOptions(
        'Cabinets and Countertops',
      ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

      expect(items.length, greaterThanOrEqualTo(900));
      expect(fullPack.itemCount, items.length);
      expect(
        items.any(
          (item) =>
              item.name ==
              'White Shaker 36 in Sink Base Cabinet Kitchen Cabinet',
        ),
        isTrue,
      );
      expect(
        items.any(
          (item) =>
              item.name ==
              'Acacia 8 ft Butcher Block Countertop Countertop Surface',
        ),
        isTrue,
      );
    },
  );

  test('cabinets countertops parser understands cabinets and finish parts', () {
    final sinkBase = matchReceiptLineToCatalog(
      'WHITE SHAKER 36IN SINK BASE CABINET',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(sinkBase, isNotNull);
    expect(sinkBase!.item.trade, 'Cabinets and Countertops');
    expect(sinkBase.item.name, contains('White Shaker'));
    expect(sinkBase.item.name, contains('36 in Sink Base Cabinet'));

    final filler = matchReceiptLineToCatalog(
      'GRAY SHAKER 3IN CABINET FILLER STRIP',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(filler, isNotNull);
    expect(filler!.item.trade, 'Cabinets and Countertops');
    expect(filler.item.name, contains('Gray Shaker 3 in'));
    expect(filler.item.name, contains('Cabinet Filler Strip'));
  });

  test('cabinets countertops parser understands bath and countertop stock', () {
    final vanity = matchReceiptLineToCatalog(
      '48IN WHITE SHAKER VANITY WITH QUARTZ TOP',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(vanity, isNotNull);
    expect(vanity!.item.trade, 'Cabinets and Countertops');
    expect(vanity.item.name, contains('White Shaker 48 in'));
    expect(vanity.item.name, contains('Vanity with Quartz Top'));

    final butcherBlock = matchReceiptLineToCatalog(
      '8FT ACACIA BUTCHER BLOCK COUNTERTOP',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(butcherBlock, isNotNull);
    expect(butcherBlock!.item.trade, 'Cabinets and Countertops');
    expect(butcherBlock.item.name, contains('Acacia 8 ft'));
    expect(butcherBlock.item.name, contains('Butcher Block Countertop'));

    final quartz = matchReceiptLineToCatalog(
      'CARRARA QUARTZ COUNTERTOP SAMPLE 37IN',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(quartz, isNotNull);
    expect(quartz!.item.trade, 'Cabinets and Countertops');
    expect(quartz.item.name, contains('Carrara Quartz Countertop Sample'));
  });

  test('cabinets countertops parser understands install supplies', () {
    final support = matchReceiptLineToCatalog(
      'COUNTERTOP SUPPORT BRACKET',
      tradeScope: 'Cabinets and Countertops',
      maxCandidates: 220,
    );
    expect(support, isNotNull);
    expect(support!.item.trade, 'Cabinets and Countertops');
    expect(support.item.name, contains('Countertop Support Bracket'));
  });

  test('cabinets countertops does not steal legacy carpentry hardware', () {
    final pull = matchReceiptLineToCatalog('MATTE BLACK CABINET PULL');
    expect(pull, isNotNull);
    expect(pull!.item.trade, 'Carpentry');

    final shim = matchReceiptLineToCatalog('CABINET SHIM PACK');
    expect(shim, isNotNull);
    expect(shim!.item.trade, 'Carpentry');
  });
}
