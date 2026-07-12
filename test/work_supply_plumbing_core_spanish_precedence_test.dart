import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('Plumbing Core keeps equal-size PEX tee precedence', () {
    final match = _expectGoodCore('3/4 PEX T');
    expect(match.item.name, contains('3/4 x 3/4 x 3/4 PEX Tee'));
  });

  test('Plumbing Core recognizes Spanish faucet and well service lines', () {
    final cases = <String, String>{
      'CONECTOR GRIFO 3/8 X 16': 'Faucet Supply Line',
      'SWITCH PRESION POZO 30/50': 'Pressure Switch',
      'INTERRUPTOR BOMBA 40/60': 'Pressure Switch',
      'VALVULA CHECK POZO 1 IN': 'Check Valve',
      'CHECK BOMBA 3/4': 'Check Valve',
    };

    for (final entry in cases.entries) {
      final match = _expectGoodCore(entry.key);
      expect(match.item.name, contains(entry.value), reason: entry.key);
    }
  });
}

ReceiptLineMatch _expectGoodCore(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    localePackId: 'es-US',
    maxCandidates: 420,
  );
  expect(match, isNotNull, reason: line);
  expect(match!.item.trade, 'Plumbing', reason: line);
  expect(match.item.packTier, WorkSupplyPackTier.core, reason: line);
  expect(match.confidenceLevel, ReceiptConfidenceLevel.good, reason: line);
  return match;
}
