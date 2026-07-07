import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS receipt guidance toggle cannot enable experimental quality claims',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final cameraController = sources.cameraController;

      final guidanceGetterStart = cameraController.indexOf(
        'func receiptGuidanceWarningsEnabled() -> Bool',
      );
      final guidanceSetterStart = cameraController.indexOf(
        'func setReceiptGuidanceWarningsEnabled(_ enabled: Bool)',
      );
      final guidanceSetterEnd = cameraController.indexOf(
        '\n}',
        guidanceSetterStart,
      );

      expect(guidanceGetterStart, greaterThanOrEqualTo(0));
      expect(guidanceSetterStart, greaterThan(guidanceGetterStart));
      expect(guidanceSetterEnd, greaterThan(guidanceSetterStart));

      final guidanceToggleBlock = cameraController.substring(
        guidanceGetterStart,
        guidanceSetterEnd,
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
      expect(
        cameraController,
        contains('if !hasExperimentalReceiptQualityWarningsEnabled()'),
      );
      expect(
        cameraController,
        contains('func experimentalLiveReceiptQualityPolicyEnabled() -> Bool'),
      );
      expect(
        cameraController,
        contains(
          'readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"',
        ),
      );
      expect(
        cameraController,
        contains('latestReadabilitySignal = "neutral_workflow_guidance_only"'),
      );
    },
  );

  test('iOS camera guidance does not use fake rotating warning copy', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final combined = sources.cameraController;

    expect(combined, isNot(contains('Timer.scheduledTimer')));
    expect(combined, isNot(contains('DispatchQueue.main.asyncAfter')));
    expect(combined, isNot(contains('guidanceMessages')));
    expect(combined, isNot(contains('warningCarousel')));
    expect(combined, isNot(contains('randomGuidance')));
  });
}
