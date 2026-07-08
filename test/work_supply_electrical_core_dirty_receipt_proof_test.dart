import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('electrical core recovers dirty OCR when enough clues remain', () {
    _expectGoodElectricalCore('L0WES 12/2 NMB R0MEX W/G 100FT', ['nm-b']);
    _expectGoodElectricalCore('HD 20A WR GFC1 RECPT WHT', ['gfci']);
    _expectGoodElectricalCore('ACE 1/2 EMT 1 H0LE STRAP 25PK', ['strap']);
    _expectGoodElectricalCore('MENARDS 3 WAY SW1TCH IVORY', ['switch']);
    _expectGoodElectricalCore('TRUE VALUE 5/8 GR0UND ROD CLAMP', ['ground']);
  });

  test('electrical core uses alternate service-stock clues when wording is rough', () {
    _expectGoodElectricalCore('LEVITON 20A GFI WR RECPT WHITE', ['gfci']);
    _expectGoodElectricalCore('CARLON 3/4 PVC LB BODY GRY', ['conduit']);
    _expectGoodElectricalCore('IDEAL LEVER CONN 3 PORT 25PK', ['lever']);
    _expectGoodElectricalCore('ACE PHOTOEYE OUTDOOR LIGHT CONTROL', [
      'photocell',
    ]);
  });

  test('electrical core keeps missing critical evidence in review', () {
    _expectReviewElectrical('12/ NM-B W/G');
    _expectReviewElectrical('/2 ROMEX');
    _expectReviewElectrical('20A RECPT');
    _expectReviewElectrical('PVC COND');
    _expectReviewElectrical('CONNECTOR KIT');
  });

  test('electrical core ignores dirty receipt totals and tender noise', () {
    _expectNoElectricalMatch('SUBT0TAL 88.19');
    _expectNoElectricalMatch('T0TAL PAID 94.28');
    _expectNoElectricalMatch('VISA APPROVED AUTH 9988');
    _expectNoElectricalMatch('CASHIER 04 REG 12 THANK Y0U');
  });

  test('electrical core handles dirty random-store service receipts', () {
    _expectGoodElectricalCore('GRAINGER 20A GFC1 WR RECPT WHT', ['gfci']);
    _expectGoodElectricalCore('FASTENAL 1/2 EMT COMP CONN STL', ['connector']);
    _expectGoodElectricalCore('LOCAL SUPPLY 12/2 MC CABLE ALUM 250FT', ['mc']);
    _expectGoodElectricalCore('TRUE VALUE PHOTOEYE OUTDR LGT CTRL', [
      'photocell',
    ]);
    _expectGoodElectricalCore('ACE 3/4 PVC LB B0DY GRY', ['conduit']);
    _expectGoodElectricalCore('LOCAL SUPPLY 120V 20A CONTACT0R', [
      'contactor',
    ]);
    _expectGoodElectricalCore('ACE 120V FAN SPEED CTRL', [
      'fan speed control',
    ]);
    _expectGoodElectricalCore('TRUE VALUE 240V TIME CL0CK 40A', [
      'time clock',
    ]);
    _expectGoodElectricalCore('MENARDS 120V RELAY 20A', ['relay']);
  });

  test('electrical core covers named regional merchant receipt families', () {
    _expectGoodElectricalCore('FERG 12/2 NM-B W/G 100FT', ['nm-b']);
    _expectGoodElectricalCore('WINSUPPLY 20A GFCI RECPT WR WHT', ['gfci']);
    _expectGoodElectricalCore('SUPPLYHOUSE 1/2 EMT COMP CONN STL', [
      'connector',
    ]);
    _expectGoodElectricalCore('TRACTOR SUPPLY 5/8 GROUND ROD CLAMP', [
      'ground',
    ]);
    _expectGoodElectricalCore('RURAL KING 15A SINGLE POLE SWITCH', ['switch']);
    _expectGoodElectricalCore('NORTHERN TOOL 3/4 PVC LB BODY GRY', [
      'conduit',
    ]);
  });

  test('electrical core covers supplemental service stock receipt language', () {
    _expectGoodElectricalCore('ACE 20A PLUG FUSE 4PK', ['fuse']);
    _expectGoodElectricalCore('TRUE VALUE 60A CART FUSE PAIR', ['fuse']);
    _expectGoodElectricalCore('LOCAL ELEC SUPPLY WH SURGE PROTECTR SPD', [
      'surge',
    ]);
    _expectGoodElectricalCore('SUPPLYHOUSE PANEL GROUND BAR KIT', ['ground']);
    _expectGoodElectricalCore('MENARDS PORCLN KEYLESS LAMPHLDR', [
      'lampholder',
    ]);
    _expectGoodElectricalCore('WINSUPPLY PHOTO EYE SWVL CONTROL 120V', [
      'photo',
    ]);
    _expectGoodElectricalCore('FASTENAL SPLIT BOLT CONN GROUND', ['split']);
  });
}

void _expectGoodElectricalCore(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Electrical',
    maxCandidates: 420,
  );
  expect(match, isNotNull, reason: line);
  final detail = '$line -> ${match!.item.name} / ${match.item.path}';
  expect(match.item.trade, 'Electrical', reason: detail);
  expect(match.item.packTier, WorkSupplyPackTier.core, reason: detail);
  expect(match.confidenceLevel, ReceiptConfidenceLevel.good, reason: detail);
  final searchable = match.item.searchableText.toLowerCase();
  for (final term in expectedTerms) {
    expect(searchable, contains(term), reason: detail);
  }
}

void _expectReviewElectrical(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Electrical',
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

void _expectNoElectricalMatch(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Electrical',
    maxCandidates: 420,
  );
  expect(match, isNull, reason: line);
}
