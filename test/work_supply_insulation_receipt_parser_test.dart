import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('insulation parser understands batts foam and loose fill', () {
    final batt = matchReceiptLineToCatalog(
      'R13 15IN KRAFT FACED BATT INSULATION',
    );
    expect(batt, isNotNull);
    expect(batt!.item.trade, 'Insulation');
    expect(batt.item.name.toLowerCase(), contains('r-13'));
    expect(batt.item.name, contains('Fiberglass'));
    expect(batt.item.name, contains('Insulation Batt'));
    expect(batt.confidenceLevel, ReceiptConfidenceLevel.good);

    final foamBoard = matchReceiptLineToCatalog('1 IN 4X8 XPS FOAM BOARD');
    expect(foamBoard, isNotNull);
    expect(foamBoard!.item.trade, 'Insulation');
    expect(foamBoard.item.name, contains('1 in 4 x 8'));
    expect(foamBoard.item.name, contains('Foam Board'));

    final looseFill = matchReceiptLineToCatalog(
      '25LB BLOWN CELLULOSE INSULATION',
    );
    expect(looseFill, isNotNull);
    expect(looseFill!.item.trade, 'Insulation');
    expect(looseFill.item.name, contains('Cellulose'));
  });

  test(
    'insulation parser understands air sealing and vapor barrier supplies',
    () {
      final sprayFoam = matchReceiptLineToCatalog(
        '16OZ WINDOW DOOR SPRAY FOAM',
      );
      expect(sprayFoam, isNotNull);
      expect(sprayFoam!.item.trade, 'Insulation');
      expect(sprayFoam.item.name, contains('16 oz'));
      expect(sprayFoam.item.name, contains('Foam'));

      final vaporBarrier = matchReceiptLineToCatalog(
        '6 MIL 10X100 VAPOR BARRIER',
      );
      expect(vaporBarrier, isNotNull);
      expect(vaporBarrier!.item.trade, 'Insulation');
      expect(vaporBarrier.item.name, contains('6 mil'));
      expect(vaporBarrier.item.name, contains('Vapor Barrier'));

      final support = matchReceiptLineToCatalog(
        '24 IN INSULATION SUPPORT WIRE',
      );
      expect(support, isNotNull);
      expect(support!.item.trade, 'Insulation');
      expect(support.item.name, contains('24 in'));
    },
  );

  test('insulation generated pack covers receipt-realistic service stock', () {
    final insulationItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Insulation')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Insulation',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(insulationItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, insulationItems.length);
    expect(
      insulationItems.any(
        (item) =>
            item.name == 'R-19 23 in Kraft Faced Fiberglass Insulation Batt',
      ),
      isTrue,
    );
    expect(
      insulationItems.any(
        (item) =>
            item.name ==
            '2 in 4 x 8 ft Foil Faced Polyiso Board Rigid Insulation Board',
      ),
      isTrue,
    );
  });

  test('insulation parser reaches generated bulk insulation families', () {
    final kraftBatt = matchReceiptLineToCatalog(
      'R19 23IN KRAFT FACED FIBERGLASS BATT',
    );
    expect(kraftBatt, isNotNull);
    expect(kraftBatt!.item.trade, 'Insulation');
    expect(kraftBatt.item.name, contains('R-19 23 in'));
    expect(kraftBatt.item.name, contains('Kraft Faced'));

    final polyiso = matchReceiptLineToCatalog(
      '2IN 4X8 FOIL FACED POLYISO BOARD',
    );
    expect(polyiso, isNotNull);
    expect(polyiso!.item.trade, 'Insulation');
    expect(polyiso.item.name, contains('2 in 4 x 8'));
    expect(polyiso.item.name, contains('Foil Faced Polyiso'));

    final fireFoam = matchReceiptLineToCatalog('20OZ FIREBLOCK SPRAY FOAM');
    expect(fireFoam, isNotNull);
    expect(fireFoam!.item.trade, 'Insulation');
    expect(fireFoam.item.name, contains('20 oz'));
    expect(fireFoam.item.name, contains('Fire Block Spray Foam'));

    final houseWrapTape = matchReceiptLineToCatalog(
      '3IN X 165FT HOUSE WRAP TAPE',
    );
    expect(houseWrapTape, isNotNull);
    expect(houseWrapTape!.item.trade, 'Insulation');
    expect(houseWrapTape.item.name, contains('House Wrap Tape'));
  });

  test('insulation parser understands weatherization and radiant supplies', () {
    final pipeWrap = matchReceiptLineToCatalog(
      '3/4 IN X 6FT FOAM PIPE INSULATION',
    );
    expect(pipeWrap, isNotNull);
    expect(pipeWrap!.item.trade, 'Insulation');
    expect(pipeWrap.item.name, contains('Foam Pipe Insulation'));

    final weatherstrip = matchReceiptLineToCatalog(
      '1/2 IN FOAM WEATHERSTRIP TAPE',
    );
    expect(weatherstrip, isNotNull);
    expect(weatherstrip!.item.trade, 'Insulation');
    expect(weatherstrip.item.name, contains('Foam Weatherstrip Tape'));

    final radiant = matchReceiptLineToCatalog(
      '4FT X 50FT RADIANT BARRIER ROLL',
    );
    expect(radiant, isNotNull);
    expect(radiant!.item.trade, 'Insulation');
    expect(radiant.item.name, contains('Radiant Barrier Roll'));

    final garageKit = matchReceiptLineToCatalog(
      '16FT GARAGE DOOR INSULATION KIT',
    );
    expect(garageKit, isNotNull);
    expect(garageKit!.item.trade, 'Insulation');
    expect(garageKit.item.name, contains('Garage Door Insulation Kit'));
  });

  test('insulation parser understands acoustic insulation supplies', () {
    final acousticSealant = matchReceiptLineToCatalog('28OZ ACOUSTIC SEALANT');
    expect(acousticSealant, isNotNull);
    expect(acousticSealant!.item.trade, 'Insulation');
    expect(acousticSealant.item.name, contains('Acoustic Sealant'));

    final soundPanel = matchReceiptLineToCatalog(
      '2X4 FT SOUND DAMPENING PANEL',
    );
    expect(soundPanel, isNotNull);
    expect(soundPanel!.item.trade, 'Insulation');
    expect(soundPanel.item.name, contains('Sound Dampening Panel'));

    final mlv = matchReceiptLineToCatalog('4X8 MASS LOADED VINYL SHEET');
    expect(mlv, isNotNull);
    expect(mlv!.item.trade, 'Insulation');
    expect(mlv.item.name, contains('Mass Loaded Vinyl'));
  });

  test(
    'insulation parser understands crawlspace firestop and sound isolation supplies',
    () {
      final liner = matchReceiptLineToCatalog('12 MIL CRAWLSPACE LINER');
      expect(liner, isNotNull);
      expect(liner!.item.trade, 'Insulation');
      expect(liner.item.name, contains('Crawlspace Liner'));

      final seamTape = matchReceiptLineToCatalog('4IN CRAWLSPACE SEAM TAPE');
      expect(seamTape, isNotNull);
      expect(seamTape!.item.trade, 'Insulation');
      expect(seamTape.item.name, contains('Crawlspace Seam Tape'));

      final firestopCollar = matchReceiptLineToCatalog('3IN FIRESTOP COLLAR');
      expect(firestopCollar, isNotNull);
      expect(firestopCollar!.item.trade, 'Insulation');
      expect(firestopCollar.item.name, contains('Firestop Collar'));

      final puttyPad = matchReceiptLineToCatalog('FIRESTOP PUTTY PAD PACK');
      expect(puttyPad, isNotNull);
      expect(puttyPad!.item.trade, 'Insulation');
      expect(puttyPad.item.name, contains('Putty Pad'));

      final soundBatt = matchReceiptLineToCatalog('R15 SOUND CONTROL BATT');
      expect(soundBatt, isNotNull);
      expect(soundBatt!.item.trade, 'Insulation');
      expect(soundBatt.item.name, contains('Sound Control Batt'));

      final isolationClip = matchReceiptLineToCatalog(
        'SOUND ISOLATION CLIP 50PK',
      );
      expect(isolationClip, isNotNull);
      expect(isolationClip!.item.trade, 'Insulation');
      expect(isolationClip.item.name, contains('Sound Isolation Clip'));
    },
  );

  test(
    'insulation parser understands attic air sealing and fastener detail',
    () {
      final baffle = matchReceiptLineToCatalog('SOFFIT VENT BAFFLE 25PK');
      expect(baffle, isNotNull);
      expect(baffle!.item.trade, 'Insulation');
      expect(baffle.item.name, contains('Soffit Vent Baffle'));

      final lightCover = matchReceiptLineToCatalog(
        'RECESSED CAN LIGHT COVER 10 PACK',
      );
      expect(lightCover, isNotNull);
      expect(lightCover!.item.trade, 'Insulation');
      expect(lightCover.item.name, contains('Can Light Cover'));

      final netting = matchReceiptLineToCatalog(
        '8FT X 100FT BLOWN IN MESH NETTING',
      );
      expect(netting, isNotNull);
      expect(netting!.item.trade, 'Insulation');
      expect(netting.item.name, contains('Blown In Mesh Netting'));

      final capNail = matchReceiptLineToCatalog(
        'VAPOR BARRIER CAP NAIL 250 PACK',
      );
      expect(capNail, isNotNull);
      expect(capNail!.item.trade, 'Insulation');
      expect(capNail.item.name, contains('Vapor Barrier Cap Nail'));
    },
  );

  test(
    'insulation parser understands firestop wrap and sound track detail',
    () {
      final impalingClip = matchReceiptLineToCatalog('IMPALING CLIP 100PK');
      expect(impalingClip, isNotNull);
      expect(impalingClip!.item.trade, 'Insulation');
      expect(impalingClip.item.name, contains('Impaling Clip'));

      final firestopWrap = matchReceiptLineToCatalog('2IN FIRESTOP WRAP STRIP');
      expect(firestopWrap, isNotNull);
      expect(firestopWrap!.item.trade, 'Insulation');
      expect(firestopWrap.item.name, contains('Firestop Wrap Strip'));

      final soundTrack = matchReceiptLineToCatalog(
        '10FT SOUND ISOLATION TRACK',
      );
      expect(soundTrack, isNotNull);
      expect(soundTrack!.item.trade, 'Insulation');
      expect(soundTrack.item.name, contains('Sound Isolation Track'));
    },
  );

  test('insulation parser understands expanded detail stock receipts', () {
    final batt = matchReceiptLineToCatalog(
      'R38 24IN UNFACED FIBERGLASS BATT',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(batt, isNotNull);
    expect(batt!.item.trade, 'Insulation');
    expect(batt.item.name, contains('R-38 24 in'));
    expect(batt.item.name, contains('Unfaced Fiberglass Batt'));

    final foamBoard = matchReceiptLineToCatalog(
      '3IN 4X8 XPS FOAM BOARD',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(foamBoard, isNotNull);
    expect(foamBoard!.item.trade, 'Insulation');
    expect(foamBoard.item.name, contains('3 in 4 x 8 ft'));
    expect(foamBoard.item.name, contains('XPS Foam Board'));

    final pestFoam = matchReceiptLineToCatalog(
      '24OZ PEST BLOCK SPRAY FOAM',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(pestFoam, isNotNull);
    expect(pestFoam!.item.trade, 'Insulation');
    expect(pestFoam.item.name, contains('24 oz Pest Block Spray Foam'));

    final liner = matchReceiptLineToCatalog(
      '20MIL 12X100 CRAWLSPACE LINER',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(liner, isNotNull);
    expect(liner!.item.trade, 'Insulation');
    expect(liner.item.name, contains('20 mil'));
    expect(liner.item.name, contains('12'));
    expect(liner.item.name, contains('100 ft'));
    expect(liner.item.name, contains('Crawlspace Liner'));

    final wrap = matchReceiptLineToCatalog(
      '4IN FIRESTOP WRAP STRIP',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(wrap, isNotNull);
    expect(wrap!.item.trade, 'Insulation');
    expect(wrap.item.name, contains('4 in Firestop Wrap Strip'));

    final track = matchReceiptLineToCatalog(
      '12FT SOUND ISOLATION TRACK',
      tradeScope: 'Insulation',
      maxCandidates: 180,
    );
    expect(track, isNotNull);
    expect(track!.item.trade, 'Insulation');
    expect(track.item.name, contains('12 ft Sound Isolation Track'));
  });

}
