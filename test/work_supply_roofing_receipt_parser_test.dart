import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('roofing parser understands shingles underlayment and edge metal', () {
    final shingles = matchReceiptLineToCatalog(
      'ARCHITECTURAL SHINGLE BUNDLE WEATHERED WOOD',
    );
    expect(shingles, isNotNull);
    expect(shingles!.item.trade, 'Roofing');
    expect(shingles.item.name.toLowerCase(), contains('architectural bundle'));
    expect(shingles.item.name, contains('Asphalt Shingles'));
    expect(shingles.confidenceLevel, ReceiptConfidenceLevel.good);

    final underlayment = matchReceiptLineToCatalog(
      'SYNTHETIC UNDERLAYMENT 10 SQ',
    );
    expect(underlayment, isNotNull);
    expect(underlayment!.item.trade, 'Roofing');
    expect(underlayment.item.name.toLowerCase(), contains('synthetic 10'));
    expect(underlayment.item.name, contains('Roof Underlayment'));

    final dripEdge = matchReceiptLineToCatalog('10FT WHITE DRIP EDGE');
    expect(dripEdge, isNotNull);
    expect(dripEdge!.item.trade, 'Roofing');
    expect(dripEdge.item.name.toLowerCase(), contains('white'));
    expect(dripEdge.item.name, contains('Drip Edge'));
  });

  test('roofing parser understands flashing vents gutters and fasteners', () {
    final pipeBoot = matchReceiptLineToCatalog('3 IN RUBBER PIPE BOOT');
    expect(pipeBoot, isNotNull);
    expect(pipeBoot!.item.trade, 'Roofing');
    expect(pipeBoot.item.name, contains('3 in'));
    expect(pipeBoot.item.name, contains('Pipe Boot Flashing'));

    final gutter = matchReceiptLineToCatalog('WHITE 5 IN K STYLE GUTTER 10 FT');
    expect(gutter, isNotNull);
    expect(gutter!.item.trade, 'Roofing');
    expect(gutter.item.name, contains('5 in'));
    expect(gutter.item.name, contains('10 ft'));
    expect(gutter.item.name, contains('Gutter'));

    final nail = matchReceiptLineToCatalog('1-1/4 ROOFING NAIL GALV');
    expect(nail, isNotNull);
    expect(nail!.item.trade, 'Roofing');
    expect(nail.item.name, contains('1-1/4 in Galvanized Roofing Nail'));
  });

  test('roofing generated pack covers receipt-realistic roofing stock', () {
    final roofingItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Roofing')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Roofing',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(roofingItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, roofingItems.length);
    expect(
      roofingItems.any(
        (item) =>
            item.name ==
            'Weathered Wood Architectural Shingle Bundle Roof Covering',
      ),
      isTrue,
    );
    expect(
      roofingItems.any(
        (item) =>
            item.name ==
            'Galvanized 4 x 4 x 8 in Step Flashing 50 Pack Roof Flashing Metal',
      ),
      isTrue,
    );
  });

  test('roofing parser reaches generated bulk roofing families', () {
    final starter = matchReceiptLineToCatalog(
      'BLACK STARTER STRIP SHINGLE BUNDLE',
    );
    expect(starter, isNotNull);
    expect(starter!.item.trade, 'Roofing');
    expect(starter.item.name, contains('Starter Strip'));

    final flashing = matchReceiptLineToCatalog('GALV STEP FLASHING 4X4X8 50PK');
    expect(flashing, isNotNull);
    expect(flashing!.item.trade, 'Roofing');
    expect(flashing.item.name, contains('Step Flashing'));
    expect(flashing.item.name, contains('50 Pack'));

    final roofSealant = matchReceiptLineToCatalog('28OZ BLACK ROOF SEALANT');
    expect(roofSealant, isNotNull);
    expect(roofSealant!.item.trade, 'Roofing');
    expect(roofSealant.item.name, contains('28 oz Black Roof Sealant'));
  });

  test('roofing parser understands deck repair and metal roof accessories', () {
    final decking = matchReceiptLineToCatalog('23/32 OSB ROOF SHEATHING');
    expect(decking, isNotNull);
    expect(decking!.item.trade, 'Roofing');
    expect(decking.item.name, contains('Roof Deck Repair Material'));

    final hClip = matchReceiptLineToCatalog('ROOF H CLIP PANEL SPACER PACK');
    expect(hClip, isNotNull);
    expect(hClip!.item.trade, 'Roofing');
    expect(hClip.item.name, contains('H-Clip Panel Spacer'));

    final ridgeCap = matchReceiptLineToCatalog('BLACK METAL ROOF RIDGE CAP');
    expect(ridgeCap, isNotNull);
    expect(ridgeCap!.item.trade, 'Roofing');
    expect(ridgeCap.item.name, contains('Ridge Cap'));

    final closure = matchReceiptLineToCatalog('FOAM CLOSURE STRIP OUTSIDE');
    expect(closure, isNotNull);
    expect(closure!.item.trade, 'Roofing');
    expect(closure.item.name, contains('Closure Strip'));
  });

  test(
    'roofing parser understands soffit fascia low slope and specialty flashing',
    () {
      final soffit = matchReceiptLineToCatalog('WHITE VENTED SOFFIT PANEL');
      expect(soffit, isNotNull);
      expect(soffit!.item.trade, 'Roofing');
      expect(soffit.item.name, contains('Vented'));
      expect(soffit.item.name, contains('Soffit Panel'));

      final fascia = matchReceiptLineToCatalog(
        '8IN WHITE ALUMINUM FASCIA COVER',
      );
      expect(fascia, isNotNull);
      expect(fascia!.item.trade, 'Roofing');
      expect(fascia.item.name, contains('8 in'));
      expect(fascia.item.name, contains('Fascia Cover'));

      final epdm = matchReceiptLineToCatalog('EPDM PATCH KIT');
      expect(epdm, isNotNull);
      expect(epdm!.item.trade, 'Roofing');
      expect(epdm.item.name, contains('EPDM Patch Kit'));

      final tpoTape = matchReceiptLineToCatalog('TPO SEAM TAPE ROLL');
      expect(tpoTape, isNotNull);
      expect(tpoTape!.item.trade, 'Roofing');
      expect(tpoTape.item.name, contains('TPO Seam Tape Roll'));

      final roofJack = matchReceiptLineToCatalog('3IN GALV ROOF JACK');
      expect(roofJack, isNotNull);
      expect(roofJack!.item.trade, 'Roofing');
      expect(roofJack.item.name, contains('Roof Jack'));

      final stormCollar = matchReceiptLineToCatalog('4IN STORM COLLAR');
      expect(stormCollar, isNotNull);
      expect(stormCollar!.item.trade, 'Roofing');
      expect(stormCollar.item.name, contains('Storm Collar'));
    },
  );

  test(
    'roofing parser understands repair tape gutter protection and safety',
    () {
      final repairShingle = matchReceiptLineToCatalog(
        'WEATHERED WOOD SHINGLE REPAIR PATCH PACK',
      );
      expect(repairShingle, isNotNull);
      expect(repairShingle!.item.trade, 'Roofing');
      expect(repairShingle.item.name, contains('Shingle Repair Patch Pack'));

      final repairTape = matchReceiptLineToCatalog(
        '6IN PEEL AND STICK ROOF REPAIR TAPE',
      );
      expect(repairTape, isNotNull);
      expect(repairTape!.item.trade, 'Roofing');
      expect(repairTape.item.name, contains('Peel and Stick Roof Repair Tape'));

      final gutterGuard = matchReceiptLineToCatalog(
        '4FT MICRO MESH GUTTER GUARD',
      );
      expect(gutterGuard, isNotNull);
      expect(gutterGuard!.item.trade, 'Roofing');
      expect(gutterGuard.item.name, contains('Micro Mesh Gutter Guard'));

      final heatCable = matchReceiptLineToCatalog(
        '80FT ROOF AND GUTTER HEAT CABLE',
      );
      expect(heatCable, isNotNull);
      expect(heatCable!.item.trade, 'Roofing');
      expect(heatCable.item.name, contains('Roof and Gutter Heat Cable'));

      final roofAnchor = matchReceiptLineToCatalog('RIDGE ROOF ANCHOR');
      expect(roofAnchor, isNotNull);
      expect(roofAnchor!.item.trade, 'Roofing');
      expect(roofAnchor.item.name, contains('Ridge Roof Anchor'));
    },
  );

  test('roofing parser understands chimney skylight and vent cap supplies', () {
    final chimneyFlashing = matchReceiptLineToCatalog(
      'COPPER CHIMNEY COUNTER FLASHING',
    );
    expect(chimneyFlashing, isNotNull);
    expect(chimneyFlashing!.item.trade, 'Roofing');
    expect(chimneyFlashing.item.name, contains('Chimney Counter Flashing'));

    final sidewall = matchReceiptLineToCatalog('BLACK SIDEWALL FLASHING');
    expect(sidewall, isNotNull);
    expect(sidewall!.item.trade, 'Roofing');
    expect(sidewall.item.name, contains('Sidewall Flashing'));

    final chimneyCap = matchReceiptLineToCatalog('6IN CHIMNEY RAIN CAP');
    expect(chimneyCap, isNotNull);
    expect(chimneyCap!.item.trade, 'Roofing');
    expect(chimneyCap.item.name, contains('Chimney Rain Cap'));

    final birdScreen = matchReceiptLineToCatalog('VENT CAP BIRD SCREEN');
    expect(birdScreen, isNotNull);
    expect(birdScreen!.item.trade, 'Roofing');
    expect(birdScreen.item.name, contains('Bird Screen'));
  });

  test('roofing parser understands expanded detail stock receipts', () {
    final ridge = matchReceiptLineToCatalog(
      'CHARCOAL HIP AND RIDGE CAP SHINGLE BUNDLE',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(ridge, isNotNull);
    expect(ridge!.item.trade, 'Roofing');
    expect(ridge.item.name, contains('Charcoal'));
    expect(ridge.item.name, contains('Hip and Ridge Cap Shingle Bundle'));

    final iceShield = matchReceiptLineToCatalog(
      '5 SQ ICE AND WATER SHIELD',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(iceShield, isNotNull);
    expect(iceShield!.item.trade, 'Roofing');
    expect(iceShield.item.name, contains('5 sq Ice and Water Shield'));

    final pipeBoot = matchReceiptLineToCatalog(
      '4IN SILICONE PIPE BOOT FLASHING',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(pipeBoot, isNotNull);
    expect(pipeBoot!.item.trade, 'Roofing');
    expect(pipeBoot.item.name, contains('4 in Silicone Pipe Boot Flashing'));

    final screw = matchReceiptLineToCatalog(
      'BLACK 1-1/2 METAL ROOFING SCREW 250PK',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(screw, isNotNull);
    expect(screw!.item.trade, 'Roofing');
    expect(screw.item.name, contains('Black'));
    expect(screw.item.name, contains('1-1/2 in'));
    expect(screw.item.name, contains('Metal Roofing Screw'));

    final fascia = matchReceiptLineToCatalog(
      'BROWN 10IN ALUMINUM FASCIA COVER',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(fascia, isNotNull);
    expect(fascia!.item.trade, 'Roofing');
    expect(fascia.item.name, contains('Brown'));
    expect(fascia.item.name, contains('10 in'));
    expect(fascia.item.name, contains('Aluminum Fascia Cover'));

    final coating = matchReceiptLineToCatalog(
      '5 GAL SILICONE ROOF COATING',
      tradeScope: 'Roofing',
      maxCandidates: 180,
    );
    expect(coating, isNotNull);
    expect(coating!.item.trade, 'Roofing');
    expect(coating.item.name, contains('5 gal Silicone Roof Coating'));
  });

}
