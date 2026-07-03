import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing receipt parser understands pipe and tubing shorthand', () {
    final pvcPipe = matchReceiptLineToCatalog(
      'LOWES PVC PIPE SCH40 1/2IN X 10FT 14.50',
    );
    expect(pvcPipe, isNotNull);
    expect(pvcPipe!.item.name, '1/2 in x 10 ft PVC Schedule 40 Pipe');
    expect(pvcPipe.confidenceLevel, ReceiptConfidenceLevel.good);

    final pexRoll = matchReceiptLineToCatalog('HD 3/4IN X 100FT PEX PIPE');
    expect(pexRoll, isNotNull);
    expect(pexRoll!.item.name, '3/4 in x 100 ft PEX Tubing');

    final dwvPipe = matchReceiptLineToCatalog('FERGUSON 4IN X 10FT DWV PIPE');
    expect(dwvPipe, isNotNull);
    expect(dwvPipe!.item.name, '4 in PVC DWV Pipe');
  });

  test('plumbing receipt parser keeps fittings separate from pipe sticks', () {
    final pvcCoupling = matchReceiptLineToCatalog('PVC C0UPLING 2.49');
    expect(pvcCoupling, isNotNull);
    expect(pvcCoupling!.item.name, contains('PVC Schedule 40 Coupling'));

    final pvcStick = matchReceiptLineToCatalog('PVC STICK SCH40 3/4 X 10FT');
    expect(pvcStick, isNotNull);
    expect(pvcStick!.item.name, '3/4 in x 10 ft PVC Schedule 40 Pipe');
  });

  test(
    'plumbing receipt parser handles compressed fitting connection wording',
    () {
      final copperCxC = matchReceiptLineToCatalog('1/2 CU CXC 90 ELL');
      expect(copperCxC, isNotNull);
      expect(copperCxC!.item.name, '1/2 in Copper 90 Elbow');

      final pvcSxM = matchReceiptLineToCatalog('PVC SCH40 1/2 S X M ADAPTER');
      expect(pvcSxM, isNotNull);
      expect(pvcSxM!.item.name, '1/2 in PVC Schedule 40 Male Adapter');

      final pvcSxF = matchReceiptLineToCatalog('PVC S40 3/4 SXF ADAPT');
      expect(pvcSxF, isNotNull);
      expect(pvcSxF!.item.name, '3/4 in PVC Schedule 40 Female Adapter');

      final cpvcElbow = matchReceiptLineToCatalog('1/2 CPVC 90 ELL');
      expect(cpvcElbow, isNotNull);
      expect(cpvcElbow!.item.name, '1/2 in CPVC 90 Elbow');
    },
  );

  test('plumbing receipt parser handles threaded and DWV supply tickets', () {
    final blackIronNipple = matchReceiptLineToCatalog('BI NIPPLE 1/2 X 6');
    expect(blackIronNipple, isNotNull);
    expect(blackIronNipple!.item.name, '1/2 x 6 in Black Iron Nipple');

    final galvanizedTee = matchReceiptLineToCatalog('GALV STL TEE 3/4');
    expect(galvanizedTee, isNotNull);
    expect(galvanizedTee!.item.name, '3/4 in Galvanized Tee');

    final sanitaryTee = matchReceiptLineToCatalog('PVC DWV 3 SAN TEE');
    expect(sanitaryTee, isNotNull);
    expect(sanitaryTee!.item.name, '3 in PVC DWV Sanitary Tee');

    final trapAdapter = matchReceiptLineToCatalog('1-1/2 MARVEL ADAPTER PVC');
    expect(trapAdapter, isNotNull);
    expect(trapAdapter!.item.name.toLowerCase(), contains('marvel adapter'));
    expect(trapAdapter.item.trade, 'Plumbing');
  });

  test('plumbing receipt parser handles brass fitting counter shorthand', () {
    final compressionUnion = matchReceiptLineToCatalog('BRS COMP UNION 3/8');
    expect(compressionUnion, isNotNull);
    expect(compressionUnion!.item.name, '3/8 in Brass Compression Union');

    final flareFitting = matchReceiptLineToCatalog('BRASS FLR FITTING 1/2');
    expect(flareFitting, isNotNull);
    expect(flareFitting!.item.name, '1/2 in Brass Flare Fitting');

    final hoseBarb = matchReceiptLineToCatalog('3/4 BRS HOSE BARB');
    expect(hoseBarb, isNotNull);
    expect(hoseBarb!.item.name, '3/4 in Brass Barb Fitting');
  });

  test('plumbing receipt parser understands service stop repairs', () {
    final angleStop = matchReceiptLineToCatalog(
      '3/8 X 1/2 ANGLE STOP VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(angleStop, isNotNull);
    expect(angleStop!.item.name, '3/8 x 1/2 in Angle Stop Valve');

    final straightStop = matchReceiptLineToCatalog(
      '3/8 X 5/8 STRAIGHT STOP VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(straightStop, isNotNull);
    expect(straightStop!.item.name, '3/8 x 5/8 in Straight Stop Valve');
  });

  test('plumbing receipt parser understands toilet repair tickets', () {
    final fillValve = matchReceiptLineToCatalog(
      'UNIVERSAL TOILET FILL VALVE KIT',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(fillValve, isNotNull);
    expect(fillValve!.item.name, 'universal Toilet Fill Valve');

    final waxRing = matchReceiptLineToCatalog(
      'EXTRA THICK WAX RING WITH HORN',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(waxRing, isNotNull);
    expect(waxRing!.item.name, contains('Toilet Wax Ring'));

    final flangeRepair = matchReceiptLineToCatalog(
      'STAINLESS TOILET FLANGE REPAIR RING',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(flangeRepair, isNotNull);
    expect(flangeRepair!.item.name, contains('Toilet Flange Repair Ring'));
  });

  test('plumbing receipt parser understands water heater and pump repairs', () {
    final reliefValve = matchReceiptLineToCatalog(
      'WATER HEATER T P RELIEF VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(reliefValve, isNotNull);
    expect(reliefValve!.item.name.toLowerCase(), contains('relief valve'));

    final drainValve = matchReceiptLineToCatalog(
      'WATER HEATER DRAIN VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(drainValve, isNotNull);
    expect(drainValve!.item.name.toLowerCase(), contains('drain valve'));

    final pumpCheck = matchReceiptLineToCatalog(
      'SUMP PUMP CHECK VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(pumpCheck, isNotNull);
    expect(pumpCheck!.item.name, contains('Pump Check Valve'));
  });

  test('plumbing receipt parser understands fixture supply lines', () {
    final faucetLine = matchReceiptLineToCatalog(
      '3/8 X 20IN FAUCET CONNECTOR BRAIDED LINE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(faucetLine, isNotNull);
    expect(faucetLine!.item.name, '3/8 x 20 in Faucet Supply Line');

    final toiletLine = matchReceiptLineToCatalog(
      '3/8 X 12IN TOILET CONNECTOR',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(toiletLine, isNotNull);
    expect(toiletLine!.item.name, '3/8 x 12 in Toilet Supply Line');
  });

  test('plumbing receipt parser understands faucet and sink repairs', () {
    final faucetStem = matchReceiptLineToCatalog(
      'HOT FAUCET STEM ASSEMBLY',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(faucetStem, isNotNull);
    expect(faucetStem!.item.name, 'hot Faucet Stem');

    final aerator = matchReceiptLineToCatalog(
      '15/16-27 MALE FAUCET AERATOR',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(aerator, isNotNull);
    expect(aerator!.item.name, '15/16-27 male Faucet Aerator');

    final basket = matchReceiptLineToCatalog(
      'STAINLESS KITCHEN SINK BASKET STRAINER',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(basket, isNotNull);
    expect(basket!.item.name, 'stainless Kitchen Sink Basket Strainer');
  });

  test('plumbing receipt parser understands shower and tub repairs', () {
    final showerCartridge = matchReceiptLineToCatalog(
      'PRESSURE BALANCE SHOWER CARTRIDGE',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(showerCartridge, isNotNull);
    expect(showerCartridge!.item.name, 'pressure balance Shower Cartridge');

    final tubSpout = matchReceiptLineToCatalog(
      'SLIP FIT DIVERTER TUB SPOUT',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(tubSpout, isNotNull);
    expect(tubSpout!.item.name, 'slip fit Tub Spout');

    final tubStopper = matchReceiptLineToCatalog(
      'TOE TOUCH TUB DRAIN STOPPER',
      tradeScope: 'Plumbing',
      maxCandidates: 120,
    );
    expect(tubStopper, isNotNull);
    expect(tubStopper!.item.name, 'toe touch Tub Drain Stopper');
  });

  test('plumbing parser understands service truck repair stock', () {
    final stopRepair = matchReceiptLineToCatalog(
      'STOP VALVE ESCUTCHEON 2 PACK',
      tradeScope: 'Plumbing',
      maxCandidates: 160,
    );
    expect(stopRepair, isNotNull);
    expect(stopRepair!.item.name, contains('Supply Stop Repair Part'));

    final drainKit = matchReceiptLineToCatalog(
      'CONTINUOUS WASTE WITH DISHWASHER BRANCH',
      tradeScope: 'Plumbing',
      maxCandidates: 160,
    );
    expect(drainKit, isNotNull);
    expect(drainKit!.item.name.toLowerCase(), contains('dishwasher'));

    final anodeRod = matchReceiptLineToCatalog(
      '42 IN MAGNESIUM ANODE ROD WATER HEATER',
      tradeScope: 'Plumbing',
      maxCandidates: 160,
    );
    expect(anodeRod, isNotNull);
    expect(anodeRod!.item.name, contains('Water Heater Repair Part'));

    final pumpAlarm = matchReceiptLineToCatalog(
      'HIGH WATER ALARM SUMP PUMP',
      tradeScope: 'Plumbing',
      maxCandidates: 160,
    );
    expect(pumpAlarm, isNotNull);
    expect(pumpAlarm!.item.name, contains('Pump Control Part'));

    final floatSwitch = matchReceiptLineToCatalog(
      'PIGGYBACK FLOAT SWITCH SUMP PUMP',
      tradeScope: 'Plumbing',
      maxCandidates: 160,
    );
    expect(floatSwitch, isNotNull);
    expect(floatSwitch!.item.name.toLowerCase(), contains('float switch'));
  });

  test('plumbing parser understands drain and finish service stock', () {
    final airGap = matchReceiptLineToCatalog(
      'AIR GAP CHROME CAP DISHWASHER',
      tradeScope: 'Plumbing',
      maxCandidates: 180,
    );
    expect(airGap, isNotNull);
    expect(airGap!.item.name.toLowerCase(), contains('air gap'));

    final cleanoutCover = matchReceiptLineToCatalog(
      '4 IN ROUND CLEANOUT COVER',
      tradeScope: 'Plumbing',
      maxCandidates: 180,
    );
    expect(cleanoutCover, isNotNull);
    expect(cleanoutCover!.item.name.toLowerCase(), contains('cleanout'));

    final flangeRepair = matchReceiptLineToCatalog(
      'STAINLESS CLOSET FLANGE REPAIR RING',
      tradeScope: 'Plumbing',
      maxCandidates: 180,
    );
    expect(flangeRepair, isNotNull);
    expect(flangeRepair!.item.name, contains('Closet Flange Repair Part'));

    final drainGrate = matchReceiptLineToCatalog(
      '3 IN ROUND FLOOR DRAIN GRATE',
      tradeScope: 'Plumbing',
      maxCandidates: 180,
    );
    expect(drainGrate, isNotNull);
    expect(drainGrate!.item.name.toLowerCase(), contains('floor drain'));

    final dishwasherBranch = matchReceiptLineToCatalog(
      'DISHWASHER BRANCH TAILPIECE',
      tradeScope: 'Plumbing',
      maxCandidates: 180,
    );
    expect(dishwasherBranch, isNotNull);
    expect(
      dishwasherBranch!.item.name,
      contains('Dishwasher Disposal Drain Part'),
    );
  });

  test(
    'plumbing parser understands seals packing and thread service stock',
    () {
      final stemPacking = matchReceiptLineToCatalog(
        'GRAPHITE VALVE STEM PACKING',
        tradeScope: 'Plumbing',
        maxCandidates: 180,
      );
      expect(stemPacking, isNotNull);
      expect(stemPacking!.item.name.toLowerCase(), contains('packing'));

      final faucetWasher = matchReceiptLineToCatalog(
        'ASSORTED FAUCET WASHER KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 180,
      );
      expect(faucetWasher, isNotNull);
      expect(faucetWasher!.item.name, contains('Faucet Washer and Seat Part'));

      final vacuumBreaker = matchReceiptLineToCatalog(
        'ANTI SIPHON VACUUM BREAKER KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 180,
      );
      expect(vacuumBreaker, isNotNull);
      expect(
        vacuumBreaker!.item.name.toLowerCase(),
        contains('vacuum breaker'),
      );

      final pipeDope = matchReceiptLineToCatalog(
        '8 OZ PIPE DOPE THREAD SEALANT',
        tradeScope: 'Plumbing',
        maxCandidates: 180,
      );
      expect(pipeDope, isNotNull);
      expect(
        pipeDope!.item.name.toLowerCase(),
        contains('pipe joint compound'),
      );

      final gasTape = matchReceiptLineToCatalog(
        'YELLOW GAS TEFLON TAPE',
        tradeScope: 'Plumbing',
        maxCandidates: 180,
      );
      expect(gasTape, isNotNull);
      expect(gasTape!.item.name.toLowerCase(), contains('ptfe tape'));
    },
  );

  test('plumbing parser handles additional receipt shorthand neighbors', () {
    final desanco = matchReceiptLineToCatalog(
      '1-1/2 DESANCO TRAP ADPT',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(desanco, isNotNull);
    expect(desanco!.item.name.toLowerCase(), contains('desanco'));

    final disposalSplash = matchReceiptLineToCatalog(
      'GARB DISP SPLASH GUARD RUBBER',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(disposalSplash, isNotNull);
    expect(disposalSplash!.item.name.toLowerCase(), contains('splash guard'));

    final cleanoutPlug = matchReceiptLineToCatalog(
      '2IN BRASS CO PLUG COUNTERSUNK',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(cleanoutPlug, isNotNull);
    expect(cleanoutPlug!.item.name.toLowerCase(), contains('cleanout plug'));

    final closetBolt = matchReceiptLineToCatalog(
      'EX LONG JOHNNY BOLTS CLOSET BOLT SET',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(closetBolt, isNotNull);
    expect(closetBolt!.item.name, contains('Closet Bolt'));

    final expansionTank = matchReceiptLineToCatalog(
      '2 GAL THERMAL EXP TANK WATER HEATER',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(expansionTank, isNotNull);
    expect(expansionTank!.item.name.toLowerCase(), contains('expansion tank'));

    final vacuumRelief = matchReceiptLineToCatalog(
      '3/4 VAC RELIEF VALVE WH',
      tradeScope: 'Plumbing',
      maxCandidates: 220,
    );
    expect(vacuumRelief, isNotNull);
    expect(vacuumRelief!.item.name.toLowerCase(), contains('vacuum relief'));
  });

  test('plumbing parser resists common neighbor collisions', () {
    final pushStop = matchReceiptLineToCatalog(
      '1/2 X 3/8 PUSH FIT SUPPLY STOP',
      tradeScope: 'Plumbing',
      maxCandidates: 240,
    );
    expect(pushStop, isNotNull);
    expect(pushStop!.item.name, '1/2 x 3/8 Push-Fit Supply Stop');
    expect(pushStop.confidenceLevel, ReceiptConfidenceLevel.good);

    final slipNut = matchReceiptLineToCatalog(
      '1-1/2 CHROME SLIP NUT SJ',
      tradeScope: 'Plumbing',
      maxCandidates: 240,
    );
    expect(slipNut, isNotNull);
    expect(slipNut!.item.name.toLowerCase(), contains('slip nut'));
    expect(slipNut.item.name.toLowerCase(), isNot(contains('adapter')));
    expect(slipNut.confidenceLevel, ReceiptConfidenceLevel.good);

    final cleanoutCover = matchReceiptLineToCatalog(
      '4 IN SQUARE CLEANOUT ACCESS COVER',
      tradeScope: 'Plumbing',
      maxCandidates: 240,
    );
    expect(cleanoutCover, isNotNull);
    expect(cleanoutCover!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanoutCover.item.name.toLowerCase(), contains('cover'));
    expect(cleanoutCover.confidenceLevel, ReceiptConfidenceLevel.good);

    final tubShoe = matchReceiptLineToCatalog(
      '1-1/2 TUB DRAIN SHOE',
      tradeScope: 'Plumbing',
      maxCandidates: 240,
    );
    expect(tubShoe, isNotNull);
    expect(tubShoe!.item.name.toLowerCase(), contains('tub drain shoe'));
    expect(tubShoe.confidenceLevel, ReceiptConfidenceLevel.good);

    final closeNipple = matchReceiptLineToCatalog(
      '1 X CLOSE GALV NIPPLE',
      tradeScope: 'Plumbing',
      maxCandidates: 240,
    );
    expect(closeNipple, isNotNull);
    expect(closeNipple!.item.name, '1 x Close Galvanized Nipple');
    expect(closeNipple.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing parser understands ABS DWV receipt wording', () {
    final absSanTee = matchReceiptLineToCatalog(
      'ABS DWV 3IN SAN TEE BLACK DRAIN',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(absSanTee, isNotNull);
    expect(absSanTee!.item.name, '3 in ABS DWV Sanitary Tee');
    expect(absSanTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final absWye = matchReceiptLineToCatalog(
      '2IN ABS WYE FITTING',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(absWye, isNotNull);
    expect(absWye!.item.name, '2 in ABS DWV Wye');
    expect(absWye.confidenceLevel, ReceiptConfidenceLevel.good);

    final absTrapAdapter = matchReceiptLineToCatalog(
      '1-1/2 BLACK TRAP ADAPTER ABS',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(absTrapAdapter, isNotNull);
    expect(absTrapAdapter!.item.name, '1-1/2 in ABS DWV Trap Adapter');
    expect(absTrapAdapter.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
