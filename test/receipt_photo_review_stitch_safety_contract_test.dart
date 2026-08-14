import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'automatic stitching rejects a weak join instead of presenting proof',
    () async {
      final stitchApi =
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_sources.dart',
          ).readAsString();

      expect(
        stitchApi,
        contains('lowConfidenceTransformIsAggressive'),
        reason: 'A weak overlap must preserve original photos for recovery.',
      );
      expect(stitchApi, isNot(contains('!match.isReviewableJoin')));
      expect(
        stitchApi,
        contains(
          '.map((image) => _resizeToWidth(image, effectiveTargetWidth))',
        ),
        reason: 'A safe source crop must not be applied a second time.',
      );
    },
  );

  test(
    'combined-receipt thumbnail opens its selected original photo',
    () async {
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();

      expect(build, contains('if (_reviewMode == _ReceiptReviewMode.stitch)'));
      expect(build, contains('_setReviewMode(_ReceiptReviewMode.preview);'));
    },
  );

  test(
    'automatic-stitch recovery targets the failed pair for retake or manual alignment',
    () async {
      final controls = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_controls.dart',
      ).readAsString();
      final recovery = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_stitch_pair_preview.dart',
      ).readAsString();
      final asyncWork = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_async_work.dart',
      ).readAsString();

      expect(controls, isNot(contains('_ReceiptManualStitchControls(')));
      expect(recovery, contains('Could not safely combine every section'));
      expect(recovery, contains(r'Align ${widget.sectionNumberLabel}'));
      expect(recovery, contains('return and retake a section'));
      expect(recovery, contains('sectionNumberLabel'));
      expect(
        asyncWork,
        isNot(contains('_toolControlsScrollController.hasClients')),
        reason:
            'Visible stitch controls must remain active without the edit toolbar.',
      );
    },
  );

  test(
    'saved proof previews the combined clear proof without scanner cleanup',
    () async {
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();
      final asyncWork = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_async_work.dart',
      ).readAsString();

      expect(build, contains('final savedProofSourcePath'));
      expect(
        build,
        matches(
          RegExp(
            r'dataSaverPreviewPath\s*\?\?\s*savedProofSourcePath',
            multiLine: true,
          ),
        ),
      );
      expect(asyncWork, contains('String _dataSaverPreviewSource('));
      expect(asyncWork, contains('await ReceiptImageProcessor.optimizeFile('));
      expect(asyncWork, isNot(contains('optimizePreparedBackupFile(')));
      expect(asyncWork, contains('await ReceiptImageProcessor.previewFile('));
      expect(asyncWork, isNot(contains('previewPreparedBackupFile(')));
    },
  );

  test(
    'three or more sections expose every adjacent join for recovery',
    () async {
      final workingSurface = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_stitch_pair_preview.dart',
      ).readAsString();
      final pairNavigator = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_stitch_pair_navigator.dart',
      ).readAsString();
      final stitchSurface = await File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_stitch_surface.dart',
      ).readAsString();

      expect(workingSurface, contains('photoPaths.length > 2'));
      expect(workingSurface, contains('pairCount: photoPaths.length - 1'));
      expect(pairNavigator, contains('Previous receipt join'));
      expect(pairNavigator, contains('Next receipt join'));
      expect(
        pairNavigator,
        contains(r'Sections ${selected + 1} + ${selected + 2}'),
      );
      expect(stitchSurface, contains('onPairSelected: _selectStitchPairIndex'));
    },
  );
}
