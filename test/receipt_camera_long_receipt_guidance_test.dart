import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('long receipt review keeps the simple numbered decision flow', () async {
    final controls = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    );
    final primaryRow = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    );
    final tray = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    );

    expect(
      controls,
      contains("return photoPaths.length > 1 ? 'Continue' : 'Use Receipt'"),
    );
    expect(
      primaryRow,
      contains('_ReceiptPhotoCountBadge(current: current, total: total)'),
    );
    expect(primaryRow, contains("uiConfig.labelFor('addPhoto'"));
    expect(primaryRow, isNot(contains('Add Bottom Section')));
    expect(tray, contains('_ReceiptOrderThumbnail('));
    expect(tray, isNot(contains('_ReceiptMultiPhotoActionRail(')));
  });

  test(
    'adding or retaking a section returns through the system camera',
    () async {
      final captureActions = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
      );

      expect(captureActions, contains('Future<void> addAnotherReceiptPhoto()'));
      expect(
        captureActions,
        contains('alignmentGuidePhotoPath: guidePhotoPath'),
      );
      expect(captureActions, isNot(contains('showAlignmentGuide: false')));
      expect(
        captureActions,
        contains('ReceiptPhotoRetakeAlignmentContext.build('),
      );
      expect(
        captureActions,
        contains('retakeContext?.preferredGuidePhotoPath'),
      );
      expect(
        captureActions,
        contains('ReceiptImagePicker.takeReceiptPhotoSet()'),
      );
    },
  );

  test('overlap guide previews the real previous section before capture', () async {
    final guideActions = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
    );
    final guidePreview = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart',
    );

    expect(guideActions, contains('_showLongReceiptAlignmentGuide('));
    expect(
      guideActions,
      contains('_ReceiptAlignmentGuidePreview(photoPath: photoPath)'),
    );
    expect(guidePreview, contains('Image.file('));
    expect(guidePreview, contains('alignment: Alignment.bottomCenter'));
    expect(
      guidePreview,
      contains('Repeat 3-5 readable lines from this bottom area'),
    );
  });

  test('multi-photo continuation opens the stitch decision before OCR', () async {
    final saveActions = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    );
    final stitchPreview = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
    );

    expect(saveActions, contains('if (_needsStitchReviewBeforeSave)'));
    expect(saveActions, contains('_reviewMode = _ReceiptReviewMode.stitch'));
    expect(saveActions, contains('_ensureStitchPreview(force: true)'));
    expect(
      stitchPreview,
      contains('ReceiptImageProcessor.stitchReceiptPhotosForOcr'),
    );
  });

  test('uploaded photo sets use the same review and stitching path', () async {
    final importActions = await _read(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    );

    expect(importActions, contains('ReceiptImagePicker.chooseReceiptImageSet'));
    expect(importActions, contains('await reviewPickedPhotoPaths('));
  });
}

Future<String> _read(String path) => File(path).readAsString();
