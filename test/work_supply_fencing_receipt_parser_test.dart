import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('fencing parser understands wood vinyl and chain link materials', () {
    final picket = matchReceiptLineToCatalog('6FT DOG EAR WOOD FENCE PICKET');
    expect(picket, isNotNull);
    expect(picket!.item.trade, 'Fencing');
    expect(picket.item.name, contains('Dog Ear'));
    expect(picket.item.name, contains('Picket'));
    expect(picket.confidenceLevel, ReceiptConfidenceLevel.good);

    final vinyl = matchReceiptLineToCatalog('WHITE VINYL PRIVACY PANEL 6X8');
    expect(vinyl, isNotNull);
    expect(vinyl!.item.trade, 'Fencing');
    expect(vinyl.item.name, contains('Vinyl'));
    expect(vinyl.item.name, contains('Privacy Panel'));

    final chainLink = matchReceiptLineToCatalog('CHAINLINK FABRIC 4FT X 50FT');
    expect(chainLink, isNotNull);
    expect(chainLink!.item.trade, 'Fencing');
    expect(chainLink.item.name, contains('4 ft x 50 ft'));
    expect(chainLink.item.name, contains('Chain Link'));
  });

  test(
    'fencing parser understands posts hardware wire and setting supplies',
    () {
      final tPost = matchReceiptLineToCatalog('7FT GREEN T POST');
      expect(tPost, isNotNull);
      expect(tPost!.item.trade, 'Fencing');
      expect(tPost.item.name, contains('7 ft'));
      expect(tPost.item.name, contains('T-Post'));

      final latch = matchReceiptLineToCatalog('LOCKABLE GATE LATCH');
      expect(latch, isNotNull);
      expect(latch!.item.trade, 'Fencing');
      expect(latch.item.name, contains('Gate Latch'));

      final concrete = matchReceiptLineToCatalog('60LB FENCE POST CONCRETE');
      expect(concrete, isNotNull);
      expect(concrete!.item.trade, 'Fencing');
      expect(concrete.item.name, contains('60 lb'));
      expect(concrete.item.name, contains('Concrete'));
    },
  );

  test('fencing generated pack covers receipt-realistic service stock', () {
    final fencingItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Fencing')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Fencing',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(fencingItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, fencingItems.length);
    expect(
      fencingItems.any(
        (item) =>
            item.name ==
            '3/4 in x 5-1/2 in x 6 ft Dog Ear Cedar Picket Wood Fence Material',
      ),
      isTrue,
    );
    expect(
      fencingItems.any(
        (item) =>
            item.name ==
            '4 ft x 50 ft Black Vinyl Coated Chain Link Fabric Chain Link Fence Material',
      ),
      isTrue,
    );
  });

  test('fencing parser reaches generated bulk fencing families', () {
    final cedarPicket = matchReceiptLineToCatalog(
      '3/4 X 5-1/2 X 6FT DOG EAR CEDAR PICKET',
    );
    expect(cedarPicket, isNotNull);
    expect(cedarPicket!.item.trade, 'Fencing');
    expect(cedarPicket.item.name, contains('Cedar'));
    expect(cedarPicket.item.name, contains('Dog Ear'));
    expect(cedarPicket.item.name, contains('Picket'));

    final coatedChainLink = matchReceiptLineToCatalog(
      '4FT X 50FT BLACK VINYL CHAIN LINK FABRIC',
    );
    expect(coatedChainLink, isNotNull);
    expect(coatedChainLink!.item.trade, 'Fencing');
    expect(coatedChainLink.item.name, contains('Black Vinyl Coated'));
    expect(coatedChainLink.item.name, contains('Chain Link Fabric'));

    final tPostClips = matchReceiptLineToCatalog('T-POST CLIP 25PK');
    expect(tPostClips, isNotNull);
    expect(tPostClips!.item.trade, 'Fencing');
    expect(tPostClips.item.name, contains('T-Post Clip'));
    expect(tPostClips.item.name, contains('25 Pack'));

    final tensionBand = matchReceiptLineToCatalog(
      '1-5/8 CHAIN LINK TENSION BAND',
    );
    expect(tensionBand, isNotNull);
    expect(tensionBand!.item.trade, 'Fencing');
    expect(tensionBand.item.name, contains('1-5/8 in'));
    expect(tensionBand.item.name, contains('Tension Band'));
  });

  test(
    'fencing parser understands gates ornamental panels and repair parts',
    () {
      final farmGate = matchReceiptLineToCatalog('12FT GALV TUBE FARM GATE');
      expect(farmGate, isNotNull);
      expect(farmGate!.item.trade, 'Fencing');
      expect(farmGate.item.name, contains('Farm Gate'));

      final ornamental = matchReceiptLineToCatalog(
        '4FT X 6FT BLACK ALUMINUM FENCE PANEL',
      );
      expect(ornamental, isNotNull);
      expect(ornamental!.item.trade, 'Fencing');
      expect(ornamental.item.name, contains('Black Aluminum Fence Panel'));

      final postCap = matchReceiptLineToCatalog('4X4 BLACK FENCE POST CAP');
      expect(postCap, isNotNull);
      expect(postCap!.item.trade, 'Fencing');
      expect(postCap.item.name, contains('Post Cap'));

      final ties = matchReceiptLineToCatalog('CHAIN LINK FENCE TIE 100PK');
      expect(ties, isNotNull);
      expect(ties!.item.trade, 'Fencing');
      expect(ties.item.name, contains('Fence Tie'));
    },
  );

  test('fencing parser understands electric fence supplies', () {
    final charger = matchReceiptLineToCatalog('10 MILE ELECTRIC FENCE CHARGER');
    expect(charger, isNotNull);
    expect(charger!.item.trade, 'Fencing');
    expect(charger.item.name, contains('Electric Fence Charger'));

    final insulator = matchReceiptLineToCatalog(
      'T-POST ELECTRIC FENCE INSULATOR 25PK',
    );
    expect(insulator, isNotNull);
    expect(insulator!.item.trade, 'Fencing');
    expect(insulator.item.name, contains('Electric Fence Insulator'));

    final tester = matchReceiptLineToCatalog('FENCE VOLTAGE TESTER');
    expect(tester, isNotNull);
    expect(tester!.item.trade, 'Fencing');
    expect(tester.item.name, contains('Voltage Tester'));
  });

  test('fencing parser understands privacy screen and barrier supplies', () {
    final slats = matchReceiptLineToCatalog(
      'BLACK CHAIN LINK PRIVACY SLAT KIT 6FT',
    );
    expect(slats, isNotNull);
    expect(slats!.item.trade, 'Fencing');
    expect(slats.item.name, contains('Privacy Slat Kit'));

    final screen = matchReceiptLineToCatalog('GREEN 6FT X 50FT FENCE SCREEN');
    expect(screen, isNotNull);
    expect(screen!.item.trade, 'Fencing');
    expect(screen.item.name, contains('Fence Privacy Screen'));

    final safetyFence = matchReceiptLineToCatalog(
      '4FT X 100FT ORANGE SAFETY FENCE',
    );
    expect(safetyFence, isNotNull);
    expect(safetyFence!.item.trade, 'Fencing');
    expect(safetyFence.item.name, contains('Orange Safety Fence'));

    final siltFence = matchReceiptLineToCatalog('36IN X 100FT SILT FENCE');
    expect(siltFence, isNotNull);
    expect(siltFence!.item.trade, 'Fencing');
    expect(siltFence.item.name, contains('Silt Fence Fabric'));
  });

  test('fencing parser understands anchors pool fence and gate controls', () {
    final postAnchor = matchReceiptLineToCatalog('4X4 POST BASE ANCHOR');
    expect(postAnchor, isNotNull);
    expect(postAnchor!.item.trade, 'Fencing');
    expect(postAnchor.item.name, contains('Post Base Anchor'));

    final railBracket = matchReceiptLineToCatalog('2X4 FENCE RAIL BRACKET');
    expect(railBracket, isNotNull);
    expect(railBracket!.item.trade, 'Fencing');
    expect(railBracket.item.name, contains('Fence Rail Bracket'));

    final poolLatch = matchReceiptLineToCatalog('MAGNETIC POOL GATE LATCH');
    expect(poolLatch, isNotNull);
    expect(poolLatch!.item.trade, 'Fencing');
    expect(poolLatch.item.name, contains('Pool Gate Latch'));

    final keypad = matchReceiptLineToCatalog('GATE OPENER KEYPAD');
    expect(keypad, isNotNull);
    expect(keypad!.item.trade, 'Fencing');
    expect(keypad.item.name, contains('Gate Opener Keypad'));
  });

  test('fencing parser understands expanded detail stock receipts', () {
    final redwoodPicket = matchReceiptLineToCatalog(
      '1X6X8 REDWOOD PRIVACY BOARD',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(redwoodPicket, isNotNull);
    expect(redwoodPicket!.item.trade, 'Fencing');
    expect(redwoodPicket.item.name, contains('Redwood Privacy Board'));

    final vinylPanel = matchReceiptLineToCatalog(
      'TAN VINYL 6X8 LATTICE TOP PANEL',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(vinylPanel, isNotNull);
    expect(vinylPanel!.item.trade, 'Fencing');
    expect(vinylPanel.item.name, contains('Tan'));
    expect(vinylPanel.item.name, contains('Vinyl'));
    expect(vinylPanel.item.name, contains('6 ft x 8 ft'));
    expect(vinylPanel.item.name, contains('Lattice Top Panel'));

    final chainPost = matchReceiptLineToCatalog(
      '2IN X 8FT CHAIN LINK LINE POST',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(chainPost, isNotNull);
    expect(chainPost!.item.trade, 'Fencing');
    expect(chainPost.item.name, contains('2 in x 8 ft'));
    expect(chainPost.item.name, contains('Line Post'));

    final gateKit = matchReceiptLineToCatalog(
      '6FT WOOD FENCE GATE KIT',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(gateKit, isNotNull);
    expect(gateKit!.item.trade, 'Fencing');
    expect(gateKit.item.name, contains('6 ft Wood Fence Gate Kit'));

    final privacyScreen = matchReceiptLineToCatalog(
      'BLACK 8FT X 50FT FENCE PRIVACY SCREEN',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(privacyScreen, isNotNull);
    expect(privacyScreen!.item.trade, 'Fencing');
    expect(privacyScreen.item.name, contains('Black 8 ft x 50 ft'));
    expect(privacyScreen.item.name, contains('Fence Privacy Screen'));

    final charger = matchReceiptLineToCatalog(
      '30 MILE ELECTRIC FENCE CHARGER',
      tradeScope: 'Fencing',
      maxCandidates: 180,
    );
    expect(charger, isNotNull);
    expect(charger!.item.trade, 'Fencing');
    expect(charger.item.name, contains('30 Mile Electric Fence Charger'));
  });

  test('fencing parser understands expanded field stock receipts', () {
    final composite = matchReceiptLineToCatalog(
      'GRAY 1X6X8 COMPOSITE PRIVACY BOARD',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(composite, isNotNull);
    expect(composite!.item.trade, 'Fencing');
    expect(composite.item.name, contains('Gray'));
    expect(composite.item.name, contains('Composite Privacy Board'));

    final gaugeFabric = matchReceiptLineToCatalog(
      '6FT X 50FT 9GA BLACK VINYL CHAIN LINK FABRIC',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(gaugeFabric, isNotNull);
    expect(gaugeFabric!.item.trade, 'Fencing');
    expect(gaugeFabric.item.name, contains('9 gauge'));
    expect(gaugeFabric.item.name, contains('Black Vinyl Coated'));

    final hogRing = matchReceiptLineToCatalog(
      'CHAIN LINK HOG RING 100PK',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(hogRing, isNotNull);
    expect(hogRing!.item.trade, 'Fencing');
    expect(hogRing.item.name, contains('Hog Ring 100 Pack'));

    final poultry = matchReceiptLineToCatalog(
      '48IN X 100FT POULTRY NETTING',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(poultry, isNotNull);
    expect(poultry!.item.trade, 'Fencing');
    expect(poultry.item.name, contains('48 in x 100 ft Poultry Netting'));

    final polyWire = matchReceiptLineToCatalog(
      '1320FT ELECTRIC FENCE POLY WIRE',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(polyWire, isNotNull);
    expect(polyWire!.item.trade, 'Fencing');
    expect(polyWire.item.name, contains('1320 ft Electric Fence Poly Wire'));

    final photoEye = matchReceiptLineToCatalog(
      'GATE OPENER PHOTO EYE SENSOR',
      tradeScope: 'Fencing',
      maxCandidates: 220,
    );
    expect(photoEye, isNotNull);
    expect(photoEye!.item.trade, 'Fencing');
    expect(photoEye.item.name, contains('Gate Opener Photo Eye Sensor'));
  });
}
