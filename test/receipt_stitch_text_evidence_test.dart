import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_text_evidence.dart';

ReceiptStitchTextEvidence section(String path, List<String> lines) {
  return ReceiptStitchTextEvidence(path: path, lines: lines);
}

void main() {
  group('long receipt OCR overlap evidence', () {
    test('finds repeated suffix and prefix lines without merchant rules', () {
      final match = matchReceiptStitchTextOverlap(
        section('top', [
          'Unfamiliar Corner Shop',
          'Copper fitting 4.98',
          'Machine screw 2.10',
          'Work gloves 8.40',
        ]),
        section('bottom', [
          'Machine screw 2.10',
          'Work gloves 8.40',
          'Sealant 6.25',
          'TOTAL 21.73',
        ]),
      );

      expect(match.isStrong, isTrue);
      expect(match.matchedLineCount, 2);
    });

    test('tolerates ordinary OCR character errors in repeated lines', () {
      final match = matchReceiptStitchTextOverlap(
        section('top', [
          'Galvanized elbow 1/2 inch 4.98',
          'Exterior screws 3 inch 12.40',
        ]),
        section('bottom', [
          'Galvanized e1bow 1/2 inch 4.98',
          'Exterior screws 3 in 12.40',
          'Tax 1.31',
        ]),
      );

      expect(match.isStrong, isTrue);
      expect(match.confidence, greaterThan(.66));
    });

    test('reorders shuffled three-section receipt from repeated lines', () {
      final plan = ReceiptStitchOrderPlan.fromEvidence([
        section('bottom', [
          'Deck screws 18.49',
          'Safety glasses 7.99',
          'Subtotal 42.95',
          'Total 46.17',
          'Thank you',
        ]),
        section('top', [
          'Remote Valley Hardware',
          'Receipt 1883',
          'PVC coupling 3.49',
          'Copper elbow 5.99',
        ]),
        section('middle', [
          'PVC coupling 3.49',
          'Copper elbow 5.99',
          'Deck screws 18.49',
          'Safety glasses 7.99',
        ]),
      ]);

      expect(plan.changed, isTrue);
      expect(plan.requiresReview, isFalse);
      expect(plan.orderedPaths, ['top', 'middle', 'bottom']);
      expect(plan.reasonCode, 'ocr_overlap_order_corrected');
    });

    test('does not trust a common total label as section overlap', () {
      final match = matchReceiptStitchTextOverlap(
        section('a', ['Shop supplies 10.00', 'Subtotal 10.00', 'Total 10.80']),
        section('b', ['Total 10.80', 'Card payment 10.80', 'Thank you']),
      );

      expect(match.isStrong, isFalse);
    });

    test('preserves selected order when one section has no OCR evidence', () {
      final plan = ReceiptStitchOrderPlan.fromEvidence([
        section('selected-first', ['Remote Hardware', 'Item A 1.00']),
        section('selected-second', const []),
      ]);

      expect(plan.changed, isFalse);
      expect(plan.requiresReview, isTrue);
      expect(plan.orderedPaths, ['selected-first', 'selected-second']);
      expect(plan.reasonCode, 'insufficient_text_evidence');
    });

    test('orders six sections using only adjacent repeated content', () {
      final evidence = <ReceiptStitchTextEvidence>[];
      for (var sectionIndex = 0; sectionIndex < 6; sectionIndex++) {
        evidence.add(
          section('section-$sectionIndex', [
            if (sectionIndex == 0) 'Independent Supply Receipt',
            if (sectionIndex > 0) 'Bridge ${sectionIndex - 1} item A',
            if (sectionIndex > 0) 'Bridge ${sectionIndex - 1} item B',
            'Section $sectionIndex unique item 12.34',
            if (sectionIndex < 5) 'Bridge $sectionIndex item A',
            if (sectionIndex < 5) 'Bridge $sectionIndex item B',
            if (sectionIndex == 5) 'Total 99.99',
          ]),
        );
      }
      final shuffled = [
        evidence[3],
        evidence[0],
        evidence[5],
        evidence[2],
        evidence[1],
        evidence[4],
      ];

      final plan = ReceiptStitchOrderPlan.fromEvidence(shuffled);

      expect(plan.changed, isTrue);
      expect(plan.orderedPaths, [
        'section-0',
        'section-1',
        'section-2',
        'section-3',
        'section-4',
        'section-5',
      ]);
    });
  });
}
