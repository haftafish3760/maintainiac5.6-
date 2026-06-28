import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('drywall parser understands sheet goods and compound shorthand', () {
    final sheet = matchReceiptLineToCatalog('HD SHEETROCK 1/2 4X12');
    expect(sheet, isNotNull);
    expect(sheet!.item.trade, 'Drywall');
    expect(sheet.item.name, contains('1/2 in 4 x 12'));
    expect(sheet.item.name, contains('Drywall Sheet'));
    expect(sheet.confidenceLevel, ReceiptConfidenceLevel.good);

    final compound = matchReceiptLineToCatalog('EASY SAND 45 MIN 18LB');
    expect(compound, isNotNull);
    expect(compound!.item.trade, 'Drywall');
    expect(compound.item.name, contains('45 min 18 lb'));
    expect(compound.item.name, contains('Setting Type Joint Compound'));
  });

  test('drywall parser separates tape, bead, patch, and screws', () {
    final tape = matchReceiptLineToCatalog('LOWES PAPER TAPE 250 FT');
    expect(tape, isNotNull);
    expect(tape!.item.trade, 'Drywall');
    expect(tape.item.name, contains('250 ft Paper'));
    expect(tape.item.name, contains('Drywall Tape'));

    final bead = matchReceiptLineToCatalog('VINYL CORNER BEAD 10FT');
    expect(bead, isNotNull);
    expect(bead!.item.trade, 'Drywall');
    expect(bead.item.name, contains('10 ft Vinyl Corner'));

    final screws = matchReceiptLineToCatalog('DRYWALL SCREW #6 X 1-5/8 COARSE');
    expect(screws, isNotNull);
    expect(screws!.item.trade, 'Drywall');
    expect(screws.item.name, contains('#6 x 1-5/8 in Coarse Thread Screw'));
  });

  test('drywall generated pack covers receipt-realistic service stock', () {
    final drywallItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Drywall')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Drywall',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(drywallItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, drywallItems.length);
    expect(
      drywallItems.any(
        (item) => item.name == '1/2 in 4 x 8 Mold Resistant Drywall Board',
      ),
      isTrue,
    );
    expect(
      drywallItems.any(
        (item) => item.name == '#6 x 1-5/8 in Coarse Thread 5 lb Drywall Screw',
      ),
      isTrue,
    );
  });

  test('drywall parser reaches generated bulk drywall families', () {
    final board = matchReceiptLineToCatalog('1/2 4X8 MOLD RESIST DRYWALL');
    expect(board, isNotNull);
    expect(board!.item.trade, 'Drywall');
    expect(board.item.name, contains('1/2 in 4 x 8'));
    expect(board.item.name, contains('Mold Resistant'));

    final plus3 = matchReceiptLineToCatalog('PLUS 3 4.5 GAL JOINT CMPD');
    expect(plus3, isNotNull);
    expect(plus3!.item.trade, 'Drywall');
    expect(plus3.item.name, contains('4.5 gal'));
    expect(plus3.item.name, contains('Plus 3'));

    final screwBox = matchReceiptLineToCatalog(
      'DRYWALL SCREWS #6 1-5/8 COARSE 5LB',
    );
    expect(screwBox, isNotNull);
    expect(screwBox!.item.trade, 'Drywall');
    expect(screwBox.item.name, contains('#6 x 1-5/8 in'));
    expect(screwBox.item.name, contains('5 lb'));
  });

  test('drywall parser understands access panels trim and dust control', () {
    final accessPanel = matchReceiptLineToCatalog('12X12 PLASTIC ACCESS PANEL');
    expect(accessPanel, isNotNull);
    expect(accessPanel!.item.trade, 'Drywall');
    expect(accessPanel.item.name, contains('Plastic Access Panel'));

    final controlJoint = matchReceiptLineToCatalog(
      '10FT DRYWALL CONTROL JOINT',
    );
    expect(controlJoint, isNotNull);
    expect(controlJoint!.item.trade, 'Drywall');
    expect(controlJoint.item.name, contains('Control Joint'));

    final dustBarrier = matchReceiptLineToCatalog('ZIP DOOR DUST BARRIER KIT');
    expect(dustBarrier, isNotNull);
    expect(dustBarrier!.item.trade, 'Drywall');
    expect(dustBarrier.item.name, contains('Dust Barrier'));
  });

  test('drywall parser understands finishing tools and texture equipment', () {
    final lift = matchReceiptLineToCatalog('DRYWALL LIFT PANEL HOIST');
    expect(lift, isNotNull);
    expect(lift!.item.trade, 'Drywall');
    expect(lift.item.name, contains('Panel Hoist'));

    final knife = matchReceiptLineToCatalog('12IN TAPING KNIFE');
    expect(knife, isNotNull);
    expect(knife!.item.trade, 'Drywall');
    expect(knife.item.name, contains('Taping Knife'));

    final hopper = matchReceiptLineToCatalog('TEXTURE HOPPER GUN');
    expect(hopper, isNotNull);
    expect(hopper!.item.trade, 'Drywall');
    expect(hopper.item.name, contains('Texture Hopper'));
  });

  test('drywall parser understands metal framing and ceiling supplies', () {
    final stud = matchReceiptLineToCatalog('25GA 3-5/8 X 10FT METAL STUD');
    expect(stud, isNotNull);
    expect(stud!.item.trade, 'Drywall');
    expect(stud.item.name, contains('Metal Stud'));
    expect(stud.item.name, contains('Drywall Metal Framing'));

    final track = matchReceiptLineToCatalog('20GA 3-5/8 X 10FT METAL TRACK');
    expect(track, isNotNull);
    expect(track!.item.trade, 'Drywall');
    expect(track.item.name, contains('Metal Track'));

    final resilient = matchReceiptLineToCatalog('12FT RESILIENT CHANNEL');
    expect(resilient, isNotNull);
    expect(resilient!.item.trade, 'Drywall');
    expect(resilient.item.name, contains('Resilient Channel'));
  });

  test('drywall parser understands sound clips wire and metal screws', () {
    final wire = matchReceiptLineToCatalog('12GA CEILING HANGER WIRE ROLL');
    expect(wire, isNotNull);
    expect(wire!.item.trade, 'Drywall');
    expect(wire.item.name, contains('Drywall Ceiling Support'));

    final clip = matchReceiptLineToCatalog('RC SOUND ISOLATION CLIP PACK');
    expect(clip, isNotNull);
    expect(clip!.item.trade, 'Drywall');
    expect(clip.item.name, contains('Drywall Ceiling Support'));

    final screw = matchReceiptLineToCatalog('7/16 PAN HEAD FRAMING SCREW');
    expect(screw, isNotNull);
    expect(screw!.item.trade, 'Drywall');
    expect(screw.item.name, contains('Metal Framing Accessory'));
  });

  test('drywall parser understands reveal trim and access doors', () {
    final reveal = matchReceiptLineToCatalog('10FT REVEAL BEAD');
    expect(reveal, isNotNull);
    expect(reveal!.item.trade, 'Drywall');
    expect(reveal.item.name, contains('Reveal Bead'));

    final bullnose = matchReceiptLineToCatalog('BULLNOSE THREE-WAY CORNER CAP');
    expect(bullnose, isNotNull);
    expect(bullnose!.item.trade, 'Drywall');
    expect(bullnose.item.name, contains('Bullnose Three-Way Corner Cap'));

    final fireDoor = matchReceiptLineToCatalog('12X12 FIRE RATED ACCESS DOOR');
    expect(fireDoor, isNotNull);
    expect(fireDoor!.item.trade, 'Drywall');
    expect(fireDoor.item.name, contains('Fire Rated Access Door'));
  });

  test(
    'drywall parser understands sanding texture and ceiling grid detail',
    () {
      final poleSander = matchReceiptLineToCatalog('DRYWALL POLE SANDER HEAD');
      expect(poleSander, isNotNull);
      expect(poleSander!.item.trade, 'Drywall');
      expect(poleSander.item.name, contains('Drywall Pole Sander Head'));

      final textureNozzle = matchReceiptLineToCatalog(
        'TEXTURE HOPPER NOZZLE KIT',
      );
      expect(textureNozzle, isNotNull);
      expect(textureNozzle!.item.trade, 'Drywall');
      expect(textureNozzle.item.name, contains('Texture Hopper Nozzle Kit'));

      final crossTee = matchReceiptLineToCatalog('4FT CEILING CROSS TEE');
      expect(crossTee, isNotNull);
      expect(crossTee!.item.trade, 'Drywall');
      expect(crossTee.item.name, contains('Ceiling Cross Tee'));

      final tile = matchReceiptLineToCatalog('2X2 ACOUSTIC CEILING TILE');
      expect(tile, isNotNull);
      expect(tile!.item.trade, 'Drywall');
      expect(tile.item.name, contains('Acoustic Ceiling Tile'));
    },
  );

  test('drywall parser understands expanded detail stock receipts', () {
    final abuseBoard = matchReceiptLineToCatalog(
      '5/8 4X12 ABUSE RESISTANT SHEETROCK',
      tradeScope: 'Drywall',
      maxCandidates: 160,
    );
    expect(abuseBoard, isNotNull);
    expect(abuseBoard!.item.trade, 'Drywall');
    expect(abuseBoard.item.name, contains('5/8 in 4 x 12'));
    expect(abuseBoard.item.name, contains('Abuse Resistant'));

    final shadowBead = matchReceiptLineToCatalog(
      '10FT SHADOW BEAD',
      tradeScope: 'Drywall',
      maxCandidates: 160,
    );
    expect(shadowBead, isNotNull);
    expect(shadowBead!.item.trade, 'Drywall');
    expect(shadowBead.item.name, contains('Shadow Bead'));

    final zFurring = matchReceiptLineToCatalog(
      '12FT Z FURRING CHANNEL',
      tradeScope: 'Drywall',
      maxCandidates: 160,
    );
    expect(zFurring, isNotNull);
    expect(zFurring!.item.trade, 'Drywall');
    expect(zFurring.item.name, contains('Z Furring Channel'));

    final gridRunner = matchReceiptLineToCatalog(
      'BLACK 12FT CEILING MAIN RUNNER',
      tradeScope: 'Drywall',
      maxCandidates: 160,
    );
    expect(gridRunner, isNotNull);
    expect(gridRunner!.item.trade, 'Drywall');
    expect(gridRunner.item.name, contains('Black 12 ft Main Runner'));

    final orangePeel = matchReceiptLineToCatalog(
      'PREMIXED ORANGE PEEL TEXTURE',
      tradeScope: 'Drywall',
      maxCandidates: 160,
    );
    expect(orangePeel, isNotNull);
    expect(orangePeel!.item.trade, 'Drywall');
    expect(orangePeel.item.name, contains('Premixed Orange Peel Texture'));
  });

  test('painting parser understands paint, prep, and caulk supplies', () {
    final paint = matchReceiptLineToCatalog('5 GAL EGGSHELL INTERIOR PAINT');
    expect(paint, isNotNull);
    expect(paint!.item.trade, 'Painting');
    expect(paint.item.name, contains('5 gal Eggshell Interior Paint'));
    expect(paint.confidenceLevel, ReceiptConfidenceLevel.good);

    final tape = matchReceiptLineToCatalog('1.88 IN PAINTER TAPE');
    expect(tape, isNotNull);
    expect(tape!.item.trade, 'Painting');
    expect(tape.item.name, contains('1.88 in Painter Tape'));

    final caulk = matchReceiptLineToCatalog('10 OZ WHITE PAINTER CAULK');
    expect(caulk, isNotNull);
    expect(caulk!.item.trade, 'Painting');
    expect(caulk.item.name, contains('10 oz white'));
    expect(caulk.item.itemType, contains('Paintable Caulk'));
  });

  test('painting generated pack covers receipt-realistic paint supplies', () {
    final paintingItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Painting')
        .toList(growable: false);
    final fullPack = buildWorkSupplyTradePackOptions(
      'Painting',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);

    expect(paintingItems.length, greaterThanOrEqualTo(500));
    expect(fullPack.itemCount, paintingItems.length);
    expect(
      paintingItems.any(
        (item) =>
            item.name == '1 gal Satin Cabinet and Furniture Paint Coating',
      ),
      isTrue,
    );
    expect(
      paintingItems.any(
        (item) => item.name == '9 in 3/8 in nap Roller Cover 3 Pack Paint Tool',
      ),
      isTrue,
    );
  });

  test('painting parser reaches generated bulk painting families', () {
    final cabinetPaint = matchReceiptLineToCatalog('1 GAL SATIN CABINET PAINT');
    expect(cabinetPaint, isNotNull);
    expect(cabinetPaint!.item.trade, 'Painting');
    expect(cabinetPaint.item.name, contains('1 gal Satin'));
    expect(cabinetPaint.item.name, contains('Cabinet'));

    final rollerPack = matchReceiptLineToCatalog('9IN 3/8 NAP ROLLER 3PK');
    expect(rollerPack, isNotNull);
    expect(rollerPack!.item.trade, 'Painting');
    expect(rollerPack.item.name, contains('9 in 3/8 in nap'));
    expect(rollerPack.item.name, contains('3 Pack'));

    final tape = matchReceiptLineToCatalog('1.88IN DELICATE PAINTER TAPE');
    expect(tape, isNotNull);
    expect(tape!.item.trade, 'Painting');
    expect(tape.item.name, contains('1.88 in Delicate Surface'));
  });

  test(
    'painting parser understands stains clear coats and specialty coatings',
    () {
      final deckStain = matchReceiptLineToCatalog('1 GAL DECK STAIN');
      expect(deckStain, isNotNull);
      expect(deckStain!.item.trade, 'Painting');
      expect(deckStain.item.name, contains('Deck Stain'));

      final poly = matchReceiptLineToCatalog('QT SATIN POLYURETHANE');
      expect(poly, isNotNull);
      expect(poly!.item.trade, 'Painting');
      expect(poly.item.name, contains('Polyurethane'));

      final garage = matchReceiptLineToCatalog(
        '1 GAL GARAGE FLOOR EPOXY COATING',
      );
      expect(garage, isNotNull);
      expect(garage!.item.trade, 'Painting');
      expect(garage.item.name, contains('Garage Floor'));
    },
  );

  test(
    'painting parser understands sprayer prep remover and color supplies',
    () {
      final tip = matchReceiptLineToCatalog('0.015 AIRLESS SPRAY TIP');
      expect(tip, isNotNull);
      expect(tip!.item.trade, 'Painting');
      expect(tip.item.name, contains('Airless Spray Tip'));

      final masker = matchReceiptLineToCatalog('HAND MASKER FILM BLADE');
      expect(masker, isNotNull);
      expect(masker!.item.trade, 'Painting');
      expect(masker.item.name, contains('Hand Masker'));

      final stripper = matchReceiptLineToCatalog('QT PAINT STRIPPER');
      expect(stripper, isNotNull);
      expect(stripper!.item.trade, 'Painting');
      expect(stripper.item.name, contains('Paint Stripper'));

      final sample = matchReceiptLineToCatalog('HALF PINT COLOR SAMPLE');
      expect(sample, isNotNull);
      expect(sample!.item.trade, 'Painting');
      expect(sample.item.name, contains('Color Sample'));
    },
  );

  test('painting parser understands specialty prep and sealants', () {
    final cleaner = matchReceiptLineToCatalog('1 GAL GARAGE FLOOR CLEANER');
    expect(cleaner, isNotNull);
    expect(cleaner!.item.trade, 'Painting');
    expect(cleaner.item.name, contains('Specialty Coating Prep Supply'));

    final rust = matchReceiptLineToCatalog('QT RUST CONVERTER');
    expect(rust, isNotNull);
    expect(rust!.item.trade, 'Painting');
    expect(rust.item.name, contains('Specialty Coating Prep Supply'));

    final stretch = matchReceiptLineToCatalog(
      '10 OZ WHITE BIG STRETCH SEALANT',
    );
    expect(stretch, isNotNull);
    expect(stretch!.item.trade, 'Painting');
    expect(stretch.item.name, contains('Painter Sealant Specialty'));

    final backer = matchReceiptLineToCatalog('1/2 IN BACKER ROD 20FT');
    expect(backer, isNotNull);
    expect(backer!.item.trade, 'Painting');
    expect(backer.item.name, contains('Painter Sealant Specialty'));
  });

  test('painting parser understands sprayer parts masking and disposal', () {
    final filter = matchReceiptLineToCatalog('60 MESH SPRAY GUN FILTER PACK');
    expect(filter, isNotNull);
    expect(filter!.item.trade, 'Painting');
    expect(filter.item.name, contains('Sprayer Service Part'));

    final repair = matchReceiptLineToCatalog('SPRAYER PUMP REPAIR KIT');
    expect(repair, isNotNull);
    expect(repair!.item.trade, 'Painting');
    expect(repair.item.name, contains('Sprayer Service Part'));

    final film = matchReceiptLineToCatalog('48IN PRE-TAPED MASKING FILM');
    expect(film, isNotNull);
    expect(film!.item.trade, 'Painting');
    expect(film.item.name, contains('Painter Protection Supply'));

    final hardener = matchReceiptLineToCatalog('1 GAL PAINT HARDENER');
    expect(hardener, isNotNull);
    expect(hardener!.item.trade, 'Painting');
    expect(hardener.item.name, contains('Painter Protection Supply'));
  });

  test('painting parser understands expanded detail stock receipts', () {
    final primer = matchReceiptLineToCatalog(
      '5 GAL STAIN BLOCKING PRIMER',
      tradeScope: 'Painting',
      maxCandidates: 160,
    );
    expect(primer, isNotNull);
    expect(primer!.item.trade, 'Painting');
    expect(primer.item.name, contains('5 gal Stain Blocking Primer'));

    final exteriorTrim = matchReceiptLineToCatalog(
      '1 GAL SEMI GLOSS EXTERIOR TRIM PAINT',
      tradeScope: 'Painting',
      maxCandidates: 160,
    );
    expect(exteriorTrim, isNotNull);
    expect(exteriorTrim!.item.trade, 'Painting');
    expect(exteriorTrim.item.name, contains('Semi Gloss'));
    expect(exteriorTrim.item.name, contains('Exterior Trim Paint'));

    final film = matchReceiptLineToCatalog(
      '72IN PRE-TAPED MASKING FILM',
      tradeScope: 'Painting',
      maxCandidates: 160,
    );
    expect(film, isNotNull);
    expect(film!.item.trade, 'Painting');
    expect(film.item.name, contains('72 in'));
    expect(film.item.name, contains('Pre-Taped Masking Film'));

    final sprayerFilter = matchReceiptLineToCatalog(
      '200 MESH SPRAY GUN FILTER PACK',
      tradeScope: 'Painting',
      maxCandidates: 160,
    );
    expect(sprayerFilter, isNotNull);
    expect(sprayerFilter!.item.trade, 'Painting');
    expect(sprayerFilter.item.name, contains('200 Mesh'));
    expect(sprayerFilter.item.name, contains('Spray Gun Filter'));

    final silicone = matchReceiptLineToCatalog(
      'CLEAR 10 OZ PAINTABLE SILICONE',
      tradeScope: 'Painting',
      maxCandidates: 160,
    );
    expect(silicone, isNotNull);
    expect(silicone!.item.trade, 'Painting');
    expect(silicone.item.name, contains('10 oz'));
    expect(silicone.item.name, contains('Clear'));
    expect(silicone.item.name, contains('Paintable Silicone'));
  });
}
