import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac core parses merchant-style filter lines', () {
    _expectGoodHvacCore('HD 16X20X1 PLEATED AIR FILTER', ['filter']);
    _expectGoodHvacCore('LOWES 20 X 25 X 1 FURN FILTER MERV 8', ['filter']);
    _expectGoodHvacCore('ACE AC FILTER 14X25X1 3PK', ['filter']);
  });

  test('hvac core parses merchant-style controls and electrical lines', () {
    _expectGoodHvacCore('SUPPLY 45/5 MFD DUAL RUN CAP', ['capacitor']);
    _expectGoodHvacCore('GRAINGER 40A 2P 24V CONTACTOR', ['contactor']);
    _expectGoodHvacCore('HD TSTAT 1H/1C PROG WHITE', ['thermostat']);
    _expectGoodHvacCore('LOWES 18/5 THERMOSTAT WIRE 50FT', ['thermostat']);
  });

  test('hvac core parses merchant-style condensate lines', () {
    _expectGoodHvacCore('HD COND PUMP 120V', ['condensate']);
    _expectGoodHvacCore('LOWES CONDENSATE FLOAT SWITCH', ['switch']);
    _expectGoodHvacCore('ACE COND DRAIN TABS', ['tablet']);
    _expectGoodHvacCore('SUPPLY 3/4 PVC CONDENSATE CPLG', ['condensate']);
  });

  test('hvac core parses merchant-style tape sealant and gas heat lines', () {
    _expectGoodHvacCore('HD UL181 FOIL HVAC TAPE', ['tape']);
    _expectGoodHvacCore('LOWES DUCT MASTIC 1 GAL', ['mastic']);
    _expectGoodHvacCore('SUPPLY FLAME SENSOR UNIVERSAL', ['flame']);
    _expectGoodHvacCore('ACE HOT SURFACE IGNITOR HSI', ['ignitor']);
  });

  test('hvac core keeps vague cross-trade lines out of good confidence', () {
    _expectNotGoodHvac('LOWES 3/4 PVC 90');
    _expectNotGoodHvac('HD FILTER');
    _expectNotGoodHvac('ACE SWITCH');
  });
}

void _expectGoodHvacCore(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'HVAC',
    maxCandidates: 420,
  );
  expect(match, isNotNull, reason: line);
  final detail = '$line -> ${match!.item.name} / ${match.item.path}';
  expect(match.item.trade, 'HVAC', reason: detail);
  expect(match.item.packTier, WorkSupplyPackTier.core, reason: detail);
  expect(match.confidenceLevel, ReceiptConfidenceLevel.good, reason: detail);
  final searchable = match.item.searchableText.toLowerCase();
  for (final term in expectedTerms) {
    expect(searchable, contains(term), reason: detail);
  }
}

void _expectNotGoodHvac(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'HVAC',
    maxCandidates: 420,
  );
  if (match == null) {
    return;
  }
  expect(
    match.confidenceLevel,
    isNot(ReceiptConfidenceLevel.good),
    reason: '$line -> ${match.item.name}',
  );
}
