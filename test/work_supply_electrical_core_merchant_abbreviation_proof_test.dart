import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('electrical core parses merchant-style wire and cable lines', () {
    _expectGoodElectricalCore('HD 12/2 NM-B W/G 250FT', ['nm-b']);
    _expectGoodElectricalCore('LOWES 14/2 NMB ROMEX 100 FT', ['nm-b']);
    _expectGoodElectricalCore('MENARDS 12 AWG THHN BLK 500FT', ['thhn']);
    _expectGoodElectricalCore('ACE 18/2 LOW VOLT STAT WIRE', ['low voltage']);
  });

  test('electrical core parses merchant-style devices and controls', () {
    _expectGoodElectricalCore('HD 20A WR GFCI RECPT WHITE', ['gfci']);
    _expectGoodElectricalCore('LOWES 15A DUPLEX RECEPT TR WHITE', ['duplex']);
    _expectGoodElectricalCore('MENARDS 3 WAY SWITCH IVORY', ['switch']);
    _expectGoodElectricalCore('ACE LED DIMMER SINGLE POLE', ['dimmer']);
  });

  test('electrical core parses merchant-style breakers and panels', () {
    _expectGoodElectricalCore('HD 20A 1P BRKR', ['breaker']);
    _expectGoodElectricalCore('LOWES 30 AMP 2 POLE GFCI BRKR', ['breaker']);
    _expectGoodElectricalCore('MENARDS AFCI 15A SINGLE POLE BREAKER', [
      'breaker',
    ]);
    _expectGoodElectricalCore('SUPPLY PANEL FILLER PLATE PK', ['filler']);
  });

  test('electrical core parses merchant-style boxes covers and raceway', () {
    _expectGoodElectricalCore('HD 1G OLD WORK BOX', ['box']);
    _expectGoodElectricalCore('LOWES 4IN CEILING FAN BOX', ['fan']);
    _expectGoodElectricalCore('ACE WP IN USE COVER', ['cover']);
    _expectGoodElectricalCore('MENARDS 1/2 EMT SET SCREW CONN', ['emt']);
    _expectGoodElectricalCore('HD 3/4 PVC ELEC 90', ['conduit']);
  });

  test(
    'electrical core parses merchant-style consumables grounding service',
    () {
      _expectGoodElectricalCore('HD WIRE NUT TAN 100PK', ['wire']);
      _expectGoodElectricalCore('LOWES ELEC TAPE BLK 3PK', ['tape']);
      _expectGoodElectricalCore('ACE 5/8 GROUND ROD CLAMP', ['ground']);
      _expectGoodElectricalCore('SUPPLY 30A AC DISCONNECT NON FUSIBLE', [
        'disconnect',
      ]);
    },
  );

  test(
    'electrical core keeps cross-trade vague PVC out of good confidence',
    () {
      _expectNotGoodElectrical('LOWES 3/4 PVC 90');
      _expectNotGoodElectrical('HD 1/2 C X C');
      _expectNotGoodElectrical('MENARDS CONNECTOR KIT');
    },
  );

  test('electrical core parses POS-noisy merchant lines', () {
    _expectGoodElectricalCore('HD 188742 2 @ 1.98 1/2 EMT SS CONN 3.96', [
      'emt',
    ]);
    _expectGoodElectricalCore('LOWES 043221 QTY2 15A TR DUP RECPT WHT', [
      'duplex',
    ]);
    _expectGoodElectricalCore('ACE 90317 100PK TAN WIRENUT DISC 10%', ['wire']);
    _expectGoodElectricalCore('MENARDS 7782 12-2 ROMEX W/G 250FT 148.00', [
      'nm-b',
    ]);
  });

  test('electrical core parses Spanish and mixed-language receipts', () {
    _expectGoodElectricalCore('FERRETERIA CABLE ROMEX 12/2 CON TIERRA', [
      'nm-b',
    ]);
    _expectGoodElectricalCore('SUMINISTRO CINTA ELECTRICA NEGRA 3PK', ['tape']);
    _expectGoodElectricalCore('ACE CAJA ELECTRICA 1G OLD WORK', ['box']);
    _expectGoodElectricalCore('LOCAL INTERRUPTOR 3 VIA BLANCO', ['switch']);
    _expectGoodElectricalCore('LOWES TOMACORRIENTE GFCI 20A BLANCO', ['gfci']);
  });

  test('electrical core parses manufacturer-heavy service receipts', () {
    _expectGoodElectricalCore('LEVITON 20A WR GFCI RECEPT WHT', ['gfci']);
    _expectGoodElectricalCore('HUBBELL 1G EXTRA DUTY IN USE COVER', ['cover']);
    _expectGoodElectricalCore('CARLON 3/4 PVC LB BODY GRAY', ['conduit']);
    _expectGoodElectricalCore('HALO PORCELAIN LAMPHOLDER KEYLESS', [
      'lampholder',
    ]);
    _expectGoodElectricalCore('IDEAL 3 PORT LEVER CONNECTOR 25PK', ['lever']);
  });

  test('electrical core parses supply-house and hardware shorthand', () {
    _expectGoodElectricalCore('WINSUPPLY 1/2 EMT COMP CPLG', ['emt']);
    _expectGoodElectricalCore('GRAINGER 3/4 LIQUIDTIGHT CONN', ['liquidtight']);
    _expectGoodElectricalCore('FASTENAL #10 GREEN GROUND SCREW 100PK', [
      'ground',
    ]);
    _expectGoodElectricalCore('TRUE VALUE 14/2 UF-B DIRECT BURIAL 50FT', [
      'uf-b',
    ]);
    _expectGoodElectricalCore('RURAL KING 5/8 GROUND ROD 8FT', ['ground']);
  });

  test('electrical core parses service-stock conduit and flex lines', () {
    _expectGoodElectricalCore('HD 12/2 MC CABLE ALUM 250FT', ['mc cable']);
    _expectGoodElectricalCore('LOWES 1/2 FLEX METAL CONDUIT 25FT', [
      'flexible',
    ]);
    _expectGoodElectricalCore('ACE 1/2 EMT 1 HOLE STRAP 25PK', ['strap']);
    _expectGoodElectricalCore('SUPPLY 3/4 PVC LB CONDUIT BODY', ['conduit']);
    _expectGoodElectricalCore('GRAINGER 1/2 LIQUIDTIGHT FLEX CONDUIT', [
      'liquidtight',
    ]);
  });

  test('electrical core parses service lighting and repair stock', () {
    _expectGoodElectricalCore('HD KEYLESS LAMPHOLDER PORCELAIN', [
      'lampholder',
    ]);
    _expectGoodElectricalCore('LOWES CEILING FAN BRACE BOX KIT', ['fan']);
    _expectGoodElectricalCore('ACE PHOTOEYE OUTDOOR LIGHT CONTROL', [
      'photocell',
    ]);
    _expectGoodElectricalCore('SUPPLY WEATHERPROOF BELL BOX 1G GRAY', [
      'weatherproof',
    ]);
    _expectGoodElectricalCore('TRUE VALUE BLANK WALL PLATE 1G WHT', ['plate']);
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
    expect(searchable, contains(term), reason: '$line -> ${match.item.name}');
  }
}

void _expectNotGoodElectrical(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Electrical',
    maxCandidates: 420,
  );
  if (match == null) {
    return;
  }
  expect(
    match.confidenceLevel,
    isNot(ReceiptConfidenceLevel.good),
    reason: line,
  );
}
