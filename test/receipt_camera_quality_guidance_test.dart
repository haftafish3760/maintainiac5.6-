import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'receipt quality scoring gives real receipts a bounded review score',
    () {
      const unreadable = ReceiptPhotoQualityCheck(
        width: 0,
        height: 0,
        focusScore: 0,
        isLikelyReadable: false,
      );
      const blurry = ReceiptPhotoQualityCheck(
        width: 900,
        height: 1100,
        focusScore: 5,
        isLikelyReadable: false,
      );
      const readable = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 14,
        isLikelyReadable: true,
      );

      expect(unreadable.reviewScore, 0);
      expect(blurry.reviewScore, inInclusiveRange(1, 60));
      expect(readable.reviewScore, greaterThan(blurry.reviewScore));
      expect(readable.reviewScore, inInclusiveRange(80, 100));
      expect(blurry.focusLabel, 'may be blurry');
      expect(readable.focusLabel, 'sharp');
    },
  );

  test(
    'camera assistance keeps red yellow green live quality states',
    () async {
      final assistSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_assist.dart',
      ).readAsString();
      final analysisSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart',
      ).readAsString();
      final barsSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_bars.dart',
      ).readAsString();

      expect(assistSource, contains("title: 'Not Ready: Low Light'"));
      expect(assistSource, contains("title: 'Almost Ready: Lines'"));
      expect(assistSource, contains("title: 'Ready'"));
      expect(assistSource, contains('Color(0xFFFF4D5E)'));
      expect(assistSource, contains('Color(0xFFFFD166)'));
      expect(assistSource, contains('Color(0xFF8EF6A4)'));
      expect(analysisSource, contains('_ReceiptCameraReadiness.notReady'));
      expect(analysisSource, contains('_ReceiptCameraReadiness.almostReady'));
      expect(analysisSource, contains('_ReceiptCameraReadiness.ready'));
      expect(barsSource, contains('_CameraQualityStrip'));
      expect(barsSource, contains("=> 'Not ready'"));
      expect(barsSource, contains("=> 'Almost ready'"));
      expect(barsSource, contains("=> 'Ready'"));
    },
  );
}
