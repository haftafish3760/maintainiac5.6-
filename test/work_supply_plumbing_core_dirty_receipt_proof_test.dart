import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test(
    'plumbing core recovers dirty OCR when enough alternate clues remain',
    () {
      _expectGoodPlumbingCore('L0WES 1/2 C0P 90 ELL C X C 2 @ 1.98', [
        'copper',
        '90',
      ]);
      _expectGoodPlumbingCore('FERG 3/4 PEX C0UP CRlMP 4.29', [
        'pex',
        'coupling',
      ]);
      _expectGoodPlumbingCore('ACE 1 1/2 P TRAP KlT WHT', ['p-trap']);
      _expectGoodPlumbingCore('WINSUPPLY 3/4 BALL VALV FlP', ['ball valve']);
      _expectGoodPlumbingCore('SUPPLYHOUSE WATTS PRV PRESS RED VALV 3/4', [
        'pressure reducing valve',
      ]);
    },
  );

  test(
    'plumbing core uses connection and brand clues when material is missing',
    () {
      _expectGoodPlumbingCore('NIBCO 1/2 CXC 90 WROT ELL', ['copper', '90']);
      _expectGoodPlumbingCore('MUELLER 3/4 C X M SWEAT ADPT', [
        'copper',
        'male',
      ]);
      _expectGoodPlumbingCore('SHARKBITE 1/2 PUSH COUP', [
        'push-fit',
        'coupling',
      ]);
      _expectGoodPlumbingCore('OATEY 4X3 CLOSET FLANGE PVC', ['flange']);
    },
  );

  test(
    'plumbing core keeps missing or broken critical size evidence in review',
    () {
      _expectReviewPlumbing('/2 COP 90 CXC');
      _expectReviewPlumbing('1/ COP 90 CXC');
      _expectReviewPlumbing('3/ PVC SCH40 CPLG');
      _expectReviewPlumbing('12 COP 90 CXC');
      _expectReviewPlumbing('PVC 90');
    },
  );

  test(
    'plumbing core keeps damaged generic material and shape lines in review',
    () {
      _expectReviewPlumbing('C0P 90');
      _expectReviewPlumbing('PEX ADPT');
      _expectReviewPlumbing('ACE ADPT 1/2');
      _expectReviewPlumbing('CPVC CPLG');
      _expectReviewPlumbing('RUBBER REPAIR');
      _expectReviewPlumbing('FAUCET REPAIR KIT');
    },
  );

  test('plumbing core ignores dirty receipt totals and payment noise', () {
    _expectNoPlumbingMatch('SUBT0TAL 43.28');
    _expectNoPlumbingMatch('SUBTOTAL 43 28');
    _expectNoPlumbingMatch('T0TAL DUE 46.72');
    _expectNoPlumbingMatch('VISA APPROVED AUTH 12345');
    _expectNoPlumbingMatch('CASHIER 08 REG 03 THANK Y0U');
  });

  test('plumbing core handles dirty random-store service receipts', () {
    _expectGoodPlumbingCore('FERG QTY1 WATTS PRV PRESS RED VLV 3/4', [
      'pressure reducing valve',
    ]);
    _expectGoodPlumbingCore('LOCAL 1 IN PVC 90', ['pvc schedule 40', 'elbow']);
    _expectGoodPlumbingCore('WlNSUPPLY 1/2 ANG ST0P COMP X OD CHR', [
      'angle stop',
    ]);
    _expectGoodPlumbingCore('RURAL KING WELL PRESS SW 40/60', [
      'pressure switch',
    ]);
    _expectGoodPlumbingCore('SUPPLYH0USE 3/4 VAC BRKR H0SE BIBB', ['vacuum']);
    _expectGoodPlumbingCore('LOCAL HW 3 X 2 FERNCO RED CPLG', ['fernco']);
    _expectGoodPlumbingCore('LOWES 1-1/2 BARBED ADAPTER SUMP PUMP 38.59', [
      'sump pump',
      'barbed adapter',
    ]);
    _expectGoodPlumbingCore('LOCAL 1/2 HP SUMP PUMP 129.99', ['sump pump']);
    _expectGoodPlumbingCore('FERG 3/8 X 50 CONDENSATE TUBING VINYL', [
      'condensate pump tubing',
    ]);
    _expectGoodPlumbingCore('FERG 3/4 BRS COMP ADPT 42.87', [
      'brass compression adapter',
    ]);
  });

  test('plumbing core handles dirty regional service-house receipts', () {
    _expectGoodPlumbingCore('MENARDS 1/2 SHKBITE PUSH CPLG LEADFREE', [
      'push-fit',
      'coupling',
    ]);
    _expectGoodPlumbingCore('TRUE VALUE 1-1/2 SJ TRAP ADPT NUT WASH', [
      'trap adapter',
    ]);
    _expectGoodPlumbingCore('FASTENAL 3/4 WTR HTR UN1ON DIELECTRIC', [
      'water heater',
      'union',
    ]);
    _expectGoodPlumbingCore('NORTHERN TOOL 1-1/4 WELL PUMP CHK VALV', [
      'check valve',
    ]);
    _expectGoodPlumbingTier('LOCAL SUPPLY 3/4 SOFTNER BYPASS VLV', [
      'softener',
      'bypass',
    ], WorkSupplyPackTier.standard);
  });

  test('plumbing core handles dirty soldering consumable receipt lines', () {
    _expectGoodPlumbingCore('L0WES LF S0LDER 1/8 8OZ PLMB', [
      'lead-free plumbing solder',
    ]);
    _expectGoodPlumbingCore('FERG TINNING FLUX 4 0Z PASTE', [
      'water soluble flux',
    ]);
    _expectGoodPlumbingCore('ACE FLUX BRUSH 3 PK AC1D BRUSH', ['acid brush']);
    _expectGoodPlumbingCore('LOCAL HW HEAT SHlELD FLAME PROTCTR', [
      'soldering heat shield',
    ]);
    _expectGoodPlumbingCore('RURAL KING MAP PR0 FUEL CYL TORCH', [
      'map-pro torch fuel',
    ]);
  });

  test(
    'plumbing core keeps noisy pvc glue receipts out of 8 inch dwv fittings',
    () {
      _expectGoodPlumbingCore('LOCAL HDW 8 OZ PVC GLUE 71.90 94.77', [
        'pvc cement',
      ]);
    },
  );

  test(
    'plumbing core keeps bare pvc elbow abbreviations in review even with trade scope',
    () {
      _expectReviewPlumbing('HD PVC EL 3/4');
      _expectReviewPlumbing('LOWES PVC 90 1/2');
    },
  );

  test(
    'plumbing core routes shorthand water-heater strap lines away from generic pipe straps',
    () {
      _expectGoodPlumbingCore('MENARDS UNIVERSAL WTR HTR STRAP 62.27', [
        'water heater',
        'strap',
      ]);
    },
  );

  test('plumbing core handles mixed Spanish dirty service receipts', () {
    _expectGoodPlumbingCore('FERG 1/2 CODO COBRE 90 CXC', [
      'copper',
      '90',
    ], localePackId: 'es-US');
    _expectGoodPlumbingCore('LOCAL 3/4 VALVULA BOLA FIP', [
      'ball valve',
    ], localePackId: 'es-US');
    _expectGoodPlumbingCore('ACE TRAMPA LAVABO 1-1/2 KIT', [
      'p-trap',
    ], localePackId: 'es-US');
    _expectGoodPlumbingCore('RURAL KING BOMBA POZO 1/2HP', [
      'well pump',
    ], localePackId: 'es-US');
    _expectGoodPlumbingTier(
      'SUPPLY CASA SAL SUAVIZADOR 40LB',
      ['softener'],
      WorkSupplyPackTier.standard,
      localePackId: 'es-US',
    );
  });
}

void _expectGoodPlumbingCore(
  String line,
  List<String> expectedTerms, {
  String localePackId = '',
}) {
  _expectGoodPlumbingTier(
    line,
    expectedTerms,
    WorkSupplyPackTier.core,
    localePackId: localePackId,
  );
}

void _expectGoodPlumbingTier(
  String line,
  List<String> expectedTerms,
  WorkSupplyPackTier expectedTier, {
  String localePackId = '',
}) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 420,
    localePackId: localePackId,
  );
  expect(match, isNotNull, reason: line);
  final detail = '$line -> ${match!.item.name} / ${match.item.path}';
  expect(match.item.trade, 'Plumbing', reason: detail);
  expect(match.item.packTier, expectedTier, reason: detail);
  expect(match.confidenceLevel, ReceiptConfidenceLevel.good, reason: detail);
  final searchable = [
    match.item.name,
    match.item.system,
    match.item.itemType,
    match.item.variant,
    ...match.item.aliases,
  ].join(' ').toLowerCase();
  for (final term in expectedTerms) {
    expect(searchable, contains(term), reason: detail);
  }
}

void _expectReviewPlumbing(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
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

void _expectNoPlumbingMatch(String line) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 420,
  );
  expect(match, isNull, reason: line);
}
