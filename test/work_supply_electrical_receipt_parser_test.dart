import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('electrical parser understands NM-B and THHN wire shorthand', () {
    final romex = matchReceiptLineToCatalog('HD ROMEX 12-2 WG 250FT');
    expect(romex, isNotNull);
    expect(romex!.item.name, '12/2 NM-B Cable');
    expect(romex.confidenceLevel, ReceiptConfidenceLevel.good);

    final thhn = matchReceiptLineToCatalog('LOWES 12 AWG THHN WIRE RED');
    expect(thhn, isNotNull);
    expect(thhn!.item.name, '12 AWG THHN Wire');
    expect(thhn.item.trade, 'Electrical');
  });

  test('electrical parser separates receptacles from breakers', () {
    final gfciOutlet = matchReceiptLineToCatalog('20A GFI OUTLET WHITE');
    expect(gfciOutlet, isNotNull);
    expect(gfciOutlet!.item.name, '20 Amp GFCI Outlet');

    final breaker = matchReceiptLineToCatalog('20A 1P BRKR');
    expect(breaker, isNotNull);
    expect(breaker!.item.name, '20 Amp Single-Pole Breaker');
  });

  test('electrical parser separates EMT fittings and wire connectors', () {
    final connector = matchReceiptLineToCatalog('1/2 EMT SET SCREW CONN');
    expect(connector, isNotNull);
    expect(connector!.item.name, '1/2 in EMT Connector');

    final coupling = matchReceiptLineToCatalog('3/4 EMT CPLG SET SCREW');
    expect(coupling, isNotNull);
    expect(coupling!.item.name, '3/4 in EMT Coupling');

    final wireNut = matchReceiptLineToCatalog('WINGED WIRE NUT 100PK');
    expect(wireNut, isNotNull);
    expect(wireNut!.item.name, contains('Winged'));
    expect(wireNut.item.name, contains('100 Pack'));
    expect(wireNut.item.name, contains('Wire Connector'));
  });

  test('electrical generated pack covers common service stock at scale', () {
    final electricalItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Electrical')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Electrical',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(electricalItems.length, greaterThanOrEqualTo(10000));
    expect(fullPack.itemCount, electricalItems.length);
    expect(
      electricalItems.any(
        (item) => item.name == '12 AWG Red 500 ft THHN Copper Wire',
      ),
      isTrue,
    );
    expect(
      electricalItems.any(
        (item) =>
            item.name == '20 Amp GFCI Single-Pole Specialty Circuit Breaker',
      ),
      isTrue,
    );
    expect(
      electricalItems.any(
        (item) => item.name == '1/2 in Set Screw Connector EMT Raceway Part',
      ),
      isTrue,
    );
  });

  test('electrical parser reaches generated bulk catalog families', () {
    final mcCable = matchReceiptLineToCatalog('12-2 MC CABLE 250FT');
    expect(mcCable, isNotNull);
    expect(mcCable!.item.trade, 'Electrical');
    expect(mcCable.item.name, contains('Armored Cable'));

    final racewayBody = matchReceiptLineToCatalog('PVC 3/4 LB BODY');
    expect(racewayBody, isNotNull);
    expect(racewayBody!.item.trade, 'Electrical');
    expect(racewayBody.item.name, contains('Conduit Body Assembly'));

    final devicePack = matchReceiptLineToCatalog('20A GFCI RECEPT WHITE 10PK');
    expect(devicePack, isNotNull);
    expect(devicePack!.item.trade, 'Electrical');
    expect(devicePack.item.name, contains('Wiring Device'));
  });

  test(
    'electrical parser understands service accessories and safety devices',
    () {
      final smokeCo = matchReceiptLineToCatalog('COMBO SMOKE CO ALARM');
      expect(smokeCo, isNotNull);
      expect(smokeCo!.item.trade, 'Electrical');
      expect(smokeCo.item.name, contains('Smoke and Carbon Monoxide Alarm'));

      final fanBrace = matchReceiptLineToCatalog('OLD WORK CEILING FAN BRACE');
      expect(fanBrace, isNotNull);
      expect(fanBrace!.item.trade, 'Electrical');
      expect(fanBrace.item.name, contains('Fixture Support Box'));

      final lbCover = matchReceiptLineToCatalog('3/4 LB BODY COVER GASKET');
      expect(lbCover, isNotNull);
      expect(lbCover!.item.trade, 'Electrical');
      expect(lbCover.item.name, contains('Conduit Body Assembly'));

      final groundBar = matchReceiptLineToCatalog('200A GROUND BAR KIT');
      expect(groundBar, isNotNull);
      expect(groundBar!.item.trade, 'Electrical');
      expect(groundBar.item.name, contains('Panel Accessory'));

      final weatherhead = matchReceiptLineToCatalog(
        '2 IN WEATHERHEAD SERVICE HEAD',
      );
      expect(weatherhead, isNotNull);
      expect(weatherhead!.item.trade, 'Electrical');
      expect(weatherhead.item.name, contains('Service Entrance Accessory'));
    },
  );

  test('electrical parser understands common service device upgrades', () {
    final wrGfci = matchReceiptLineToCatalog(
      '20A WR GFCI RECEPTACLE WHITE',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(wrGfci, isNotNull);
    expect(wrGfci!.item.trade, 'Electrical');
    expect(wrGfci.item.name, contains('GFCI'));

    final dualBreaker = matchReceiptLineToCatalog(
      '20A 1P DUAL FUNCTION AFCI GFCI BREAKER',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(dualBreaker, isNotNull);
    expect(dualBreaker!.item.trade, 'Electrical');
    expect(dualBreaker.item.name, contains('Dual Function'));

    final surge = matchReceiptLineToCatalog(
      'WHOLE HOME SURGE PROTECTIVE DEVICE',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(surge, isNotNull);
    expect(surge!.item.trade, 'Electrical');
    expect(surge.item.name, contains('Surge'));
  });

  test('electrical parser understands low voltage and box service stock', () {
    final doorbell = matchReceiptLineToCatalog(
      '16V DOORBELL TRANSFORMER',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(doorbell, isNotNull);
    expect(doorbell!.item.trade, 'Electrical');
    expect(doorbell.item.name, contains('Doorbell Transformer'));

    final lvBracket = matchReceiptLineToCatalog(
      'LOW VOLTAGE BRACKET SINGLE GANG',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(lvBracket, isNotNull);
    expect(lvBracket!.item.trade, 'Electrical');
    expect(lvBracket.item.name, contains('Box Accessory'));

    final bubbleCover = matchReceiptLineToCatalog(
      '1 GANG EXTRA DUTY BUBBLE COVER',
      tradeScope: 'Electrical',
      maxCandidates: 120,
    );
    expect(bubbleCover, isNotNull);
    expect(bubbleCover!.item.trade, 'Electrical');
    expect(bubbleCover.item.name, contains('Weatherproof'));
  });
}
