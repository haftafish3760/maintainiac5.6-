import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'release-one camera fixture matrix covers required failure families',
    () {
      final scenarios = receiptCameraReleaseOneFixtureExpectations
          .map((expectation) => expectation.scenario)
          .toSet();

      expect(scenarios, containsAll(ReceiptCameraFixtureScenario.values));
      expect(
        receiptCameraReleaseOneFixtureExpectationByScenario.length,
        ReceiptCameraFixtureScenario.values.length,
      );
    },
  );

  test(
    'camera fixture expectations keep OCR source and privacy rules stable',
    () {
      for (final expectation in receiptCameraReleaseOneFixtureExpectations) {
        expect(expectation.shouldUseOcrSourceFirst, isTrue);
        expect(expectation.description, isNotEmpty);
        expect(expectation.privacySafeRegressionBucket, isNotEmpty);
        expect(
          expectation.privacySafeRegressionBucket,
          isNot(anyOf(contains('/'), contains(r'\'), contains('@'))),
        );
        expect(
          expectation.privacySafeMetadata.toString(),
          isNot(anyOf(contains('/tmp'), contains('.jpg'), contains('.png'))),
        );
      }
    },
  );

  test('long receipt fixture families lock stitch and fallback behavior', () {
    final matrix = receiptCameraReleaseOneFixtureExpectationByScenario;
    final strong =
        matrix[ReceiptCameraFixtureScenario.longReceiptStrongOverlap]!;
    final weak = matrix[ReceiptCameraFixtureScenario.longReceiptWeakOverlap]!;
    final duplicate = matrix[ReceiptCameraFixtureScenario.duplicateSection]!;
    final oversized = matrix[ReceiptCameraFixtureScenario.oversizedStitch]!;

    expect(strong.expectsStitchedImage, isTrue);
    expect(strong.shouldUseOrderedFallback, isFalse);
    expect(
      weak.expectedStitchSafetyCode,
      {'ordered_sections_after_overlap_confidence_low_fallback'}.single,
    );
    expect(weak.shouldUseOrderedFallback, isTrue);
    expect(weak.requiresManualReview, isTrue);
    expect(duplicate.shouldUseOrderedFallback, isTrue);
    expect(duplicate.expectedQualityWarnings, contains('duplicate_overlap'));
    expect(
      oversized.expectedQualityWarnings,
      contains('large_image_memory_guard'),
    );
    expect(oversized.shouldUseOrderedFallback, isTrue);
  });

  test('coverage fixtures identify when more receipt photos are needed', () {
    final matrix = receiptCameraReleaseOneFixtureExpectationByScenario;
    final cropped = matrix[ReceiptCameraFixtureScenario.croppedEdges]!;
    final missingBottom =
        matrix[ReceiptCameraFixtureScenario.missingBottomTotals]!;
    final clean = matrix[ReceiptCameraFixtureScenario.cleanSingleReceipt]!;

    expect(
      cropped.expectedCoverageStatus,
      ReceiptPhotoCoverageStatus.likelyCutOff,
    );
    expect(cropped.requiresMorePhotos, isTrue);
    expect(
      missingBottom.expectedCoverageStatus,
      ReceiptPhotoCoverageStatus.maybeContinues,
    );
    expect(missingBottom.requiresMorePhotos, isTrue);
    expect(missingBottom.expectedQualityWarnings, contains('missing_total'));
    expect(clean.requiresMorePhotos, isFalse);
    expect(clean.requiresManualReview, isFalse);
  });

  test('barcode and bad input fixtures stay in camera handoff scope', () {
    final matrix = receiptCameraReleaseOneFixtureExpectationByScenario;
    final barcode = matrix[ReceiptCameraFixtureScenario.barcodeQrPresent]!;
    final corrupted = matrix[ReceiptCameraFixtureScenario.corruptedImageFile]!;
    final wrongType = matrix[ReceiptCameraFixtureScenario.wrongFileType]!;
    final empty = matrix[ReceiptCameraFixtureScenario.emptyImage]!;

    expect(barcode.expectsBarcodeHandoff, isTrue);
    expect(barcode.requiresManualReview, isFalse);
    expect(corrupted.requiresManualReview, isTrue);
    expect(
      corrupted.expectedStitchSafetyCode,
      'image_decode_failed_recoverable',
    );
    expect(
      wrongType.expectedStitchSafetyCode,
      'image_type_rejected_recoverable',
    );
    expect(empty.expectedStitchSafetyCode, 'empty_image_rejected_recoverable');
  });
}
