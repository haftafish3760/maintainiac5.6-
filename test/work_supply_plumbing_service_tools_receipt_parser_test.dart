import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing parser handles PEX and press service tool receipts', () {
    _expectPlumbingTool('LOWES PEX CINCH CLAMP TOOL', ['cinch']);
    _expectPlumbingTool('HD PEX EXPANDER HEAD KIT', ['expander']);
    _expectPlumbingTool('FERG 1/2 PROPRESS JAW', ['propress']);
    _expectPlumbingTool('SUPPLY COPPER PRESS FITTING TOOL JAW', ['press']);
  });

  test('plumbing parser handles drain and fixture service tool receipts', () {
    _expectPlumbingTool('ACE BASIN WRENCH TELESCOPING', ['basin wrench']);
    _expectPlumbingTool('HD CLOSET AUGER 3FT', ['closet auger']);
    _expectPlumbingTool('LOWES HAND DRAIN AUGER 25FT', ['drain auger']);
    _expectPlumbingTool('TRACTOR SUPPLY SMALL DRAIN SNAKE', ['drain snake']);
  });

  test('plumbing parser handles pipe cutting blade receipts', () {
    _expectPlumbingTool('HD 9IN BI METAL SAWZALL BLADE', ['reciprocating']);
    _expectPlumbingTool('LOWES PVC PLASTIC RECIP BLADE 6IN', ['pvc']);
    _expectPlumbingTool('ACE CAST IRON CARBIDE RECIP BLADE', ['cast iron']);
    _expectPlumbingTool('MENARDS 2-1/8 HOLE SAW BI METAL', ['hole saw']);
  });
}

void _expectPlumbingTool(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 320,
  );
  expect(match, isNotNull, reason: line);
  final item = match!.item;
  final text = '${item.name} ${item.aliases.join(' ')}'.toLowerCase();
  expect(item.trade, 'Plumbing', reason: line);
  expect(item.system, 'Plumbing Hand Tools', reason: line);
  for (final term in expectedTerms) {
    expect(text, contains(term), reason: line);
  }
  expect(match.confidenceLevel, ReceiptConfidenceLevel.good, reason: line);
}
