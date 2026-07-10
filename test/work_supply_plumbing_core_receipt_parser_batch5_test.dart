import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core parser handles pressure pipe shorthand batch five', () {
    final cpvcFemale = matchReceiptLineToCatalog(
      'LOWES 1/2 IN CPVC FLOWGUARD FEMALE ADPT',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(cpvcFemale, isNotNull);
    expect(cpvcFemale!.item.name.toLowerCase(), contains('cpvc'));
    expect(cpvcFemale.item.name.toLowerCase(), contains('female adapter'));
    expect(cpvcFemale.confidenceLevel, ReceiptConfidenceLevel.good);

    final pexCoupling = matchReceiptLineToCatalog(
      'HD 3/4 PEX POLY CRIMP COUPLING',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(pexCoupling, isNotNull);
    expect(pexCoupling!.item.name.toLowerCase(), contains('pex coupling'));
    expect(pexCoupling.confidenceLevel, ReceiptConfidenceLevel.good);

    final pushBallValve = matchReceiptLineToCatalog(
      'ACE 1/2 PUSH CONNECT BALL VALVE',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(pushBallValve, isNotNull);
    expect(pushBallValve!.item.name.toLowerCase(), contains('push-fit'));
    expect(pushBallValve.item.name.toLowerCase(), contains('valve'));
    expect(pushBallValve.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles DWV access shorthand batch five', () {
    final dwvWye = matchReceiptLineToCatalog(
      'FERG 3IN PVC DWV WYE',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(dwvWye, isNotNull);
    expect(dwvWye!.item.name.toLowerCase(), contains('wye'));
    expect(dwvWye.confidenceLevel, ReceiptConfidenceLevel.good);

    final trapAdapter = matchReceiptLineToCatalog(
      'HD 1-1/2 PVC TRAP ADPT',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(trapAdapter, isNotNull);
    expect(trapAdapter!.item.name.toLowerCase(), contains('trap adapter'));
    expect(trapAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final lavPTrap = matchReceiptLineToCatalog(
      'HD 1-1/4 LAV P TRAP 1.00',
      tradeScope: 'Plumbing',
      maxCandidates: 24,
    );
    expect(lavPTrap, isNotNull);
    expect(lavPTrap!.item.name.toLowerCase(), contains('tubular p-trap'));
    expect(lavPTrap.confidenceLevel, ReceiptConfidenceLevel.good);

    final tailpiece = matchReceiptLineToCatalog(
      'LOWES 1-1/4 LAV TAILPIECE 2.07',
      tradeScope: 'Plumbing',
      maxCandidates: 24,
    );
    expect(tailpiece, isNotNull);
    expect(tailpiece!.item.name.toLowerCase(), contains('tailpiece'));
    expect(tailpiece.confidenceLevel, ReceiptConfidenceLevel.good);

    final slipJoint = matchReceiptLineToCatalog(
      'ACE 1-1/2 SLIP JOINT NUT WASHER 3.14',
      tradeScope: 'Plumbing',
      maxCandidates: 24,
    );
    expect(slipJoint, isNotNull);
    expect(slipJoint!.item.name.toLowerCase(), contains('slip joint'));
    expect(slipJoint.confidenceLevel, ReceiptConfidenceLevel.good);

    final cleanoutPlug = matchReceiptLineToCatalog(
      'LOWES 4IN PVC CLEANOUT PLUG',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(cleanoutPlug, isNotNull);
    expect(cleanoutPlug!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanoutPlug.item.name.toLowerCase(), contains('plug'));
    expect(cleanoutPlug.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles fixture repair shorthand batch five', () {
    final flangeSpacer = matchReceiptLineToCatalog(
      'ACE CLOSET FLANGE SPACER KIT',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(flangeSpacer, isNotNull);
    expect(flangeSpacer!.item.name.toLowerCase(), contains('flange spacer'));
    expect(flangeSpacer.confidenceLevel, ReceiptConfidenceLevel.good);

    final supplyStop = matchReceiptLineToCatalog(
      'HD 1/2 X 3/8 QT ANGLE STOP CHROME',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(supplyStop, isNotNull);
    expect(supplyStop!.item.name.toLowerCase(), contains('angle stop'));
    expect(supplyStop.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing core parser handles water treatment shorthand batch five', () {
    final pressureGauge = matchReceiptLineToCatalog(
      'TRACTOR SUPPLY WELL PRESSURE GAUGE 100 PSI',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(pressureGauge, isNotNull);
    expect(pressureGauge!.item.name.toLowerCase(), contains('pressure gauge'));
    expect(pressureGauge.confidenceLevel, ReceiptConfidenceLevel.good);

    final softenerSalt = matchReceiptLineToCatalog(
      'WALMART WATER SOFTENER SALT PELLETS 40 LB',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(softenerSalt, isNotNull);
    expect(softenerSalt!.item.name.toLowerCase(), contains('softener'));
    expect(softenerSalt.item.name.toLowerCase(), contains('salt'));
    expect(softenerSalt.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing core parser avoids overconfidence on vague batch five lines',
    () {
      final vaguePush = matchReceiptLineToCatalog(
        'LOWES 1/2 PUSH CONNECT',
        tradeScope: 'Plumbing',
        maxCandidates: 360,
      );
      expect(vaguePush, isNotNull);
      expect(vaguePush!.confidenceLevel, isNot(ReceiptConfidenceLevel.good));

      final vagueGauge = matchReceiptLineToCatalog(
        'ACE PRESSURE GAUGE',
        tradeScope: 'Plumbing',
        maxCandidates: 360,
      );
      expect(vagueGauge, isNotNull);
      expect(vagueGauge!.confidenceLevel, isNot(ReceiptConfidenceLevel.good));

      final unspecificSalt = matchReceiptLineToCatalog(
        'WALMART SALT PELLETS 40 LB',
        tradeScope: 'Plumbing',
        maxCandidates: 360,
      );
      expect(unspecificSalt, isNotNull);
      expect(
        unspecificSalt!.confidenceLevel,
        isNot(ReceiptConfidenceLevel.good),
      );

      final vagueSpanishValve = matchReceiptLineToCatalog(
        'ACE VALVULA 1/2',
        localePackId: 'es-US',
        tradeScope: 'Plumbing',
        maxCandidates: 360,
      );
      expect(vagueSpanishValve, isNotNull);
      expect(
        vagueSpanishValve!.confidenceLevel,
        isNot(ReceiptConfidenceLevel.good),
      );
    },
  );
}
