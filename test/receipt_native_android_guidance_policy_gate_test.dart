import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native receipt camera enables standard live quality guidance',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final cameraActivity = sources.cameraActivity;

      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.experimentalLiveReceiptQualityPolicyEnabled(): Boolean',
        ),
      );
      expect(
        cameraActivity,
        contains(
          'readabilityGuidancePolicy == "native_camera_receipt_quality_guidance_v1"',
        ),
      );
      expect(
        cameraActivity,
        contains('if (!experimentalLiveReceiptQualityPolicyEnabled()) {'),
      );
      expect(
        cameraActivity,
        contains('val experimentalQualityWarningsEnabled ='),
      );
      expect(
        cameraActivity,
        contains(
          'internal fun ReceiptCameraActivity.enforceExperimentalReceiptQualityPolicyGuard()',
        ),
      );
      expect(
        cameraActivity,
        contains('enforceExperimentalReceiptQualityPolicyGuard()'),
      );
      expect(cameraActivity, contains('lowLightWarningEnabled = false'));
      expect(cameraActivity, contains('glareWarningEnabled = false'));
      expect(cameraActivity, contains('dirtyLensWarningEnabled = false'));
      expect(cameraActivity, contains('motionBlurWarningEnabled = false'));
      expect(cameraActivity, contains('shadowWarningEnabled = false'));
    },
  );

  test(
    'Android camera guidance does not use fake rotating warning copy',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final combined = sources.cameraActivity;

      expect(combined, isNot(contains('Timer(')));
      expect(combined, isNot(contains('guidanceMessages.postDelayed')));
      expect(combined, isNot(contains('guidanceMessages')));
      expect(combined, isNot(contains('warningCarousel')));
      expect(combined, isNot(contains('randomGuidance')));

      final guidanceToggleStart = combined.indexOf(
        'internal fun ReceiptCameraActivity.setReceiptGuidanceWarningsEnabled',
      );
      expect(guidanceToggleStart, greaterThanOrEqualTo(0));
      final guidanceToggleEnd = combined.indexOf('\n}', guidanceToggleStart);
      expect(guidanceToggleEnd, greaterThan(guidanceToggleStart));
      final guidanceToggleBlock = combined.substring(
        guidanceToggleStart,
        guidanceToggleEnd,
      );

      expect(guidanceToggleBlock, contains('tooFarTooCloseWarningEnabled'));
      expect(
        guidanceToggleBlock,
        contains('receiptFullyVisibleWarningEnabled'),
      );
      expect(guidanceToggleBlock, contains('textTooSmallWarningEnabled'));
      expect(guidanceToggleBlock, isNot(contains('shadowWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('dirtyLensWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('glareWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('lowLightWarningEnabled')));
      expect(guidanceToggleBlock, isNot(contains('motionBlurWarningEnabled')));
    },
  );
}
