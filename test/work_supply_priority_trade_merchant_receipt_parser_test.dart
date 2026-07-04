import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main() {
  group('priority trade merchant receipt parser behavior', () {
    test('electrical merchant wording matches Core service material', () {
      final cases = <({String line, Set<String> expectedEvidence})>[
        (
          line: 'HOME DEPOT 12/2 NM-B W/G 25FT',
          expectedEvidence: {'nm-b', 'ground'},
        ),
        (line: 'LOWES 3/4 PVC COND 10FT', expectedEvidence: {'pvc', 'conduit'}),
        (line: 'LOCAL ELEC SUPPLY 1G OLD WORK BOX', expectedEvidence: {'box'}),
      ];

      for (final receiptCase in cases) {
        final match = matchReceiptLineToCatalog(
          receiptCase.line,
          tradeScope: 'Electrical',
          localePackId: 'en-US',
          maxCandidates: 500,
        );

        expect(match, isNotNull, reason: receiptCase.line);
        expect(match!.item.trade, 'Electrical', reason: receiptCase.line);
        expect(match.needsReview, isTrue, reason: receiptCase.line);
        expect(match.confidence, lessThan(1), reason: receiptCase.line);
        _expectEvidence(match, receiptCase.expectedEvidence, receiptCase.line);
      }
    });

    test('HVAC merchant wording matches Core service material', () {
      final cases = <({String line, Set<String> expectedEvidence})>[
        (line: 'WALMART 20X25X1 MERV 8 FILTER', expectedEvidence: {'filter'}),
        (
          line: 'ACE 3/4 PVC CONDENSATE CPLG',
          expectedEvidence: {'pvc', 'condensate'},
        ),
        (
          line: 'HVAC SUPPLY FOIL TAPE 2 IN',
          expectedEvidence: {'foil', 'tape'},
        ),
      ];

      for (final receiptCase in cases) {
        final match = matchReceiptLineToCatalog(
          receiptCase.line,
          tradeScope: 'HVAC',
          localePackId: 'en-US',
          maxCandidates: 500,
        );

        expect(match, isNotNull, reason: receiptCase.line);
        expect(match!.item.trade, 'HVAC', reason: receiptCase.line);
        expect(match.needsReview, isTrue, reason: receiptCase.line);
        expect(match.confidence, lessThan(1), reason: receiptCase.line);
        _expectEvidence(match, receiptCase.expectedEvidence, receiptCase.line);
      }
    });

    test('Spanish merchant wording preserves priority trade routing', () {
      final cases = <({String line, String trade, Set<String> evidence})>[
        (
          line: 'LOWES 3/4 CONDUCTO PVC',
          trade: 'Electrical',
          evidence: {'pvc', 'conduit'},
        ),
        (
          line: 'ACE FILTRO 20X25X1 MERV 8',
          trade: 'HVAC',
          evidence: {'filter'},
        ),
        (line: 'FERG 1/2 CODO PEX 90', trade: 'Plumbing', evidence: {'pex'}),
      ];

      for (final receiptCase in cases) {
        final match = matchReceiptLineToCatalog(
          receiptCase.line,
          tradeScope: receiptCase.trade,
          localePackId: 'es-US',
          maxCandidates: 500,
        );

        expect(match, isNotNull, reason: receiptCase.line);
        expect(match!.item.trade, receiptCase.trade, reason: receiptCase.line);
        expect(match.needsReview, isTrue, reason: receiptCase.line);
        _expectEvidence(match, receiptCase.evidence, receiptCase.line);
      }
    });
  });
}

void _expectEvidence(
  ReceiptLineMatch match,
  Set<String> expectedTerms,
  String receiptLine,
) {
  final evidence = match.matchedTerms.join(' ').toLowerCase();
  for (final term in expectedTerms) {
    expect(
      evidence.contains(term),
      isTrue,
      reason: 'Expected "$term" evidence for $receiptLine; got $evidence.',
    );
  }
}
