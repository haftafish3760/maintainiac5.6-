import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('tile parser understands tile thinset grout and waterproofing', () {
    final porcelain = matchReceiptLineToCatalog('12X24 PORCELAIN FLOOR TILE');
    expect(porcelain, isNotNull);
    expect(porcelain!.item.trade, 'Tile');
    expect(porcelain.item.name, contains('12 x 24 in Porcelain Floor Tile'));
    expect(porcelain.confidenceLevel, ReceiptConfidenceLevel.good);

    final thinset = matchReceiptLineToCatalog('50 LB GRAY MODIFIED THINSET');
    expect(thinset, isNotNull);
    expect(thinset!.item.trade, 'Tile');
    expect(thinset.item.name, contains('50 lb Gray Modified Thinset Mortar'));

    final grout = matchReceiptLineToCatalog('10 LB CHARCOAL SANDED GROUT');
    expect(grout, isNotNull);
    expect(grout!.item.trade, 'Tile');
    expect(grout.item.name, contains('10 lb'));
    expect(grout.item.name, contains('Sanded Grout'));
  });

  test('tile parser understands shower systems and layout accessories', () {
    final membrane = matchReceiptLineToCatalog('3FT X 33FT SHOWER MEMBRANE');
    expect(membrane, isNotNull);
    expect(membrane!.item.trade, 'Tile');
    expect(membrane.item.name, contains('3 ft x 33 ft'));
    expect(membrane.item.name, contains('Waterproofing Membrane'));

    final linearDrain = matchReceiptLineToCatalog('36 IN LINEAR SHOWER DRAIN');
    expect(linearDrain, isNotNull);
    expect(linearDrain!.item.trade, 'Tile');
    expect(linearDrain.item.name, contains('36 in Linear Shower Drain'));

    final spacer = matchReceiptLineToCatalog('1/8 IN TILE LEVELING CLIPS');
    expect(spacer, isNotNull);
    expect(spacer!.item.trade, 'Tile');
    expect(spacer.item.name, contains('1/8 in Tile Leveling Clip'));
  });

  test('tile generated pack covers receipt-realistic tile stock', () {
    final tileItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Tile')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Tile',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(tileItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, tileItems.length);
    expect(
      tileItems.any(
        (item) => item.name == '12 x 24 in Matte Porcelain Floor Tile Box',
      ),
      isTrue,
    );
    expect(
      tileItems.any(
        (item) => item.name == '50 lb Gray LFT Mortar Tile Setting Supply',
      ),
      isTrue,
    );
  });

  test('tile parser reaches generated bulk tile families', () {
    final matteTile = matchReceiptLineToCatalog(
      '12X24 MATTE PORCELAIN FLOOR TILE',
    );
    expect(matteTile, isNotNull);
    expect(matteTile!.item.trade, 'Tile');
    expect(matteTile.item.name, contains('12 x 24 in'));
    expect(matteTile.item.name, contains('Matte Porcelain'));

    final lftMortar = matchReceiptLineToCatalog('50LB GRAY LFT MORTAR');
    expect(lftMortar, isNotNull);
    expect(lftMortar!.item.trade, 'Tile');
    expect(lftMortar.item.name, contains('50 lb Gray'));
    expect(lftMortar.item.name, contains('LFT Mortar'));

    final epoxyGrout = matchReceiptLineToCatalog('1QT CHARCOAL EPOXY GROUT');
    expect(epoxyGrout, isNotNull);
    expect(epoxyGrout!.item.trade, 'Tile');
    expect(epoxyGrout.item.name, contains('1 qt Charcoal'));
    expect(epoxyGrout.item.name, contains('Epoxy Grout'));

    final blackDrain = matchReceiptLineToCatalog(
      '36IN MATTE BLACK LINEAR SHOWER DRAIN',
    );
    expect(blackDrain, isNotNull);
    expect(blackDrain!.item.trade, 'Tile');
    expect(blackDrain.item.name, contains('36 in Matte Black'));

    final trim = matchReceiptLineToCatalog('8FT BRUSHED NICKEL SCHLUTER TRIM');
    expect(trim, isNotNull);
    expect(trim!.item.trade, 'Tile');
    expect(trim.item.name, contains('8 ft Brushed Nickel'));
    expect(
      trim.item.name,
      anyOf(contains('Profile'), contains('Tile Edge Trim')),
    );
  });

  test('tile parser understands shower accessories and backer fasteners', () {
    final curb = matchReceiptLineToCatalog('60IN FOAM SHOWER CURB');
    expect(curb, isNotNull);
    expect(curb!.item.trade, 'Tile');
    expect(curb.item.name, contains('Shower Curb'));

    final shelf = matchReceiptLineToCatalog('TRIANGULAR CORNER SHOWER SHELF');
    expect(shelf, isNotNull);
    expect(shelf!.item.trade, 'Tile');
    expect(shelf.item.name, contains('Corner Shower Shelf'));

    final screws = matchReceiptLineToCatalog('BACKER BOARD SCREW 185PK');
    expect(screws, isNotNull);
    expect(screws!.item.trade, 'Tile');
    expect(screws.item.name, contains('Backer Board Screw'));
  });

  test('tile parser understands thresholds profiles and grout repair', () {
    final threshold = matchReceiptLineToCatalog('4X36 WHITE MARBLE THRESHOLD');
    expect(threshold, isNotNull);
    expect(threshold!.item.trade, 'Tile');
    expect(threshold.item.name, contains('Marble Threshold'));

    final caulk = matchReceiptLineToCatalog(
      'CHARCOAL SANDED CERAMIC TILE CAULK',
    );
    expect(caulk, isNotNull);
    expect(caulk!.item.trade, 'Tile');
    expect(caulk.item.name, contains('Ceramic Tile Caulk'));

    final haze = matchReceiptLineToCatalog('GROUT HAZE REMOVER QUART');
    expect(haze, isNotNull);
    expect(haze!.item.trade, 'Tile');
    expect(haze.item.name, contains('Grout Haze Remover'));
  });

  test(
    'tile parser understands decorative trim floor heat and drain details',
    () {
      final glassTile = matchReceiptLineToCatalog('BLUE GLASS SUBWAY TILE');
      expect(glassTile, isNotNull);
      expect(glassTile!.item.trade, 'Tile');
      expect(glassTile.item.name, contains('Glass'));
      expect(glassTile.item.name, contains('Subway'));
      expect(glassTile.item.name, contains('Tile'));

      final bullnose = matchReceiptLineToCatalog('WHITE 3X12 BULLNOSE TILE');
      expect(bullnose, isNotNull);
      expect(bullnose!.item.trade, 'Tile');
      expect(bullnose.item.name, contains('Bullnose Tile'));

      final membrane = matchReceiptLineToCatalog(
        'CRACK ISOLATION MEMBRANE ROLL',
      );
      expect(membrane, isNotNull);
      expect(membrane!.item.trade, 'Tile');
      expect(membrane.item.name, contains('Crack Isolation Membrane'));

      final primer = matchReceiptLineToCatalog('1GAL TILE MEMBRANE PRIMER');
      expect(primer, isNotNull);
      expect(primer!.item.trade, 'Tile');
      expect(primer.item.name, contains('Tile Membrane Primer'));

      final floorHeat = matchReceiptLineToCatalog('25 SQ FT FLOOR HEAT MAT');
      expect(floorHeat, isNotNull);
      expect(floorHeat!.item.trade, 'Tile');
      expect(floorHeat.item.name, contains('Floor Heat Mat'));

      final tileableDrain = matchReceiptLineToCatalog(
        'MATTE BLACK TILEABLE DRAIN GRATE',
      );
      expect(tileableDrain, isNotNull);
      expect(tileableDrain!.item.trade, 'Tile');
      expect(tileableDrain.item.name, contains('Tileable Drain'));
    },
  );

  test(
    'tile parser understands advanced grout mortar and decorative detail',
    () {
      final quarterRound = matchReceiptLineToCatalog(
        'WHITE CERAMIC QUARTER ROUND TRIM',
      );
      expect(quarterRound, isNotNull);
      expect(quarterRound!.item.trade, 'Tile');
      expect(quarterRound.item.name, contains('Quarter Round Trim'));

      final glassMortar = matchReceiptLineToCatalog(
        '50LB WHITE GLASS TILE MORTAR',
      );
      expect(glassMortar, isNotNull);
      expect(glassMortar!.item.trade, 'Tile');
      expect(glassMortar.item.name, contains('Glass Tile Mortar'));

      final urethane = matchReceiptLineToCatalog(
        '1GAL CHARCOAL URETHANE GROUT',
      );
      expect(urethane, isNotNull);
      expect(urethane!.item.trade, 'Tile');
      expect(urethane.item.name, contains('Urethane Grout'));
    },
  );

  test(
    'tile parser understands waterproofing detail and floor heat service',
    () {
      final washer = matchReceiptLineToCatalog('FOAM BOARD WASHER 100PK');
      expect(washer, isNotNull);
      expect(washer!.item.trade, 'Tile');
      expect(washer.item.name, contains('Foam Board Washer'));

      final sealant = matchReceiptLineToCatalog('KERDI FIX SEALANT TUBE');
      expect(sealant, isNotNull);
      expect(sealant!.item.trade, 'Tile');
      expect(sealant.item.name, contains('Kerdi Fix Sealant'));

      final extension = matchReceiptLineToCatalog('60X60 SHOWER PAN EXTENSION');
      expect(extension, isNotNull);
      expect(extension!.item.trade, 'Tile');
      expect(extension.item.name, contains('Shower Pan Extension'));

      final sensor = matchReceiptLineToCatalog('FLOOR HEAT SENSOR WIRE');
      expect(sensor, isNotNull);
      expect(sensor!.item.trade, 'Tile');
      expect(sensor.item.name, contains('Floor Heat Sensor Wire'));
    },
  );

  test('tile parser understands cleanup blades and leveling cap detail', () {
    final cap = matchReceiptLineToCatalog('1/8 TILE LEVELING CAP 50PK');
    expect(cap, isNotNull);
    expect(cap!.item.trade, 'Tile');
    expect(cap.item.name, contains('Tile Leveling Cap'));

    final blade = matchReceiptLineToCatalog('7IN PORCELAIN DIAMOND BLADE');
    expect(blade, isNotNull);
    expect(blade!.item.trade, 'Tile');
    expect(blade.item.name, contains('Porcelain Diamond Blade'));

    final release = matchReceiptLineToCatalog('GROUT RELEASE QUART');
    expect(release, isNotNull);
    expect(release!.item.trade, 'Tile');
    expect(release.item.name, contains('Grout Release'));

    final removal = matchReceiptLineToCatalog('CARBIDE GROUT REMOVAL BLADE');
    expect(removal, isNotNull);
    expect(removal!.item.trade, 'Tile');
    expect(removal.item.name, contains('Grout Removal Blade'));
  });

  test('tile parser understands expanded field tile families', () {
    final largeFormat = matchReceiptLineToCatalog(
      '24X48 MATTE CARRARA RECTIFIED PORCELAIN TILE',
      tradeScope: 'Tile',
      maxCandidates: 140,
    );
    expect(largeFormat, isNotNull);
    expect(largeFormat!.item.trade, 'Tile');
    expect(largeFormat.item.name, contains('24 x 48 in'));
    expect(largeFormat.item.name, contains('Carrara'));
    expect(largeFormat.item.name, contains('Rectified Tile'));

    final mosaic = matchReceiptLineToCatalog(
      'SAGE GLASS HEX MOSAIC SHEET',
      tradeScope: 'Tile',
      maxCandidates: 140,
    );
    expect(mosaic, isNotNull);
    expect(mosaic!.item.trade, 'Tile');
    expect(mosaic.item.name, contains('Sage'));
    expect(mosaic.item.name, contains('Glass'));
    expect(mosaic.item.name, contains('Hex Mosaic Sheet'));

    final quarry = matchReceiptLineToCatalog(
      '6X6 RED QUARRY COVE BASE TILE',
      tradeScope: 'Tile',
      maxCandidates: 140,
    );
    expect(quarry, isNotNull);
    expect(quarry!.item.trade, 'Tile');
    expect(quarry.item.name, contains('6 x 6 in'));
    expect(quarry.item.name, contains('Red'));
    expect(quarry.item.name, contains('Quarry'));
    expect(quarry.item.name, contains('Cove Base Tile'));
  });
}
