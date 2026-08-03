import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

import 'helpers/receipt_camera_source_readers.dart';
import 'helpers/receipt_stitching_image_helpers.dart';

void main() {
  test(
    'phase 6 final stitch handoff keeps preview disposable until Use Receipt',
    () async {
      final saveActions = await readReceiptPhotoReviewSaveActionsSource();
      final reviewScreen = await readReceiptPhotoReviewScreenSource();
      final stitchPreviewAsync = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
      ).readAsString();
      final stitchExitActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
      ).readAsString();
      final imageProcessor = await File(
        'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
      ).readAsString();

      expect(
        saveActions,
        contains('Future<void> continueReceiptPhotoReview()'),
      );
      expect(saveActions, contains('_needsStitchReviewBeforeSave'));
      expect(
        saveActions,
        contains('_setReviewMode(_ReceiptReviewMode.stitch)'),
      );
      expect(saveActions, contains('_ensureStitchPreview(force: true)'));
      expect(
        saveActions,
        contains(
          "stitchPreview.fallbackReasonCode == 'duplicate_section_image'",
        ),
      );
      expect(
        saveActions,
        contains(
          'Remove or replace the highlighted duplicate before continuing.',
        ),
      );
      expect(saveActions, contains('_reviewMode = _ReceiptReviewMode.order;'));
      expect(
        saveActions,
        contains('final stitchFuture = _finalStitchResultForOcr('),
      );
      expect(saveActions, contains("fallbackReasonCode: 'stitch_timeout'"));
      expect(
        saveActions,
        contains('_deleteStitchPreviewPath(lateStitch.stitchedPath)'),
      );
      expect(saveActions, contains('await _deleteGeneratedStitchPreview();'));
      expect(
          saveActions.indexOf('prepareForOcrAndBackup('),
        lessThan(
          saveActions.indexOf('final stitchFuture = _finalStitchResultForOcr('),
        ),
      );

      expect(
        stitchPreviewAsync,
        contains('ReceiptImageProcessor.stitchReceiptPhotosForOcr('),
      );
      expect(stitchPreviewAsync, contains('const Duration(seconds: 15)'));
      expect(stitchPreviewAsync, contains('stitch_preview_timeout'));
      expect(
        stitchPreviewAsync,
        contains(
          'They will stay in order as separate photos so you can continue.',
        ),
      );
      expect(
        stitchPreviewAsync,
        contains('_deleteStitchPreviewPath(lateResult.stitchedPath)'),
      );
      expect(
        stitchPreviewAsync,
        contains('// Best effort cleanup for app-created stitch previews.'),
      );
      expect(
        stitchExitActions,
        contains(
          'if (previewCanBeUsed &&\n'
          '        (preview.usedFallback ||\n'
          '            preview.status == ReceiptStitchStatus.notNeeded)) {',
        ),
      );
      expect(
        stitchExitActions,
        contains('ReceiptImageProcessor.copyReceiptOcrArtifact('),
      );
      expect(stitchExitActions, contains('preview.copyForFinalOcr('));
      expect(
        stitchExitActions,
        contains('return ReceiptImageProcessor.stitchReceiptPhotosForOcr('),
      );
      expect(imageProcessor, contains('copyReceiptOcrArtifact'));

      expect(
        reviewScreen.indexOf('_stitchPreviewResult'),
        lessThan(reviewScreen.indexOf('_deleteGeneratedStitchPreview')),
      );
    },
  );

  test(
    'phase 6 stitched handoff produces a derived OCR artifact while preserving original ordered sections',
    () {
      final preview = ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
        ocrSourcePaths: ['/tmp/preview-stitched.jpg'],
        stitchedPath: '/tmp/preview-stitched.jpg',
        confidence: .92,
        overlapPixels: [244],
        stitchedWidth: 1080,
        stitchedHeight: 2280,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 244,
            confidence: .92,
          ),
        ],
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: const ['/tmp/prepared-top.jpg', '/tmp/prepared-bottom.jpg'],
        ocrSourcePaths: const ['/tmp/final-stitched.jpg'],
        stitchedPath: '/tmp/final-stitched.jpg',
      );

      expect(finalResult.didStitch, isTrue);
      expect(finalResult.usesDerivedCombinedOcrArtifact, isTrue);
      expect(finalResult.inputPaths, [
        '/tmp/prepared-top.jpg',
        '/tmp/prepared-bottom.jpg',
      ]);
      expect(finalResult.ocrSourcePaths, ['/tmp/final-stitched.jpg']);
      expect(
        finalResult.sourcePreservationCode,
        'original_sections_preserved_derived_stitched_ocr_artifact',
      );
      expect(finalResult.hasValidOcrSourceContract, isTrue);
      expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
      expect(
        finalResult.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrHandoffUsesCombinedImage', true),
      );
      expect(
        finalResult.privacySafeOcrHandoffSafety,
        containsPair('stitchOcrHandoffUsesOrderedSections', false),
      );
    },
  );

  test(
    'phase 6 five-section stitched handoff still uses one derived OCR artifact',
    () {
      final preview = ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: [
          for (var index = 1; index <= 5; index++) '/tmp/raw-$index.jpg',
        ],
        ocrSourcePaths: ['/tmp/preview-five-section-stitched.jpg'],
        stitchedPath: '/tmp/preview-five-section-stitched.jpg',
        confidence: .91,
        overlapPixels: [242, 238, 246, 240],
        stitchedWidth: 1080,
        stitchedHeight: 6120,
        pairs: const [
          ReceiptStitchPairResult(
            pairIndex: 0,
            overlapPixels: 242,
            confidence: .91,
          ),
          ReceiptStitchPairResult(
            pairIndex: 1,
            overlapPixels: 238,
            confidence: .92,
          ),
          ReceiptStitchPairResult(
            pairIndex: 2,
            overlapPixels: 246,
            confidence: .93,
          ),
          ReceiptStitchPairResult(
            pairIndex: 3,
            overlapPixels: 240,
            confidence: .91,
          ),
        ],
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: [
          for (var index = 1; index <= 5; index++) '/tmp/prepared-$index.jpg',
        ],
        ocrSourcePaths: const ['/tmp/final-five-section-stitched.jpg'],
        stitchedPath: '/tmp/final-five-section-stitched.jpg',
      );

      expect(finalResult.didStitch, isTrue);
      expect(finalResult.inputPaths, hasLength(5));
      expect(finalResult.ocrSourcePaths, [
        '/tmp/final-five-section-stitched.jpg',
      ]);
      expect(finalResult.usesDerivedCombinedOcrArtifact, isTrue);
      expect(finalResult.ocrSourceContractCode, 'stitched_ocr_source_ready');
      expect(
        finalResult.sourcePreservationCode,
        'original_sections_preserved_derived_stitched_ocr_artifact',
      );
      expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
      expect(finalResult.overlapPixels, [242, 238, 246, 240]);
    },
  );

  test(
    'phase 6 ordered fallback preview can be rebound for final OCR without losing review metadata',
    () {
      final preview = ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/raw-top.jpg', '/tmp/raw-bottom.jpg'],
        warning: 'Overlap was not clear enough.',
        fallbackReasonCode: 'overlap_confidence_low',
        confidence: .34,
        failedPairIndex: 0,
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: const ['/tmp/prepared-top.jpg', '/tmp/prepared-bottom.jpg'],
        ocrSourcePaths: const [
          '/tmp/prepared-top.jpg',
          '/tmp/prepared-bottom.jpg',
        ],
      );

      expect(finalResult.usedFallback, isTrue);
      expect(finalResult.didStitch, isFalse);
      expect(finalResult.inputPaths, [
        '/tmp/prepared-top.jpg',
        '/tmp/prepared-bottom.jpg',
      ]);
      expect(finalResult.ocrSourcePaths, [
        '/tmp/prepared-top.jpg',
        '/tmp/prepared-bottom.jpg',
      ]);
      expect(finalResult.failedPairIndex, 0);
      expect(finalResult.failedPairLabel, 'Photo 1 to 2');
      expect(finalResult.fallbackReasonCode, 'overlap_confidence_low');
      expect(finalResult.warning, 'Overlap was not clear enough.');
    },
  );

  test(
    'phase 6 oversized stitch fallback keeps ordered OCR sources review blocked',
    () {
      final preview = ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/raw-section-1.jpg',
          '/tmp/raw-section-2.jpg',
          '/tmp/raw-section-3.jpg',
          '/tmp/raw-section-4.jpg',
          '/tmp/raw-section-5.jpg',
        ],
        warning: 'Receipt is too long to stitch safely on this device.',
        fallbackReasonCode: 'output_too_large',
        stitchedWidth: 1200,
        stitchedHeight: 21000,
      );

      final finalResult = preview.copyForFinalOcr(
        inputPaths: const [
          '/tmp/prepared-section-1.jpg',
          '/tmp/prepared-section-2.jpg',
          '/tmp/prepared-section-3.jpg',
          '/tmp/prepared-section-4.jpg',
          '/tmp/prepared-section-5.jpg',
        ],
        ocrSourcePaths: const [
          '/tmp/prepared-section-1.jpg',
          '/tmp/prepared-section-2.jpg',
          '/tmp/prepared-section-3.jpg',
          '/tmp/prepared-section-4.jpg',
          '/tmp/prepared-section-5.jpg',
        ],
      );

      expect(finalResult.usedFallback, isTrue);
      expect(finalResult.didStitch, isFalse);
      expect(finalResult.fallbackReasonCode, 'output_too_large');
      expect(
        finalResult.ocrSourceContractCode,
        'fallback_derived_stitch_too_large',
      );
      expect(finalResult.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(
        finalResult.assistedReadinessCode,
        'stitch_contract_review_required',
      );
      expect(
        finalResult.sourcePreservationCode,
        'original_sections_preserved_ordered_ocr_sources',
      );
      expect(finalResult.reviewPathLabel, '5 receipt sections top to bottom');
      expect(finalResult.stitchedPixelCount, greaterThan(16000000));
    },
  );

  test(
    'phase 6 overlap removal collapses repeated receipt lines instead of stacking full heights',
    () async {
      final top = receiptStitchingSection(seed: 140, topTextOffset: 0);
      final bottom = receiptStitchingSection(seed: 141, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: bottom, pixels: 336);

      final topFile = await writeTempReceiptStitchingImage(
        top,
        'phase6_overlap_top',
      );
      final bottomFile = await writeTempReceiptStitchingImage(
        bottom,
        'phase6_overlap_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, bottomFile.path],
      );

      expect(result.didStitch, isTrue, reason: result.detailLabel);
      expect(result.usedFallback, isFalse);
      expect(result.overlapPixels, hasLength(1));
      expect(result.overlapPixels.single, greaterThan(120));
      expect(result.matchedPairCount, 1);
      expect(result.allPairsHaveOverlapEvidence, isTrue);
      expect(result.overlapPixelTotal, greaterThan(0));
      expect(result.usesDerivedCombinedOcrArtifact, isTrue);
      expect(
        result.sourcePreservationCode,
        'original_sections_preserved_derived_stitched_ocr_artifact',
      );
      expect(result.hasValidOcrSourceContract, isTrue);
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.assistedReadinessCode, 'stitched_overlap_review_required');
      expect(result.ocrHandoffSafetyCode, 'stitched_overlap_needs_review');
    },
  );

  test(
    'phase 6 low-confidence stitch falls back gracefully to ordered section review',
    () async {
      final top = receiptStitchingSection(seed: 160, topTextOffset: 0);
      final middle = receiptStitchingSection(seed: 161, topTextOffset: 18);
      copyReceiptStitchingOverlap(from: top, to: middle, pixels: 320);

      final topFile = await writeTempReceiptStitchingImage(
        top,
        'phase6_fallback_top',
      );
      final middleFile = await writeTempReceiptStitchingImage(
        middle,
        'phase6_fallback_middle',
      );
      final badBottomFile = await writeTempReceiptStitchingImage(
        blankDarkReceiptPhotoSection(),
        'phase6_fallback_bad_bottom',
      );

      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: [topFile.path, middleFile.path, badBottomFile.path],
      );

      expect(result.usedFallback, isTrue);
      expect(result.didStitch, isFalse);
      expect(result.failedPairIndex, anyOf(0, 1));
      expect(
        result.fallbackReasonCode,
        anyOf('overlap_confidence_low', 'duplicate_section_image'),
      );
      expect(result.ocrSourcePaths, [
        topFile.path,
        middleFile.path,
        badBottomFile.path,
      ]);
      expect(
        result.sourcePreservationCode,
        'original_sections_preserved_ordered_ocr_sources',
      );
      expect(result.hasValidOcrSourceContract, isFalse);
      expect(result.requiresOcrSourceReviewBeforeAssistedRead, isTrue);
      expect(result.assistedReadinessCode, 'stitch_contract_review_required');
      expect(result.reviewPathLabel, '3 receipt sections top to bottom');
      expect(
        result.ocrHandoffSafetyLabel,
        'OCR will read ordered sections because stitching was not trusted.',
      );
    },
  );
}
