import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'masonry concrete pack is broad enough for first-pass trade coverage',
    () {
      final audit = auditWorkSupplyCatalog();
      final masonry = audit.tradeCoverage.singleWhere(
        (coverage) => coverage.tradeName == 'Masonry and Concrete',
      );
      final landscaping = audit.tradeCoverage.singleWhere(
        (coverage) => coverage.tradeName == 'Landscaping',
      );

      expect(masonry.itemCount, greaterThanOrEqualTo(500));
      expect(masonry.aliasCoverage, greaterThan(.70));
      expect(masonry.parserReadinessLabel, 'Strong');
      expect(landscaping.itemCount, greaterThanOrEqualTo(500));
      expect(landscaping.aliasCoverage, greaterThan(.70));
      expect(landscaping.parserReadinessLabel, 'Strong');
    },
  );

  test('masonry parser understands mixes block and reinforcement', () {
    final concrete = matchReceiptLineToCatalog('80LB CONCRETE MIX QUIKRETE');
    expect(concrete, isNotNull);
    expect(concrete!.item.trade, 'Masonry and Concrete');
    expect(concrete.item.name, contains('80 lb Concrete Mix'));
    expect(concrete.confidenceLevel, ReceiptConfidenceLevel.good);

    final block = matchReceiptLineToCatalog('8X8X16 CMU CONCRETE BLOCK');
    expect(block, isNotNull);
    expect(block!.item.trade, 'Masonry and Concrete');
    expect(block.item.name, contains('8 x 8 x 16 in Concrete Block'));

    final rebar = matchReceiptLineToCatalog('#4 X 10 FT REBAR');
    expect(rebar, isNotNull);
    expect(rebar!.item.trade, 'Masonry and Concrete');
    expect(rebar.item.name, contains('#4 x 10 ft Rebar'));

    final remesh = matchReceiptLineToCatalog('42X84 REMESH SHEET WIRE MESH');
    expect(remesh, isNotNull);
    expect(remesh!.item.trade, 'Masonry and Concrete');
    expect(remesh.item.name, contains('Concrete Wire Mesh'));
  });

  test('masonry parser understands anchors forms and repair materials', () {
    final tapcon = matchReceiptLineToCatalog(
      '1/4 X 2-3/4 TAPCON CONCRETE SCREW',
    );
    expect(tapcon, isNotNull);
    expect(tapcon!.item.trade, 'Masonry and Concrete');
    expect(tapcon.item.name, contains('Concrete Screw Anchor'));

    final form = matchReceiptLineToCatalog('2X6X8 CONCRETE FORM BOARD');
    expect(form, isNotNull);
    expect(form!.item.trade, 'Masonry and Concrete');
    expect(form.item.name, contains('2 x 6 x 8 ft'));
    expect(form.item.name, contains('Form Board'));

    final patch = matchReceiptLineToCatalog('20LB CONCRETE PATCH');
    expect(patch, isNotNull);
    expect(patch!.item.trade, 'Masonry and Concrete');
    expect(patch.item.name, contains('20 lb Concrete Patch'));

    final resurfacer = matchReceiptLineToCatalog('40LB CONCRETE RESURFACER');
    expect(resurfacer, isNotNull);
    expect(resurfacer!.item.trade, 'Masonry and Concrete');
    expect(resurfacer.item.name, contains('Concrete Resurfacer'));
  });

  test(
    'masonry parser understands mortar cement and hardscape consumables',
    () {
      final mortar = matchReceiptLineToCatalog('80LB TYPE S MORTAR MIX');
      expect(mortar, isNotNull);
      expect(mortar!.item.trade, 'Masonry and Concrete');
      expect(mortar.item.name, contains('80 lb Type S Mortar Mix'));

      final cement = matchReceiptLineToCatalog('94LB PORTLAND CEMENT');
      expect(cement, isNotNull);
      expect(cement!.item.trade, 'Masonry and Concrete');
      expect(cement.item.name, contains('94 lb Portland Cement'));

      final adhesive = matchReceiptLineToCatalog(
        '28OZ LANDSCAPE BLOCK ADHESIVE',
      );
      expect(adhesive, isNotNull);
      expect(adhesive!.item.trade, 'Masonry and Concrete');
      expect(adhesive.item.name, contains('Landscape Block Adhesive'));
    },
  );

  test(
    'masonry parser understands slab joint stain and stucco accessories',
    () {
      final joint = matchReceiptLineToCatalog('1/2 IN ZIP STRIP CONTROL JOINT');
      expect(joint, isNotNull);
      expect(joint!.item.trade, 'Masonry and Concrete');
      expect(joint.item.name, contains('Control Joint'));

      final stain = matchReceiptLineToCatalog('1GAL ACID STAIN CONCRETE');
      expect(stain, isNotNull);
      expect(stain!.item.trade, 'Masonry and Concrete');
      expect(stain.item.name, contains('Acid Stain'));

      final screed = matchReceiptLineToCatalog('10FT GALVANIZED WEEP SCREED');
      expect(screed, isNotNull);
      expect(screed!.item.trade, 'Masonry and Concrete');
      expect(screed.item.name, contains('Weep Screed'));

      final lath = matchReceiptLineToCatalog(
        '27IN X 8FT SELF FURRING METAL LATH',
      );
      expect(lath, isNotNull);
      expect(lath!.item.trade, 'Masonry and Concrete');
      expect(lath.item.name, contains('Self Furring Metal Lath'));
    },
  );

  test('masonry parser understands chimney hardscape and tool consumables', () {
    final flue = matchReceiptLineToCatalog('8X12 CLAY FLUE LINER');
    expect(flue, isNotNull);
    expect(flue!.item.trade, 'Masonry and Concrete');
    expect(flue.item.name, contains('Clay Flue Liner'));

    final paverEdge = matchReceiptLineToCatalog('8FT PAVER EDGE RESTRAINT');
    expect(paverEdge, isNotNull);
    expect(paverEdge!.item.trade, 'Masonry and Concrete');
    expect(paverEdge.item.name, contains('Paver Edge Restraint'));

    final blade = matchReceiptLineToCatalog('7IN CONCRETE DIAMOND BLADE');
    expect(blade, isNotNull);
    expect(blade!.item.trade, 'Masonry and Concrete');
    expect(blade.item.name, contains('Concrete Diamond Blade'));

    final bit = matchReceiptLineToCatalog('1/2IN SDS MASONRY BIT');
    expect(bit, isNotNull);
    expect(bit!.item.trade, 'Masonry and Concrete');
    expect(bit.item.name, contains('SDS Masonry Bit'));
  });

  test('masonry parser understands expanded detail stock receipts', () {
    final psiMix = matchReceiptLineToCatalog('80LB 5000 PSI CONCRETE MIX');
    expect(psiMix, isNotNull);
    expect(psiMix!.item.trade, 'Masonry and Concrete');
    expect(psiMix.item.name, contains('80 lb 5000 PSI Concrete Mix'));

    final color = matchReceiptLineToCatalog(
      '5LB CHARCOAL INTEGRAL CONCRETE COLOR',
    );
    expect(color, isNotNull);
    expect(color!.item.trade, 'Masonry and Concrete');
    expect(color.item.name, contains('Charcoal Integral Concrete Color'));

    final paver = matchReceiptLineToCatalog('CHARCOAL 4X8 HOLLAND PAVER');
    expect(paver, isNotNull);
    expect(paver!.item.trade, 'Masonry and Concrete');
    expect(paver.item.name, contains('Charcoal 4 x 8 in Holland Paver'));

    final tube = matchReceiptLineToCatalog('12IN X 60IN CONCRETE FORM TUBE');
    expect(tube, isNotNull);
    expect(tube!.item.trade, 'Masonry and Concrete');
    expect(tube.item.name, contains('12 in x 60 in Concrete Form Tube'));

    final screw = matchReceiptLineToCatalog('3/16 X 1-3/4 BLUE CONCRETE SCREW');
    expect(screw, isNotNull);
    expect(screw!.item.trade, 'Masonry and Concrete');
    expect(screw.item.name, contains('3/16 in x 1-3/4 in Blue Concrete Screw'));

    final lath = matchReceiptLineToCatalog(
      '36IN X 150FT PAPER BACKED WIRE LATH',
    );
    expect(lath, isNotNull);
    expect(lath!.item.trade, 'Masonry and Concrete');
    expect(lath.item.name, contains('Paper Backed Wire Lath'));

    final bit = matchReceiptLineToCatalog('5/8IN SDS PLUS MASONRY BIT');
    expect(bit, isNotNull);
    expect(bit!.item.trade, 'Masonry and Concrete');
    expect(bit.item.name, contains('5/8 in SDS Plus Masonry Bit'));
  });

  test('landscaping parser understands irrigation and drainage receipts', () {
    final drip = matchReceiptLineToCatalog('1/2 IN X 100 FT DRIP TUBING');
    expect(drip, isNotNull);
    expect(drip!.item.trade, 'Landscaping');
    expect(drip.item.name, contains('1/2 in x 100 ft Drip Tubing'));
    expect(drip.confidenceLevel, ReceiptConfidenceLevel.good);

    final sprinkler = matchReceiptLineToCatalog('ROTOR SPRINKLER HEAD');
    expect(sprinkler, isNotNull);
    expect(sprinkler!.item.trade, 'Landscaping');
    expect(sprinkler.item.name, contains('Sprinkler Head'));

    final basin = matchReceiptLineToCatalog('12X12 CATCH BASIN DRAIN BOX');
    expect(basin, isNotNull);
    expect(basin!.item.trade, 'Landscaping');
    expect(basin.item.name, contains('12 x 12 in Catch Basin'));

    final funnyPipe = matchReceiptLineToCatalog('1/2 IN SWING PIPE FUNNY PIPE');
    expect(funnyPipe, isNotNull);
    expect(funnyPipe!.item.trade, 'Landscaping');
    expect(funnyPipe.item.name, contains('Funny Pipe'));

    final ezDrain = matchReceiptLineToCatalog('4 IN EZ DRAIN BUNDLE');
    expect(ezDrain, isNotNull);
    expect(ezDrain!.item.trade, 'Landscaping');
    expect(ezDrain.item.name, contains('EZ Drain'));
  });

  test('landscaping parser understands hardscape mulch and fabric', () {
    final base = matchReceiptLineToCatalog('40LB PAVER BASE');
    expect(base, isNotNull);
    expect(base!.item.trade, 'Landscaping');
    expect(base.item.name, contains('40 lb Paver Base'));

    final mulch = matchReceiptLineToCatalog('2 CU FT BLACK BAGGED MULCH');
    expect(mulch, isNotNull);
    expect(mulch!.item.trade, 'Landscaping');
    expect(mulch.item.name.toLowerCase(), contains('black bagged mulch'));

    final fabric = matchReceiptLineToCatalog(
      '4FT X 100FT WEED BARRIER LANDSCAPE FABRIC',
    );
    expect(fabric, isNotNull);
    expect(fabric!.item.trade, 'Landscaping');
    expect(
      fabric.item.name,
      anyOf(contains('Landscape Fabric'), contains('Weed Barrier')),
    );

    final seed = matchReceiptLineToCatalog('20LB TALL FESCUE GRASS SEED');
    expect(seed, isNotNull);
    expect(seed!.item.trade, 'Landscaping');
    expect(seed.item.name, contains('Tall Fescue Grass Seed'));

    final edging = matchReceiptLineToCatalog('20FT STEEL LANDSCAPE EDGING');
    expect(edging, isNotNull);
    expect(edging!.item.trade, 'Landscaping');
    expect(edging.item.name, contains('Steel Landscape Edging'));
  });

  test('landscaping parser understands repair wire treatment and tools', () {
    final wire = matchReceiptLineToCatalog('18GA 100FT SPRINKLER WIRE');
    expect(wire, isNotNull);
    expect(wire!.item.trade, 'Landscaping');
    expect(wire.item.name, contains('Sprinkler Wire'));

    final greaseCap = matchReceiptLineToCatalog(
      '25PK IRRIGATION GREASE CAP WATERPROOF CONNECTOR',
    );
    expect(greaseCap, isNotNull);
    expect(greaseCap!.item.trade, 'Landscaping');
    expect(greaseCap.item.name, contains('Wire Connector'));

    final weedKiller = matchReceiptLineToCatalog(
      '1GAL CONCENTRATE WEED KILLER',
    );
    expect(weedKiller, isNotNull);
    expect(weedKiller!.item.trade, 'Landscaping');
    expect(weedKiller.item.name, contains('Weed Killer'));

    final trimmerLine = matchReceiptLineToCatalog('TRIMMER LINE SPOOL');
    expect(trimmerLine, isNotNull);
    expect(trimmerLine!.item.trade, 'Landscaping');
    expect(trimmerLine.item.name, contains('Trimmer Line'));
  });

  test('landscaping parser understands sod straw and landscape lighting', () {
    final sod = matchReceiptLineToCatalog('1000 SQ FT SOD ROLL');
    expect(sod, isNotNull);
    expect(sod!.item.trade, 'Landscaping');
    expect(sod.item.name, contains('Sod Roll'));

    final straw = matchReceiptLineToCatalog('2 CU FT PINE STRAW BALE');
    expect(straw, isNotNull);
    expect(straw!.item.trade, 'Landscaping');
    expect(straw.item.name, contains('Pine Straw Bale'));

    final transformer = matchReceiptLineToCatalog(
      '120W LOW VOLTAGE TRANSFORMER',
    );
    expect(transformer, isNotNull);
    expect(transformer!.item.trade, 'Landscaping');
    expect(transformer.item.name, contains('Low Voltage Transformer'));

    final pathLight = matchReceiptLineToCatalog(
      'BRONZE LED LANDSCAPE PATH LIGHT',
    );
    expect(pathLight, isNotNull);
    expect(pathLight!.item.trade, 'Landscaping');
    expect(pathLight.item.name, contains('Landscape Path Light'));
  });

  test(
    'landscaping parser understands sprinkler repair and hardscape extras',
    () {
      final nozzle = matchReceiptLineToCatalog('ADJUSTABLE SPRAY NOZZLE PACK');
      expect(nozzle, isNotNull);
      expect(nozzle!.item.trade, 'Landscaping');
      expect(nozzle.item.name, contains('Sprinkler Repair Part'));

      final riser = matchReceiptLineToCatalog('1/2 X 6 CUT-OFF RISER');
      expect(riser, isNotNull);
      expect(riser!.item.trade, 'Landscaping');
      expect(riser.item.name, contains('Sprinkler Repair Part'));

      final sealer = matchReceiptLineToCatalog('1GAL PAVER SEALER');
      expect(sealer, isNotNull);
      expect(sealer!.item.trade, 'Landscaping');
      expect(sealer.item.name, contains('Hardscape Accessory'));

      final geogrid = matchReceiptLineToCatalog('GEOGRID RETAINING WALL GRID');
      expect(geogrid, isNotNull);
      expect(geogrid!.item.trade, 'Landscaping');
      expect(geogrid.item.name, contains('Hardscape Accessory'));
    },
  );

  test('landscaping parser understands planting and equipment consumables', () {
    final treeTie = matchReceiptLineToCatalog('3IN TREE TIE STRAP ROLL');
    expect(treeTie, isNotNull);
    expect(treeTie!.item.trade, 'Landscaping');
    expect(treeTie.item.name, contains('Tree Tie Strap Roll'));

    final rootStimulator = matchReceiptLineToCatalog('ROOT STIMULATOR 1 GAL');
    expect(rootStimulator, isNotNull);
    expect(rootStimulator!.item.trade, 'Landscaping');
    expect(rootStimulator.item.name, contains('1 gal Root Stimulator'));

    final oil = matchReceiptLineToCatalog('2 CYCLE OIL 2.6 OZ');
    expect(oil, isNotNull);
    expect(oil!.item.trade, 'Landscaping');
    expect(oil.item.name, contains('Landscape Equipment Consumable'));

    final plug = matchReceiptLineToCatalog('MOWER SPARK PLUG');
    expect(plug, isNotNull);
    expect(plug!.item.trade, 'Landscaping');
    expect(plug.item.name, contains('Landscape Equipment Consumable'));
  });

  test('landscaping parser understands drip valve and drainage detail', () {
    final emitter = matchReceiptLineToCatalog(
      '2 GPH PRESSURE COMPENSATING DRIP EMITTER 25PK',
    );
    expect(emitter, isNotNull);
    expect(emitter!.item.trade, 'Landscaping');
    expect(emitter.item.name, contains('Pressure Compensating Drip Emitter'));

    final manifold = matchReceiptLineToCatalog('DRIP MANIFOLD 6 OUTLET');
    expect(manifold, isNotNull);
    expect(manifold!.item.trade, 'Landscaping');
    expect(manifold.item.name, contains('Drip Manifold 6 Outlet'));

    final channelGrate = matchReceiptLineToCatalog('4IN CHANNEL DRAIN GRATE');
    expect(channelGrate, isNotNull);
    expect(channelGrate!.item.trade, 'Landscaping');
    expect(channelGrate.item.name, contains('Channel Drain Grate'));

    final atrium = matchReceiptLineToCatalog('12X12 ATRIUM GRATE');
    expect(atrium, isNotNull);
    expect(atrium!.item.trade, 'Landscaping');
    expect(atrium.item.name, contains('Atrium Grate'));
  });

  test('landscaping parser understands turf edging and lighting detail', () {
    final edging = matchReceiptLineToCatalog('20FT NO-DIG LANDSCAPE EDGING');
    expect(edging, isNotNull);
    expect(edging!.item.trade, 'Landscaping');
    expect(edging.item.name, contains('No-Dig Landscape Edging'));

    final turf = matchReceiptLineToCatalog('6FT X 8FT ARTIFICIAL TURF ROLL');
    expect(turf, isNotNull);
    expect(turf!.item.trade, 'Landscaping');
    expect(turf.item.name, contains('Artificial Turf Roll'));

    final wallCap = matchReceiptLineToCatalog('RETAINING WALL CAP');
    expect(wallCap, isNotNull);
    expect(wallCap!.item.trade, 'Landscaping');
    expect(wallCap.item.name, contains('Retaining Wall Cap'));

    final connector = matchReceiptLineToCatalog(
      'LANDSCAPE LIGHTING WIRE CONNECTOR 25PK',
    );
    expect(connector, isNotNull);
    expect(connector!.item.trade, 'Landscaping');
    expect(connector.item.name, contains('Landscape Lighting Wire Connector'));

    final hardscapeLight = matchReceiptLineToCatalog(
      'BRONZE HARDSCAPE WALL LIGHT',
    );
    expect(hardscapeLight, isNotNull);
    expect(hardscapeLight!.item.trade, 'Landscaping');
    expect(hardscapeLight.item.name, contains('Hardscape Wall Light'));
  });

  test('landscaping parser understands expanded detail stock receipts', () {
    final bluLock = matchReceiptLineToCatalog(
      '1IN BLU-LOCK TEE',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(bluLock, isNotNull);
    expect(bluLock!.item.trade, 'Landscaping');
    expect(bluLock.item.name, contains('1 in Blu-Lock Tee'));

    final basinAdapter = matchReceiptLineToCatalog(
      '12X12 CATCH BASIN OUTLET ADAPTER',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(basinAdapter, isNotNull);
    expect(basinAdapter!.item.trade, 'Landscaping');
    expect(basinAdapter.item.name, contains('12 x 12 in Catch Basin Outlet'));

    final mulch = matchReceiptLineToCatalog(
      '3 CU FT RED BAGGED MULCH',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(mulch, isNotNull);
    expect(mulch!.item.trade, 'Landscaping');
    expect(mulch.item.name, contains('3 cu ft Red Bagged Mulch'));

    final weedControl = matchReceiptLineToCatalog(
      '2GAL PRE-EMERGENT WEED CONTROL',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(weedControl, isNotNull);
    expect(weedControl!.item.trade, 'Landscaping');
    expect(weedControl.item.name, contains('2 gal Pre-Emergent Weed Control'));

    final paverPanel = matchReceiptLineToCatalog(
      'PAVER SAND BASE PANEL 20PK',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(paverPanel, isNotNull);
    expect(paverPanel!.item.trade, 'Landscaping');
    expect(paverPanel.item.name, contains('Paver Sand Base Panel 20 Pack'));

    final lightingWire = matchReceiptLineToCatalog(
      '12/2 250FT LOW VOLTAGE LANDSCAPE WIRE',
      tradeScope: 'Landscaping',
      maxCandidates: 220,
    );
    expect(lightingWire, isNotNull);
    expect(lightingWire!.item.trade, 'Landscaping');
    expect(lightingWire.item.name, contains('12/2 x 250 ft'));
    expect(lightingWire.item.name, contains('Low Voltage Landscape Wire'));
  });
}
