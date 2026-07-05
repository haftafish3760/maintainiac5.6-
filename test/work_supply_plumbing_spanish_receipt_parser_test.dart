import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing es-US parser handles common residential fitting wording', () {
    final pexElbow = matchReceiptLineToCatalog(
      'LOWES 1/2 CODO PEX 90',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(pexElbow, isNotNull);
    expect(pexElbow!.item.name, '1/2 in PEX 90 Elbow');
    expect(pexElbow.confidenceLevel, ReceiptConfidenceLevel.good);

    final ballValve = matchReceiptLineToCatalog(
      'HD 3/4 VALVULA DE BOLA PEX',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(ballValve, isNotNull);
    expect(ballValve!.item.name.toLowerCase(), contains('ball valve'));
    expect(ballValve.confidenceLevel, ReceiptConfidenceLevel.good);

    final closetFlange = matchReceiptLineToCatalog(
      'FERG 4 X 3 PVC BRIDA SANITARIO',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(closetFlange, isNotNull);
    expect(closetFlange!.item.name.toLowerCase(), contains('flange'));
    expect(closetFlange.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing es-US parser handles support fastener wording', () {
    final threadedRod = matchReceiptLineToCatalog(
      'FERG 3/8 VARILLA ROSCADA 36 IN',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(threadedRod, isNotNull);
    expect(threadedRod!.item.name.toLowerCase(), contains('threaded rod'));
    expect(threadedRod.confidenceLevel, ReceiptConfidenceLevel.good);

    final concreteScrew = matchReceiptLineToCatalog(
      'LOWES 1/4 X 2-1/4 TORNILLO CONCRETO',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(concreteScrew, isNotNull);
    expect(concreteScrew!.item.name.toLowerCase(), contains('concrete screw'));
    expect(concreteScrew.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test(
    'plumbing es-US parser handles fixture and appliance repair wording',
    () {
      final faucetCartridge = matchReceiptLineToCatalog(
        'LOWES CARTUCHO LLAVE MONOMANDO',
        localePackId: 'es-US',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(faucetCartridge, isNotNull);
      expect(faucetCartridge!.item.name.toLowerCase(), contains('cartridge'));
      expect(faucetCartridge.confidenceLevel, ReceiptConfidenceLevel.good);

      final faucetSupply = matchReceiptLineToCatalog(
        'HD 3/8 X 1/2 LINEA SUMINISTRO LLAVE',
        localePackId: 'es-US',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(faucetSupply, isNotNull);
      expect(faucetSupply!.item.name.toLowerCase(), contains('faucet'));
      expect(faucetSupply.item.name.toLowerCase(), contains('supply line'));
      expect(faucetSupply.confidenceLevel, ReceiptConfidenceLevel.good);

      final dishwasherHose = matchReceiptLineToCatalog(
        'LOWES MANGUERA DRENAJE LAVAPLATOS 7/8',
        localePackId: 'es-US',
        tradeScope: 'Plumbing',
        maxCandidates: 320,
      );
      expect(dishwasherHose, isNotNull);
      expect(dishwasherHose!.item.name.toLowerCase(), contains('dishwasher'));
      expect(dishwasherHose.item.name.toLowerCase(), contains('hose'));
      expect(dishwasherHose.confidenceLevel, ReceiptConfidenceLevel.good);
    },
  );

  test('plumbing es-US parser handles support accessory wording', () {
    final insulation = matchReceiptLineToCatalog(
      'LOWES 3/4 X 6FT AISLAMIENTO TUBO',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(insulation, isNotNull);
    expect(insulation!.item.name.toLowerCase(), contains('pipe insulation'));
    expect(insulation.confidenceLevel, ReceiptConfidenceLevel.good);

    final studGuard = matchReceiptLineToCatalog(
      'HD PLACA PROTECCIÓN CLAVO 16GA',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(studGuard, isNotNull);
    expect(studGuard!.item.name.toLowerCase(), contains('stud guard'));
    expect(studGuard.confidenceLevel, ReceiptConfidenceLevel.good);
  });

  test('plumbing es-US parser handles water treatment service wording', () {
    final softenerSalt = matchReceiptLineToCatalog(
      'LOWES 40LB SAL SUAVIZADOR AGUA',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(softenerSalt, isNotNull);
    expect(softenerSalt!.item.trade, 'Plumbing');
    expect(softenerSalt.item.name.toLowerCase(), contains('softener'));
    expect(softenerSalt.item.name.toLowerCase(), contains('salt'));

    final roMembrane = matchReceiptLineToCatalog(
      'HD MEMBRANA OSMOSIS INVERSA 75 GPD',
      localePackId: 'es-US',
      tradeScope: 'Plumbing',
      maxCandidates: 320,
    );
    expect(roMembrane, isNotNull);
    expect(roMembrane!.item.trade, 'Plumbing');
    expect(roMembrane.item.name.toLowerCase(), contains('reverse osmosis'));
    expect(roMembrane.item.name.toLowerCase(), contains('membrane'));
  });
}
