import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android native receipt camera keeps experimental live quality warnings behind future opt-in policy',
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
          'return readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"',
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
    },
  );
}
