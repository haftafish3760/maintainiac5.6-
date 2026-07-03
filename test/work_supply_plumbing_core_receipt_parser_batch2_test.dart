import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'plumbing core parser handles water heater install accessory shorthand',
    () {
      final expansionTank = matchReceiptLineToCatalog(
        'LOWES 2 GAL THERMAL EXP TANK',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(expansionTank, isNotNull);
      expect(
        expansionTank!.item.name.toLowerCase(),
        contains('expansion tank'),
      );
      expect(expansionTank.confidenceLevel, ReceiptConfidenceLevel.good);

      final heaterPan = matchReceiptLineToCatalog(
        'HD 24IN WATER HEATER PAN W FITTING',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(heaterPan, isNotNull);
      expect(heaterPan!.item.name.toLowerCase(), contains('drain pan'));
      expect(heaterPan.confidenceLevel, ReceiptConfidenceLevel.good);

      final seismicStrap = matchReceiptLineToCatalog(
        'ACE WATER HTR EARTHQUAKE STRAP KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(seismicStrap, isNotNull);
      expect(seismicStrap!.item.name.toLowerCase(), contains('strap'));
      expect(seismicStrap.confidenceLevel, ReceiptConfidenceLevel.good);

      final sedimentTrap = matchReceiptLineToCatalog(
        'FERG GAS SEDIMENT TRAP KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(sedimentTrap, isNotNull);
      expect(sedimentTrap!.item.name.toLowerCase(), contains('sediment trap'));
      expect(sedimentTrap.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles hose bibb and outdoor faucet shorthand',
    () {
      final hoseBibb = matchReceiptLineToCatalog(
        'LOWES 1/2 FIP HOSE BIBB',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(hoseBibb, isNotNull);
      expect(hoseBibb!.item.name.toLowerCase(), contains('hose bibb'));
      expect(hoseBibb.confidenceLevel, ReceiptConfidenceLevel.good);

      final sillcock = matchReceiptLineToCatalog(
        'HD 12IN FROST FREE SILLCOCK ANTI SIPHON',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(sillcock, isNotNull);
      expect(sillcock!.item.name.toLowerCase(), contains('sillcock'));
      expect(sillcock.confidenceLevel, ReceiptConfidenceLevel.good);

      final vacuumBreaker = matchReceiptLineToCatalog(
        'ACE HOSE BIBB VAC BRKR KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(vacuumBreaker, isNotNull);
      expect(
        vacuumBreaker!.item.name.toLowerCase(),
        contains('vacuum breaker'),
      );
      expect(vacuumBreaker.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles toilet service shorthand batch two', () {
    final fillValve = matchReceiptLineToCatalog(
      'WALMART UNIVERSAL TOILET FILL VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(fillValve, isNotNull);
    expect(fillValve!.item.name.toLowerCase(), contains('fill valve'));
    expect(fillValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final waxRing = matchReceiptLineToCatalog(
      'HD EXTRA THICK WAX RING W HORN',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(waxRing, isNotNull);
    expect(waxRing!.item.name.toLowerCase(), contains('wax ring'));
    expect(waxRing.confidenceLevel, ReceiptConfidenceLevel.good);

    final tankLever = matchReceiptLineToCatalog(
      'LOWES TOILET TANK LEVER CHROME',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(tankLever, isNotNull);
    expect(tankLever!.item.name.toLowerCase(), contains('tank lever'));
    expect(tankLever.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles water heater safety repair shorthand', () {
    final tprValve = matchReceiptLineToCatalog(
      'FERG 3/4 T&P RELIEF VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(tprValve, isNotNull);
    expect(tprValve!.item.name.toLowerCase(), contains('relief valve'));
    expect(tprValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final anodeRod = matchReceiptLineToCatalog(
      'HD 42IN ALUM ZINC ANODE ROD',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(anodeRod, isNotNull);
    expect(anodeRod!.item.name.toLowerCase(), contains('anode rod'));
    expect(anodeRod.confidenceLevel, ReceiptConfidenceLevel.good);

    final dielectricUnion = matchReceiptLineToCatalog(
      'LOWES 3/4 DIELECTRIC UNION WTR HTR',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(dielectricUnion, isNotNull);
    expect(dielectricUnion!.item.name.toLowerCase(), contains('dielectric'));
    expect(dielectricUnion.confidenceLevel, ReceiptConfidenceLevel.good);

    final drainValve = matchReceiptLineToCatalog(
      'ACE 3/4 BRASS WATER HEATER DRAIN VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(drainValve, isNotNull);
    expect(drainValve!.item.name.toLowerCase(), contains('drain valve'));
    expect(drainValve.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles faucet repair shorthand batch two', () {
    final aerator = matchReceiptLineToCatalog(
      'HD 15/16 FAUCET AERATOR CHR',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(aerator, isNotNull);
    expect(aerator!.item.name.toLowerCase(), contains('aerator'));
    expect(aerator.confidenceLevel, ReceiptConfidenceLevel.good);

    final cartridge = matchReceiptLineToCatalog(
      'LOWES SINGLE HANDLE FAUCET CARTRIDGE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cartridge, isNotNull);
    expect(cartridge!.item.name.toLowerCase(), contains('cartridge'));
    expect(cartridge.confidenceLevel, ReceiptConfidenceLevel.good);

    final oRingKit = matchReceiptLineToCatalog(
      'ACE FAUCET O RING ASSORTMENT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(oRingKit, isNotNull);
    expect(oRingKit!.item.name.toLowerCase(), contains('o-ring'));
    expect(oRingKit.confidenceLevel, ReceiptConfidenceLevel.good);

    final stemPacking = matchReceiptLineToCatalog(
      'FERG STEM PACKING VALVE REPAIR',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(stemPacking, isNotNull);
    expect(stemPacking!.item.name.toLowerCase(), contains('stem packing'));
    expect(stemPacking.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles pump and discharge shorthand batch two',
    () {
      final sumpPump = matchReceiptLineToCatalog(
        'HD 1/3 HP SUBMERSIBLE SUMP PUMP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(sumpPump, isNotNull);
      expect(sumpPump!.item.name.toLowerCase(), contains('sump pump'));
      expect(sumpPump.confidenceLevel, ReceiptConfidenceLevel.good);

      final condensatePump = matchReceiptLineToCatalog(
        'LOWES CONDENSATE REMOVAL PUMP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(condensatePump, isNotNull);
      expect(
        condensatePump!.item.name.toLowerCase(),
        contains('condensate pump'),
      );
      expect(condensatePump.confidenceLevel, ReceiptConfidenceLevel.good);

      final pumpCheck = matchReceiptLineToCatalog(
        'ACE 1-1/2 SUMP PUMP CHECK VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pumpCheck, isNotNull);
      expect(pumpCheck!.item.name.toLowerCase(), contains('check valve'));
      expect(pumpCheck.confidenceLevel, ReceiptConfidenceLevel.good);

      final dischargeHose = matchReceiptLineToCatalog(
        'MENARDS SUMP PUMP DISCHARGE HOSE KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(dischargeHose, isNotNull);
      expect(
        dischargeHose!.item.name.toLowerCase(),
        contains('discharge hose'),
      );
      expect(dischargeHose.confidenceLevel, ReceiptConfidenceLevel.good);

      final floatSwitch = matchReceiptLineToCatalog(
        'FERG PUMP FLOAT SWITCH TETHERED',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(floatSwitch, isNotNull);
      expect(floatSwitch!.item.name.toLowerCase(), contains('float switch'));
      expect(floatSwitch.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles drain finish shorthand batch two', () {
    final trapAdapter = matchReceiptLineToCatalog(
      'HD 1-1/2 PVC DWV TRAP ADAPTER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(trapAdapter, isNotNull);
    expect(trapAdapter!.item.name.toLowerCase(), contains('trap adapter'));
    expect(trapAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final marvelAdapter = matchReceiptLineToCatalog(
      'LOWES 1-1/2 MARVEL ADAPTER TUBULAR',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(marvelAdapter, isNotNull);
    expect(marvelAdapter!.item.name.toLowerCase(), contains('adapter'));
    expect(marvelAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final cleanoutPlug = matchReceiptLineToCatalog(
      'FERG 4 IN BRASS CO PLUG CLEANOUT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cleanoutPlug, isNotNull);
    expect(cleanoutPlug!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanoutPlug.item.name.toLowerCase(), contains('plug'));
    expect(cleanoutPlug.confidenceLevel, ReceiptConfidenceLevel.good);

    final flangeRepair = matchReceiptLineToCatalog(
      'ACE STAINLESS TOILET FLANGE REPAIR RING',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(flangeRepair, isNotNull);
    expect(flangeRepair!.item.name.toLowerCase(), contains('flange repair'));
    expect(flangeRepair.confidenceLevel, ReceiptConfidenceLevel.good);

    final basketStrainer = matchReceiptLineToCatalog(
      'HD KITCHEN SINK BASKET STRAINER SS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(basketStrainer, isNotNull);
    expect(
      basketStrainer!.item.name.toLowerCase(),
      contains('basket strainer'),
    );
    expect(basketStrainer.confidenceLevel, ReceiptConfidenceLevel.good);

    final popUpDrain = matchReceiptLineToCatalog(
      'LOWES LAV POP UP DRAIN CHROME',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(popUpDrain, isNotNull);
    expect(popUpDrain!.item.name.toLowerCase(), contains('pop-up'));
    expect(popUpDrain.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles valve and protection shorthand batch two',
    () {
      final prv = matchReceiptLineToCatalog(
        'FERG 3/4 PRESS REDUCING VALVE PRV',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(prv, isNotNull);
      expect(prv!.item.name.toLowerCase(), contains('pressure reducing valve'));
      expect(prv.confidenceLevel, ReceiptConfidenceLevel.good);

      final threadedBallValve = matchReceiptLineToCatalog(
        'HD 1/2 FIP FULL PORT BALL VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(threadedBallValve, isNotNull);
      expect(
        threadedBallValve!.item.name.toLowerCase(),
        contains('ball valve'),
      );
      expect(threadedBallValve.item.name.toLowerCase(), contains('threaded'));
      expect(threadedBallValve.confidenceLevel, ReceiptConfidenceLevel.good);

      final pvcBallValve = matchReceiptLineToCatalog(
        'LOWES 1 PVC SLIP BALL VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pvcBallValve, isNotNull);
      expect(pvcBallValve!.item.name.toLowerCase(), contains('pvc ball valve'));
      expect(pvcBallValve.confidenceLevel, ReceiptConfidenceLevel.good);

      final gateValve = matchReceiptLineToCatalog(
        'ACE 3/4 WATER GATE VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(gateValve, isNotNull);
      expect(gateValve!.item.name.toLowerCase(), contains('gate valve'));
      expect(gateValve.confidenceLevel, ReceiptConfidenceLevel.good);

      final backwaterValve = matchReceiptLineToCatalog(
        'FERG 4 IN SEWER BACKWATER VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(backwaterValve, isNotNull);
      expect(
        backwaterValve!.item.name.toLowerCase(),
        contains('backwater valve'),
      );
      expect(backwaterValve.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles heater connection shorthand batch two',
    () {
      final dielectricNipple = matchReceiptLineToCatalog(
        'LOWES 3/4 X 3 DIELECTRIC NIPPLE WTR HTR',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(dielectricNipple, isNotNull);
      expect(dielectricNipple!.item.name.toLowerCase(), contains('dielectric'));
      expect(dielectricNipple.item.name.toLowerCase(), contains('nipple'));
      expect(dielectricNipple.confidenceLevel, ReceiptConfidenceLevel.good);

      final boilerDrain = matchReceiptLineToCatalog(
        'HD 3/4 BRASS BOILER DRAIN',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(boilerDrain, isNotNull);
      expect(boilerDrain!.item.name.toLowerCase(), contains('drain valve'));
      expect(boilerDrain.confidenceLevel, ReceiptConfidenceLevel.good);

      final heaterConnector = matchReceiptLineToCatalog(
        'ACE 3/4 X 18 WATER HTR FLEX CONNECTOR',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(heaterConnector, isNotNull);
      expect(
        heaterConnector!.item.name.toLowerCase(),
        contains('water heater'),
      );
      expect(heaterConnector.item.name.toLowerCase(), contains('connector'));
      expect(heaterConnector.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );
}
