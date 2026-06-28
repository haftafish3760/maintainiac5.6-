import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('carpentry pack has expanded first-pass service coverage', () {
    final audit = auditWorkSupplyCatalog();
    final carpentry = audit.tradeCoverage.singleWhere(
      (coverage) => coverage.tradeName == 'Carpentry',
    );

    expect(carpentry.itemCount, greaterThanOrEqualTo(550));
    expect(carpentry.aliasCoverage, greaterThan(.70));
    expect(carpentry.parserReadinessLabel, 'Strong');
  });

  test('carpentry parser understands lumber and sheet-good shorthand', () {
    final stud = matchReceiptLineToCatalog('2X4X8 KD STUD');
    expect(stud, isNotNull);
    expect(stud!.item.trade, 'Carpentry');
    expect(stud.item.name, contains('2 x 4 x 8 ft'));
    expect(stud.confidenceLevel, ReceiptConfidenceLevel.good);

    final osb = matchReceiptLineToCatalog('23/32 OSB SHEATHING');
    expect(osb, isNotNull);
    expect(osb!.item.trade, 'Carpentry');
    expect(osb.item.name.toLowerCase(), contains('osb'));
  });

  test('carpentry parser understands fasteners and framing connectors', () {
    final deckScrew = matchReceiptLineToCatalog('2-1/2 DECK SCREWS EXT');
    expect(deckScrew, isNotNull);
    expect(deckScrew!.item.trade, 'Carpentry');
    expect(deckScrew.item.name.toLowerCase(), contains('deck screw'));

    final hanger = matchReceiptLineToCatalog('2X8 FACE MOUNT JOIST HANGER');
    expect(hanger, isNotNull);
    expect(hanger!.item.trade, 'Carpentry');
    expect(hanger.item.name.toLowerCase(), contains('joist hanger'));
  });

  test('carpentry parser understands trim and cabinet hardware', () {
    final baseboard = matchReceiptLineToCatalog('3-1/4 MDF BASEBOARD');
    expect(baseboard, isNotNull);
    expect(baseboard!.item.trade, 'Carpentry');
    expect(baseboard.item.name.toLowerCase(), contains('baseboard'));

    final pull = matchReceiptLineToCatalog('3 IN MATTE BLACK CABINET PULL');
    expect(pull, isNotNull);
    expect(pull!.item.trade, 'Carpentry');
    expect(pull.item.name.toLowerCase(), contains('cabinet pull'));

    final slide = matchReceiptLineToCatalog('18 IN SOFT CLOSE DRAWER SLIDE');
    expect(slide, isNotNull);
    expect(slide!.item.trade, 'Carpentry');
    expect(slide.item.name.toLowerCase(), contains('drawer slide'));
  });

  test('carpentry parser understands finish boards and stair parts', () {
    final projectPanel = matchReceiptLineToCatalog(
      '2FT X 4FT OAK PROJECT PANEL',
    );
    expect(projectPanel, isNotNull);
    expect(projectPanel!.item.trade, 'Carpentry');
    expect(projectPanel.item.name.toLowerCase(), contains('project panel'));

    final tread = matchReceiptLineToCatalog('42IN OAK STAIR TREAD');
    expect(tread, isNotNull);
    expect(tread!.item.trade, 'Carpentry');
    expect(tread.item.name.toLowerCase(), contains('stair tread'));

    final bracket = matchReceiptLineToCatalog('MATTE BLACK HANDRAIL BRACKET');
    expect(bracket, isNotNull);
    expect(bracket!.item.trade, 'Carpentry');
    expect(bracket.item.name.toLowerCase(), contains('handrail bracket'));
  });

  test('carpentry parser understands door locks and entry hardware', () {
    final lockset = matchReceiptLineToCatalog('SATIN NICKEL ENTRY DOOR KNOB');
    expect(lockset, isNotNull);
    expect(lockset!.item.trade, 'Carpentry');
    expect(lockset.item.name.toLowerCase(), contains('entry door knob'));

    final deadbolt = matchReceiptLineToCatalog(
      'MATTE BLACK SINGLE CYL DEADBOLT',
    );
    expect(deadbolt, isNotNull);
    expect(deadbolt!.item.trade, 'Carpentry');
    expect(deadbolt.item.name.toLowerCase(), contains('deadbolt'));

    final sweep = matchReceiptLineToCatalog('ADJUSTABLE DOOR SWEEP');
    expect(sweep, isNotNull);
    expect(sweep!.item.trade, 'Carpentry');
    expect(sweep.item.name.toLowerCase(), contains('door sweep'));
  });

  test(
    'carpentry parser understands door window and deck install supplies',
    () {
      final foam = matchReceiptLineToCatalog('LOW EXPANSION WINDOW DOOR FOAM');
      expect(foam, isNotNull);
      expect(foam!.item.trade, 'Carpentry');
      expect(foam.item.name, contains('Door or Window Install Supply'));

      final sillPan = matchReceiptLineToCatalog('EXTERIOR DOOR SILL PAN');
      expect(sillPan, isNotNull);
      expect(sillPan!.item.trade, 'Carpentry');
      expect(sillPan.item.name, contains('Door or Window Install Supply'));

      final joistTape = matchReceiptLineToCatalog('DECK JOIST TAPE ROLL');
      expect(joistTape, isNotNull);
      expect(joistTape!.item.trade, 'Carpentry');
      expect(joistTape.item.name, contains('Deck Framing Supply'));
    },
  );

  test('carpentry parser understands joinery and cabinet install supplies', () {
    final biscuit = matchReceiptLineToCatalog('#20 WOOD BISCUIT PACK');
    expect(biscuit, isNotNull);
    expect(biscuit!.item.trade, 'Carpentry');
    expect(biscuit.item.name, contains('Joinery or Cabinet Install Supply'));

    final pocketScrew = matchReceiptLineToCatalog('1-1/4 POCKET HOLE SCREWS');
    expect(pocketScrew, isNotNull);
    expect(pocketScrew!.item.trade, 'Carpentry');
    expect(
      pocketScrew.item.name,
      contains('Joinery or Cabinet Install Supply'),
    );

    final cabinetShim = matchReceiptLineToCatalog('CABINET SHIM PACK');
    expect(cabinetShim, isNotNull);
    expect(cabinetShim!.item.trade, 'Carpentry');
    expect(
      cabinetShim.item.name,
      contains('Joinery or Cabinet Install Supply'),
    );
  });

  test(
    'carpentry parser understands cabinet closet and shelf detail parts',
    () {
      final filler = matchReceiptLineToCatalog(
        'WHITE 3IN CABINET FILLER STRIP',
      );
      expect(filler, isNotNull);
      expect(filler!.item.trade, 'Carpentry');
      expect(filler.item.name, contains('Cabinet Filler Strip'));

      final toeKick = matchReceiptLineToCatalog('OAK TOE KICK BOARD');
      expect(toeKick, isNotNull);
      expect(toeKick!.item.trade, 'Carpentry');
      expect(toeKick.item.name, contains('Toe Kick Board'));

      final lazySusan = matchReceiptLineToCatalog('LAZY SUSAN BEARING');
      expect(lazySusan, isNotNull);
      expect(lazySusan!.item.trade, 'Carpentry');
      expect(lazySusan.item.name, contains('Lazy Susan Bearing'));

      final closetShelf = matchReceiptLineToCatalog('48IN WHITE WIRE SHELF');
      expect(closetShelf, isNotNull);
      expect(closetShelf!.item.trade, 'Carpentry');
      expect(closetShelf.item.name, contains('White Wire Shelf'));
    },
  );

  test('carpentry parser understands door stair and deck detail parts', () {
    final jambRepair = matchReceiptLineToCatalog('DOOR JAMB REPAIR KIT');
    expect(jambRepair, isNotNull);
    expect(jambRepair!.item.trade, 'Carpentry');
    expect(jambRepair.item.name, contains('Door Jamb Repair Kit'));

    final stairNosing = matchReceiptLineToCatalog('OAK STAIR NOSING');
    expect(stairNosing, isNotNull);
    expect(stairNosing!.item.trade, 'Carpentry');
    expect(stairNosing.item.name, contains('Stair Nosing'));

    final deckLight = matchReceiptLineToCatalog('BLACK DECK POST CAP LIGHT');
    expect(deckLight, isNotNull);
    expect(deckLight!.item.trade, 'Carpentry');
    expect(deckLight.item.name, contains('Deck Post Cap Light'));

    final fasciaScrew = matchReceiptLineToCatalog('DECK FASCIA SCREW 100 PACK');
    expect(fasciaScrew, isNotNull);
    expect(fasciaScrew!.item.trade, 'Carpentry');
    expect(fasciaScrew.item.name, contains('Deck Fascia Screw'));
  });

  test(
    'carpentry parser understands expanded structural and door detail stock',
    () {
      final lvl = matchReceiptLineToCatalog(
        '1-3/4 X 11-7/8 X 16FT LVL BEAM',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(lvl, isNotNull);
      expect(lvl!.item.trade, 'Carpentry');
      expect(lvl.item.name, contains('11-7/8 in'));
      expect(lvl.item.name, contains('LVL Beam'));

      final iJoist = matchReceiptLineToCatalog(
        '14IN X 20FT I JOIST',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(iJoist, isNotNull);
      expect(iJoist!.item.trade, 'Carpentry');
      expect(iJoist.item.name, contains('14 in'));
      expect(iJoist.item.name, contains('I Joist'));

      final subfloor = matchReceiptLineToCatalog(
        '23/32 4X8 TONGUE AND GROOVE SUBFLOOR',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(subfloor, isNotNull);
      expect(subfloor!.item.trade, 'Carpentry');
      expect(subfloor.item.name, contains('23/32 in'));
      expect(subfloor.item.name, contains('Subfloor'));

      final prehung = matchReceiptLineToCatalog(
        '30IN LH PREHUNG INTERIOR DOOR',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(prehung, isNotNull);
      expect(prehung!.item.trade, 'Carpentry');
      expect(prehung.item.name, contains('30 in'));
      expect(prehung.item.name, contains('Prehung Interior Door'));

      final drawerSlide = matchReceiptLineToCatalog(
        '22IN 100LB SOFT CLOSE DRAWER SLIDE',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(drawerSlide, isNotNull);
      expect(drawerSlide!.item.trade, 'Carpentry');
      expect(drawerSlide.item.name, contains('22 in'));
      expect(drawerSlide.item.name, contains('Soft Close Drawer Slide'));

      final shelfPin = matchReceiptLineToCatalog(
        'NICKEL SHELF PIN PACK',
        tradeScope: 'Carpentry',
        maxCandidates: 160,
      );
      expect(shelfPin, isNotNull);
      expect(shelfPin!.item.trade, 'Carpentry');
      expect(shelfPin.item.name, contains('Nickel Shelf Pin'));
    },
  );
}
