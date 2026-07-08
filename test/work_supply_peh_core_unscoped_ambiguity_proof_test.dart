import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  test('peh core keeps unscoped cross-trade PVC lines in review', () {
    _expectReviewOrNoMatch('PVC 90');
    _expectReviewOrNoMatch('3/4 PVC UNION');
    _expectReviewOrNoMatch('3/4 PVC CPLG');
    _expectReviewOrNoMatch('PVC COND');
    _expectReviewOrNoMatch('PVC PIPE');
  });

  test('peh core keeps unscoped generic service words in review', () {
    _expectReviewOrNoMatch('SWITCH');
    _expectReviewOrNoMatch('RELAY');
    _expectReviewOrNoMatch('CONNECTOR KIT');
    _expectReviewOrNoMatch('FILTER');
    _expectReviewOrNoMatch('TAPE');
  });

  test('peh core still allows strong unscoped item evidence', () {
    _expectGoodUnscoped('1/2 COP 90 CXC', ['Plumbing', 'copper']);
    _expectGoodUnscoped('12/2 NMB ROMEX W/G 100FT', ['Electrical', 'nm-b']);
    _expectGoodUnscoped('20 X 25 X 1 FURN FILTER MERV 8', ['HVAC', 'filter']);
  });
}

void _expectReviewOrNoMatch(String line) {
  final match = matchReceiptLineToCatalog(line, maxCandidates: 420);
  if (match == null) return;
  expect(
    match.confidenceLevel,
    isNot(ReceiptConfidenceLevel.good),
    reason:
        '$line must require review without trade scope instead of a confident '
        'inventory item: ${match.item.name} confidence=${match.confidence}',
  );
}

void _expectGoodUnscoped(String line, List<String> expectedTerms) {
  final match = matchReceiptLineToCatalog(line, maxCandidates: 420);
  expect(match, isNotNull, reason: line);
  expect(match!.confidenceLevel, ReceiptConfidenceLevel.good, reason: line);
  final searchable = [
    match.item.trade,
    match.item.name,
    match.item.system,
    match.item.itemType,
    match.item.variant,
    ...match.item.aliases,
  ].join(' ').toLowerCase();
  for (final term in expectedTerms) {
    expect(searchable, contains(term.toLowerCase()), reason: line);
  }
}
