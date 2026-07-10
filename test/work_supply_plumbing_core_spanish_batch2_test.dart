import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing es-US parser handles valve shorthand batch two', () {
    final pushBallValve = matchReceiptLineToCatalog(
      'HD 1/2 VALVULA BOLA CONEXION RAPIDA',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(pushBallValve, isNotNull);
    expect(pushBallValve!.item.name.toLowerCase(), contains('push-fit'));
    expect(pushBallValve.item.name.toLowerCase(), contains('ball valve'));
    expect(pushBallValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final angleStop = matchReceiptLineToCatalog(
      'LOWES 1/2 X 3/8 LLAVE ESCUADRA CROMO',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(angleStop, isNotNull);
    expect(angleStop!.item.name.toLowerCase(), contains('angle stop'));
    expect(angleStop.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing es-US parser handles DWV access shorthand batch two', () {
    final trapAdapter = matchReceiptLineToCatalog(
      'FERG 1-1/2 PVC ADAPTADOR TRAMPA',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(trapAdapter, isNotNull);
    expect(trapAdapter!.item.name.toLowerCase(), contains('trap adapter'));
    expect(trapAdapter.confidenceLevel, ReceiptConfidenceLevel.good);

    final cleanout = matchReceiptLineToCatalog(
      'HD 4IN TAPON LIMPIEZA PVC',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(cleanout, isNotNull);
    expect(cleanout!.item.name.toLowerCase(), contains('cleanout'));
    expect(cleanout.item.name.toLowerCase(), contains('plug'));
    expect(cleanout.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing es-US parser handles well pressure shorthand batch two', () {
    final pressureGauge = matchReceiptLineToCatalog(
      'ACE MANOMETRO PRESION POZO 100 PSI',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 360,
    );
    expect(pressureGauge, isNotNull);
    expect(pressureGauge!.item.name.toLowerCase(), contains('pressure gauge'));
    expect(pressureGauge.confidenceLevel, ReceiptConfidenceLevel.good);
  });
}
