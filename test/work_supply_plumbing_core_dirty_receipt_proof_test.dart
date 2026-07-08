import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('plumbing core recovers dirty OCR when enough alternate clues remain', () {
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
  });

  test('plumbing core uses connection and brand clues when material is missing', () {
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
  });

  test('plumbing core keeps missing or broken critical size evidence in review', () {
    _expectReviewPlumbing('/2 COP 90 CXC');
    _expectReviewPlumbing('1/ COP 90 CXC');
    _expectReviewPlumbing('3/ PVC SCH40 CPLG');
    _expectReviewPlumbing('12 COP 90 CXC');
    _expectReviewPlumbing('PVC 90');
  });

  test('plumbing core keeps damaged generic material and shape lines in review', () {
    _expectReviewPlumbing('C0P 90');
    _expectReviewPlumbing('PEX ADPT');
    _expectReviewPlumbing('CPVC CPLG');
    _expectReviewPlumbing('RUBBER REPAIR');
    _expectReviewPlumbing('FAUCET REPAIR KIT');
  });

  test('plumbing core ignores dirty receipt totals and payment noise', () {
    _expectNoPlumbingMatch('SUBT0TAL 43.28');
    _expectNoPlumbingMatch('T0TAL DUE 46.72');
    _expectNoPlumbingMatch('VISA APPROVED AUTH 12345');
    _expectNoPlumbingMatch('CASHIER 08 REG 03 THANK Y0U');
  });

  test('plumbing core handles dirty random-store service receipts', () {
    _expectGoodPlumbingCore('FERG QTY1 WATTS PRV PRESS RED VLV 3/4', [
      'pressure reducing valve',
    ]);
    _expectGoodPlumbingCore('WlNSUPPLY 1/2 ANG ST0P COMP X OD CHR', [
      'angle stop',
    ]);
    _expectGoodPlumbingCore('RURAL KING WELL PRESS SW 40/60', [
      'pressure switch',
    ]);
    _expectGoodPlumbingCore('SUPPLYH0USE 3/4 VAC BRKR H0SE BIBB', [
      'vacuum',
    ]);
    _expectGoodPlumbingCore('LOCAL HW 3 X 2 FERNCO RED CPLG', ['fernco']);
  });
}

void _expectGoodPlumbingCore(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(
    line,
    tradeScope: 'Plumbing',
    maxCandidates: 420,
  );
  expect(match, isNotNull, reason: line);
  final detail = '$line -> ${match!.item.name} / ${match.item.path}';
  expect(match.item.trade, 'Plumbing', reason: detail);
  expect(match.item.packTier, WorkSupplyPackTier.core, reason: detail);
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
