import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core parser handles PEX fitting shorthand batch three', () {
    final pexTee = matchReceiptLineToCatalog(
      'LOWES 1/2 PEX CRIMP TEE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexTee, isNotNull);
    expect(pexTee!.item.name.toLowerCase(), contains('pex tee'));
    expect(pexTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final pexMaleAdapter = matchReceiptLineToCatalog(
      'HD 3/4 PEX MIP ADAPTER CRIMP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexMaleAdapter, isNotNull);
    expect(
      pexMaleAdapter!.item.name.toLowerCase(),
      contains('pex male adapter'),
    );
    expect(pexMaleAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final pexFemaleAdapter = matchReceiptLineToCatalog(
      'ACE 1/2 PEX FIP ADAPTER CRIMP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexFemaleAdapter, isNotNull);
    expect(
      pexFemaleAdapter!.item.name.toLowerCase(),
      contains('pex female adapter'),
    );
    expect(pexFemaleAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final dropEar = matchReceiptLineToCatalog(
      'FERG 1/2 PEX DROP EAR ELBOW',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(dropEar, isNotNull);
    expect(dropEar!.item.name.toLowerCase(), contains('drop-ear'));
    expect(dropEar.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles push-fit repair and adapter shorthand',
    () {
      final pushSlip = matchReceiptLineToCatalog(
        'HD 1/2 SHARKBITE SLIP REPAIR COUPLING',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pushSlip, isNotNull);
      expect(pushSlip!.item.name.toLowerCase(), contains('push-fit'));
      expect(pushSlip.item.name.toLowerCase(), contains('slip coupling'));
      expect(pushSlip.confidenceLevel, ReceiptConfidenceLevel.good);

      final pushMale = matchReceiptLineToCatalog(
        'LOWES 3/4 PUSH MIP ADAPTER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pushMale, isNotNull);
      expect(
        pushMale!.item.name.toLowerCase(),
        contains('push-fit male adapter'),
      );
      expect(pushMale.confidenceLevel, ReceiptConfidenceLevel.good);

      final pushFemale = matchReceiptLineToCatalog(
        'ACE 1/2 PUSH FIP ADAPTER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pushFemale, isNotNull);
      expect(
        pushFemale!.item.name.toLowerCase(),
        contains('push-fit female adapter'),
      );
      expect(pushFemale.confidenceLevel, ReceiptConfidenceLevel.good);

      final pushStop = matchReceiptLineToCatalog(
        'HD 1/2 X 3/8 PUSH ANGLE STOP',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pushStop, isNotNull);
      expect(pushStop!.item.name.toLowerCase(), contains('push-fit'));
      expect(pushStop.item.name.toLowerCase(), contains('supply stop'));
      expect(pushStop.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles copper repair and adapter shorthand', () {
    final copperRepair = matchReceiptLineToCatalog(
      'FERG 3/4 COPPER NO STOP REPAIR COUPLING',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(copperRepair, isNotNull);
    expect(copperRepair!.item.name.toLowerCase(), contains('copper repair'));
    expect(copperRepair.confidenceLevel, ReceiptConfidenceLevel.good);

    final copperMale = matchReceiptLineToCatalog(
      'HD 1/2 COPPER SWEAT MIP ADAPTER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(copperMale, isNotNull);
    expect(
      copperMale!.item.name.toLowerCase(),
      contains('copper male adapter'),
    );
    expect(copperMale.confidenceLevel, ReceiptConfidenceLevel.good);

    final copperFemale = matchReceiptLineToCatalog(
      'LOWES 3/4 COPPER SWEAT FIP ADAPTER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(copperFemale, isNotNull);
    expect(
      copperFemale!.item.name.toLowerCase(),
      contains('copper female adapter'),
    );
    expect(copperFemale.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles CPVC fitting shorthand batch three', () {
    final cpvcTee = matchReceiptLineToCatalog(
      'LOWES 3/4 CPVC CTS TEE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcTee, isNotNull);
    expect(cpvcTee!.item.name.toLowerCase(), contains('cpvc tee'));
    expect(cpvcTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcTransition = matchReceiptLineToCatalog(
      'HD 1/2 CPVC COPPER TRANSITION ADAPTER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcTransition, isNotNull);
    expect(cpvcTransition!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcTransition.item.name.toLowerCase(), contains('transition'));
    expect(cpvcTransition.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcBushing = matchReceiptLineToCatalog(
      'ACE 3/4 X 1/2 CPVC REDUCING BUSHING',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcBushing, isNotNull);
    expect(cpvcBushing!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcBushing.item.name.toLowerCase(), contains('bushing'));
    expect(cpvcBushing.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles PVC schedule 40 shorthand batch three',
    () {
      final pvcTee = matchReceiptLineToCatalog(
        'HD 1 IN PVC SCH40 TEE',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pvcTee, isNotNull);
      expect(pvcTee!.item.name.toLowerCase(), contains('pvc schedule 40 tee'));
      expect(pvcTee.confidenceLevel, ReceiptConfidenceLevel.good);

      final pvcFemale = matchReceiptLineToCatalog(
        'LOWES 3/4 PVC SLIP X FIP ADAPTER',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pvcFemale, isNotNull);
      expect(pvcFemale!.item.name.toLowerCase(), contains('pvc schedule 40'));
      expect(pvcFemale.item.name.toLowerCase(), contains('female adapter'));
      expect(pvcFemale.confidenceLevel, ReceiptConfidenceLevel.good);

      final pvcBushing = matchReceiptLineToCatalog(
        'ACE 1 X 3/4 PVC SPIGOT BUSHING',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(pvcBushing, isNotNull);
      expect(pvcBushing!.item.name.toLowerCase(), contains('pvc schedule 40'));
      expect(pvcBushing.item.name.toLowerCase(), contains('bushing'));
      expect(pvcBushing.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing core parser handles PVC DWV shorthand batch three', () {
    final dwvWye = matchReceiptLineToCatalog(
      'FERG 3 IN PVC DWV WYE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(dwvWye, isNotNull);
    expect(dwvWye!.item.name.toLowerCase(), contains('pvc dwv'));
    expect(dwvWye.item.name.toLowerCase(), contains('wye'));
    expect(dwvWye.confidenceLevel, ReceiptConfidenceLevel.good);

    final reducingSanTee = matchReceiptLineToCatalog(
      'HD 3 X 2 PVC DWV REDUCING SAN TEE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(reducingSanTee, isNotNull);
    expect(reducingSanTee!.item.name.toLowerCase(), contains('pvc dwv'));
    expect(reducingSanTee.item.name.toLowerCase(), contains('sanitary tee'));
    expect(reducingSanTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final testTee = matchReceiptLineToCatalog(
      'LOWES 2 IN PVC DWV TEST TEE CLEANOUT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(testTee, isNotNull);
    expect(testTee!.item.name.toLowerCase(), contains('pvc dwv'));
    expect(testTee.item.name.toLowerCase(), contains('test tee'));
    expect(testTee.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles ABS and no-hub shorthand batch three', () {
    final absSanTee = matchReceiptLineToCatalog(
      'WIN 2 IN ABS SAN TEE BLACK DRAIN',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(absSanTee, isNotNull);
    expect(absSanTee!.item.name.toLowerCase(), contains('abs dwv'));
    expect(absSanTee.item.name.toLowerCase(), contains('sanitary tee'));
    expect(absSanTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final absCleanout = matchReceiptLineToCatalog(
      'ACE 3 IN ABS CLEANOUT PLUG BLACK',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(absCleanout, isNotNull);
    expect(absCleanout!.item.name.toLowerCase(), contains('abs dwv'));
    expect(absCleanout.item.name.toLowerCase(), contains('cleanout'));
    expect(absCleanout.confidenceLevel, ReceiptConfidenceLevel.good);

    final noHubReducer = matchReceiptLineToCatalog(
      'FERG 4 X 3 SHIELDED NO HUB REDUCER',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(noHubReducer, isNotNull);
    expect(noHubReducer!.item.name.toLowerCase(), contains('no-hub'));
    expect(noHubReducer.item.name.toLowerCase(), contains('reducing'));
    expect(noHubReducer.confidenceLevel, ReceiptConfidenceLevel.good);

    final donutGasket = matchReceiptLineToCatalog(
      'HD 4 IN CAST IRON DONUT GASKET',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(donutGasket, isNotNull);
    expect(
      donutGasket!.item.name.toLowerCase(),
      contains('compression gasket'),
    );
    expect(donutGasket.confidenceLevel, ReceiptConfidenceLevel.good);

    final noHubBand = matchReceiptLineToCatalog(
      'LOWES 3 IN NO HUB BAND CLAMP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(noHubBand, isNotNull);
    expect(noHubBand!.item.name.toLowerCase(), contains('band clamp'));
    expect(noHubBand.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles black iron shorthand batch three', () {
    final blackIronTee = matchReceiptLineToCatalog(
      'FERG 1/2 BLACK IRON THREADED TEE',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(blackIronTee, isNotNull);
    expect(blackIronTee!.item.name.toLowerCase(), contains('black iron tee'));
    expect(blackIronTee.confidenceLevel, ReceiptConfidenceLevel.good);

    final blackIronUnion = matchReceiptLineToCatalog(
      'ACE 3/4 BLACK PIPE THREADED UNION',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(blackIronUnion, isNotNull);
    expect(blackIronUnion!.item.name.toLowerCase(), contains('black iron'));
    expect(blackIronUnion.item.name.toLowerCase(), contains('union'));
    expect(blackIronUnion.confidenceLevel, ReceiptConfidenceLevel.good);

    final blackIronBushing = matchReceiptLineToCatalog(
      'HD 1 X 1/2 BLACK IRON REDUCING BUSHING',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(blackIronBushing, isNotNull);
    expect(blackIronBushing!.item.name.toLowerCase(), contains('black iron'));
    expect(blackIronBushing.item.name.toLowerCase(), contains('bushing'));
    expect(blackIronBushing.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser handles supply stop repair shorthand batch three',
    () {
      final straightStop = matchReceiptLineToCatalog(
        'LOWES 3/8 X 1/2 STRAIGHT STOP QTR TURN',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(straightStop, isNotNull);
      expect(straightStop!.item.name.toLowerCase(), contains('straight stop'));
      expect(straightStop.confidenceLevel, ReceiptConfidenceLevel.good);

      final ferruleKit = matchReceiptLineToCatalog(
        'HD 5/8 COMP NUT FERRULE KIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(ferruleKit, isNotNull);
      expect(ferruleKit!.item.name.toLowerCase(), contains('ferrule'));
      expect(ferruleKit.confidenceLevel, ReceiptConfidenceLevel.good);

      final stopEscutcheon = matchReceiptLineToCatalog(
        'ACE STOP VALVE ESCUTCHEON SPLIT',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(stopEscutcheon, isNotNull);
      expect(stopEscutcheon!.item.name.toLowerCase(), contains('escutcheon'));
      expect(stopEscutcheon.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test(
    'plumbing core parser handles fixture connector shorthand batch three',
    () {
      final faucetLine = matchReceiptLineToCatalog(
        'LOWES 3/8 X 24IN LAV FAUCET CONNECTOR',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(faucetLine, isNotNull);
      expect(
        faucetLine!.item.name.toLowerCase(),
        contains('faucet supply line'),
      );
      expect(faucetLine.confidenceLevel, ReceiptConfidenceLevel.good);

      final toiletLine = matchReceiptLineToCatalog(
        'HD 3/8 X 16 CLOSET TOILET CONNECTOR',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(toiletLine, isNotNull);
      expect(
        toiletLine!.item.name.toLowerCase(),
        contains('toilet supply line'),
      );
      expect(toiletLine.confidenceLevel, ReceiptConfidenceLevel.good);

      final supplyEscutcheon = matchReceiptLineToCatalog(
        'FERG CHROME SUPPLY LINE ESCUTCHEON',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(supplyEscutcheon, isNotNull);
      expect(supplyEscutcheon!.item.name.toLowerCase(), contains('escutcheon'));
      expect(supplyEscutcheon.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );
}
