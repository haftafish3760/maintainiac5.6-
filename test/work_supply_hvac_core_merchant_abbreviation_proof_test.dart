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

  test('hvac core parses POS-noisy merchant lines', () {
    _expectGoodHvacCore('HD 88231 2 @ 11.98 16X25X1 MERV8 FILT 23.96', [
      'filter',
    ]);
    _expectGoodHvacCore('LOWES QTY1 45/5 MFD DUAL CAP DISC 10%', ['capacitor']);
    _expectGoodHvacCore('ACE 120V COND PMP W/ SAFETY SW', ['condensate']);
    _expectGoodHvacCore('SUPPLY 24V 40A 2P CONTCTR', ['contactor']);
  });

  test('hvac core parses Spanish and mixed-language receipts', () {
    _expectGoodHvacCore('FERRETERIA FILTRO AIRE 20X20X1 MERV 8', ['filter']);
    _expectGoodHvacCore('SUMINISTRO TERMOSTATO PROGRAMABLE 1H/1C', [
      'thermostat',
    ]);
    _expectGoodHvacCore('LOCAL BOMBA CONDENSADO 120V', ['condensate']);
    _expectGoodHvacCore('ACE CINTA FOIL HVAC UL181', ['tape']);
  });

  test('hvac core parses manufacturer-heavy service receipts', () {
    _expectGoodHvacCore('HONEYWELL TSTAT PRO 1H/1C WHITE', ['thermostat']);
    _expectGoodHvacCore('SUPCO SPP6 HARD START KIT', ['hard start']);
    _expectGoodHvacCore('DIVERSITECH CONDENSATE PAN TABS', ['tablet']);
    _expectGoodHvacCore('APRILAIRE 16X25X1 PLEATED FILTER', ['filter']);
  });

  test('hvac core parses supply-house shorthand service stock', () {
    _expectGoodHvacCore('WINSUPPLY 35/5 UF DUAL RUN CAP', ['capacitor']);
    _expectGoodHvacCore('GRAINGER 30A 1P 24V CONTACTOR', ['contactor']);
    _expectGoodHvacCore('FERG COND FLOAT SW INLINE', ['switch']);
    _expectGoodHvacCore('SUPPLY DUCT MASTIC QT UL181', ['mastic']);
  });

  test('hvac core parses airflow duct repair and control service stock', () {
    _expectGoodHvacCore('HD 6IN INS FLEX DUCT R6 25FT', ['flex duct']);
    _expectGoodHvacCore('LOWES 6IN START COLLAR TAKEOFF', ['takeoff']);
    _expectGoodHvacCore('ACE ZIP SCREW HVAC 1/2 100PK', ['screw']);
    _expectGoodHvacCore('SUPPLY 24V TRANSFORMER 40VA', ['transformer']);
    _expectGoodHvacCore('GRAINGER BLADE FUSE 3A 5PK', ['fuse']);
    _expectGoodHvacCore('WINSUPPLY TIME DELAY RELAY 24V', ['relay']);
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
