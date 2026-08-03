import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'long receipt capture keeps readable neighbor guides out of the center',
    () {
      final androidGuide = File(
        'android/app/src/main/kotlin/com/maintainiac/'
        'ReceiptCameraPreviousSectionGuide.kt',
      ).readAsStringSync();
      final androidChrome = File(
        'android/app/src/main/kotlin/com/maintainiac/'
        'ReceiptCameraUiChrome.kt',
      ).readAsStringSync();
      final reviewExit = File(
        'lib/shared/widgets/receipt_capture/'
        'receipt_photo_review_exit_actions.dart',
      ).readAsStringSync();

      expect(androidGuide, contains('buildPreviousSectionGuide'));
      expect(androidGuide, contains('buildNextSectionGuide'));
      expect(
        androidGuide,
        contains(
          'Top overlap guide showing the bottom of the previous receipt photo',
        ),
      );
      expect(
        androidGuide,
        contains(
          'Bottom overlap guide showing the top of the next receipt photo',
        ),
      );
      expect(androidGuide, contains('guidePanel(Gravity.TOP'));
      expect(androidGuide, contains('guidePanel(Gravity.BOTTOM'));
      expect(androidGuide, contains('dp(152)'));
      expect(androidGuide, contains('setBackgroundColor(Color.BLACK)'));
      expect(androidGuide, contains('guideImage(alpha: Float)'));
      expect(androidGuide, contains('Line up 3-5 readable lines at the top.'));
      expect(androidGuide, isNot(contains('TextView')));
      expect(
        androidChrome,
        contains('Pinch to zoom'),
        reason:
            'The gesture must be discoverable without covering receipt text.',
      );
      expect(
        androidChrome,
        contains('Pinch the receipt view with two fingers to zoom'),
      );
      expect(
        androidChrome,
        contains('cameraRootView.addView(buildNextSectionGuide())'),
      );
      expect(reviewExit, contains('Future<void> handleReceiptReviewBack()'));
      expect(reviewExit, contains('_ReceiptReviewMode.stitch'));
      expect(reviewExit, contains('_ReceiptReviewMode.dataSaver'));
    },
  );
}
