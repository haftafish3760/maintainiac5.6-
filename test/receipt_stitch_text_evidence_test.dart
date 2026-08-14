import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_text_evidence.dart';

ReceiptStitchTextEvidence section(String path, List<String> lines) {
  return ReceiptStitchTextEvidence(path: path, lines: lines);
}

ReceiptStitchTextEvidence positionedSection(
  String path,
  List<(String, double)> lines,
) {
  return ReceiptStitchTextEvidence(
    path: path,
    lines: [for (final line in lines) line.$1],
    positionedLines: [
      for (final line in lines)
        ReceiptStitchTextLineEvidence(
          text: line.$1,
          left: .08,
          top: line.$2,
          right: .92,
          bottom: line.$2 + .04,
        ),
    ],
  );
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

    test('does not reorder indistinguishable repeated-item sections', () {
      final original = [
        section('selected-1', [
          'Independent Hardware Receipt',
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
        ]),
        section('selected-2', [
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
        ]),
        section('selected-3', [
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
          'Copper elbow half inch 2.49',
          'Total 24.90',
        ]),
      ];

      final plan = ReceiptStitchOrderPlan.fromEvidence(original);

      expect(plan.changed, isFalse);
      expect(plan.requiresReview, isTrue);
      expect(plan.orderedPaths, ['selected-1', 'selected-2', 'selected-3']);
      expect(plan.reasonCode, 'ocr_overlap_order_ambiguous');
    });

    test('distinct shared lines can safely accelerate upright geometry', () {
      final previous = section('top', [
        'Independent Supply Receipt',
        'Copper elbow half inch 2.49',
        'Exterior screws three inch 12.40',
      ]);
      final next = section('bottom', [
        'Copper elbow half inch 2.49',
        'Exterior screws three inch 12.40',
        'Subtotal 14.89',
      ]);
      final match = matchReceiptStitchTextOverlap(previous, next);

      expect(match.isStrong, isTrue);
      expect(match.matchedLineCount, 2);
      expect(
        receiptStitchTextSafelyAcceleratesGeometry(previous, next, match),
        isTrue,
      );
    });

    test('identical repeated purchases never accelerate geometry', () {
      final previous = section('top', [
        'Independent Supply Receipt',
        'Copper elbow half inch 2.49',
        'Copper elbow half inch 2.49',
        'Copper elbow half inch 2.49',
      ]);
      final next = section('bottom', [
        'Copper elbow half inch 2.49',
        'Copper elbow half inch 2.49',
        'Copper elbow half inch 2.49',
        'Subtotal 24.90',
      ]);
      final match = matchReceiptStitchTextOverlap(previous, next);

      expect(match.isStrong, isTrue);
      expect(match.matchedLineCount, greaterThanOrEqualTo(2));
      expect(
        receiptStitchTextSafelyAcceleratesGeometry(previous, next, match),
        isFalse,
      );
    });

    test('keeps normalized line positions with the overlap decision', () {
      final match = matchReceiptStitchTextOverlap(
        positionedSection('top', [
          ('Independent Supply Receipt', .08),
          ('Copper elbow half inch 2.49', .76),
          ('Exterior screws three inch 12.40', .86),
        ]),
        positionedSection('bottom', [
          ('Copper elbow half inch 2.49', .06),
          ('Exterior screws three inch 12.40', .16),
          ('Subtotal 14.89', .82),
        ]),
      );

      expect(match.isStrong, isTrue);
      expect(match.hasPositionalEvidence, isTrue);
      expect(match.positionalConfidence, greaterThan(.75));
      expect(match.previousOverlapStart, closeTo(.76, .001));
      expect(match.nextOverlapEnd, closeTo(.20, .001));
      expect(match.nextContinuationStart, closeTo(.82, .001));
      expect(match.nextContinuationEnd, closeTo(.86, .001));
    });

    test('matches a long OCR overlap even when one read inserts a line', () {
      final shared = [
        for (var index = 0; index < 12; index++)
          'Hardware item $index code ${410000 + index} ${index + 1}.49',
      ];
      final previous = positionedSection('top', [
        ('Independent Supply Receipt', .08),
        for (var index = 0; index < shared.length; index++)
          (shared[index], .42 + index * .04),
        ('Subtotal 149.88', .91),
        ('Total 161.12', .95),
      ]);
      final next = positionedSection('bottom', [
        for (var index = 0; index < shared.length; index++) ...[
          (shared[index], .02 + index * .035),
          if (index == 4) ('Wrinkle read as an extra line', .18),
        ],
        ('Subtotal 149.88', .45),
        ('Total 161.12', .49),
        ('Card payment approved', .78),
      ]);

      final match = matchReceiptStitchTextOverlap(previous, next);

      expect(match.isStrong, isTrue);
      expect(match.usesSparsePositionAnchors, isTrue);
      expect(match.matchedLineCount, greaterThanOrEqualTo(10));
      expect(
        receiptStitchTextSafelyAcceleratesGeometry(previous, next, match),
        isTrue,
      );
    });

    test(
      'keeps the fuller overlap when a shorter match scores slightly higher',
      () {
        final previous = section('top', [
          'Merchant heading 4411',
          'Copper elbow half inch 2.49',
          'Exterior screws three inch 12.40',
          'Arm hammer detergent 14.97',
          'Diet mountain dew 6.48',
        ]);
        final next = section('bottom', [
          'Copper elbow half in 2.49',
          'Exterior screws three in 12.40',
          'Arm hammer detergent 14.97',
          'Diet mountain dew 6.48',
          'Subtotal 36.34',
        ]);

        final match = matchReceiptStitchTextOverlap(previous, next);

        expect(match.isStrong, isTrue);
        expect(match.matchedLineCount, 4);
      },
    );

    test('keeps horizontal, width, and angle anchors for registration', () {
      ReceiptStitchTextEvidence evidence(
        String path,
        List<ReceiptStitchTextLineEvidence> lines,
      ) {
        return ReceiptStitchTextEvidence(
          path: path,
          lines: [for (final line in lines) line.text],
          positionedLines: lines,
        );
      }

      final match = matchReceiptStitchTextOverlap(
        evidence('top', const [
          ReceiptStitchTextLineEvidence(
            text: 'Copper elbow half inch 2.49',
            left: .16,
            top: .76,
            right: .76,
            bottom: .80,
            angleDegrees: 1.4,
          ),
          ReceiptStitchTextLineEvidence(
            text: 'Exterior screws three inch 12.40',
            left: .20,
            top: .86,
            right: .84,
            bottom: .90,
            angleDegrees: 1.2,
          ),
        ]),
        evidence('bottom', const [
          ReceiptStitchTextLineEvidence(
            text: 'Copper elbow half inch 2.49',
            left: .10,
            top: .06,
            right: .66,
            bottom: .10,
            angleDegrees: -.4,
          ),
          ReceiptStitchTextLineEvidence(
            text: 'Exterior screws three inch 12.40',
            left: .14,
            top: .16,
            right: .74,
            bottom: .20,
            angleDegrees: -.6,
          ),
        ]),
      );

      expect(match.hasPositionalEvidence, isTrue);
      expect(match.previousAnchorCentersX, [.46, .52]);
      expect(match.nextAnchorCentersX, [.38, .44]);
      expect(match.previousAnchorWidths[0], closeTo(.60, .0001));
      expect(match.previousAnchorWidths[1], closeTo(.64, .0001));
      expect(match.nextAnchorWidths[0], closeTo(.56, .0001));
      expect(match.nextAnchorWidths[1], closeTo(.60, .0001));
      expect(match.previousAnchorAngles, [1.4, 1.2]);
      expect(match.nextAnchorAngles, [-.4, -.6]);
    });

    test('rejects text overlap that runs backward through the document', () {
      final match = matchReceiptStitchTextOverlap(
        positionedSection('top', [
          ('Copper elbow half inch 2.49', .05),
          ('Exterior screws three inch 12.40', .15),
          ('Later unique item 9.99', .85),
        ]),
        positionedSection('bottom', [
          ('Earlier unique item 8.99', .10),
          ('Copper elbow half inch 2.49', .80),
          ('Exterior screws three inch 12.40', .90),
        ]),
      );

      expect(match.isStrong, isFalse);
    });

    test('orders eight sections with bounded path search', () {
      final evidence = <ReceiptStitchTextEvidence>[];
      for (var index = 0; index < 8; index++) {
        evidence.add(
          section('section-$index', [
            if (index == 0) 'Independent Supply Receipt',
            if (index > 0) 'Bridge ${index - 1} item A',
            if (index > 0) 'Bridge ${index - 1} item B',
            'Section $index unique item 12.34',
            if (index < 7) 'Bridge $index item A',
            if (index < 7) 'Bridge $index item B',
            if (index == 7) 'Total 199.99',
          ]),
        );
      }
      final shuffled = [
        evidence[5],
        evidence[2],
        evidence[7],
        evidence[0],
        evidence[4],
        evidence[1],
        evidence[6],
        evidence[3],
      ];

      final plan = ReceiptStitchOrderPlan.fromEvidence(shuffled);

      expect(plan.changed, isTrue);
      expect(plan.requiresReview, isFalse);
      expect(plan.orderedPaths, [
        for (var index = 0; index < 8; index++) 'section-$index',
      ]);
      expect(plan.reasonCode, 'ocr_overlap_order_corrected');
    });

    test('header and footer topology resolves a circular overlap tie', () {
      final plan = ReceiptStitchOrderPlan.fromEvidence([
        section('middle', [
          'Loop B item one 4.00',
          'Loop B item two 5.00',
          'Loop C item one 6.00',
          'Loop C item two 7.00',
        ]),
        section('bottom', [
          'Loop C item one 6.00',
          'Loop C item two 7.00',
          'Loop A item one 2.00',
          'Loop A item two 3.00',
          'Subtotal 27.00',
          'Total 29.16',
          'Thank you',
        ]),
        section('top', [
          'Independent Store Receipt',
          'Address 10 Main Street',
          'Loop A item one 2.00',
          'Loop A item two 3.00',
          'Loop B item one 4.00',
          'Loop B item two 5.00',
        ]),
      ]);

      expect(plan.changed, isTrue);
      expect(plan.requiresReview, isFalse);
      expect(plan.orderedPaths, ['top', 'middle', 'bottom']);
    });

    test('keeps ambiguous eight-section repeated purchases selected', () {
      final evidence = [
        for (var index = 0; index < 8; index++)
          section('selected-$index', [
            'Copper elbow half inch 2.49',
            'Copper elbow half inch 2.49',
            'Copper elbow half inch 2.49',
          ]),
      ];

      final plan = ReceiptStitchOrderPlan.fromEvidence(evidence);

      expect(plan.changed, isFalse);
      expect(plan.requiresReview, isTrue);
      expect(plan.orderedPaths, [
        for (var index = 0; index < 8; index++) 'selected-$index',
      ]);
      expect(plan.reasonCode, 'ocr_overlap_order_ambiguous');
    });
  });
}
