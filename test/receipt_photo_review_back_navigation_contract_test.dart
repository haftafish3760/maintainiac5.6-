import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'system and top-bar Back stay inside receipt review until preview',
    () async {
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();
      final exit = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
      ).readAsString();

      expect(build, contains('return PopScope('));
      expect(build, contains('canPop: _closingReview'));
      expect(
        build,
        contains('if (!didPop && !_closingReview) handleReceiptReviewBack();'),
      );
      expect(build, contains('onClose: handleReceiptReviewBack'));

      expect(exit, contains('case _ReceiptReviewMode.crop:'));
      expect(exit, contains('_cancelCropReview();'));
      expect(exit, contains('case _ReceiptReviewMode.dataSaver:'));
      expect(
        exit,
        contains(
          '_photoPaths.length > 1\n'
          '              ? _ReceiptReviewMode.stitch\n'
          '              : _ReceiptReviewMode.preview',
        ),
      );
      expect(exit, contains('case _ReceiptReviewMode.order:'));
      expect(exit, contains('case _ReceiptReviewMode.stitch:'));
      expect(exit, contains('case _ReceiptReviewMode.preview:'));
      expect(exit, contains('if (_returnToStitchOnPreviewBack &&'));
      expect(exit, contains('_setReviewMode(_ReceiptReviewMode.stitch);'));
      expect(exit, contains('await leaveReceiptReviewWithoutSaving();'));
      expect(build, contains('_returnToStitchOnPreviewBack = true;'));
      expect(
        exit,
        contains(
          'reserved for leaving receipt review itself, not for leaving matching',
        ),
      );
    },
  );
}
