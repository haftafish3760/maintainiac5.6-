import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing parser lets trusted local item identities win first', () {
    final expected = searchWorkSupplies(
      '3/4 in Push-Fit Coupling',
    ).firstWhere((item) => item.trade == 'Plumbing');
    final match = matchReceiptLineToCatalog(
      'LOWES PRO X-USER-774433 3/4 PUSH COUP 18.49',
      trustedItemIdentityIds: {
        'X-USER-774433': expected.id,
        '00888432100099': expected.id,
      },
      tradeScope: 'Plumbing',
      maxCandidates: 1,
    );

    expect(match, isNotNull);
    expect(match!.item.id, expected.id);
    expect(match.source, ReceiptMatchSource.trustedItemIdentity);
    expect(match.confidence, 0.99);
  });

  test('plumbing parser treats regional hardware names as merchant noise', () {
    expect(normalizeMerchantName('TRUE VALUE HARDWARE'), 'true value');
    expect(normalizeMerchantName('TRACTOR SUPPLY CO'), 'tractor supply');
    expect(normalizeMerchantName('MCCOY BUILDING SUPPLY'), 'mccoys');

    final trueValueFlapper = matchReceiptLineToCatalog(
      'TRUE VALUE 3 IN TOILET FLAPPER',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(trueValueFlapper, isNotNull);
    expect(trueValueFlapper!.item.name.toLowerCase(), contains('flapper'));
    expect(trueValueFlapper.confidenceLevel, ReceiptConfidenceLevel.good);

    final tractorVacBreaker = matchReceiptLineToCatalog(
      'TRACTOR SUPPLY 3/4 HOSE BIBB VAC BRKR',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(tractorVacBreaker, isNotNull);
    expect(tractorVacBreaker!.item.name.toLowerCase(), contains('vacuum'));
    expect(tractorVacBreaker.confidenceLevel, ReceiptConfidenceLevel.good);

    final mccoysPexAdapter = matchReceiptLineToCatalog(
      'MCCOYS 1/2 PEX MIP ADPT CRIMP',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(mccoysPexAdapter, isNotNull);
    expect(mccoysPexAdapter!.item.name.toLowerCase(), contains('pex'));
    expect(mccoysPexAdapter.item.name.toLowerCase(), contains('male adapter'));
    expect(mccoysPexAdapter.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing parser handles big-box and supply-house receipt wording', () {
    final menardsPexElbow = matchReceiptLineToCatalog(
      'MENARDS 1/2 PEX ELB CRIMP',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(menardsPexElbow, isNotNull);
    expect(menardsPexElbow!.item.name, '1/2 in PEX 90 Elbow');
    expect(menardsPexElbow.confidenceLevel, ReceiptConfidenceLevel.good);

    final homeDepotPushCoupling = matchReceiptLineToCatalog(
      'THE HOME DEPOT 3/4 SHARKBITE PUSH COUP',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(homeDepotPushCoupling, isNotNull);
    expect(homeDepotPushCoupling!.item.name, '3/4 in Push-Fit Coupling');
    expect(homeDepotPushCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

    final fergusonReliefValve = matchReceiptLineToCatalog(
      'FERG WTR HTR 3/4 T&P RELIEF VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(fergusonReliefValve, isNotNull);
    expect(
      fergusonReliefValve!.item.name.toLowerCase(),
      contains('relief valve'),
    );
    expect(fergusonReliefValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final graingerCleanout = matchReceiptLineToCatalog(
      'GRAINGER 2 IN BRASS CO PLUG COUNTERSUNK',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(graingerCleanout, isNotNull);
    expect(graingerCleanout!.item.name.toLowerCase(), contains('cleanout'));
    expect(graingerCleanout.item.name.toLowerCase(), contains('plug'));
    expect(graingerCleanout.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing parser handles online and regional supply-house wording', () {
    final supplyHouseNipple = matchReceiptLineToCatalog(
      'SUPPLYHOUSE 1/2 BI NIP 6 IN',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(supplyHouseNipple, isNotNull);
    expect(supplyHouseNipple!.item.name, '1/2 x 6 in Black Iron Nipple');
    expect(supplyHouseNipple.confidenceLevel, ReceiptConfidenceLevel.good);

    final winsupplyAbsWye = matchReceiptLineToCatalog(
      'WINSUPPLY 1-1/2 ABS DWV WYE BLACK DRAIN',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(winsupplyAbsWye, isNotNull);
    expect(winsupplyAbsWye!.item.name, '1-1/2 in ABS DWV Wye');
    expect(winsupplyAbsWye.confidenceLevel, ReceiptConfidenceLevel.good);

    final hajocaAngleStop = matchReceiptLineToCatalog(
      'HAJOCA 3/8 X 1/2 ANG STOP QTR TURN',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(hajocaAngleStop, isNotNull);
    expect(hajocaAngleStop!.item.name, '3/8 x 1/2 in Angle Stop Valve');
    expect(hajocaAngleStop.confidenceLevel, ReceiptConfidenceLevel.good);

    final reeceExpansionTank = matchReceiptLineToCatalog(
      'REECE 2 GAL THERM EXP TANK WH',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(reeceExpansionTank, isNotNull);
    expect(
      reeceExpansionTank!.item.name.toLowerCase(),
      contains('expansion tank'),
    );
    expect(reeceExpansionTank.confidenceLevel, ReceiptConfidenceLevel.good);

    final webbAnode = matchReceiptLineToCatalog(
      'F W WEBB 42 IN MAG ANODE ROD WTR HTR',
      tradeScope: 'Plumbing',
      maxCandidates: 260,
    );
    expect(webbAnode, isNotNull);
    expect(webbAnode!.item.name.toLowerCase(), contains('anode rod'));
    expect(webbAnode.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing parser handles common residential service receipt shorthand',
    () {
      final lowesPvcFemaleAdapter = matchReceiptLineToCatalog(
        'LOWES PVC S40 3/4 SXF ADAPT',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(lowesPvcFemaleAdapter, isNotNull);
      expect(
        lowesPvcFemaleAdapter!.item.name,
        '3/4 in PVC Schedule 40 Female Adapter',
      );
      expect(
        lowesPvcFemaleAdapter.confidenceLevel,
        ReceiptConfidenceLevel.good,
      );

      final hdCpvcCoupling = matchReceiptLineToCatalog(
        'HD PRO 1/2 CPV C COUPLING',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(hdCpvcCoupling, isNotNull);
      expect(hdCpvcCoupling!.item.name, '1/2 in CPVC Coupling');
      expect(hdCpvcCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

      final acePrv = matchReceiptLineToCatalog(
        'ACE 3/4 PRV PRESS RED VALVE',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(acePrv, isNotNull);
      expect(acePrv!.item.name.toLowerCase(), contains('pressure reducing'));
      expect(acePrv.confidenceLevel, ReceiptConfidenceLevel.good);

      final menardsVacBreaker = matchReceiptLineToCatalog(
        'MENARDS 3/4 HOSE BIB VAC BRKR',
        tradeScope: 'Plumbing',
        maxCandidates: 280,
      );
      expect(menardsVacBreaker, isNotNull);
      expect(menardsVacBreaker!.item.name.toLowerCase(), contains('vacuum'));
      expect(menardsVacBreaker.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing parser handles drain sewer and fixture repair shorthand', () {
    final noHubCoupling = matchReceiptLineToCatalog(
      'FERG 3 IN NH CPLG SHIELDED',
      tradeScope: 'Plumbing',
      maxCandidates: 280,
    );
    expect(noHubCoupling, isNotNull);
    expect(noHubCoupling!.item.name.toLowerCase(), contains('no-hub'));
    expect(noHubCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

    final corrugatedDrain = matchReceiptLineToCatalog(
      'CORE MAIN 4IN X 25FT CORR DRAIN PIPE',
      tradeScope: 'Plumbing',
      maxCandidates: 280,
    );
    expect(corrugatedDrain, isNotNull);
    expect(corrugatedDrain!.item.name, '4 in x 25 ft Corrugated Drain Pipe');
    expect(corrugatedDrain.confidenceLevel, ReceiptConfidenceLevel.good);

    final closetFlange = matchReceiptLineToCatalog(
      'SUPPLYHOUSE 4 X 3 PVC CLOSET FLG',
      tradeScope: 'Plumbing',
      maxCandidates: 280,
    );
    expect(closetFlange, isNotNull);
    expect(closetFlange!.item.name.toLowerCase(), contains('closet flange'));
    expect(closetFlange.confidenceLevel, ReceiptConfidenceLevel.good);

    final wasteOverflow = matchReceiptLineToCatalog(
      'REECE TUB WASTE OVERFLOW TRIP LEVER',
      tradeScope: 'Plumbing',
      maxCandidates: 280,
    );
    expect(wasteOverflow, isNotNull);
    expect(wasteOverflow!.item.name.toLowerCase(), contains('waste'));
    expect(wasteOverflow.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
