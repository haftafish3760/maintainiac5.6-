import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('appliance generated pack covers receipt-realistic install stock', () {
    final items = workSupplyCatalogItems
        .where((item) => item.trade == 'Appliance Installation and Repair')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Appliance Installation and Repair',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(items.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, items.length);
    expect(
      items.any(
        (item) =>
            item.name ==
            'Universal 6 ft 3/8 in Compression Dishwasher Connector Kit Dishwasher Install Part',
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) =>
            item.name ==
            'Universal 50 Amp 4 Prong 6 ft Range Cord Range Appliance Part',
      ),
      isTrue,
    );
  });

  test(
    'appliance parser understands dishwasher disposal and laundry stock',
    () {
      final dishwasher = matchReceiptLineToCatalog(
        '6FT 3/8 COMPRESSION DISHWASHER CONNECTOR KIT',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(dishwasher, isNotNull);
      expect(dishwasher!.item.trade, 'Appliance Installation and Repair');
      expect(dishwasher.item.name, contains('Dishwasher Connector Kit'));

      final disposal = matchReceiptLineToCatalog(
        '1/2 HP GARBAGE DISPOSAL POWER CORD KIT',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(disposal, isNotNull);
      expect(disposal!.item.trade, 'Appliance Installation and Repair');
      expect(disposal.item.name, contains('1/2 HP'));
      expect(disposal.item.name, contains('Power Cord Kit'));

      final washer = matchReceiptLineToCatalog(
        '6FT STAINLESS WASHER HOSE PAIR',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(washer, isNotNull);
      expect(washer!.item.trade, 'Appliance Installation and Repair');
      expect(washer.item.name, contains('Stainless Washer Hose Pair'));
    },
  );

  test(
    'appliance parser understands dryer range refrigerator and microwave',
    () {
      final dryerCord = matchReceiptLineToCatalog(
        '30 AMP 4 PRONG 6FT DRYER CORD',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(dryerCord, isNotNull);
      expect(dryerCord!.item.trade, 'Appliance Installation and Repair');
      expect(dryerCord.item.name, contains('30 Amp 4 Prong 6 ft Dryer Cord'));

      final rangeCord = matchReceiptLineToCatalog(
        '50 AMP 4 PRONG 6FT RANGE CORD',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(rangeCord, isNotNull);
      expect(rangeCord!.item.trade, 'Appliance Installation and Repair');
      expect(rangeCord.item.name, contains('50 Amp 4 Prong 6 ft Range Cord'));

      final fridge = matchReceiptLineToCatalog(
        '20FT BRAIDED REFRIGERATOR WATER LINE',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(fridge, isNotNull);
      expect(fridge!.item.trade, 'Appliance Installation and Repair');
      expect(
        fridge.item.name,
        contains('20 ft Braided Refrigerator Water Line'),
      );

      final microwave = matchReceiptLineToCatalog(
        'STAINLESS OVER RANGE MICROWAVE MOUNTING BRACKET',
        tradeScope: 'Appliance Installation and Repair',
        maxCandidates: 220,
      );
      expect(microwave, isNotNull);
      expect(microwave!.item.trade, 'Appliance Installation and Repair');
      expect(microwave.item.name, contains('Microwave Mounting Bracket'));
    },
  );

  test('appliance parser understands service and protection supplies', () {
    final fuse = matchReceiptLineToCatalog(
      'DRYER THERMAL FUSE',
      tradeScope: 'Appliance Installation and Repair',
      maxCandidates: 220,
    );
    expect(fuse, isNotNull);
    expect(fuse!.item.trade, 'Appliance Installation and Repair');
    expect(fuse.item.name, contains('Dryer Thermal Fuse'));

    final pan = matchReceiptLineToCatalog(
      '30IN WASHER DRAIN PAN',
      tradeScope: 'Appliance Installation and Repair',
      maxCandidates: 220,
    );
    expect(pan, isNotNull);
    expect(pan!.item.trade, 'Appliance Installation and Repair');
    expect(pan.item.name, contains('30 in Washer Drain Pan'));
  });

  test('appliance pack does not steal neighboring trade receipts', () {
    final romex = matchReceiptLineToCatalog('12/2 NM-B ROMEX 250FT');
    expect(romex, isNotNull);
    expect(romex!.item.trade, 'Electrical');

    final pex = matchReceiptLineToCatalog('1/2IN PEX BALL VALVE');
    expect(pex, isNotNull);
    expect(pex!.item.trade, 'Plumbing');

    final appliancePaint = matchReceiptLineToCatalog(
      '12 OZ APPLIANCE EPOXY SPRAY PAINT',
    );
    expect(appliancePaint, isNotNull);
    expect(appliancePaint!.item.trade, 'Painting');

    final garage = matchReceiptLineToCatalog(
      '3/4 HP BELT DRIVE GARAGE DOOR OPENER',
    );
    expect(garage, isNotNull);
    expect(garage!.item.trade, 'Garage Doors and Openers');
  });
}
