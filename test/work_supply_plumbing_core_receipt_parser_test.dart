import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core parser handles shutoff and valve receipt shorthand', () {
    final angleStop = matchReceiptLineToCatalog(
      'LOWES 3/8 X 1/2 ANG STOP QTR TURN',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(angleStop, isNotNull);
    expect(angleStop!.item.name.toLowerCase(), contains('angle stop'));
    expect(angleStop.confidenceLevel, ReceiptConfidenceLevel.good);

    final prv = matchReceiptLineToCatalog(
      'HD 3/4 PRESS RED VALVE PRV',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(prv, isNotNull);
    expect(prv!.item.name.toLowerCase(), contains('pressure reducing'));
    expect(prv.confidenceLevel, ReceiptConfidenceLevel.good);

    final hoseVacBreaker = matchReceiptLineToCatalog(
      'ACE 3/4 HOSE BIBB VAC BRKR',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(hoseVacBreaker, isNotNull);
    expect(hoseVacBreaker!.item.name.toLowerCase(), contains('vacuum'));
    expect(hoseVacBreaker.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles water heater repair shorthand', () {
    final relief = matchReceiptLineToCatalog(
      'FERG WTR HTR 3/4 T&P RELIEF VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(relief, isNotNull);
    expect(relief!.item.name.toLowerCase(), contains('relief valve'));
    expect(relief.confidenceLevel, ReceiptConfidenceLevel.good);

    final anode = matchReceiptLineToCatalog(
      'SUPPLYHOUSE 42 IN MAG ANODE ROD WH',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(anode, isNotNull);
    expect(anode!.item.name.toLowerCase(), contains('anode rod'));
    expect(anode.confidenceLevel, ReceiptConfidenceLevel.good);

    final element = matchReceiptLineToCatalog(
      'HD 4500W WTR HTR ELEMENT SCREW IN',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(element, isNotNull);
    expect(element!.item.name.toLowerCase(), contains('element'));
    expect(element.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles toilet and faucet repair shorthand', () {
    final fillValve = matchReceiptLineToCatalog(
      'WALMART UNIV TOILET FILL VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(fillValve, isNotNull);
    expect(fillValve!.item.name.toLowerCase(), contains('fill valve'));
    expect(fillValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final flapper = matchReceiptLineToCatalog(
      'TRUE VALUE 3 IN TOILET FLAPPER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(flapper, isNotNull);
    expect(flapper!.item.name.toLowerCase(), contains('flapper'));
    expect(flapper.confidenceLevel, ReceiptConfidenceLevel.good);

    final faucetCart = matchReceiptLineToCatalog(
      'LOWES SINGLE HANDLE FAUCET CARTRIDGE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(faucetCart, isNotNull);
    expect(faucetCart!.item.name.toLowerCase(), contains('cartridge'));
    expect(faucetCart.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles drain consumables and sealants', () {
    final waxRing = matchReceiptLineToCatalog(
      'HD EXTRA THICK WAX RING BOLTS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(waxRing, isNotNull);
    expect(waxRing!.item.name.toLowerCase(), contains('wax'));
    expect(waxRing.confidenceLevel, ReceiptConfidenceLevel.good);

    final pvcCement = matchReceiptLineToCatalog(
      'MENARDS PVC CEMENT CLEAR 8 OZ',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pvcCement, isNotNull);
    expect(pvcCement!.item.name.toLowerCase(), contains('cement'));
    expect(pvcCement.confidenceLevel, ReceiptConfidenceLevel.good);

    final threadTape = matchReceiptLineToCatalog(
      'ACE PTFE THREAD TAPE WHITE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(threadTape, isNotNull);
    expect(threadTape!.item.name.toLowerCase(), contains('tape'));
    expect(threadTape.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles adapter and supply-line shorthand', () {
    final pexMaleAdapter = matchReceiptLineToCatalog(
      'LOWES 1/2 PEX MIP ADPT CRIMP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexMaleAdapter, isNotNull);
    expect(pexMaleAdapter!.item.name.toLowerCase(), contains('pex'));
    expect(pexMaleAdapter.item.name.toLowerCase(), contains('male adapter'));
    expect(pexMaleAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcFemaleAdapter = matchReceiptLineToCatalog(
      'HD 3/4 CPVC FIP ADAPT CTS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcFemaleAdapter, isNotNull);
    expect(cpvcFemaleAdapter!.item.name.toLowerCase(), contains('cpvc'));
    expect(
      cpvcFemaleAdapter.item.name.toLowerCase(),
      contains('female adapter'),
    );
    expect(cpvcFemaleAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final faucetConnector = matchReceiptLineToCatalog(
      'ACE 3/8 X 1/2 FAUCET CONN BRAIDED',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(faucetConnector, isNotNull);
    expect(faucetConnector!.item.name.toLowerCase(), contains('faucet'));
    expect(faucetConnector.item.name.toLowerCase(), contains('supply line'));
    expect(faucetConnector.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles cleanout and support shorthand', () {
    final cleanoutCover = matchReceiptLineToCatalog(
      'HD 4 IN CO COVER CLEANOUT PLATE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cleanoutCover, isNotNull);
    expect(cleanoutCover!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanoutCover.item.name.toLowerCase(), contains('cover'));
    expect(cleanoutCover.confidenceLevel, ReceiptConfidenceLevel.good);

    final pipeStrap = matchReceiptLineToCatalog(
      'LOWES 3/4 COPPER PIPE STRAP 2 HOLE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pipeStrap, isNotNull);
    expect(pipeStrap!.item.name.toLowerCase(), contains('pipe strap'));
    expect(pipeStrap.confidenceLevel, ReceiptConfidenceLevel.good);

    final jHook = matchReceiptLineToCatalog(
      'MENARDS 1/2 PEX J HOOK PIPE HANGER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(jHook, isNotNull);
    expect(jHook!.item.name.toLowerCase(), contains('j-hook'));
    expect(jHook.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles fixture and appliance hookup shorthand',
    () {
      final tubSpout = matchReceiptLineToCatalog(
        'HD CHROME TUB SPOUT DIVERTER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(tubSpout, isNotNull);
      expect(tubSpout!.item.name.toLowerCase(), contains('tub spout'));
      expect(tubSpout.confidenceLevel, ReceiptConfidenceLevel.good);

      final showerCart = matchReceiptLineToCatalog(
        'LOWES POSI TEMP SHOWER CARTRIDGE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(showerCart, isNotNull);
      expect(showerCart!.item.name.toLowerCase(), contains('cartridge'));
      expect(showerCart.confidenceLevel, ReceiptConfidenceLevel.good);

      final disposalSplash = matchReceiptLineToCatalog(
        'ACE GARBAGE DISPOSAL SPLASH GUARD',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(disposalSplash, isNotNull);
      expect(disposalSplash!.item.name.toLowerCase(), contains('splash guard'));
      expect(disposalSplash.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles pump and toilet install shorthand', () {
    final pumpFloat = matchReceiptLineToCatalog(
      'MENARDS SUMP PUMP PIGGYBACK FLOAT SWITCH',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pumpFloat, isNotNull);
    expect(pumpFloat!.item.name.toLowerCase(), contains('float switch'));
    expect(pumpFloat.confidenceLevel, ReceiptConfidenceLevel.good);

    final closetFlange = matchReceiptLineToCatalog(
      'LOWES 4 X 3 PVC CLOSET FLG',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(closetFlange, isNotNull);
    expect(closetFlange!.item.name.toLowerCase(), contains('closet flange'));
    expect(closetFlange.confidenceLevel, ReceiptConfidenceLevel.good);

    final closetBolts = matchReceiptLineToCatalog(
      'HD TOILET CLOSET BOLTS BRASS 5/16',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(closetBolts, isNotNull);
    expect(closetBolts!.item.name.toLowerCase(), contains('closet bolt'));
    expect(closetBolts.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles DWV trap and tubular shorthand', () {
    final pTrap = matchReceiptLineToCatalog(
      'LOWES 1-1/2 PVC P TRAP KIT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pTrap, isNotNull);
    expect(pTrap!.item.name.toLowerCase(), contains('trap'));
    expect(pTrap.confidenceLevel, ReceiptConfidenceLevel.good);

    final tailpiece = matchReceiptLineToCatalog(
      'HD 1-1/2 X 12 TAILPC EXT TUBE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(tailpiece, isNotNull);
    expect(tailpiece!.item.name.toLowerCase(), contains('tailpiece'));
    expect(tailpiece.confidenceLevel, ReceiptConfidenceLevel.good);

    final slipNut = matchReceiptLineToCatalog(
      'ACE 1-1/2 S/J NUT WASHER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(slipNut, isNotNull);
    expect(slipNut!.item.name.toLowerCase(), contains('slip joint'));
    expect(slipNut.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles service fastener shorthand', () {
    final tapcon = matchReceiptLineToCatalog(
      'HD 1/4 X 2-1/4 TAPCON BLUE SCREW',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(tapcon, isNotNull);
    expect(tapcon!.item.name.toLowerCase(), contains('concrete screw'));
    expect(tapcon.confidenceLevel, ReceiptConfidenceLevel.good);

    final strutNut = matchReceiptLineToCatalog(
      'GRAINGER 3/8 STRUT NUT SPRING NUT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(strutNut, isNotNull);
    expect(strutNut!.item.name.toLowerCase(), contains('strut'));
    expect(strutNut.confidenceLevel, ReceiptConfidenceLevel.good);

    final beamClamp = matchReceiptLineToCatalog(
      'FERG 3/8 ROD BEAM CLAMP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(beamClamp, isNotNull);
    expect(beamClamp!.item.name.toLowerCase(), contains('beam clamp'));
    expect(beamClamp.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles common OCR-output substitutions', () {
    final pexElbow = matchReceiptLineToCatalog(
      'LOWES I/2 PEX CRMP E1B BRASS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexElbow, isNotNull);
    expect(pexElbow!.item.name.toLowerCase(), contains('pex'));
    expect(pexElbow.item.name.toLowerCase(), contains('elbow'));
    expect(pexElbow.confidenceLevel, ReceiptConfidenceLevel.good);

    final pvcCoupling = matchReceiptLineToCatalog(
      'HD 3/4 PYC S40 CPLG',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pvcCoupling, isNotNull);
    expect(pvcCoupling!.item.name.toLowerCase(), contains('pvc schedule 40'));
    expect(pvcCoupling.item.name.toLowerCase(), contains('coupling'));
    expect(pvcCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcAdapter = matchReceiptLineToCatalog(
      'MENARDS I/2 CPYG FIP ADPT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcAdapter, isNotNull);
    expect(cpvcAdapter!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcAdapter.item.name.toLowerCase(), contains('female adapter'));
    expect(cpvcAdapter.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser avoids high confidence on vague core lines', () {
    final vagueElbow = matchReceiptLineToCatalog(
      'LOWES 1/2 ELBOW',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(vagueElbow, isNotNull);
    expect(vagueElbow!.confidenceLevel, isNot(ReceiptConfidenceLevel.good));

    final vagueAdapter = matchReceiptLineToCatalog(
      'HD 3/4 ADAPTER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(vagueAdapter, isNotNull);
    expect(vagueAdapter!.confidenceLevel, isNot(ReceiptConfidenceLevel.good));

    final vagueValve = matchReceiptLineToCatalog(
      'ACE 3/4 VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(vagueValve, isNotNull);
    expect(vagueValve!.confidenceLevel, isNot(ReceiptConfidenceLevel.good));
  });

  test('plumbing core parser handles rings clamps pipe and DWV shorthand', () {
    final crimpRing = matchReceiptLineToCatalog(
      'LOWES 1/2 COPPER PEX CRIMP RING 25PK',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(crimpRing, isNotNull);
    expect(crimpRing!.item.name.toLowerCase(), contains('crimp ring'));
    expect(crimpRing.confidenceLevel, ReceiptConfidenceLevel.good);

    final cinchRing = matchReceiptLineToCatalog(
      'HD 1/2 PEX CINCH CLAMP RING 10PK',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cinchRing, isNotNull);
    expect(cinchRing!.item.name.toLowerCase(), contains('clamp ring'));
    expect(cinchRing.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcPipe = matchReceiptLineToCatalog(
      'MENARDS 3/4 CPVC CTS PIPE 10FT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcPipe, isNotNull);
    expect(cpvcPipe!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcPipe.item.name.toLowerCase(), contains('pipe'));
    expect(cpvcPipe.confidenceLevel, ReceiptConfidenceLevel.good);

    final sanitaryTee = matchReceiptLineToCatalog(
      'HD 2 IN PVC DWV SAN TEE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(sanitaryTee, isNotNull);
    expect(sanitaryTee!.item.name.toLowerCase(), contains('pvc dwv'));
    expect(sanitaryTee.item.name.toLowerCase(), contains('sanitary tee'));
    expect(sanitaryTee.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles push-fit and appliance hookup shorthand',
    () {
      final pushCoupling = matchReceiptLineToCatalog(
        'HD 3/4 SHARKBITE PUSH COUP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pushCoupling, isNotNull);
      expect(pushCoupling!.item.name.toLowerCase(), contains('push-fit'));
      expect(pushCoupling.item.name.toLowerCase(), contains('coupling'));
      expect(pushCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

      final iceMaker = matchReceiptLineToCatalog(
        'LOWES 1/4 X 25 FT ICE MAKER LINE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(iceMaker, isNotNull);
      expect(iceMaker!.item.name.toLowerCase(), contains('ice maker'));
      expect(iceMaker.confidenceLevel, ReceiptConfidenceLevel.good);

      final washerHose = matchReceiptLineToCatalog(
        'WALMART WASHING MACHINE HOSE 6FT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(washerHose, isNotNull);
      expect(washerHose!.item.name.toLowerCase(), contains('washing machine'));
      expect(washerHose.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );
}
