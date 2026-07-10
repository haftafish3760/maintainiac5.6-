import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core parser handles sealant shorthand batch four', () {
    final pipeDope = matchReceiptLineToCatalog(
      'HD PIPE DOPE THREAD SEALANT 4OZ',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pipeDope, isNotNull);
    expect(pipeDope!.item.name.toLowerCase(), contains('thread sealant'));
    expect(pipeDope.confidenceLevel, ReceiptConfidenceLevel.good);

    final gasTape = matchReceiptLineToCatalog(
      'LOWES YELLOW GAS PTFE TAPE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(gasTape, isNotNull);
    expect(gasTape!.item.name.toLowerCase(), contains('ptfe'));
    expect(gasTape.confidenceLevel, ReceiptConfidenceLevel.good);

    final pipeLube = matchReceiptLineToCatalog(
      'FERG PIPE LUBE GASKET LUBRICANT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pipeLube, isNotNull);
    expect(pipeLube!.item.name.toLowerCase(), contains('lubricant'));
    expect(pipeLube.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles faucet washer and packing shorthand batch four',
    () {
      final faucetWasher = matchReceiptLineToCatalog(
        'ACE ASSORTED FAUCET WASHER KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(faucetWasher, isNotNull);
      expect(faucetWasher!.item.name.toLowerCase(), contains('washer'));
      expect(faucetWasher.confidenceLevel, ReceiptConfidenceLevel.good);

      final seatWasher = matchReceiptLineToCatalog(
        'HD SEAT WASHER FAUCET REPAIR',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(seatWasher, isNotNull);
      expect(seatWasher!.item.name.toLowerCase(), contains('seat'));
      expect(seatWasher.confidenceLevel, ReceiptConfidenceLevel.good);

      final bonnetPacking = matchReceiptLineToCatalog(
        'LOWES GRAPHITE BONNET PACKING',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(bonnetPacking, isNotNull);
      expect(bonnetPacking!.item.name.toLowerCase(), contains('packing'));
      expect(bonnetPacking.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles toilet and hose seal shorthand batch four',
    () {
      final tankGasket = matchReceiptLineToCatalog(
        'WALMART TANK TO BOWL GASKET KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(tankGasket, isNotNull);
      expect(tankGasket!.item.name.toLowerCase(), contains('gasket'));
      expect(tankGasket.confidenceLevel, ReceiptConfidenceLevel.good);

      final fillValveWasher = matchReceiptLineToCatalog(
        'HD FILL VALVE SHANK WASHER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(fillValveWasher, isNotNull);
      expect(fillValveWasher!.item.name.toLowerCase(), contains('washer'));
      expect(fillValveWasher.confidenceLevel, ReceiptConfidenceLevel.good);

      final hoseWasher = matchReceiptLineToCatalog(
        'ACE HOSE BIBB WASHER 10PK',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(hoseWasher, isNotNull);
      expect(hoseWasher!.item.name.toLowerCase(), contains('hose'));
      expect(hoseWasher.item.name.toLowerCase(), contains('washer'));
      expect(hoseWasher.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles dishwasher disposal shorthand batch four',
    () {
      final dishwasherHose = matchReceiptLineToCatalog(
        'LOWES 7/8 DISHWASHER DRAIN HOSE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(dishwasherHose, isNotNull);
      expect(dishwasherHose!.item.name.toLowerCase(), contains('dishwasher'));
      expect(dishwasherHose.item.name.toLowerCase(), contains('hose'));
      expect(dishwasherHose.confidenceLevel, ReceiptConfidenceLevel.good);

      final branchTailpiece = matchReceiptLineToCatalog(
        'HD DISHWASHER BRANCH TAILPIECE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(branchTailpiece, isNotNull);
      expect(branchTailpiece!.item.name.toLowerCase(), contains('dishwasher'));
      expect(branchTailpiece.item.name.toLowerCase(), contains('tailpiece'));
      expect(branchTailpiece.confidenceLevel, ReceiptConfidenceLevel.good);

      final airGap = matchReceiptLineToCatalog(
        'ACE DISHWASHER AIR GAP CHROME CAP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(airGap, isNotNull);
      expect(airGap!.item.name.toLowerCase(), contains('air gap'));
      expect(airGap.confidenceLevel, ReceiptConfidenceLevel.good);

      final disposalGasket = matchReceiptLineToCatalog(
        'LOWES DISPOSAL ELBOW GASKET KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(disposalGasket, isNotNull);
      expect(disposalGasket!.item.name.toLowerCase(), contains('disposal'));
      expect(disposalGasket.item.name.toLowerCase(), contains('gasket'));
      expect(disposalGasket.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles slip joint washer shorthand batch four',
    () {
      final trapWasher = matchReceiptLineToCatalog(
        'HD 1-1/2 BEVELED TRAP WASHER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(trapWasher, isNotNull);
      expect(trapWasher!.item.name.toLowerCase(), contains('washer'));
      expect(trapWasher.confidenceLevel, ReceiptConfidenceLevel.good);

      final reducingWasher = matchReceiptLineToCatalog(
        'ACE RUBBER REDUCING WASHER 1-1/2 X 1-1/4',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(reducingWasher, isNotNull);
      expect(reducingWasher!.item.name.toLowerCase(), contains('washer'));
      expect(reducingWasher.confidenceLevel, ReceiptConfidenceLevel.good);

      final nutWasherKit = matchReceiptLineToCatalog(
        'LOWES SLIP JOINT NUT AND WASHER KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(nutWasherKit, isNotNull);
      expect(nutWasherKit!.item.name.toLowerCase(), contains('washer'));
      expect(nutWasherKit.item.name.toLowerCase(), contains('nut'));
      expect(nutWasherKit.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles support fastener shorthand batch four',
    () {
      final strutNut = matchReceiptLineToCatalog(
        'GRAINGER 3/8 STRUT NUT 25PK',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(strutNut, isNotNull);
      expect(strutNut!.item.name.toLowerCase(), contains('strut nut'));
      expect(strutNut.confidenceLevel, ReceiptConfidenceLevel.good);

      final couplingNut = matchReceiptLineToCatalog(
        'HD 3/8 ROD COUPLING NUT 10PK',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(couplingNut, isNotNull);
      expect(couplingNut!.item.name.toLowerCase(), contains('coupling nut'));
      expect(couplingNut.confidenceLevel, ReceiptConfidenceLevel.good);

      final tapcon = matchReceiptLineToCatalog(
        'LOWES 1/4 X 2-1/4 TAPCON BLUE SCREW',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(tapcon, isNotNull);
      expect(tapcon!.item.name.toLowerCase(), contains('concrete screw'));
      expect(tapcon.confidenceLevel, ReceiptConfidenceLevel.good);

      final wedgeAnchor = matchReceiptLineToCatalog(
        'FERG 3/8 WEDGE ANCHOR ROD HANGER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(wedgeAnchor, isNotNull);
      expect(wedgeAnchor!.item.name.toLowerCase(), contains('wedge anchor'));
      expect(wedgeAnchor.confidenceLevel, ReceiptConfidenceLevel.good);

      final riserClamp = matchReceiptLineToCatalog(
        'HD 2 IN PIPE RISER CLAMP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(riserClamp, isNotNull);
      expect(riserClamp!.item.name.toLowerCase(), contains('riser clamp'));
      expect(riserClamp.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles pipe support accessories batch four', () {
    final pipeInsulation = matchReceiptLineToCatalog(
      'LOWES 3/4 X 6FT FOAM PIPE INSULATION',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pipeInsulation, isNotNull);
    expect(
      pipeInsulation!.item.name.toLowerCase(),
      contains('pipe insulation'),
    );
    expect(pipeInsulation.confidenceLevel, ReceiptConfidenceLevel.good);

    final studGuard = matchReceiptLineToCatalog(
      'HD 3 X 5 STUD GUARD NAIL PLATE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(studGuard, isNotNull);
    expect(studGuard!.item.name.toLowerCase(), contains('stud guard'));
    expect(studGuard.confidenceLevel, ReceiptConfidenceLevel.good);

    final splitRing = matchReceiptLineToCatalog(
      'FERG 1 IN SPLIT RING PIPE HANGER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(splitRing, isNotNull);
    expect(splitRing!.item.name.toLowerCase(), contains('split ring'));
    expect(splitRing.confidenceLevel, ReceiptConfidenceLevel.good);

    final bellHanger = matchReceiptLineToCatalog(
      'ACE 3/4 COPPER BELL HANGER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(bellHanger, isNotNull);
    expect(bellHanger!.item.name.toLowerCase(), contains('bell hanger'));
    expect(bellHanger.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
