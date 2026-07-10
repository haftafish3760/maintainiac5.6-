import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing parser keeps supply fitting materials separated', () {
    final pexElbow = matchReceiptLineToCatalog(
      'LOWES 1/2 PEX CRIMP 90 ELL BRASS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexElbow, isNotNull);
    expect(pexElbow!.item.name.toLowerCase(), contains('pex'));
    expect(pexElbow.item.name.toLowerCase(), contains('90'));
    expect(pexElbow.item.name.toLowerCase(), contains('elbow'));
    expect(pexElbow.confidenceLevel, ReceiptConfidenceLevel.good);

    final cpvcElbow = matchReceiptLineToCatalog(
      'HD 1/2 CPVC 90 DEG ELBOW CTS',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cpvcElbow, isNotNull);
    expect(cpvcElbow!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcElbow.item.name.toLowerCase(), contains('elbow'));
    expect(cpvcElbow.confidenceLevel, ReceiptConfidenceLevel.good);

    final pvcAdapter = matchReceiptLineToCatalog(
      'MENARDS 3/4 PVC SCH40 MALE ADAPT MIP',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pvcAdapter, isNotNull);
    expect(pvcAdapter!.item.name.toLowerCase(), contains('pvc schedule 40'));
    expect(pvcAdapter.item.name.toLowerCase(), contains('male adapter'));
    expect(pvcAdapter.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing parser keeps drain families separated', () {
    final absTrapAdapter = matchReceiptLineToCatalog(
      'WINSUPPLY 1-1/2 ABS DWV TRAP ADAPT BLACK',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(absTrapAdapter, isNotNull);
    expect(absTrapAdapter!.item.name.toLowerCase(), contains('abs dwv'));
    expect(absTrapAdapter.item.name.toLowerCase(), contains('trap adapter'));
    expect(absTrapAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final tubularAdapter = matchReceiptLineToCatalog(
      'ACE 1-1/2 TUBULAR DRAIN ADAPTER SLIP JOINT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(tubularAdapter, isNotNull);
    expect(tubularAdapter!.item.name.toLowerCase(), contains('tubular'));
    expect(tubularAdapter.item.name.toLowerCase(), contains('adapter'));
    expect(tubularAdapter.item.name.toLowerCase(), isNot(contains('abs dwv')));
    expect(tubularAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final cleanoutPlug = matchReceiptLineToCatalog(
      'FERG 3 IN PVC DWV CO PLUG CLEANOUT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(cleanoutPlug, isNotNull);
    expect(cleanoutPlug!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanoutPlug.item.name.toLowerCase(), contains('plug'));
    expect(cleanoutPlug.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing parser keeps gas, metal, and support stock separated', () {
    final blackIronNipple = matchReceiptLineToCatalog(
      'SUPPLYHOUSE 1/2 BLACK IRON NIPPLE 6IN',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(blackIronNipple, isNotNull);
    expect(blackIronNipple!.item.name.toLowerCase(), contains('black iron'));
    expect(blackIronNipple.item.name.toLowerCase(), contains('nipple'));
    expect(blackIronNipple.confidenceLevel, ReceiptConfidenceLevel.good);

    final copperCoupling = matchReceiptLineToCatalog(
      'HD 3/4 COPPER COUPLING SWEAT C X C',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(copperCoupling, isNotNull);
    expect(copperCoupling!.item.name.toLowerCase(), contains('copper'));
    expect(copperCoupling.item.name.toLowerCase(), contains('coupling'));
    expect(copperCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

    final allThread = matchReceiptLineToCatalog(
      'GRAINGER 3/8 ALL THREAD ROD ZINC 6FT',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(allThread, isNotNull);
    expect(allThread!.item.name.toLowerCase(), contains('threaded rod'));
    expect(allThread.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
