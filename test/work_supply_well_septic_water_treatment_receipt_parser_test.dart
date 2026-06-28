import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('well septic generated pack covers receipt-realistic stock', () {
    final items = workSupplyCatalogItems
        .where((item) => item.trade == 'Well Septic and Water Treatment')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Well Septic and Water Treatment',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(items.length, greaterThanOrEqualTo(400));
    expect(fullPack.itemCount, items.length);
    expect(
      items.any(
        (item) =>
            item.name ==
            'Standard 3/4 HP 230V Submersible Well Pump Well Pump Part',
      ),
      isTrue,
    );
    expect(
      items.any(
        (item) =>
            item.name ==
            'Standard 4.5 x 20 in 5 Micron Sediment Filter Cartridge Water Filter Part',
      ),
      isTrue,
    );
  });

  test('well septic parser understands pumps tanks and fittings', () {
    final pump = matchReceiptLineToCatalog(
      '3/4 HP 230V SUBMERSIBLE WELL PUMP',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(pump, isNotNull);
    expect(pump!.item.trade, 'Well Septic and Water Treatment');
    expect(pump.item.name, contains('Submersible Well Pump'));

    final tank = matchReceiptLineToCatalog(
      '44 GAL PRE CHARGED PRESSURE TANK',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(tank, isNotNull);
    expect(tank!.item.trade, 'Well Septic and Water Treatment');
    expect(tank.item.name, contains('44 gal Pre Charged Pressure Tank'));

    final pitless = matchReceiptLineToCatalog(
      '1IN PITLESS ADAPTER',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(pitless, isNotNull);
    expect(pitless!.item.trade, 'Well Septic and Water Treatment');
    expect(pitless.item.name, contains('1 in Pitless Adapter'));
  });

  test('well septic parser understands treatment cartridges and uv', () {
    final filter = matchReceiptLineToCatalog(
      '4.5X20 5 MICRON SEDIMENT FILTER CARTRIDGE',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(filter, isNotNull);
    expect(filter!.item.trade, 'Well Septic and Water Treatment');
    expect(filter.item.name, contains('5 Micron Sediment Filter Cartridge'));

    final softener = matchReceiptLineToCatalog(
      '48K GRAIN WATER SOFTENER',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(softener, isNotNull);
    expect(softener!.item.trade, 'Well Septic and Water Treatment');
    expect(softener.item.name, contains('48K Grain Water Softener'));

    final uv = matchReceiptLineToCatalog(
      '25W UV LAMP',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(uv, isNotNull);
    expect(uv!.item.trade, 'Well Septic and Water Treatment');
    expect(uv.item.name, contains('25W UV Lamp'));
  });

  test('well septic parser understands septic and water testing', () {
    final riser = matchReceiptLineToCatalog(
      '24IN X 12IN SEPTIC TANK RISER',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(riser, isNotNull);
    expect(riser!.item.trade, 'Well Septic and Water Treatment');
    expect(riser.item.name, contains('Septic Tank Riser'));

    final chamber = matchReceiptLineToCatalog(
      '22X48 LEACH FIELD CHAMBER',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(chamber, isNotNull);
    expect(chamber!.item.trade, 'Well Septic and Water Treatment');
    expect(chamber.item.name, contains('Leach Field Chamber'));

    final testKit = matchReceiptLineToCatalog(
      'WATER HARDNESS TEST KIT',
      tradeScope: 'Well Septic and Water Treatment',
      maxCandidates: 220,
    );
    expect(testKit, isNotNull);
    expect(testKit!.item.trade, 'Well Septic and Water Treatment');
    expect(testKit.item.name, contains('Water Hardness Test Kit'));
  });

  test('well septic does not steal neighboring trade receipts', () {
    final pex = matchReceiptLineToCatalog('1/2IN PEX BALL VALVE');
    expect(pex, isNotNull);
    expect(pex!.item.trade, 'Plumbing');

    final hvacPump = matchReceiptLineToCatalog('LITTLE PUMP COND PUMP 115V');
    expect(hvacPump, isNotNull);
    expect(hvacPump!.item.trade, 'HVAC');

    final appliance = matchReceiptLineToCatalog(
      '6FT 3/8 COMPRESSION DISHWASHER CONNECTOR KIT',
    );
    expect(appliance, isNotNull);
    expect(appliance!.item.trade, 'Appliance Installation and Repair');
  });
}
