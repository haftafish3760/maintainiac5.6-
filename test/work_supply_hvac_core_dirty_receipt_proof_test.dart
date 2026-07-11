import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('hvac core recovers dirty OCR when enough clues remain', () {
    _expectGoodHvacCore('L0WES 20 X 25 X 1 FURN F1LTER MERV 8', ['filter']);
    _expectGoodHvacCore('SUPPLY 45/5 MFD DUAL RUN CAPAC1T0R', ['capacitor']);
    _expectGoodHvacCore('ACE C0NDENSATE FL0AT SW1TCH', ['switch']);
    _expectGoodHvacCore('HD UL181 F0IL HVAC TAPE', ['tape']);
    _expectGoodHvacCore('WINSUPPLY TIME DELAY RELAY 24V', ['relay']);
  });

  test('hvac core uses alternate service-stock clues when wording is rough', () {
    _expectGoodHvacCore('HONEYWELL TSTAT PRO 1H/1C WHT', ['thermostat']);
    _expectGoodHvacCore('SUPCO SPP6 HARD START KT', ['hard start']);
    _expectGoodHvacCore('DIVERSITECH PAN TABS CONDENSATE', ['tablet']);
    _expectGoodHvacCore('LOWES AC LINESET COVER KIT WHITE', ['line set']);
    _expectGoodHvacCore('LOCAL SUPPLY CONDENSATE NEUTRALIZER KIT', [
      'neutralizer',
    ]);
  });

  test('hvac core keeps missing critical evidence in review', () {
    _expectReviewHvac('FILTER 20X25X1');
    _expectReviewHvac('CAP 45/5');
    _expectReviewHvac('SWITCH');
    _expectReviewHvac('PVC 3/4 UNION');
    _expectReviewHvac('RELAY');
  });

  test('hvac core ignores dirty receipt totals and tender noise', () {
    _expectNoHvacMatch('SUBT0TAL 112.90');
    _expectNoHvacMatch('T0TAL PAID 119.42');
    _expectNoHvacMatch('CARD APPROVED AUTH 4402');
    _expectNoHvacMatch('CASHIER 11 REG 02 THANK Y0U');
  });

  test('hvac core handles dirty random-store service receipts', () {
    _expectGoodHvacCore('GRAINGER 40/5 MFD DUAL RUN CAP 440V', ['capacitor']);
    _expectGoodHvacCore('WlNSUPPLY C0NDENSATE PUMP 120V', [
      'condensate pump',
    ]);
    _expectGoodHvacCore('SUPPLY 18/5 STAT WlRE 50FT', ['thermostat']);
    _expectGoodHvacCore('SUPPLYH0USE R410A SERV VALV CAP', ['valve cap']);
    _expectGoodHvacCore('LOCAL SUPPLY 3/4X3/8 LINESET 50FT', ['line set']);
    _expectGoodHvacCore('LOCAL HVAC 3/8 ACR C0PPER TUBING 20FT', ['acr']);
    _expectGoodHvacCore('ACE HVAC F0IL TAPE UL181', ['tape']);
  });

  test('hvac core covers named regional merchant receipt families', () {
    _expectGoodHvacCore('MENARDS 16X25X1 FURN FILTER MERV 8', ['filter']);
    _expectGoodHvacCore('TRUE VALUE 45/5 MFD DUAL RUN CAP', ['capacitor']);
    _expectGoodHvacCore('FERG 3/4 CONDENSATE FLOAT SWITCH', ['switch']);
    _expectGoodHvacCore('FASTENAL UL181 FOIL HVAC TAPE', ['tape']);
    _expectGoodHvacCore('TRACTOR SUPPLY 1H/1C TSTAT WHT', ['thermostat']);
    _expectGoodHvacCore('RURAL KING PAN TABS CONDENSATE', ['tablet']);
    _expectGoodHvacCore('NORTHERN TOOL 1/2 IN X 6FT EQUIP WHIP', [
      'equipment whip',
    ]);
  });

  test('hvac core covers supplemental service stock receipt language', () {
    _expectGoodHvacCore('LOCAL HVAC 40/5 MFD DUAL RUN CAP 440V', [
      'capacitor',
    ]);
    _expectGoodHvacCore('FERG 30A 2P CONTACT0R 24V COIL', ['contactor']);
    _expectGoodHvacCore('WINSUPPLY 3A LOW VOLT FUSE PK', ['fuse']);
    _expectGoodHvacCore('ACE C WIRE ADAPTER TSTAT', ['adapter']);
    _expectGoodHvacCore('MENARDS NO RINSE COIL CLEANER', ['cleaner']);
    _expectGoodHvacCore('FASTENAL FOAM GASKET TAPE ROLL', ['tape']);
    _expectGoodHvacCore('RURAL KING 30X30 EQUIP PAD', ['pad']);
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

void _expectReviewHvac(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'HVAC',
    maxCandidates: 420,
  );
  if (match == null) return;
  expect(
    match.confidenceLevel,
    isNot(ReceiptConfidenceLevel.good),
    reason:
        '$line must require review instead of a confident inventory item: '
        '${match.item.name} confidence=${match.confidence}',
  );
}

void _expectNoHvacMatch(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'HVAC',
    maxCandidates: 420,
  );
  expect(match, isNull, reason: line);
}
